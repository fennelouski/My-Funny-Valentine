#!/usr/bin/env python3
"""Root-native isolated check of actual card archive, identity adoption and revision decisions. No CloudKit client."""
from pathlib import Path
import subprocess
import tempfile
import plistlib
import re

def method(text, signature):
    start = text.index(signature)
    opening = text.index('{', start)
    end, depth = opening + 1, 1
    while depth:
        depth += (text[end] == '{') - (text[end] == '}')
        end += 1
    return text[start:end]

def check_cloud_configuration(project, entitlements, info):
    binding = 'CODE_SIGN_ENTITLEMENTS = "My Funny Valentine/My_Funny_Valentine.entitlements";'
    assert project.count(binding) == 2
    assert entitlements['com.apple.developer.icloud-container-identifiers'] == ['iCloud.com.nathanfennel.My-Funny-Valentine']
    assert entitlements['com.apple.developer.icloud-services'] == ['CloudKit']
    assert entitlements['com.apple.developer.icloud-container-environment'] == '$(MFV_CLOUDKIT_ENVIRONMENT)'
    target = method(project, '809F97F32F3E1B7E0059E1EF /* My Funny Valentine */ =')
    configuration_list = target.split('buildConfigurationList = ', 1)[1].split()[0]
    configurations = method(project, configuration_list + ' /* Build configuration list for PBXNativeTarget "My Funny Valentine" */ =')
    references = re.findall(r'([A-F0-9]{24}) /\* (Debug|Release) \*/', configurations)
    assert len(references) == 2 and {name for _, name in references} == {'Debug', 'Release'}
    assert project.count('MFV_CLOUDKIT_ENVIRONMENT =') == 2
    assert info['MFVCloudKitEnvironment'] == '$(MFV_CLOUDKIT_ENVIRONMENT)'
    info_binding = 'INFOPLIST_FILE = "My Funny Valentine/Info.plist";'
    assert project.count(info_binding) == 2
    assert 'INFOPLIST_KEY_MFVCloudKitEnvironment' not in project
    for identifier, name in references:
        configuration = method(project, identifier + ' /* ' + name + ' */ =')
        assert 'name = ' + name + ';' in configuration
        assert 'PRODUCT_BUNDLE_IDENTIFIER = "com.nathanfennel.My-Funny-Valentine";' in configuration
        assert configuration.count(binding) == 1
        assert configuration.count(info_binding) == 1
        environment = {'Debug': 'Development', 'Release': 'Production'}[name]
        assert 'MFV_CLOUDKIT_ENVIRONMENT = ' + environment + ';' in configuration

root = Path(__file__).resolve().parent.parent
app = root / 'My Funny Valentine'
project = (root / 'My Funny Valentine.xcodeproj/project.pbxproj').read_text()
entitlements = plistlib.loads((app / 'My_Funny_Valentine.entitlements').read_bytes())
info = plistlib.loads((app / 'Info.plist').read_bytes())
check_cloud_configuration(project, entitlements, info)
info_binding = 'INFOPLIST_FILE = "My Funny Valentine/Info.plist";'
for invalid_project, invalid_info in [
    (project, {key: value for key, value in info.items() if key != 'MFVCloudKitEnvironment'}),
    (project, {**info, 'MFVCloudKitEnvironment': 'Development'}),
    (project, {**info, 'MFVCloudKitEnvironment': '$(OTHER_ENVIRONMENT)'}),
    (project.replace(info_binding, 'INFOPLIST_FILE = "Wrong/Info.plist";', 1), info),
    (project.replace(info_binding, info_binding + '\nINFOPLIST_KEY_MFVCloudKitEnvironment = "$(MFV_CLOUDKIT_ENVIRONMENT)";', 1), info),
]:
    try:
        check_cloud_configuration(invalid_project, entitlements, invalid_info)
    except (AssertionError, KeyError):
        pass
    else:
        raise AssertionError('Invalid CloudKit Info.plist binding accepted')
