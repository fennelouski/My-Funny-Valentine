//
//  CardImage.swift
//  My Funny Valentine
//
//  Created by Nathan Fennel on 2/12/26.
//

import Foundation
import CoreGraphics
import SwiftData

enum ImageSource: String, Codable {
    case imagePlayground
    case sticker
    case smartCutout
    case photoImport
}

@Model
final class CardImage {
    var id: UUID
    var cardId: UUID
    var source: ImageSource
    var imageData: Data
    var position: CGPoint
    var size: CGSize
    var rotation: Double
    
    init(
        id: UUID = UUID(),
        cardId: UUID,
        source: ImageSource,
        imageData: Data,
        position: CGPoint = .zero,
        size: CGSize = .zero,
        rotation: Double = 0.0
    ) {
        self.id = id
        self.cardId = cardId
        self.source = source
        self.imageData = imageData
        self.position = position
        self.size = size
        self.rotation = rotation
    }
}
