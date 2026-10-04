//
//  Card.swift
//  My Funny Valentine
//

import Foundation
import SwiftData

@Model
final class Card {
    var id: UUID
    var templateId: String?
    var saying: String?
    var customText: String?
    var createdAt: Date
    var modifiedAt: Date
    var syncedToCloud: Bool
    
    @Relationship(deleteRule: .cascade)
    var faces: [FaceImage]?
    
    @Relationship(deleteRule: .cascade)
    var images: [CardImage]?
    
    @Relationship(deleteRule: .cascade)
    var stickers: [StickerReference]?
    
    var layoutData: Data?
    
    init(
        id: UUID = UUID(),
        templateId: String? = nil,
        saying: String? = nil,
        customText: String? = nil,
        createdAt: Date = Date(),
        modifiedAt: Date = Date(),
        syncedToCloud: Bool = false,
        faces: [FaceImage] = [],
        images: [CardImage] = [],
        stickers: [StickerReference] = [],
        layoutData: CardLayoutData? = nil
    ) {
        self.id = id
        self.templateId = templateId
        self.saying = saying
        self.customText = customText
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
        self.syncedToCloud = syncedToCloud
        self.faces = faces
        self.images = images
        self.stickers = stickers
        
        if let layoutData = layoutData {
            let encoder = JSONEncoder()
            self.layoutData = try? encoder.encode(layoutData)
        } else {
            self.layoutData = nil
        }
    }
    
    func getLayoutData() -> CardLayoutData? {
        guard let data = layoutData else { return nil }
        let decoder = JSONDecoder()
        return try? decoder.decode(CardLayoutData.self, from: data)
    }
    
    func setLayoutData(_ layoutData: CardLayoutData?) {
        if let layoutData = layoutData {
            let encoder = JSONEncoder()
            self.layoutData = try? encoder.encode(layoutData)
        } else {
            self.layoutData = nil
        }
    }
    
    func updateModifiedDate() {
        self.modifiedAt = Date()
        self.syncedToCloud = false
    }
    
    func updateTextPosition(at index: Int, text: String) {
        var data = getLayoutData() ?? CardLayoutData()
        if index < data.textPositions.count {
            data.textPositions[index].text = text
            setLayoutData(data)
        }
    }
}

// CardLayoutData for storing layout information
nonisolated struct CardLayoutData: Codable {
    var backgroundColor: String
    var textPositions: [TextPosition]
    var imagePositions: [ImagePosition]
    var stickerPositions: [StickerPosition]
    var templateLayoutId: String?
    var textPositionX: CGFloat?
    var textPositionY: CGFloat?
    var textRotation: Double?
    var imagePlacements: [ImagePosition]?
    var composition: CardComposition?

    init(
        backgroundColor: String = "#FFFFFF",
        textPositions: [TextPosition] = [],
        imagePositions: [ImagePosition] = [],
        stickerPositions: [StickerPosition] = [],
        templateLayoutId: String? = nil,
        textPositionX: CGFloat? = nil,
        textPositionY: CGFloat? = nil,
        textRotation: Double? = nil,
        imagePlacements: [ImagePosition]? = nil,
        composition: CardComposition? = nil
    ) {
        self.backgroundColor = backgroundColor
        self.textPositions = textPositions
        self.imagePositions = imagePositions
        self.stickerPositions = stickerPositions
        self.templateLayoutId = templateLayoutId
        self.textPositionX = textPositionX
        self.textPositionY = textPositionY
        self.textRotation = textRotation
        self.imagePlacements = imagePlacements
        self.composition = composition
    }

    private enum CodingKeys: String, CodingKey {
        case backgroundColor, textPositions, imagePositions, stickerPositions, templateLayoutId
        case textPositionX, textPositionY, textRotation, imagePlacements, composition
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        backgroundColor = try values.decode(String.self, forKey: .backgroundColor)
        textPositions = try values.decode([TextPosition].self, forKey: .textPositions)
        imagePositions = try values.decode([ImagePosition].self, forKey: .imagePositions)
        stickerPositions = try values.decode([StickerPosition].self, forKey: .stickerPositions)
        templateLayoutId = try values.decodeIfPresent(String.self, forKey: .templateLayoutId)
        textPositionX = try values.decodeIfPresent(CGFloat.self, forKey: .textPositionX)
        textPositionY = try values.decodeIfPresent(CGFloat.self, forKey: .textPositionY)
        textRotation = try values.decodeIfPresent(Double.self, forKey: .textRotation)
        imagePlacements = try values.decodeIfPresent([ImagePosition].self, forKey: .imagePlacements)
        // A future design family must not discard a saved classic layout.
        composition = try? values.decodeIfPresent(CardComposition.self, forKey: .composition)
    }
}

nonisolated struct TextPosition: Codable {
    var text: String
    var fontName: String
    var fontSize: CGFloat
    var color: String
    var position: CGPoint
    var size: CGSize
}

nonisolated struct ImagePosition: Codable {
    var imageId: UUID
    var position: CGPoint
    var size: CGSize
    var rotation: Double
}

nonisolated struct StickerPosition: Codable {
    var stickerId: String
    var position: CGPoint
    var size: CGSize
    var rotation: Double
}
