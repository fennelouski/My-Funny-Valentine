//
//  PlatformImage.swift
//  My Funny Valentine
//
//  Platform-agnostic image type abstraction
//

import Foundation
import SwiftUI
import CoreGraphics

#if os(iOS) || os(visionOS)
import UIKit
typealias PlatformImage = UIImage
#elseif os(macOS)
import AppKit
typealias PlatformImage = NSImage
#endif

/// Platform-agnostic image operations
nonisolated struct PlatformImageUtils {
    /// Convert PlatformImage to Data (JPEG)
    static func jpegData(from image: PlatformImage, compressionQuality: CGFloat = 0.9) -> Data? {
        #if os(iOS) || os(visionOS)
        return image.jpegData(compressionQuality: compressionQuality)
        #elseif os(macOS)
        guard let tiffData = image.tiffRepresentation,
              let bitmapImage = NSBitmapImageRep(data: tiffData),
              let jpegData = bitmapImage.representation(using: .jpeg, properties: [.compressionFactor: compressionQuality]) else {
            return nil
        }
        return jpegData
        #endif
    }
    
    /// Convert PlatformImage to Data (PNG)
    static func pngData(from image: PlatformImage) -> Data? {
        #if os(iOS) || os(visionOS)
        return image.pngData()
        #elseif os(macOS)
        guard let tiffData = image.tiffRepresentation,
              let bitmapImage = NSBitmapImageRep(data: tiffData),
              let pngData = bitmapImage.representation(using: .png, properties: [:]) else {
            return nil
        }
        return pngData
        #endif
    }
    
    /// Create PlatformImage from Data
    static func image(from data: Data) -> PlatformImage? {
        #if os(iOS) || os(visionOS)
        return UIImage(data: data)
        #elseif os(macOS)
        return NSImage(data: data)
        #endif
    }
    
    /// Get image size
    static func size(of image: PlatformImage) -> CGSize {
        #if os(iOS) || os(visionOS)
        return image.size
        #elseif os(macOS)
        return image.size
        #endif
    }
    
    /// Convert PlatformImage to SwiftUI Image
    static func swiftUIImage(from image: PlatformImage) -> Image {
        #if os(iOS) || os(visionOS)
        return Image(uiImage: image)
        #elseif os(macOS)
        return Image(nsImage: image)
        #endif
    }

    /// Load an SF Symbol as a platform image
    static func systemImage(named name: String) -> PlatformImage? {
        #if os(iOS) || os(visionOS)
        return UIImage(systemName: name)
        #elseif os(macOS)
        return NSImage(systemSymbolName: name, accessibilityDescription: nil)
        #endif
    }

    /// Resize to an exact size (aspect ratio is the caller's concern)
    static func resized(_ image: PlatformImage, to newSize: CGSize) -> PlatformImage? {
        PlatformGraphics.image(size: newSize, scale: 1.0) { context in
            PlatformGraphics.draw(image, in: CGRect(origin: .zero, size: newSize), context: context)
        }
    }

    /// Resize so the longest edge is at most `maxDimension`, preserving aspect ratio.
    /// Returns the original when it already fits.
    static func resized(_ image: PlatformImage, maxDimension: CGFloat) -> PlatformImage {
        let size = image.size
        guard size.width > 0, size.height > 0 else { return image }

        let ratio = min(maxDimension / size.width, maxDimension / size.height)
        guard ratio < 1 else { return image }

        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        return resized(image, to: newSize) ?? image
    }
}

// Note: Cross-platform conversions can be added here if needed
// For now, we use PlatformImage typealias which handles platform differences
