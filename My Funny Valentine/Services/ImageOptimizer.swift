//
//  ImageOptimizer.swift
//  My Funny Valentine
//
//  Created by Nathan Fennel on 2/12/26.
//

import Foundation
import CoreGraphics
import UniformTypeIdentifiers

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

enum SharingDestination {
    case instagram
    case facebook
    case tiktok
    case email
    case messages
    case photos
    case general
}

struct ImageOptimizationSettings {
    let maxWidth: CGFloat
    let maxHeight: CGFloat
    let quality: CGFloat
    let format: ImageFormat
    
    enum ImageFormat {
        case jpeg
        case png
        
        var utType: UTType {
            switch self {
            case .jpeg:
                return .jpeg
            case .png:
                return .png
            }
        }
    }
}

class ImageOptimizer {
    static let shared = ImageOptimizer()
    
    private init() {}
    
    /// Get optimization settings for a specific sharing destination
    func settings(for destination: SharingDestination) -> ImageOptimizationSettings {
        switch destination {
        case .instagram:
            // Instagram: 1080x1080 square or 1080x1350 portrait
            return ImageOptimizationSettings(
                maxWidth: 1080,
                maxHeight: 1350,
                quality: 0.92,
                format: .jpeg
            )
        case .facebook:
            // Facebook: 1200x630 for link previews, or original for photos
            return ImageOptimizationSettings(
                maxWidth: 1200,
                maxHeight: 1200,
                quality: 0.90,
                format: .jpeg
            )
        case .tiktok:
            // TikTok: 1080x1920 vertical (9:16 aspect ratio)
            return ImageOptimizationSettings(
                maxWidth: 1080,
                maxHeight: 1920,
                quality: 0.85,
                format: .jpeg
            )
        case .email:
            // Email: Compress to reduce size
            return ImageOptimizationSettings(
                maxWidth: 1200,
                maxHeight: 1200,
                quality: 0.70,
                format: .jpeg
            )
        case .messages:
            // Messages: Balance quality and size
            return ImageOptimizationSettings(
                maxWidth: 2048,
                maxHeight: 2048,
                quality: 0.80,
                format: .jpeg
            )
        case .photos:
            // Photos: High quality, original dimensions
            return ImageOptimizationSettings(
                maxWidth: 4096,
                maxHeight: 4096,
                quality: 0.85,
                format: .jpeg
            )
        case .general:
            // General sharing: Good quality
            return ImageOptimizationSettings(
                maxWidth: 2048,
                maxHeight: 2048,
                quality: 0.85,
                format: .jpeg
            )
        }
    }
    
    /// Optimize an image for a specific sharing destination
    func optimize(_ image: PlatformImage, for destination: SharingDestination) -> Data? {
        let settings = settings(for: destination)
        return optimize(image, with: settings)
    }
    
    /// Optimize an image with specific settings
    func optimize(_ image: PlatformImage, with settings: ImageOptimizationSettings) -> Data? {
        // Resize if needed
        let resizedImage = resize(image, maxWidth: settings.maxWidth, maxHeight: settings.maxHeight)
        
        // Convert to data with appropriate format and quality
        switch settings.format {
        case .jpeg:
            return PlatformImageUtils.jpegData(from: resizedImage, compressionQuality: settings.quality)
        case .png:
            return PlatformImageUtils.pngData(from: resizedImage)
        }
    }
    
    /// Resize image maintaining aspect ratio
    private func resize(_ image: PlatformImage, maxWidth: CGFloat, maxHeight: CGFloat) -> PlatformImage {
        let size = image.size
        
        // If image is smaller than max dimensions, return original
        if size.width <= maxWidth && size.height <= maxHeight {
            return image
        }
        
        // Calculate new size maintaining aspect ratio
        let aspectRatio = size.width / size.height
        var newSize: CGSize
        
        if size.width > size.height {
            // Landscape
            newSize = CGSize(width: maxWidth, height: maxWidth / aspectRatio)
            if newSize.height > maxHeight {
                newSize = CGSize(width: maxHeight * aspectRatio, height: maxHeight)
            }
        } else {
            // Portrait or square
            newSize = CGSize(width: maxHeight * aspectRatio, height: maxHeight)
            if newSize.width > maxWidth {
                newSize = CGSize(width: maxWidth, height: maxWidth / aspectRatio)
            }
        }
        
        // Render resized image
        return PlatformImageUtils.resized(image, to: newSize) ?? image
    }
    
    /// Optimize for Instagram with specific aspect ratio
    func optimizeForInstagram(_ image: PlatformImage, isPortrait: Bool = false) -> Data? {
        let targetSize: CGSize
        if isPortrait {
            targetSize = CGSize(width: 1080, height: 1350)
        } else {
            targetSize = CGSize(width: 1080, height: 1080)
        }
        
        let resizedImage = resizeToExactSize(image, targetSize: targetSize, maintainAspectRatio: true)
        return resizedImage.flatMap { PlatformImageUtils.jpegData(from: $0, compressionQuality: 0.92) }
    }
    
    /// Optimize for TikTok (vertical 9:16)
    func optimizeForTikTok(_ image: PlatformImage) -> Data? {
        let targetSize = CGSize(width: 1080, height: 1920)
        let resizedImage = resizeToExactSize(image, targetSize: targetSize, maintainAspectRatio: true)
        return resizedImage.flatMap { PlatformImageUtils.jpegData(from: $0, compressionQuality: 0.85) }
    }
    
    /// Resize to exact size, optionally maintaining aspect ratio (with letterboxing/pillarboxing)
    private func resizeToExactSize(_ image: PlatformImage, targetSize: CGSize, maintainAspectRatio: Bool) -> PlatformImage? {
        PlatformGraphics.image(size: targetSize, scale: 1.0) { context in
            guard maintainAspectRatio else {
                PlatformGraphics.draw(image, in: CGRect(origin: .zero, size: targetSize), context: context)
                return
            }

            // Calculate aspect-fit size
            let imageAspect = image.size.width / image.size.height
            let targetAspect = targetSize.width / targetSize.height

            let drawSize: CGSize
            let drawOrigin: CGPoint

            if imageAspect > targetAspect {
                // Image is wider - fit to width
                drawSize = CGSize(width: targetSize.width, height: targetSize.width / imageAspect)
                drawOrigin = CGPoint(x: 0, y: (targetSize.height - drawSize.height) / 2)
            } else {
                // Image is taller - fit to height
                drawSize = CGSize(width: targetSize.height * imageAspect, height: targetSize.height)
                drawOrigin = CGPoint(x: (targetSize.width - drawSize.width) / 2, y: 0)
            }

            // Letterbox/pillarbox background
            context.setFillColor(PlatformColor.white.cgColor)
            context.fill(CGRect(origin: .zero, size: targetSize))

            PlatformGraphics.draw(image, in: CGRect(origin: drawOrigin, size: drawSize), context: context)
        }
    }
    
    /// Check if image data size is within limit (for email, etc.)
    func isWithinSizeLimit(_ data: Data, maxSizeMB: Double) -> Bool {
        let sizeInMB = Double(data.count) / (1024 * 1024)
        return sizeInMB <= maxSizeMB
    }
    
    /// Further compress if needed to meet size limit
    func compressToSizeLimit(_ image: PlatformImage, maxSizeMB: Double, for destination: SharingDestination) -> Data? {
        var quality: CGFloat = settings(for: destination).quality
        
        while quality > 0.1 {
            if let data = optimize(image, for: destination) {
                if isWithinSizeLimit(data, maxSizeMB: maxSizeMB) {
                    return data
                }
            }
            quality -= 0.1
        }
        
        return nil
    }
}
