//
//  CardImage.swift
//  My Funny Valentine
//
//  Created by Nathan Fennel on 2/12/26.
//

import Foundation
import CoreGraphics
import SwiftData

// ImageSource is defined in ImageSource.swift

@Model
final class CardImage {
    var id: UUID
    var cardId: UUID
    var imageData: Data
    var rotation: Double

    // Stored as primitives so SwiftData can persist them; see FaceImage for why.
    var sourceRawValue: String
    var positionX: Double
    var positionY: Double
    var sizeWidth: Double
    var sizeHeight: Double

    var syncedToCloud: Bool = false

    var source: ImageSource {
        get { ImageSource(rawValue: sourceRawValue) ?? .photoImport }
        set { sourceRawValue = newValue.rawValue }
    }

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
        source: ImageSource,
        imageData: Data,
        position: CGPoint = .zero,
        // Non-zero so an image added without an explicit size is still visible.
        size: CGSize = CGSize(width: 200, height: 200),
        rotation: Double = 0.0
    ) {
        self.id = id
        self.cardId = cardId
        self.sourceRawValue = source.rawValue
        self.imageData = imageData
        self.positionX = position.x
        self.positionY = position.y
        self.sizeWidth = size.width
        self.sizeHeight = size.height
        self.rotation = rotation
    }
}
