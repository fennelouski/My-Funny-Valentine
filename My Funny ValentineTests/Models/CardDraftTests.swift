import Foundation
import CoreGraphics
import SwiftData
import Testing
@testable import My_Funny_Valentine

@MainActor
struct CardDraftTests {
    @Test("Detached drafts cancel safely, retain child identities, and reopen after Save")
    func testFullDraftLifecycle() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let storeURL = directory.appendingPathComponent("cards.store")
        let schema = Schema([Card.self, FaceImage.self, CardImage.self, StickerReference.self])
        let configuration = ModelConfiguration(schema: schema, url: storeURL, cloudKitDatabase: .none)
        let cardID = UUID()
        let newCardID = UUID()
        let faceID = UUID()
        let imageID = UUID()
        let stickerID = UUID()
        let removedFaceID = UUID()
        let removedImageID = UUID()
        let removedStickerID = UUID()
        let addedFaceID = UUID()
        let createdAt = Date(timeIntervalSince1970: 1_000.5)
        let modifiedAt = Date(timeIntervalSince1970: 2_000.5)
        let detectedAt = Date(timeIntervalSince1970: 3_000.5)
        let pixels = TestData.sampleImageData()
        var rawLayout = Data(" \n".utf8)
        rawLayout.append(try JSONEncoder().encode(CardLayoutData(backgroundColor: "#345678", textRotation: 12)))

        do {
            let container = try ModelContainer(for: schema, configurations: [configuration])
            let context = ModelContext(container)
            context.autosaveEnabled = true
            let original = Card(id: cardID, templateId: "saved-template", saying: "Be mine", customText: "Original", createdAt: createdAt, modifiedAt: modifiedAt, syncedToCloud: true)
            original.layoutData = rawLayout
            let face = FaceImage(id: faceID, cardId: cardID, imageData: pixels, thumbnailData: pixels, detectedAt: detectedAt, position: CGPoint(x: 12, y: 34), size: CGSize(width: 56, height: 78))
            face.syncedToCloud = true
            let image = CardImage(id: imageID, cardId: cardID, source: .photoImport, imageData: pixels, position: CGPoint(x: 21, y: 43), size: CGSize(width: 65, height: 87), rotation: 19)
            image.sourceRawValue = "future-source"
            image.syncedToCloud = true
            let sticker = StickerReference(id: stickerID, cardId: cardID, stickerId: "heart", stickerData: pixels, position: CGPoint(x: 31, y: 42), size: CGSize(width: 53, height: 64), rotation: 23)
            let removedFace = TestData.sampleFaceImage(cardId: cardID)
            removedFace.id = removedFaceID
            let removedImage = TestData.sampleCardImage(cardId: cardID)
            removedImage.id = removedImageID
            let removedSticker = TestData.sampleStickerReference(cardId: cardID)
            removedSticker.id = removedStickerID
            original.faces = [face, removedFace]
            original.images = [image, removedImage]
            original.stickers = [sticker, removedSticker]
            context.insert(original)
            try context.save()
            let persistentFaceID = face.persistentModelID
            let persistentImageID = image.persistentModelID
            let persistentStickerID = sticker.persistentModelID

            let draft = CardDraft.copy(of: original)
            #expect(draft.modelContext == nil)
            #expect(draft.id == cardID && draft.createdAt == createdAt && draft.modifiedAt == modifiedAt)
            #expect(draft.layoutData == rawLayout && draft.syncedToCloud == true)
            // SwiftData to-many relationships do not promise array order after Save.
            let draftFace = try #require(draft.faces?.first { $0.id == faceID })
            let draftImage = try #require(draft.images?.first { $0.id == imageID })
            let draftSticker = try #require(draft.stickers?.first { $0.id == stickerID })
            #expect(draftFace !== face && draftImage !== image && draftSticker !== sticker)
            #expect(draftFace.modelContext == nil && draftImage.modelContext == nil && draftSticker.modelContext == nil)
            #expect(draftFace.detectedAt == detectedAt && draftFace.syncedToCloud == true)
            #expect(draftImage.sourceRawValue == "future-source" && draftImage.syncedToCloud == true)
            draft.saying = "Edited"
            draft.customText = "A personal note"
            draftFace.position = CGPoint(x: 90, y: 91)
            draftImage.rotation = 45
            draftSticker.stickerData = Data([1, 2, 3])
            #expect(original.saying == "Be mine" && face.position == CGPoint(x: 12, y: 34))
            #expect(image.rotation == 19 && sticker.stickerData == pixels)
            let addedFace = TestData.sampleFaceImage(cardId: cardID)
            addedFace.id = addedFaceID
            draft.faces = draft.faces?.filter { $0.id != removedFaceID }
            draft.faces?.append(addedFace)
            draft.images = draft.images?.filter { $0.id != removedImageID }
            draft.stickers = draft.stickers?.filter { $0.id != removedStickerID }

            let saved = try CardDraft.save(draft, replacing: original, in: context)
            #expect(saved === original)
            let savedFace = try #require(saved.faces?.first { $0.id == faceID })
            let savedImage = try #require(saved.images?.first { $0.id == imageID })
            let savedSticker = try #require(saved.stickers?.first { $0.id == stickerID })
            let savedAddedFace = try #require(saved.faces?.first { $0.id == addedFaceID })
            #expect(savedFace === face && savedImage === image && savedSticker === sticker)
            #expect(face.persistentModelID == persistentFaceID && image.persistentModelID == persistentImageID && sticker.persistentModelID == persistentStickerID)
            #expect(savedAddedFace !== addedFace && addedFace.modelContext == nil)
            #expect(Set(saved.faces?.map(\.id) ?? []) == Set([faceID, addedFaceID]))
            #expect(Set(saved.images?.map(\.id) ?? []) == Set([imageID]))
            #expect(Set(saved.stickers?.map(\.id) ?? []) == Set([stickerID]))
            #expect(context.autosaveEnabled == true && draft.modelContext == nil)
            #expect(try context.fetchCount(FetchDescriptor<FaceImage>()) == 2)
            #expect(try context.fetchCount(FetchDescriptor<CardImage>()) == 1)
            #expect(try context.fetchCount(FetchDescriptor<StickerReference>()) == 1)
            #expect(try context.fetch(FetchDescriptor<FaceImage>()).allSatisfy { $0.id != removedFaceID })
            #expect(try context.fetch(FetchDescriptor<CardImage>()).allSatisfy { $0.id != removedImageID })
            #expect(try context.fetch(FetchDescriptor<StickerReference>()).allSatisfy { $0.id != removedStickerID })

            let newDraft = Card(id: newCardID, saying: "New card", createdAt: createdAt, modifiedAt: modifiedAt)
            newDraft.faces = [TestData.sampleFaceImage(cardId: newCardID)]
            newDraft.images = nil
            newDraft.stickers = nil
            let copiedNew = CardDraft.copy(of: newDraft)
            #expect((copiedNew.images ?? []).isEmpty && (copiedNew.stickers ?? []).isEmpty)
            let savedNew = try CardDraft.save(newDraft, replacing: nil, in: context)
            #expect(savedNew !== newDraft && savedNew.faces?.first !== newDraft.faces?.first)
            #expect(newDraft.modelContext == nil && newDraft.faces?.first?.modelContext == nil)
            #expect((newDraft.images ?? []).isEmpty && (newDraft.stickers ?? []).isEmpty)
            // Persisted empty to-many relationships may be normalized to [].
            #expect((savedNew.images ?? []).isEmpty && (savedNew.stickers ?? []).isEmpty)
        }

