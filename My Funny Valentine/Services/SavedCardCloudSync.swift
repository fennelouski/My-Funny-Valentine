import Foundation
import SwiftData
import SwiftUI
import CloudKit
import Combine

/// Saved cards only. The local SwiftData graph remains independent of CloudKit provisioning.
@MainActor final class SavedCardCloudSync: ObservableObject {
    static let containerID = "iCloud.com.nathanfennel.My-Funny-Valentine"
    static let enabledKey = "MFVCloudDraftsEnabled"
    private static var sharedService: SavedCardCloudSync?
    static func service(for context: ModelContext) -> SavedCardCloudSync {
        if let sharedService, sharedService.context.container === context.container { return sharedService }
        let service = SavedCardCloudSync(context: context)
        sharedService = service
        return service
    }
    @Published private(set) var status = "iCloud hasn't been checked yet."
    @Published private(set) var isSyncing = false
    @Published private(set) var accountChanged = false
    @Published private(set) var conflictCardIDs: Set<UUID> = []
    private let context: ModelContext
    private var state = LocalState()
    private var didLoadState = false
    private var allowAccountChange = false
    private var editors: [UUID: Int] = [:]
    func beginEditing(_ cardID: UUID) { editors[cardID, default: 0] += 1 }
    func endEditing(_ cardID: UUID) {
        let remaining = (editors[cardID] ?? 1) - 1
        editors[cardID] = remaining > 0 ? remaining : nil
    }
    private var eligible: Bool {
        !MFVRuntime.isPrivate && context.container.configurations.allSatisfy { !$0.isStoredInMemoryOnly && $0.allowsSave }
    }
    private var enabled: Bool {
        MFVRuntime.preferences.object(forKey: Self.enabledKey) == nil || MFVRuntime.preferences.bool(forKey: Self.enabledKey)
    }

    private struct Entry: Codable {
        var heads: [String]
        var digest: String?
        var deleted: Bool
    }
    private struct LocalState: Codable {
        var accountID: String?
        var entries: [String: Entry] = [:]
        var conflictCopies: [String: UUID] = [:]
    }

    init(context: ModelContext) { self.context = context }
    func sync() { Task { await synchronize() } }
    func useCurrentAccount() { allowAccountChange = true; accountChanged = false; sync() }
    func runWhileActive() async {
        while !Task.isCancelled {
            await synchronize()
            do { try await Task.sleep(for: .seconds(30)) } catch { break }
        }
    }

    private func stateURL() throws -> URL {
        guard let environment = Bundle.main.object(forInfoDictionaryKey: "MFVCloudKitEnvironment") as? String,
              ["Development", "Production"].contains(environment) else { throw CloudError.environmentConfiguration }
        let directory = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask,
                                                    appropriateFor: nil, create: true)
            .appendingPathComponent("MFVSavedCardSync", isDirectory: true)
            .appendingPathComponent(environment, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent("revision-state.json")
    }
    private func loadState() throws {
        guard !didLoadState else { return }
        let url = try stateURL()
        if FileManager.default.fileExists(atPath: url.path) {
            let size = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? Int.max
            guard size <= 10 * 1024 * 1024 else { throw CardCloudArchive.ArchiveError.invalid }
            state = try JSONDecoder().decode(LocalState.self, from: Data(contentsOf: url))
            guard state.entries.count <= 5_000, state.conflictCopies.count <= 5_000 else { throw CardCloudArchive.ArchiveError.invalid }
            for (key, value) in state.entries {
                guard UUID(uuidString: key)?.uuidString == key, value.heads.count <= 100,
                      Set(value.heads).count == value.heads.count, value.heads.allSatisfy(CardCloudRevision.validHash),
                      value.digest.map(CardCloudRevision.validHash) ?? value.deleted else { throw CardCloudArchive.ArchiveError.invalid }
            }
        }
        conflictCardIDs = Set(state.conflictCopies.values)
        didLoadState = true
    }
    private func saveState() throws {
        let encoder = JSONEncoder(); encoder.outputFormatting = [.sortedKeys]
        try encoder.encode(state).write(to: stateURL(), options: .atomic)
        conflictCardIDs = Set(state.conflictCopies.values)
    }
    private func cards() throws -> [Card] {
        let cards = try context.fetch(FetchDescriptor<Card>())
        guard cards.count <= 5_000, Set(cards.map(\.id)).count == cards.count else { throw CardCloudArchive.ArchiveError.invalid }
        return cards
    }
    private func digest(of card: Card?) throws -> String? {
        try card.map { CardCloudArchive.hash(try CardCloudArchive($0).encoded()) }
    }
    private func requireUnchanged(_ cardID: UUID, digest expected: String?) throws -> Card? {
        guard editors.isEmpty else { throw CloudError.editorOpen }
        guard !context.hasChanges else { throw CloudError.localChanges }
        let card = try cards().first { $0.id == cardID }
        guard try digest(of: card) == expected else { throw CloudError.localChanges }
        return card
    }
    private func requireAccount(_ container: CKContainer, _ expected: String) async throws {
        guard try await container.userRecordID().recordName == expected else { throw CloudError.accountChanged }
        guard enabled, !Task.isCancelled else { throw CancellationError() }
        guard editors.isEmpty else { throw CloudError.editorOpen }
    }

