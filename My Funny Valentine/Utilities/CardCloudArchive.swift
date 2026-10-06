import Foundation
import CryptoKit
import ImageIO

/// One saved card, including its original media. No temporary editor state or account data.
nonisolated struct CardCloudArchive: Codable {
    static let byteLimit = 32 * 1024 * 1024
    var version = 1
    var id: UUID
    var templateId: String?
    var saying: String?
    var customText: String?
    var createdAt: Date
    var modifiedAt: Date
    var layoutData: Data?
    var faces: [Face]
    var images: [Image]
    var stickers: [Sticker]

    struct Face: Codable {
        var id: UUID
        var imageData: Data
        var thumbnailData: Data
        var detectedAt: Date
        var x: Double, y: Double, width: Double, height: Double
    }
    struct Image: Codable {
        var id: UUID
        var source: String
        var imageData: Data
        var x: Double, y: Double, width: Double, height: Double, rotation: Double
    }
    struct Sticker: Codable {
        var id: UUID
        var stickerId: String
        var stickerData: Data?
        var x: Double, y: Double, width: Double, height: Double, rotation: Double
    }

    @MainActor init(_ card: Card) throws {
        guard (card.faces ?? []).allSatisfy({ $0.cardId == card.id }),
              (card.images ?? []).allSatisfy({ $0.cardId == card.id }),
              (card.stickers ?? []).allSatisfy({ $0.cardId == card.id }) else { throw ArchiveError.invalid }
        id = card.id; templateId = card.templateId; saying = card.saying; customText = card.customText
        createdAt = card.createdAt; modifiedAt = card.modifiedAt; layoutData = card.layoutData
        // SwiftData to-many order is not persistent; identities and explicit geometry are.
        faces = (card.faces ?? []).sorted { $0.id.uuidString < $1.id.uuidString }.map {
            Face(id: $0.id, imageData: $0.imageData, thumbnailData: $0.thumbnailData, detectedAt: $0.detectedAt,
                 x: $0.positionX, y: $0.positionY, width: $0.sizeWidth, height: $0.sizeHeight)
        }
        images = (card.images ?? []).sorted { $0.id.uuidString < $1.id.uuidString }.map {
            Image(id: $0.id, source: $0.sourceRawValue, imageData: $0.imageData,
                  x: $0.positionX, y: $0.positionY, width: $0.sizeWidth, height: $0.sizeHeight, rotation: $0.rotation)
        }
        stickers = (card.stickers ?? []).sorted { $0.id.uuidString < $1.id.uuidString }.map {
            Sticker(id: $0.id, stickerId: $0.stickerId, stickerData: $0.stickerData,
                    x: $0.positionX, y: $0.positionY, width: $0.sizeWidth, height: $0.sizeHeight, rotation: $0.rotation)
        }
    }

    func encoded() throws -> Data {
        try validate()
        let encoder = JSONEncoder(); encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(self)
        guard data.count <= Self.byteLimit else { throw ArchiveError.tooLarge }
        return data
    }
    static func decode(_ data: Data, cardID: UUID, digest: String) throws -> Self {
        guard data.count <= byteLimit, hash(data) == digest else { throw ArchiveError.invalid }
        let archive = try JSONDecoder().decode(Self.self, from: data)
        guard archive.id == cardID else { throw ArchiveError.invalid }
        try archive.validate()
        return archive
    }
    static func hash(_ data: Data) -> String { SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined() }

    func validate() throws {
        let allIDs = faces.map(\.id) + images.map(\.id) + stickers.map(\.id)
        guard version == 1, faces.count <= 100, images.count <= 100, stickers.count <= 100,
              Set(allIDs).count == allIDs.count,
              createdAt.timeIntervalSince1970.isFinite, modifiedAt.timeIntervalSince1970.isFinite,
              [templateId, saying, customText].allSatisfy({ ($0?.utf8.count ?? 0) <= 256_000 }),
              (layoutData?.count ?? 0) <= 1_000_000 else { throw ArchiveError.invalid }
        if let layoutData { _ = try JSONDecoder().decode(CardLayoutData.self, from: layoutData) }
        func geometry(_ values: [Double], width: Double, height: Double) throws {
            guard values.allSatisfy(\.isFinite), width >= 0, height >= 0 else { throw ArchiveError.invalid }
        }
        func pixels(_ data: Data, emptyAllowed: Bool = false) throws {
            if emptyAllowed && data.isEmpty { return }
            guard data.count <= Self.byteLimit,
                  let image = CGImageSourceCreateWithData(data as CFData, nil),
                  CGImageSourceGetCount(image) > 0,
                  let properties = CGImageSourceCopyPropertiesAtIndex(image, 0, nil) as? [CFString: Any],
                  let width = properties[kCGImagePropertyPixelWidth] as? NSNumber,
                  let height = properties[kCGImagePropertyPixelHeight] as? NSNumber,
                  width.doubleValue > 0, height.doubleValue > 0,
                  width.doubleValue * height.doubleValue <= 64_000_000 else { throw ArchiveError.invalid }
        }
        for face in faces {
            try geometry([face.x, face.y, face.width, face.height], width: face.width, height: face.height)
            guard face.detectedAt.timeIntervalSince1970.isFinite else { throw ArchiveError.invalid }
            try pixels(face.imageData); try pixels(face.thumbnailData, emptyAllowed: true)
        }
        for image in images {
            try geometry([image.x, image.y, image.width, image.height, image.rotation], width: image.width, height: image.height)
            guard image.source.utf8.count <= 1_000 else { throw ArchiveError.invalid }
            try pixels(image.imageData)
        }
        for sticker in stickers {
            try geometry([sticker.x, sticker.y, sticker.width, sticker.height, sticker.rotation], width: sticker.width, height: sticker.height)
            guard sticker.stickerId.utf8.count <= 1_000 else { throw ArchiveError.invalid }
            if let data = sticker.stickerData { try pixels(data) }
        }
    }

    @MainActor func card(copyID: UUID? = nil) throws -> Card {
        try validate()
        let cardID = copyID ?? id
        let card = Card(id: cardID, templateId: templateId, saying: saying, customText: customText,
                        createdAt: createdAt, modifiedAt: modifiedAt, syncedToCloud: true)
        var replacements: [UUID: UUID] = [:]
        func childID(_ original: UUID) -> UUID {
            if copyID == nil { return original }
            let value = CardCloudRevision.stableUUID("\(cardID.uuidString):\(original.uuidString)")
            replacements[original] = value
            return value
        }
        card.faces = faces.map {
            FaceImage(id: childID($0.id), cardId: cardID, imageData: $0.imageData, thumbnailData: $0.thumbnailData,
                      detectedAt: $0.detectedAt, position: CGPoint(x: $0.x, y: $0.y), size: CGSize(width: $0.width, height: $0.height))
        }
        card.images = images.map {
            let image = CardImage(id: childID($0.id), cardId: cardID, source: ImageSource(rawValue: $0.source) ?? .photoImport,
                                 imageData: $0.imageData, position: CGPoint(x: $0.x, y: $0.y), size: CGSize(width: $0.width, height: $0.height), rotation: $0.rotation)
            image.sourceRawValue = $0.source
            return image
        }
        card.stickers = stickers.map {
            StickerReference(id: childID($0.id), cardId: cardID, stickerId: $0.stickerId, stickerData: $0.stickerData,
                             position: CGPoint(x: $0.x, y: $0.y), size: CGSize(width: $0.width, height: $0.height), rotation: $0.rotation)
        }
        card.layoutData = layoutData
        if copyID != nil, var layout = card.getLayoutData() {
            for index in layout.imagePositions.indices {
                if let value = replacements[layout.imagePositions[index].imageId] { layout.imagePositions[index].imageId = value }
            }
            if var placements = layout.imagePlacements {
                for index in placements.indices {
                    if let value = replacements[placements[index].imageId] { placements[index].imageId = value }
                }
                layout.imagePlacements = placements
            }
            let encoder = JSONEncoder(); encoder.outputFormatting = [.sortedKeys]
            card.layoutData = try encoder.encode(layout)
        }
        return card
    }

    enum ArchiveError: LocalizedError {
        case invalid, tooLarge
        var errorDescription: String? {
            switch self {
            case .invalid: "This iCloud card is incomplete or couldn't be read. Your local cards are safe."
            case .tooLarge: "This card is too large to sync. It remains saved on this device."
            }
        }
    }
}

