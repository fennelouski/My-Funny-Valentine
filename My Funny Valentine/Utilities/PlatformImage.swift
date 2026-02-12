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
struct PlatformImageUtils {
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
}

// Note: Cross-platform conversions can be added here if needed
// For now, we use PlatformImage typealias which handles platform differences
