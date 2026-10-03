import Foundation
import CoreGraphics
import SwiftData
import Testing
@testable import My_Funny_Valentine

@MainActor
struct StarterTemplateCatalogTests {
    private let worlds: [String: TemplateCategory] = [
        "pizza": .funny,
        "space": .romantic,
        "birds": .cute,
        "dino": .funny,
        "disco": .modern,
        "sweets": .classic
    ]

    @Test("Thirty complete starters have stable IDs, distinct names and short sayings")
    func startersAreComplete() throws {
        let templates = TemplateManager.shared.getStarterTemplates()
        let expectedIDs = Set(worlds.keys.flatMap { world in (1...5).map { "starter_\(world)_\($0)" } })
        #expect(templates.count == 30)
        #expect(Set(templates.map(\.id)) == expectedIDs)
        #expect(Set(templates.map(\.name)).count == 30)
        let sayings = try templates.map { try #require($0.textAreas.first?.defaultText) }
        #expect(Set(sayings).count == 30)

        for template in templates {
            let world = try #require(worlds.keys.first { template.id.hasPrefix("starter_\($0)_") })
            #expect(template.category == worlds[world])
            #expect(template.imageName == "starter_\(world)")
            #expect(template.minimumFaceCount == 0)
            #expect(!template.name.isEmpty)
            #expect(template.textAreas.count == 1)
            let area = try #require(template.textAreas.first)
            let saying = try #require(area.defaultText)
            #expect(!saying.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            #expect(saying.split(whereSeparator: \.isWhitespace).count <= 15)
            #expect(saying.count <= area.maxLength)
        }
    }

    @Test("Message and optional photo geometry fit the 400 by 600 card")
    func starterGeometryFits() throws {
        let canvas = CGRect(x: 0, y: 0, width: 400, height: 600)
        for template in TemplateManager.shared.getStarterTemplates() {
            let area = try #require(template.textAreas.first)
            #expect(area.position == CGPoint(x: 32, y: 430))
            #expect(area.size == CGSize(width: 336, height: 130))
            #expect(canvas.contains(CGRect(origin: area.position, size: area.size)))
            #expect(template.facePositions.count == 1)
            let face = try #require(template.facePositions.first)
            #expect(face.index == 0)
            #expect(face.position == CGPoint(x: 154, y: 164))
            #expect(face.size == CGSize(width: 92, height: 110))
            #expect(canvas.contains(CGRect(origin: face.position, size: face.size)))
            #expect((0...1).contains(template.backgroundColor.red))
            #expect((0...1).contains(template.backgroundColor.green))
            #expect((0...1).contains(template.backgroundColor.blue))
            #expect(template.backgroundColor.alpha == 1)
        }
    }

    @Test("Draft creation leaves the saved library untouched and uses editable plain text")
    func draftsStayUnsaved() throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        let container = try ModelContainer(for: Card.self, FaceImage.self, CardImage.self, StickerReference.self,
                                           configurations: configuration)
        let context = ModelContext(container)
        let saved = Card(saying: "Already saved")
        context.insert(saved)
        try context.save()
        let initialCount = try context.fetchCount(FetchDescriptor<Card>())
        var draftIDs: Set<UUID> = []

        for template in TemplateManager.shared.getStarterTemplates() {
            let draft = TemplateManager.shared.makeDraft(from: template)
            #expect(draft.modelContext == nil)
            #expect(draft.templateId == template.id)
            #expect(draft.saying == template.textAreas.first?.defaultText)
            #expect(draft.customText == nil)
            #expect(draft.syncedToCloud == false)
            #expect(draft.faces?.isEmpty == true)
            #expect(draft.images?.isEmpty == true)
            #expect(draft.stickers?.isEmpty == true)
            let layout = try #require(draft.getLayoutData())
            #expect(layout.backgroundColor == template.backgroundColor.hexString)
            #expect(layout.textPositions.isEmpty)
            #expect(layout.imagePositions.isEmpty)
            #expect(layout.stickerPositions.isEmpty)
            draft.saying = "My own Valentine message"
            #expect(draft.saying == "My own Valentine message")
            #expect(draftIDs.insert(draft.id).inserted)
        }
        #expect(try context.fetchCount(FetchDescriptor<Card>()) == initialCount)
        #expect(saved.saying == "Already saved")
        #expect(!context.hasChanges)
    }

    @Test("Legacy IDs remain available and missing minimumFaceCount decodes as nil")
    func legacyTemplatesRemainCompatible() throws {
        let expectedIDs = Set([
            "romantic_1", "romantic_2", "romantic_3", "romantic_4", "romantic_5",
            "funny_1", "funny_2", "funny_3", "cute_1", "cute_2", "cute_3",
            "classic_1", "classic_2", "modern_1", "modern_2"
        ])
        let legacy = TemplateManager.shared.getAllTemplates().filter { !$0.id.hasPrefix("starter_") }
        #expect(legacy.count == 15)
        #expect(Set(legacy.map(\.id)) == expectedIDs)
        for template in legacy {
            #expect(template.minimumFaceCount == nil)
            let data = try JSONEncoder().encode(template)
            var json = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
            json.removeValue(forKey: "minimumFaceCount")
            let oldData = try JSONSerialization.data(withJSONObject: json)
            let decoded = try JSONDecoder().decode(CardTemplate.self, from: oldData)
            #expect(decoded.id == template.id)
            #expect(decoded.minimumFaceCount == nil)
            #expect(decoded.facePositions.count == template.facePositions.count)
        }

        for template in TemplateManager.shared.getStarterTemplates() {
            let decoded = try JSONDecoder().decode(CardTemplate.self, from: JSONEncoder().encode(template))
            #expect(decoded.minimumFaceCount == 0)
            #expect(decoded.id == template.id)
            #expect(decoded.textAreas.first?.defaultText == template.textAreas.first?.defaultText)
        }
    }
}
