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

#if os(macOS)
// MARK: - UIImage to NSImage Conversion (for compatibility)
extension NSImage {
    /// Create NSImage from UIImage (for cross-platform compatibility)
    convenience init?(uiImage: UIImage) {
        guard let cgImage = uiImage.cgImage else { return nil }
        let size = CGSize(width: cgImage.width, height: cgImage.height)
        self.init(size: size)
        self.lockFocus()
        NSGraphicsContext.current?.imageInterpolation = .high
        NSGraphicsContext.current?.cgContext.draw(cgImage, in: CGRect(origin: .zero, size: size))
        self.unlockFocus()
    }
    
    /// Convert NSImage to UIImage (for cross-platform compatibility)
    var uiImage: UIImage? {
        guard let tiffData = self.tiffRepresentation,
              let bitmapImage = NSBitmapImageRep(data: tiffData),
              let cgImage = bitmapImage.cgImage else {
            return nil
        }
        return UIImage(cgImage: cgImage)
    }
}
#endif

#if os(iOS) || os(visionOS)
// MARK: - NSImage to UIImage Conversion (for compatibility)
extension UIImage {
    /// Create UIImage from NSImage (for cross-platform compatibility)
    convenience init?(nsImage: NSImage) {
        guard let tiffData = nsImage.tiffRepresentation,
              let bitmapImage = NSBitmapImageRep(data: tiffData),
              let cgImage = bitmapImage.cgImage else {
            return nil
        }
        self.init(cgImage: cgImage)
    }
    
    /// Convert UIImage to NSImage (for cross-platform compatibility)
    var nsImage: NSImage? {
        guard let cgImage = self.cgImage else { return nil }
        let size = CGSize(width: cgImage.width, height: cgImage.height)
        let nsImage = NSImage(size: size)
        nsImage.lockFocus()
        NSGraphicsContext.current?.imageInterpolation = .high
        NSGraphicsContext.current?.cgContext.draw(cgImage, in: CGRect(origin: .zero, size: size))
        nsImage.unlockFocus()
        return nsImage
    }
}
#endif
