//
//  Card+Sharing.swift
//  My Funny Valentine
//
//  Created by Nathan Fennel on 2/12/26.
//

import Foundation
import CoreGraphics

extension Card {
    /// Render card as an image for sharing
    func renderAsImage(size: CGSize = CGSize(width: 1080, height: 1080)) -> PlatformImage? {
        return CardRenderer.shared.renderCard(self, size: size)
    }

    /// Get optimized image for sharing destination
    func optimizedImage(for destination: SharingDestination) -> PlatformImage? {
        guard let image = renderAsImage() else { return nil }
        guard let optimizedData = ImageOptimizer.shared.optimize(image, for: destination),
              let optimizedImage = PlatformImageUtils.image(from: optimizedData) else {
            return image // Fallback to original
        }
        return optimizedImage
    }
}
