//
//  FaceImage.swift
//  My Funny Valentine
//
//  Created by Nathan Fennel on 2/12/26.
//

import Foundation
import CoreGraphics
import SwiftData

@Model
final class FaceImage {
    var id: UUID
    var cardId: UUID
    var imageData: Data
    var thumbnailData: Data
    var detectedAt: Date

    // CGPoint/CGSize encode to unkeyed containers, which SwiftData's composite
    // coder cannot persist ("Composite Coder only supports Keyed Container").
    // Store the components and expose the geometry types as computed properties.
    var positionX: Double
    var positionY: Double
    var sizeWidth: Double
    var sizeHeight: Double

    var syncedToCloud: Bool = false

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
        imageData: Data,
        thumbnailData: Data,
        detectedAt: Date = Date(),
        position: CGPoint = .zero,
        size: CGSize = .zero
    ) {
        self.id = id
        self.cardId = cardId
        self.imageData = imageData
        self.thumbnailData = thumbnailData
        self.detectedAt = detectedAt
        self.positionX = position.x
        self.positionY = position.y
        self.sizeWidth = size.width
        self.sizeHeight = size.height
    }
}