    private func synchronize() async {
        guard eligible else { status = "Private previews and test libraries don't use iCloud."; return }
        guard enabled else { status = "iCloud sync is off. Your cards stay on this device."; return }
        guard !accountChanged, !isSyncing else { return }
        guard editors.isEmpty else { status = "Save or close your open card editor to update iCloud."; return }
        guard !context.hasChanges else { status = "Waiting for your saved changes…"; return }
        isSyncing = true; status = "Syncing saved cards…"
        defer { isSyncing = false }
        do {
            try loadState()
            let container = CKContainer(identifier: Self.containerID)
            guard try await container.accountStatus() == .available else { throw CloudError.signIn }
            let accountID = try await container.userRecordID().recordName
            if let previous = state.accountID, previous != accountID {
                guard allowAccountChange else { throw CloudError.accountChanged }
                state = LocalState()
            }
            allowAccountChange = false
            state.accountID = accountID
            try saveState()
            let database = container.privateCloudDatabase
            var revisions = try await fetchRevisions(database)
            try await requireAccount(container, accountID)
            // Validate the complete graph before writing or replacing any saved card.
            for family in Dictionary(grouping: Array(revisions.values), by: \.cardID).values {
                _ = try CardCloudRevision.heads(family)
            }
            for (key, entry) in state.entries {
                guard entry.heads.allSatisfy({ revisions[$0]?.cardID.uuidString == key }) else { throw CardCloudArchive.ArchiveError.invalid }
            }
            guard !context.hasChanges else { throw CloudError.localChanges }
            let local = try cards()
            var live: Set<String> = []
            for card in local {
                let key = card.id.uuidString; live.insert(key)
                let bytes = try CardCloudArchive(card).encoded()
                let digest = CardCloudArchive.hash(bytes)
                let old = state.entries[key]
                if old?.digest == digest && old?.deleted == false { continue }
                let revision = CardCloudRevision(cardID: card.id, parents: (old?.heads ?? []).sorted(), digest: digest, deleted: false)
                try await requireAccount(container, accountID)
                try await publish(revision, payload: bytes, in: database)
                try await requireAccount(container, accountID)
                revisions[revision.id] = revision
                state.entries[key] = Entry(heads: [revision.id], digest: digest, deleted: false)
                try saveState()
            }
            // A saved local deletion becomes a tombstone; a parallel edit is retained as a copy.
            for key in Array(state.entries.keys).sorted() where !live.contains(key) {
                guard let entry = state.entries[key], !entry.deleted, let cardID = UUID(uuidString: key) else { continue }
                let revision = CardCloudRevision(cardID: cardID, parents: entry.heads.sorted(), digest: CardCloudArchive.hash(Data()), deleted: true)
                try await requireAccount(container, accountID)
                try await publish(revision, payload: nil, in: database)
                try await requireAccount(container, accountID)
                revisions[revision.id] = revision
                state.entries[key] = Entry(heads: [revision.id], digest: nil, deleted: true)
                try saveState()
            }
            for (cardID, family) in Dictionary(grouping: Array(revisions.values), by: \.cardID).sorted(by: { $0.key.uuidString < $1.key.uuidString }) {
                let heads = try CardCloudRevision.heads(family)
                let key = cardID.uuidString
                let entry = state.entries[key]
                if Set(heads.map(\.id)) == Set(entry?.heads ?? []) { continue }
                let expected = entry?.digest
                let original = try requireUnchanged(cardID, digest: expected)
                let fastForward = heads.count == 1 && CardCloudRevision.descends(heads[0], from: entry?.heads ?? [], in: family)
                if fastForward {
                    let head = heads[0]
                    if head.deleted {
                        try await requireAccount(container, accountID)
                        let current = try requireUnchanged(cardID, digest: expected)
                        if let current {
                            context.delete(current)
                            do { try context.save() } catch { context.rollback(); throw error }
                        }
                        state.entries[key] = Entry(heads: [head.id], digest: nil, deleted: true)
                    } else {
                        let archive = try await readArchive(head, from: database)
                        try await requireAccount(container, accountID)
                        let current = try requireUnchanged(cardID, digest: expected)
                        let saved = try CardDraft.save(archive.card(), replacing: current, in: context)
                        state.entries[key] = Entry(heads: [head.id], digest: try digest(of: saved), deleted: false)
                    }
                } else {
                    // Keep the current local card. Unseen parallel versions get independent identities.
                    for head in heads where !head.deleted && !(entry?.heads.contains(head.id) ?? false) {
                        let copyID = CardCloudRevision.stableUUID("conflict:\(head.id)")
                        if state.conflictCopies[head.id] != nil { continue }
                        // Its own cloud family (including a deletion) owns an existing copy.
                        // A fresh device must not recreate it from the older source conflict.
                        if CardCloudRevision.shouldMaterializeCopy(of: head, in: Array(revisions.values)) {
                            let archive = try await readArchive(head, from: database)
                            try await requireAccount(container, accountID)
                            _ = try requireUnchanged(cardID, digest: expected)
                            if !(try cards().contains { $0.id == copyID }) {
                                _ = try CardDraft.save(archive.card(copyID: copyID), replacing: nil, in: context)
                            }
                        }
                        state.conflictCopies[head.id] = copyID
                        try saveState()
                    }
                    // A fresh device with a deletion head keeps only the live conflict copies.
                    state.entries[key] = Entry(heads: heads.map(\.id), digest: try digest(of: original), deleted: original == nil)
                }
                try saveState()
            }
            // Changes saved while a network request was suspended remain pending.
            let current = try cards()
            guard !context.hasChanges,
                  current.allSatisfy({ state.entries[$0.id.uuidString]?.deleted == false }),
                  state.entries.allSatisfy({ key, entry in entry.deleted || current.contains { $0.id.uuidString == key } }) else {
                throw CloudError.localChanges
            }
            for card in current {
                guard try digest(of: card) == state.entries[card.id.uuidString]?.digest else { throw CloudError.localChanges }
            }
            status = conflictCardIDs.isEmpty ? "Saved cards are up to date in iCloud." : "Saved cards are up to date. Copies from parallel edits are in My Cards."
        } catch is CancellationError {
            status = "Sync paused. Your cards stay saved locally."
        } catch CloudError.accountChanged {
            accountChanged = true
            status = "The iCloud account changed. Choose whether to copy these saved cards to the current account."
        } catch {
            status = error.localizedDescription
        }
    }

