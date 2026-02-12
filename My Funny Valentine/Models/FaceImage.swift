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
    var position: CGPoint
    var size: CGSize
    
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
        self.position = position
        self.size = size
    }
}