/// Immutable revisions retain parallel edits instead of choosing a winner by device clocks.
nonisolated struct CardCloudRevision: Codable, Equatable {
    var cardID: UUID
    var parents: [String]
    var digest: String
    var deleted: Bool
    var id: String {
        let fields = "card:\(cardID.uuidString)\nparents:\(parents.joined(separator: ","))\ndigest:\(digest)\ndeleted:\(deleted ? 1 : 0)\n"
        return CardCloudArchive.hash(Data(fields.utf8))
    }
    static func validHash(_ value: String) -> Bool {
        value.count == 64 && value.allSatisfy { "0123456789abcdef".contains($0) }
    }
    func validate() throws {
        guard Self.validHash(digest), parents.count <= 100,
              parents == Array(Set(parents)).sorted(), parents.allSatisfy(Self.validHash),
              !parents.contains(id), !deleted || digest == CardCloudArchive.hash(Data()) else {
            throw CardCloudArchive.ArchiveError.invalid
        }
    }
    static func heads(_ revisions: [Self]) throws -> [Self] {
        let map = Dictionary(grouping: revisions, by: \.id)
        guard map.values.allSatisfy({ $0.count == 1 }), Set(revisions.map(\.cardID)).count <= 1 else {
            throw CardCloudArchive.ArchiveError.invalid
        }
        let ids = Set(map.keys)
        for revision in revisions {
            try revision.validate()
            guard Set(revision.parents).isSubset(of: ids) else { throw CardCloudArchive.ArchiveError.invalid }
        }
        let retired = Set(revisions.flatMap(\.parents))
        return revisions.filter { !retired.contains($0.id) }.sorted { $0.id < $1.id }
    }
    static func descends(_ revision: Self, from parents: [String], in revisions: [Self]) -> Bool {
        let map = Dictionary(uniqueKeysWithValues: revisions.map { ($0.id, $0) })
        var visited: Set<String> = [], pending = revision.parents
        while let id = pending.popLast() {
            if visited.insert(id).inserted { pending += map[id]?.parents ?? [] }
        }
        return Set(parents).isSubset(of: visited.union([revision.id]))
    }
    static func stableUUID(_ input: String) -> UUID {
        let hex = CardCloudArchive.hash(Data(input.utf8))
        let chars = Array(hex.prefix(32))
        let value = String(chars[0..<8]) + "-" + String(chars[8..<12]) + "-" + String(chars[12..<16]) + "-" + String(chars[16..<20]) + "-" + String(chars[20..<32])
        return UUID(uuidString: value)!
    }
    static func shouldMaterializeCopy(of revision: Self, in revisions: [Self]) -> Bool {
        let copyID = stableUUID("conflict:\(revision.id)")
        return !revisions.contains { $0.cardID == copyID }
    }
}
