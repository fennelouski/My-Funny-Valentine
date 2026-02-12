//
//  StickerReference.swift
//  My Funny Valentine
//
//  Created by Nathan Fennel on 2/12/26.
//

import Foundation
import CoreGraphics
import SwiftData

@Model
final class StickerReference {
    var id: UUID
    var cardId: UUID
    var stickerId: String
    @Attribute(.externalStorage) var stickerData: Data?
    var position: CGPoint
    var size: CGSize
    var rotation: Double
    
    init(
        id: UUID = UUID(),
        cardId: UUID,
        stickerId: String,
        stickerData: Data? = nil,
        position: CGPoint = .zero,
        size: CGSize = .zero,
        rotation: Double = 0.0
    ) {
        self.id = id
        self.cardId = cardId
        self.stickerId = stickerId
        self.stickerData = stickerData
        self.position = position
        self.size = size
        self.rotation = rotation
    }
}