    private static let metadataKeys = ["schema", "cardID", "revisionID", "parents", "digest", "deleted"]
    private func metadata(_ record: CKRecord) throws -> CardCloudRevision {
        guard record.recordType == "CardDraftRevision", let schema = record["schema"] as? NSNumber, schema.intValue == 1,
              let cardText = record["cardID"] as? String, let cardID = UUID(uuidString: cardText), cardID.uuidString == cardText,
              let revisionID = record["revisionID"] as? String,
              let digest = record["digest"] as? String, let deleted = record["deleted"] as? NSNumber,
              deleted.intValue == 0 || deleted.intValue == 1 else { throw CardCloudArchive.ArchiveError.invalid }
        guard record["parents"] == nil || record["parents"] is [String] else { throw CardCloudArchive.ArchiveError.invalid }
        // An empty CloudKit list may be omitted; the revision hash still proves empty ancestry.
        let parents = record["parents"] as? [String] ?? []
        let revision = CardCloudRevision(cardID: cardID, parents: parents, digest: digest, deleted: deleted.boolValue)
        try revision.validate()
        guard revisionID == revision.id, record.recordID.recordName == "Draft-" + revision.id else { throw CardCloudArchive.ArchiveError.invalid }
        return revision
    }
    private func fetchRevisions(_ database: CKDatabase) async throws -> [String: CardCloudRevision] {
        let query = CKQuery(recordType: "CardDraftRevision", predicate: NSPredicate(value: true))
        var page = try await database.records(matching: query, desiredKeys: Self.metadataKeys, resultsLimit: 200)
        var revisions: [String: CardCloudRevision] = [:]
        while true {
            for (_, result) in page.matchResults {
                let revision = try metadata(result.get())
                guard revisions[revision.id] == nil, revisions.count < 5_000 else { throw CardCloudArchive.ArchiveError.invalid }
                revisions[revision.id] = revision
            }
            guard let cursor = page.queryCursor else { break }
            page = try await database.records(continuingMatchFrom: cursor, desiredKeys: Self.metadataKeys, resultsLimit: 200)
        }
        return revisions
    }
    private func readArchive(_ revision: CardCloudRevision, from database: CKDatabase) async throws -> CardCloudArchive {
        let record = try await database.record(for: CKRecord.ID(recordName: "Draft-" + revision.id))
        guard try metadata(record) == revision, !revision.deleted,
              let asset = record["payload"] as? CKAsset, let url = asset.fileURL else { throw CardCloudArchive.ArchiveError.invalid }
        let size = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? Int.max
        guard size <= CardCloudArchive.byteLimit else { throw CardCloudArchive.ArchiveError.tooLarge }
        return try CardCloudArchive.decode(Data(contentsOf: url), cardID: revision.cardID, digest: revision.digest)
    }
    private func publish(_ revision: CardCloudRevision, payload: Data?, in database: CKDatabase) async throws {
        try revision.validate()
        guard revision.deleted ? payload == nil : payload.map(CardCloudArchive.hash) == revision.digest else { throw CardCloudArchive.ArchiveError.invalid }
        let recordID = CKRecord.ID(recordName: "Draft-" + revision.id)
        do {
            let existing = try await database.record(for: recordID)
            guard try metadata(existing) == revision else { throw CardCloudArchive.ArchiveError.invalid }
            if !revision.deleted { _ = try await readArchive(revision, from: database) }
            return
        } catch let error as CKError where error.code == .unknownItem { }
        let record = CKRecord(recordType: "CardDraftRevision", recordID: recordID)
        record["schema"] = 1 as NSNumber
        record["cardID"] = revision.cardID.uuidString
        record["revisionID"] = revision.id
        record["parents"] = revision.parents
        record["digest"] = revision.digest
        record["deleted"] = revision.deleted as NSNumber
        let temporary = FileManager.default.temporaryDirectory.appendingPathComponent("MFV-card-\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: temporary) }
        if let payload {
            try payload.write(to: temporary, options: .atomic)
            try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: temporary.path)
            record["payload"] = CKAsset(fileURL: temporary)
        }
        do { _ = try await database.save(record) }
        catch let error as CKError where error.code == .serverRecordChanged {
            let existing = try await database.record(for: recordID)
            guard try metadata(existing) == revision else { throw error }
            if !revision.deleted { _ = try await readArchive(revision, from: database) }
        }
    }
    private enum CloudError: LocalizedError {
        case signIn, accountChanged, localChanges, editorOpen, environmentConfiguration
        var errorDescription: String? {
            switch self {
            case .signIn: "Sign in to iCloud to continue saved cards on another device. Your local cards are safe."
            case .accountChanged: "The iCloud account changed. Your local cards are safe."
            case .localChanges: "Saved changes are waiting for the next iCloud sync."
            case .editorOpen: "Save or close your open card editor to update iCloud."
            case .environmentConfiguration: "iCloud isn't configured for this build. Your cards stay saved locally."
            }
        }
    }
}

private struct SavedCardCloudSyncKey: EnvironmentKey {
    static let defaultValue: SavedCardCloudSync? = nil
}
extension EnvironmentValues {
    var savedCardCloudSync: SavedCardCloudSync? {
        get { self[SavedCardCloudSyncKey.self] }
        set { self[SavedCardCloudSyncKey.self] = newValue }
    }
}
