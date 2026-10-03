import Foundation
import SwiftData

/// Editors work on detached models, so Cancel never changes the saved graph.
@MainActor
enum CardDraft {
    static func copy(of card: Card) -> Card {
        let draft = Card(
            id: card.id,
            templateId: card.templateId,
            saying: card.saying,
            customText: card.customText,
            createdAt: card.createdAt,
            modifiedAt: card.modifiedAt,
            syncedToCloud: card.syncedToCloud
        )
        draft.layoutData = card.layoutData
        draft.faces = card.faces?.map { source in
            let face = FaceImage(cardId: source.cardId, imageData: source.imageData, thumbnailData: source.thumbnailData)
            update(face, from: source)
            return face
        }
        draft.images = card.images?.map { source in
            let image = CardImage(cardId: source.cardId, source: source.source, imageData: source.imageData)
            update(image, from: source)
            return image
        }
        draft.stickers = card.stickers?.map { source in
            let sticker = StickerReference(cardId: source.cardId, stickerId: source.stickerId)
            update(sticker, from: source)
            return sticker
        }
        return draft
    }

    @discardableResult
    static func save(_ draft: Card, replacing original: Card?, in context: ModelContext) throws -> Card {
        // A read-only context can retain attempted insertions even after rollback.
        // Reject it before changing the user's visible library.
        guard context.container.configurations.allSatisfy(\.allowsSave) else {
            throw DraftError.readOnly
        }
        // Insert a separate graph so a failed save cannot consume the UI draft.
        let prepared = copy(of: draft)
        let autosaveEnabled = context.autosaveEnabled
        context.autosaveEnabled = false
        defer { context.autosaveEnabled = autosaveEnabled }

        do {
            guard original == nil || original?.id == draft.id else {
                throw DraftError.differentCard
            }
            try requireUniqueIDs(prepared.faces, id: \.id)
            try requireUniqueIDs(prepared.images, id: \.id)
            try requireUniqueIDs(prepared.stickers, id: \.id)

            let saved: Card
            if let original {
                try requireUniqueIDs(original.faces, id: \.id)
                try requireUniqueIDs(original.images, id: \.id)
                try requireUniqueIDs(original.stickers, id: \.id)
                original.templateId = prepared.templateId
                original.saying = prepared.saying
                original.customText = prepared.customText
                original.createdAt = prepared.createdAt
                original.modifiedAt = prepared.modifiedAt
                original.syncedToCloud = prepared.syncedToCloud
                original.layoutData = prepared.layoutData
                original.faces = reconcile(original.faces, with: prepared.faces, id: \.id, in: context, update: update)
                original.images = reconcile(original.images, with: prepared.images, id: \.id, in: context, update: update)
                original.stickers = reconcile(original.stickers, with: prepared.stickers, id: \.id, in: context, update: update)
                saved = original
            } else {
                context.insert(prepared)
                saved = prepared
            }
            try context.save()
            return saved
        } catch {
            context.rollback()
            throw error
        }
    }

    private static func reconcile<Item: PersistentModel>(
        _ existing: [Item]?, with incoming: [Item]?, id: KeyPath<Item, UUID>,
        in context: ModelContext, update: (Item, Item) -> Void
    ) -> [Item]? {
        let retained = Dictionary(uniqueKeysWithValues: (existing ?? []).map { ($0[keyPath: id], $0) })
        let incomingIDs = Set((incoming ?? []).map { $0[keyPath: id] })
        for item in existing ?? [] where !incomingIDs.contains(item[keyPath: id]) {
            context.delete(item)
        }
        return incoming?.map { item in
            if let saved = retained[item[keyPath: id]] {
                update(saved, item)
                return saved
            }
            context.insert(item)
            return item
        }
    }

    private static func requireUniqueIDs<Item>(_ items: [Item]?, id: KeyPath<Item, UUID>) throws {
        let ids = (items ?? []).map { $0[keyPath: id] }
        guard Set(ids).count == ids.count else { throw DraftError.duplicateItems }
    }

    private static func update(_ face: FaceImage, from source: FaceImage) {
        face.id = source.id
        face.cardId = source.cardId
        face.imageData = source.imageData
        face.thumbnailData = source.thumbnailData
        face.detectedAt = source.detectedAt
        face.positionX = source.positionX
        face.positionY = source.positionY
        face.sizeWidth = source.sizeWidth
        face.sizeHeight = source.sizeHeight
        face.syncedToCloud = source.syncedToCloud
    }

    private static func update(_ image: CardImage, from source: CardImage) {
        image.id = source.id
        image.cardId = source.cardId
        image.imageData = source.imageData
        image.sourceRawValue = source.sourceRawValue
        image.positionX = source.positionX
        image.positionY = source.positionY
        image.sizeWidth = source.sizeWidth
        image.sizeHeight = source.sizeHeight
        image.rotation = source.rotation
        image.syncedToCloud = source.syncedToCloud
    }

    private static func update(_ sticker: StickerReference, from source: StickerReference) {
        sticker.id = source.id
        sticker.cardId = source.cardId
        sticker.stickerId = source.stickerId
        sticker.stickerData = source.stickerData
        sticker.positionX = source.positionX
        sticker.positionY = source.positionY
        sticker.sizeWidth = source.sizeWidth
        sticker.sizeHeight = source.sizeHeight
        sticker.rotation = source.rotation
    }

    private enum DraftError: LocalizedError {
        case differentCard, duplicateItems, readOnly

        var errorDescription: String? {
            switch self {
            case .differentCard: "This draft belongs to a different card."
            case .duplicateItems: "This card contains duplicate items and couldn't be saved."
            case .readOnly: "This card library is read-only. Your changes are still in the editor."
            }
        }
    }
}
