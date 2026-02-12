//
//  Card+Sharing.swift
//  My Funny Valentine
//
//  Created by Nathan Fennel on 2/12/26.
//

import Foundation
import UIKit

extension Card {
    /// Render card as UIImage for sharing
    func renderAsImage(size: CGSize = CGSize(width: 1080, height: 1080)) -> UIImage? {
        return CardRenderer.shared.renderCard(self, size: size)
    }
    
    /// Get optimized image for sharing destination
    func optimizedImage(for destination: SharingDestination) -> UIImage? {
        guard let image = renderAsImage() else { return nil }
        guard let optimizedData = ImageOptimizer.shared.optimize(image, for: destination),
              let optimizedImage = UIImage(data: optimizedData) else {
            return image // Fallback to original
        }
        return optimizedImage
    }
}
