//
//  GIFExporter.swift
//  My Funny Valentine
//
//  Created by Nathan Fennel on 2/12/26.
//

import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

enum AnimationType {
    case fadeInOut
    case slide
    case zoom
    case heartAnimation
    case textReveal
}

struct GIFExportOptions {
    var frameRate: Double = 12.0 // fps
    var duration: Double = 4.0 // seconds
    var maxColors: Int = 256
    var maxSizeMB: Double = 10.0
    var animationType: AnimationType = .fadeInOut
}

#if os(macOS)
import AppKit

class GIFExporter {
    static let shared = GIFExporter()
    
    private init() {}
    
    /// Create animated GIF from card image with animation
    func createAnimatedGIF(from image: NSImage, options: GIFExportOptions = GIFExportOptions()) -> Data? {
        let frameCount = Int(options.frameRate * options.duration)
        let frameDelay = 1.0 / options.frameRate
        
        // Generate frames based on animation type
        let frames = generateFrames(from: image, animationType: options.animationType, frameCount: frameCount)
        
        // Create GIF data
        guard let gifData = encodeGIF(frames: frames, frameDelay: frameDelay, maxColors: options.maxColors) else {
            return nil
        }
        
        // Check size limit
        let sizeInMB = Double(gifData.count) / (1024 * 1024)
        if sizeInMB > options.maxSizeMB {
            // Try reducing frame rate or colors
            return createOptimizedGIF(from: image, options: options)
        }
        
        return gifData
    }
    
    /// Generate animation frames
    private func generateFrames(from image: NSImage, animationType: AnimationType, frameCount: Int) -> [NSImage] {
        var frames: [NSImage] = []
        
        switch animationType {
        case .fadeInOut:
            frames = generateFadeInOutFrames(image: image, frameCount: frameCount)
        case .slide:
            frames = generateSlideFrames(image: image, frameCount: frameCount)
        case .zoom:
            frames = generateZoomFrames(image: image, frameCount: frameCount)
        case .heartAnimation:
            frames = generateHeartAnimationFrames(image: image, frameCount: frameCount)
        case .textReveal:
            frames = generateTextRevealFrames(image: image, frameCount: frameCount)
        }
        
        return frames
    }
    
    /// Generate fade in/out frames
    private func generateFadeInOutFrames(image: NSImage, frameCount: Int) -> [NSImage] {
        var frames: [NSImage] = []
        let halfCount = frameCount / 2
        
        for i in 0..<frameCount {
            let alpha: CGFloat
            if i < halfCount {
                // Fade in
                alpha = CGFloat(i) / CGFloat(halfCount)
            } else {
                // Fade out
                alpha = 1.0 - CGFloat(i - halfCount) / CGFloat(halfCount)
            }
            
            if let frame = applyAlpha(to: image, alpha: alpha) {
                frames.append(frame)
            }
        }
        
        return frames
    }
    
    /// Generate slide frames
    private func generateSlideFrames(image: NSImage, frameCount: Int) -> [NSImage] {
        var frames: [NSImage] = []
        let size = image.size
        
        for i in 0..<frameCount {
            let progress = Double(i) / Double(frameCount)
            let offsetX = size.width * CGFloat(sin(progress * .pi * 2))
            
            if let frame = applyTransform(to: image, translation: CGPoint(x: offsetX, y: 0)) {
                frames.append(frame)
            }
        }
        
        return frames
    }
    
    /// Generate zoom frames
    private func generateZoomFrames(image: NSImage, frameCount: Int) -> [NSImage] {
        var frames: [NSImage] = []
        let size = image.size
        
        for i in 0..<frameCount {
            let progress = Double(i) / Double(frameCount)
            let scale: CGFloat = 1.0 + CGFloat(sin(progress * .pi * 2)) * 0.2 // Zoom between 1.0 and 1.2
            
            if let frame = applyTransform(to: image, scale: scale, center: CGPoint(x: size.width / 2, y: size.height / 2)) {
                frames.append(frame)
            }
        }
        
        return frames
    }
    
    /// Generate heart animation frames (hearts float around)
    private func generateHeartAnimationFrames(image: NSImage, frameCount: Int) -> [NSImage] {
        // For simplicity, use fade in/out with slight movement
        // In a full implementation, you'd overlay heart emojis/stickers
        return generateFadeInOutFrames(image: image, frameCount: frameCount)
    }
    
    /// Generate text reveal frames
    private func generateTextRevealFrames(image: NSImage, frameCount: Int) -> [NSImage] {
        // For simplicity, use fade in
        // In a full implementation, you'd animate text appearing
        return generateFadeInOutFrames(image: image, frameCount: frameCount)
    }
    