names = ['Models/Card.swift', 'Models/FaceImage.swift', 'Models/CardImage.swift',
         'Models/StickerReference.swift', 'Models/ImageSource.swift', 'Utilities/CardDraft.swift',
         'Utilities/CardCloudArchive.swift']
source = 'import Foundation\nimport CoreGraphics\nimport ImageIO\nimport SwiftData\n'
for name in names:
    source += (app / name).read_text() + '\n'
# The trailing render-only snapshot refers to TemplateManager; keep actual composition/motion types.
composition = (app / 'Models/CardComposition.swift').read_text()
source += composition[:composition.index('/// Frozen value graph.')] + '\n'

sync = (app / 'Services/SavedCardCloudSync.swift').read_text()
detail = (app / 'Views/CardDetailView.swift').read_text()
checkpoint = method(sync, 'private func stateURL()')
# Inert boundaries only; the actual validation and path construction remain intact.
bundle_value = 'Bundle.main.object(forInfoDictionaryKey: "MFVCloudKitEnvironment")'
support_root = 'try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask,\n                                                    appropriateFor: nil, create: true)'
assert checkpoint.count(bundle_value) == checkpoint.count(support_root) == 1
checkpoint = checkpoint.replace(bundle_value, 'environmentValue').replace(support_root, 'rootURL')
source += '@MainActor final class CheckpointPaths { let rootURL: URL; let environmentValue: Any?\n'
source += 'init(rootURL: URL, environmentValue: Any?) { self.rootURL = rootURL; self.environmentValue = environmentValue }\n'
source += 'func url() throws -> URL { try stateURL() }\n'
source += checkpoint + '\n' + method(sync, 'private enum CloudError') + '\n}\n'
source += '@MainActor final class EditorLocks { private var editors: [UUID: Int] = [:]; var blocked: Bool { !editors.isEmpty }\n'
source += method(sync, 'func beginEditing(') + '\n' + method(sync, 'func endEditing(') + '\n}\n'
source += r'''
@MainActor final class EditorSave {
    let modelContext: ModelContext
    let savedCardID: UUID?
    var draft: Card
    var openedCardBytes: Data?
    var openedModifiedAt: Date?
    var needsSeparateCopy = false, dismissed = false
    var error: String?
    init(_ original: Card, in context: ModelContext) throws {
        modelContext = context; savedCardID = original.id
        draft = CardDraft.copy(of: original)
        openedCardBytes = try CardCloudArchive(original).encoded(); openedModifiedAt = original.modifiedAt
    }
    func fail(_ message: String) { error = message }
    func dismiss() { dismissed = true }
    func performSave() { save() }
    func performSaveSeparate() { saveSeparateCard() }
'''
source += method(detail, 'private func save()') + '\n' + method(detail, 'private func saveSeparateCard()') + '\n}\n'
source += r'''
@main struct SavedCardCheck {
    @MainActor static func main() throws {
        let pixels = NSMutableData()
        let provider = CGDataProvider(data: Data([255, 100, 140, 255]) as CFData)!
        let image = CGImage(width: 1, height: 1, bitsPerComponent: 8, bitsPerPixel: 32,
                            bytesPerRow: 4, space: CGColorSpaceCreateDeviceRGB(),
                            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue),
                            provider: provider, decode: nil, shouldInterpolate: false, intent: .defaultIntent)!
        let destination = CGImageDestinationCreateWithData(pixels, "public.png" as CFString, 1, nil)!
        CGImageDestinationAddImage(destination, image, nil)
        precondition(CGImageDestinationFinalize(destination))
        let png = pixels as Data
        let schema = Schema([Card.self, FaceImage.self, CardImage.self, StickerReference.self])
        let container = try ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)])
        let context = ModelContext(container)
        let card = Card(saying: "Be mine", customText: "Saved wording", createdAt: Date(timeIntervalSince1970: 1000.5), modifiedAt: Date(timeIntervalSince1970: 2000.5))
        let face = FaceImage(cardId: card.id, imageData: png, thumbnailData: png, detectedAt: Date(timeIntervalSince1970: 3000.5), position: CGPoint(x: 1, y: 2), size: CGSize(width: 10, height: 20))
        let photo = CardImage(cardId: card.id, source: .photoImport, imageData: png, position: CGPoint(x: 3, y: 4), size: CGSize(width: 30, height: 40), rotation: 12)
        photo.sourceRawValue = "future-source"
        let sticker = StickerReference(cardId: card.id, stickerId: "heart", stickerData: png, position: CGPoint(x: 5, y: 6), size: CGSize(width: 50, height: 60), rotation: 34)
        card.faces = [face]; card.images = [photo]; card.stickers = [sticker]
        let layout = CardLayoutData(backgroundColor: "#abcdef", imagePositions: [ImagePosition(imageId: photo.id, position: photo.position, size: photo.size, rotation: photo.rotation)], imagePlacements: [ImagePosition(imageId: photo.id, position: photo.position, size: photo.size, rotation: photo.rotation)], composition: CardComposition(family: .photoBooth, variant: 2, motionEnabled: false))
        var rawLayout = Data(" \n".utf8); rawLayout.append(try JSONEncoder().encode(layout)); card.layoutData = rawLayout
        let archive = try CardCloudArchive(card), bytes = try archive.encoded(), digest = CardCloudArchive.hash(bytes)
        let decoded = try CardCloudArchive.decode(bytes, cardID: card.id, digest: digest)
        let reopened = try decoded.card()
        precondition(reopened.id == card.id && reopened.saying == card.saying && reopened.customText == card.customText)
        precondition(reopened.createdAt == card.createdAt && reopened.modifiedAt == card.modifiedAt && reopened.layoutData == rawLayout)
        precondition(reopened.faces?.first?.id == face.id && reopened.faces?.first?.imageData == png && reopened.faces?.first?.thumbnailData == png)
        precondition(reopened.images?.first?.id == photo.id && reopened.images?.first?.sourceRawValue == "future-source" && reopened.images?.first?.imageData == png)
        precondition(reopened.stickers?.first?.id == sticker.id && reopened.stickers?.first?.stickerData == png)
        let roundTrip = try CardCloudArchive(reopened).encoded()
        precondition(roundTrip == bytes, "Original media and raw layout must survive exact archive round trip")
        let saved = try CardDraft.save(reopened, replacing: nil, in: context)
        let originalFace = saved.faces!.first!
        let updated = try decoded.card(); updated.customText = "Continued on another device"
        let same = try CardDraft.save(updated, replacing: saved, in: context)
        precondition(same === saved && same.faces?.first === originalFace && same.customText == updated.customText)
        precondition(same.faces?.first?.position == face.position && same.images?.first?.rotation == photo.rotation)
        let copyID = CardCloudRevision.stableUUID("one parallel edit")
        let copy = try decoded.card(copyID: copyID)
        precondition(copy.id == copyID && copy.saying == card.saying && copy.customText == card.customText)
        precondition(copy.faces?.first?.cardId == copyID && copy.faces?.first?.id != face.id)
        precondition(copy.images?.first?.cardId == copyID && copy.images?.first?.id != photo.id)
        precondition(copy.stickers?.first?.cardId == copyID && copy.stickers?.first?.id != sticker.id)
        precondition(copy.getLayoutData()?.imagePositions.first?.imageId == copy.images?.first?.id)
        precondition(copy.getLayoutData()?.imagePlacements?.first?.imageId == copy.images?.first?.id)
        precondition(copy.images?.first?.imageData == png && copy.stickers?.first?.stickerData == png)
        let repeatedCopy = try decoded.card(copyID: copyID)
        precondition(repeatedCopy.images?.first?.id == copy.images?.first?.id)
        let firstCopyBytes = try CardCloudArchive(copy).encoded(), secondCopyBytes = try CardCloudArchive(repeatedCopy).encoded()
        precondition(firstCopyBytes == secondCopyBytes, "Deterministic copies must have canonical nested layout bytes")
        let editor = try EditorSave(saved, in: context)
        editor.draft.customText = "Unsaved parallel wording"
        saved.customText = "Other window wording"; try context.save()
        editor.performSave()
        precondition(editor.needsSeparateCopy && !editor.dismissed && saved.customText == "Other window wording")
        editor.performSaveSeparate()
        precondition(editor.dismissed)
        let separate = try context.fetch(FetchDescriptor<Card>()).first { $0.id != saved.id }
        precondition(separate?.customText == "Unsaved parallel wording" && separate?.images?.first?.imageData == png)
        let deletedEditor = try EditorSave(saved, in: context)
        deletedEditor.draft.customText = "Keep my draft after deletion"
        let deletedID = saved.id
        context.delete(saved); try context.save()
        deletedEditor.performSave()
        precondition(deletedEditor.needsSeparateCopy && !deletedEditor.dismissed)
        deletedEditor.performSaveSeparate()
        let survivors = try context.fetch(FetchDescriptor<Card>())
        precondition(deletedEditor.dismissed && survivors.allSatisfy { $0.id != deletedID })
        precondition(survivors.contains { $0.customText == "Keep my draft after deletion" })
        let locks = EditorLocks(), editingID = UUID()
        locks.beginEditing(editingID); locks.beginEditing(editingID)
        locks.endEditing(editingID); precondition(locks.blocked)
        locks.endEditing(editingID); precondition(!locks.blocked)
        func rejects(_ operation: () throws -> Void) {
            do { try operation(); preconditionFailure("Invalid archive accepted") } catch { }
        }
        let checkpointRoot = FileManager.default.temporaryDirectory.appendingPathComponent("MFV-checkpoint-" + UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: checkpointRoot) }
        let legacy = checkpointRoot.appendingPathComponent("MFVSavedCardSync/revision-state.json")
        try FileManager.default.createDirectory(at: legacy.deletingLastPathComponent(), withIntermediateDirectories: true)
        let legacyBytes = Data("Retained old checkpoint".utf8)
        try legacyBytes.write(to: legacy)
        let development = try CheckpointPaths(rootURL: checkpointRoot, environmentValue: "Development").url()
        let production = try CheckpointPaths(rootURL: checkpointRoot, environmentValue: "Production").url()
        precondition(development != production && development != legacy && production != legacy)
        precondition(development.deletingLastPathComponent().lastPathComponent == "Development")
        precondition(production.deletingLastPathComponent().lastPathComponent == "Production")
        let developmentBytes = Data("Development heads".utf8), productionBytes = Data("Production heads".utf8)
        try developmentBytes.write(to: development); try productionBytes.write(to: production)
        let savedDevelopment = try Data(contentsOf: development), savedProduction = try Data(contentsOf: production)
        let savedLegacy = try Data(contentsOf: legacy)
        precondition(savedDevelopment == developmentBytes && savedProduction == productionBytes && savedLegacy == legacyBytes)
        let priorContents = try FileManager.default.subpathsOfDirectory(atPath: checkpointRoot.path).sorted()
        for invalid in [nil, NSNull(), 1, "", "development", "$(MFV_CLOUDKIT_ENVIRONMENT)", "../Production"] as [Any?] {
            rejects { _ = try CheckpointPaths(rootURL: checkpointRoot, environmentValue: invalid).url() }
        }
        let currentContents = try FileManager.default.subpathsOfDirectory(atPath: checkpointRoot.path).sorted()
        precondition(currentContents == priorContents)
        rejects { _ = try CardCloudArchive.decode(bytes + Data([0]), cardID: card.id, digest: digest) }
        rejects { _ = try CardCloudArchive.decode(bytes, cardID: UUID(), digest: digest) }
        var duplicate = archive; duplicate.faces[0].id = duplicate.images[0].id
        rejects { _ = try duplicate.encoded() }
        var missing = archive; missing.images[0].imageData = Data()
        rejects { _ = try missing.encoded() }
        var geometry = archive; geometry.images[0].width = -1
        rejects { _ = try geometry.encoded() }
        var unknown = archive; unknown.version = 2
        rejects { _ = try unknown.encoded() }
        rejects { _ = try CardCloudArchive.decode(Data(repeating: 0, count: CardCloudArchive.byteLimit + 1), cardID: card.id, digest: digest) }
        let count = try context.fetchCount(FetchDescriptor<Card>()); precondition(count == 2)
        let root = CardCloudRevision(cardID: card.id, parents: [], digest: digest, deleted: false)
        let edit = CardCloudRevision(cardID: card.id, parents: [root.id], digest: CardCloudArchive.hash(Data("edited".utf8)), deleted: false)
        let deletion = CardCloudRevision(cardID: card.id, parents: [root.id], digest: CardCloudArchive.hash(Data()), deleted: true)
        let parallel = try CardCloudRevision.heads([root, edit, deletion])
        precondition(parallel.count == 2 && Set(parallel.map(\.id)) == Set([edit.id, deletion.id]))
        precondition(!CardCloudRevision.descends(edit, from: [deletion.id], in: [root, edit, deletion]))
        let merged = CardCloudRevision(cardID: card.id, parents: [edit.id, deletion.id].sorted(), digest: digest, deleted: false)
        let mergedHeads = try CardCloudRevision.heads([root, edit, deletion, merged]); precondition(mergedHeads == [merged])
        precondition(CardCloudRevision.descends(merged, from: [edit.id, deletion.id], in: [root, edit, deletion, merged]))
        rejects { _ = try CardCloudRevision.heads([edit]) }
        rejects { _ = try CardCloudRevision.heads([root, root]) }
        rejects { try CardCloudRevision(cardID: card.id, parents: [root.id, root.id], digest: digest, deleted: false).validate() }
        rejects { try CardCloudRevision(cardID: card.id, parents: [], digest: digest, deleted: true).validate() }
        let cloudCopyID = CardCloudRevision.stableUUID("conflict:\(edit.id)")
        let copyRoot = CardCloudRevision(cardID: cloudCopyID, parents: [], digest: digest, deleted: false)
        let copyDeleted = CardCloudRevision(cardID: cloudCopyID, parents: [copyRoot.id], digest: CardCloudArchive.hash(Data()), deleted: true)
        precondition(CardCloudRevision.shouldMaterializeCopy(of: edit, in: [root, edit, deletion]))
        precondition(!CardCloudRevision.shouldMaterializeCopy(of: edit, in: [root, edit, deletion, copyRoot]))
        precondition(!CardCloudRevision.shouldMaterializeCopy(of: edit, in: [root, edit, deletion, copyRoot, copyDeleted]))
        print("PASS: environment-bound checkpoints with old-file preservation and invalid-environment isolation, exact card/media/layout round trip and adoption, canonical conflict identities, stale/deleted editor Save isolation and separate-copy path, two-editor locks, invalid payload isolation, ancestry/parallel-deletion decisions and deleted-copy suppression; no CloudKit client")
    }
}
'''
with tempfile.TemporaryDirectory(prefix='mfv-saved-card-check-') as temporary:
    path = Path(temporary) / 'check.swift'
    binary = Path(temporary) / 'check'
    path.write_text(source)
    subprocess.run(['xcrun', 'swiftc', '-parse-as-library', str(path), '-o', str(binary)], check=True)
    subprocess.run([str(binary)], check=True)
