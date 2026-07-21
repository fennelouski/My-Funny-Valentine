//
//  PlatformGraphics.swift
//  My Funny Valentine
//
//  Cross-platform drawing built on CoreGraphics so card rendering behaves
//  identically on iOS and macOS.
//

import Foundation
import CoreGraphics
import CoreText
import SwiftUI

#if canImport(UIKit)
import UIKit
typealias PlatformColor = UIColor
typealias PlatformFont = UIFont
#elseif canImport(AppKit)
import AppKit
typealias PlatformColor = NSColor
typealias PlatformFont = NSFont
#endif

nonisolated enum PlatformGraphics {

    /// Draws into a top-left-origin context (UIKit convention) and returns the result.
    static func image(size: CGSize, scale: CGFloat = 2.0, _ draw: (CGContext) -> Void) -> PlatformImage? {
        let pixelWidth = Int(size.width * scale)
        let pixelHeight = Int(size.height * scale)
        guard pixelWidth > 0, pixelHeight > 0 else { return nil }

        guard let context = CGContext(
            data: nil,
            width: pixelWidth,
            height: pixelHeight,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        context.scaleBy(x: scale, y: scale)
        // Flip so callers can use top-left origin coordinates on both platforms.
        context.translateBy(x: 0, y: size.height)
        context.scaleBy(x: 1, y: -1)

        draw(context)

        guard let cgImage = context.makeImage() else { return nil }
        return makeImage(from: cgImage, size: size)
    }

    /// Draws an image into a flipped (top-left origin) context, right way up.
    static func draw(_ image: PlatformImage, in rect: CGRect, context: CGContext) {
        guard let cgImage = cgImage(from: image) else { return }
        context.saveGState()
        context.translateBy(x: rect.origin.x, y: rect.origin.y + rect.height)
        context.scaleBy(x: 1, y: -1)
        context.draw(cgImage, in: CGRect(origin: .zero, size: rect.size))
        context.restoreGState()
    }

    /// Draws attributed text into a flipped context using CoreText.
    static func draw(_ text: NSAttributedString, in rect: CGRect, context: CGContext) {
        context.saveGState()
        // CoreText draws bottom-up; flip back locally for correct glyph orientation.
        context.translateBy(x: 0, y: rect.origin.y + rect.height)
        context.scaleBy(x: 1, y: -1)

        let path = CGPath(rect: CGRect(origin: CGPoint(x: rect.origin.x, y: 0), size: rect.size), transform: nil)
        let framesetter = CTFramesetterCreateWithAttributedString(text as CFAttributedString)
        let frame = CTFramesetterCreateFrame(
            framesetter,
            CFRangeMake(0, text.length),
            path,
            nil
        )
        CTFrameDraw(frame, context)
        context.restoreGState()
    }

    /// Measures attributed text, constrained to `maxWidth`.
    static func size(of text: NSAttributedString, maxWidth: CGFloat = .greatestFiniteMagnitude) -> CGSize {
        let framesetter = CTFramesetterCreateWithAttributedString(text as CFAttributedString)
        return CTFramesetterSuggestFrameSizeWithConstraints(
            framesetter,
            CFRangeMake(0, text.length),
            nil,
            CGSize(width: maxWidth, height: .greatestFiniteMagnitude),
            nil
        )
    }

    static func makeImage(from cgImage: CGImage, size: CGSize) -> PlatformImage {
        #if canImport(UIKit)
        return UIImage(cgImage: cgImage)
        #elseif canImport(AppKit)
        return NSImage(cgImage: cgImage, size: size)
        #endif
    }

    static func cgImage(from image: PlatformImage) -> CGImage? {
        #if canImport(UIKit)
        return image.cgImage
        #elseif canImport(AppKit)
        var rect = CGRect(origin: .zero, size: image.size)
        return image.cgImage(forProposedRect: &rect, context: nil, hints: nil)
        #endif
    }

    /// Opens a URL using the platform's application object.
    @MainActor
    static func open(_ url: URL) {
        #if canImport(UIKit)
        UIApplication.shared.open(url)
        #elseif canImport(AppKit)
        NSWorkspace.shared.open(url)
        #endif
    }
}

// MARK: - Hex colors

nonisolated extension PlatformColor {
    /// Creates a color from `#RGB`, `#RRGGBB`, or `#AARRGGBB`.
    static func fromHex(_ hex: String) -> PlatformColor? {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)

        let a, r, g, b: UInt64
        switch cleaned.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (value >> 8) * 17, (value >> 4 & 0xF) * 17, (value & 0xF) * 17)
        case 6: // RRGGBB
            (a, r, g, b) = (255, value >> 16, value >> 8 & 0xFF, value & 0xFF)
        case 8: // AARRGGBB
            (a, r, g, b) = (value >> 24, value >> 16 & 0xFF, value >> 8 & 0xFF, value & 0xFF)
        default:
            return nil
        }

        #if canImport(UIKit)
        return PlatformColor(
            red: CGFloat(r) / 255,
            green: CGFloat(g) / 255,
            blue: CGFloat(b) / 255,
            alpha: CGFloat(a) / 255
        )
        #elseif canImport(AppKit)
        return PlatformColor(
            srgbRed: CGFloat(r) / 255,
            green: CGFloat(g) / 255,
            blue: CGFloat(b) / 255,
            alpha: CGFloat(a) / 255
        )
        #endif
    }

    /// RGBA components in the sRGB space.
    var rgbaComponents: (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        #if canImport(UIKit)
        getRed(&r, green: &g, blue: &b, alpha: &a)
        #elseif canImport(AppKit)
        (usingColorSpace(.sRGB) ?? self).getRed(&r, green: &g, blue: &b, alpha: &a)
        #endif
        return (r, g, b, a)
    }
}