    /// Apply alpha to image
    private func applyAlpha(to image: NSImage, alpha: CGFloat) -> NSImage? {
        let size = image.size
        let rep = NSBitmapImageRep(bitmapDataPlanes: nil,
                                   pixelsWide: Int(size.width),
                                   pixelsHigh: Int(size.height),
                                   bitsPerSample: 8,
                                   samplesPerPixel: 4,
                                   hasAlpha: true,
                                   isPlanar: false,
                                   colorSpaceName: .calibratedRGB,
                                   bytesPerRow: 0,
                                   bitsPerPixel: 0)
        
        guard let bitmapRep = rep else { return nil }
        
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmapRep)
        
        image.draw(at: .zero, from: .zero, operation: .sourceOver, fraction: alpha)
        
        NSGraphicsContext.restoreGraphicsState()
        
        let newImage = NSImage(size: size)
        newImage.addRepresentation(bitmapRep)
        return newImage
    }
    
    /// Apply transform to image
    private func applyTransform(to image: NSImage, translation: CGPoint = .zero, scale: CGFloat = 1.0, center: CGPoint? = nil) -> NSImage? {
        let size = image.size
        let rep = NSBitmapImageRep(bitmapDataPlanes: nil,
                                   pixelsWide: Int(size.width),
                                   pixelsHigh: Int(size.height),
                                   bitsPerSample: 8,
                                   samplesPerPixel: 4,
                                   hasAlpha: true,
                                   isPlanar: false,
                                   colorSpaceName: .calibratedRGB,
                                   bytesPerRow: 0,
                                   bitsPerPixel: 0)
        
        guard let bitmapRep = rep else { return nil }
        
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmapRep)
        
        let context = NSGraphicsContext.current?.cgContext
        context?.translateBy(x: translation.x, y: translation.y)
        
        if let center = center {
            context?.translateBy(x: center.x, y: center.y)
            context?.scaleBy(x: scale, y: scale)
            context?.translateBy(x: -center.x, y: -center.y)
        } else {
            context?.scaleBy(x: scale, y: scale)
        }
        
        image.draw(at: .zero, from: .zero, operation: .sourceOver, fraction: 1.0)
        
        NSGraphicsContext.restoreGraphicsState()
        
        let newImage = NSImage(size: size)
        newImage.addRepresentation(bitmapRep)
        return newImage
    }
    
    /// Encode frames as GIF
    private func encodeGIF(frames: [NSImage], frameDelay: Double, maxColors: Int) -> Data? {
        guard !frames.isEmpty else { return nil }
        
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(data, UTType.gif.identifier as CFString, frames.count, nil) else {
            return nil
        }
        
        // GIF properties
        let gifProperties: [CFString: Any] = [
            kCGImagePropertyGIFDictionary: [
                kCGImagePropertyGIFLoopCount: 0, // Infinite loop
                kCGImagePropertyGIFHasGlobalColorMap: true
            ]
        ]
        
        CGImageDestinationSetProperties(destination, gifProperties as CFDictionary)
        
        // Add frames
        for (index, frame) in frames.enumerated() {
            guard let cgImage = frame.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
                continue
            }
            
            let frameProperties: [CFString: Any] = [
                kCGImagePropertyGIFDictionary: [
                    kCGImagePropertyGIFDelayTime: frameDelay
                ]
            ]
            
            CGImageDestinationAddImage(destination, cgImage, frameProperties as CFDictionary)
        }
        
        guard CGImageDestinationFinalize(destination) else {
            return nil
        }
        
        return data as Data
    }
    
    /// Create optimized GIF if initial size is too large
    private func createOptimizedGIF(from image: NSImage, options: GIFExportOptions) -> Data? {
        var optimizedOptions = options
        
        // Reduce frame rate
        optimizedOptions.frameRate = max(8.0, options.frameRate * 0.75)
        
        // Reduce duration
        optimizedOptions.duration = max(2.0, options.duration * 0.75)
        
        // Reduce colors
        optimizedOptions.maxColors = max(128, options.maxColors / 2)
        
        return createAnimatedGIF(from: image, options: optimizedOptions)
    }
    
    /// Save GIF to file with file dialog
    func saveGIF(_ gifData: Data, suggestedFilename: String = "card.gif") {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.gif]
        savePanel.nameFieldStringValue = suggestedFilename
        savePanel.canCreateDirectories = true
        
        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                do {
                    try gifData.write(to: url)
                } catch {
                    print("Failed to save GIF: \(error)")
                }
            }
        }
    }
}

#endif
