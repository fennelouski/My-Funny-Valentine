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
    var rotation: Double

    // Stored as primitives so SwiftData can persist them; see FaceImage for why.
    var positionX: Double
    var positionY: Double
    var sizeWidth: Double
    var sizeHeight: Double

    var position: CGPoint {
        get { CGPoint(x: positionX, y: positionY) }
        set {
            positionX = newValue.x
            positionY = newValue.y
        }
    }

    var size: CGSize {
        get { CGSize(width: sizeWidth, height: sizeHeight) }
        set {
            sizeWidth = newValue.width
            sizeHeight = newValue.height
        }
    }

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
        self.positionX = position.x
        self.positionY = position.y
        self.sizeWidth = size.width
        self.sizeHeight = size.height
        self.rotation = rotation
    }
}