        // Reopen the disk store after the editing context and container close.
        do {
            let container = try ModelContainer(for: schema, configurations: [configuration])
            let context = ModelContext(container)
            let cards = try context.fetch(FetchDescriptor<Card>())
            let saved = try #require(cards.first { $0.id == cardID })
            #expect(cards.count == 2)
            #expect(saved.templateId == "saved-template" && saved.saying == "Edited" && saved.customText == "A personal note")
            #expect(saved.createdAt == createdAt && saved.modifiedAt == modifiedAt && saved.syncedToCloud == true)
            #expect(saved.layoutData == rawLayout)
            let face = try #require(saved.faces?.first { $0.id == faceID })
            let image = try #require(saved.images?.first { $0.id == imageID })
            let sticker = try #require(saved.stickers?.first { $0.id == stickerID })
            #expect(Set(saved.faces?.map(\.id) ?? []) == Set([faceID, addedFaceID]))
            #expect(Set(saved.images?.map(\.id) ?? []) == Set([imageID]))
            #expect(Set(saved.stickers?.map(\.id) ?? []) == Set([stickerID]))
            #expect(try context.fetch(FetchDescriptor<FaceImage>()).allSatisfy { $0.id != removedFaceID })
            #expect(try context.fetch(FetchDescriptor<CardImage>()).allSatisfy { $0.id != removedImageID })
            #expect(try context.fetch(FetchDescriptor<StickerReference>()).allSatisfy { $0.id != removedStickerID })
            #expect(saved.faces?.count == 2 && face.imageData == pixels && face.thumbnailData == pixels)
            #expect(face.cardId == cardID && face.detectedAt == detectedAt && face.syncedToCloud == true)
            #expect(face.position == CGPoint(x: 90, y: 91) && face.size == CGSize(width: 56, height: 78))
            #expect(image.sourceRawValue == "future-source" && image.rotation == 45 && image.syncedToCloud == true)
            #expect(image.cardId == cardID && image.imageData == pixels)
            #expect(image.position == CGPoint(x: 21, y: 43) && image.size == CGSize(width: 65, height: 87))
            #expect(sticker.stickerId == "heart" && sticker.stickerData == Data([1, 2, 3]) && sticker.rotation == 23)
            #expect(sticker.cardId == cardID)
            #expect(sticker.position == CGPoint(x: 31, y: 42) && sticker.size == CGSize(width: 53, height: 64))
            let savedNew = try #require(cards.first { $0.id == newCardID })
            #expect(savedNew.faces?.count == 1)
            #expect((savedNew.images ?? []).isEmpty && (savedNew.stickers ?? []).isEmpty)
        }

        // A real read-only library must reject Save before inserting a visible card.
        do {
            let readOnly = ModelConfiguration(schema: schema, url: storeURL, allowsSave: false, cloudKitDatabase: .none)
            let container = try ModelContainer(for: schema, configurations: [readOnly])
            let context = ModelContext(container)
            let unsaved = Card(saying: "Keep my changes")
            unsaved.faces = [TestData.sampleFaceImage(cardId: unsaved.id)]
            do {
                try CardDraft.save(unsaved, replacing: nil, in: context)
                Issue.record("A read-only store must reject Save")
            } catch {
                #expect(unsaved.modelContext == nil && unsaved.faces?.first?.modelContext == nil)
                #expect(unsaved.saying == "Keep my changes" && unsaved.faces?.count == 1)
                let survivingCards = try context.fetch(FetchDescriptor<Card>())
                #expect(Set(survivingCards.map(\.id)) == Set([cardID, newCardID]))
            }
        }
    }
}
