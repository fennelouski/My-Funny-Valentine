import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers
#if os(macOS)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

enum AnimationType {
    case fadeInOut
    case slide
    case zoom
    case heartAnimation
    case textReveal
    case faceWiggle
}

struct GIFExportOptions {
    var frameRate: Double = 12
    var duration: Double = 4
    // Retained for source compatibility; ImageIO chooses the GIF palette.
    var maxColors: Int = 256
    var maxSizeMB: Double = 10
    var animationType: AnimationType = .fadeInOut
}

class GIFExporter {
    static let shared = GIFExporter()
    private init() {}

    /// Each frame comes from the same renderer as the editor. Only faces move.
    func createAnimatedGIF(
        from card: Card,
        options: GIFExportOptions = GIFExportOptions(animationType: .faceWiggle)
    ) -> Data? {
        guard options.animationType != .faceWiggle || !(card.faces ?? []).isEmpty else { return nil }
        return encodeGIF(size: CardRenderer.canvasSize, options: options) { phase, size in
            let image = CardRenderer.shared.renderCard(
                card, size: size,
                faceAnimationPhase: options.animationType == .faceWiggle ? phase : nil
            )
            guard let image else { return nil }
            return self.frame(from: image, phase: phase, animation: options.animationType, size: size)
        }
    }

    /// Compatibility path for an already flattened card image.
    func createAnimatedGIF(from image: PlatformImage, options: GIFExportOptions = GIFExportOptions()) -> Data? {
        guard options.animationType != .faceWiggle else { return nil }
        return encodeGIF(size: image.size, options: options) { phase, size in
            self.frame(from: image, phase: phase, animation: options.animationType, size: size)
        }
    }

    private func encodeGIF(
        size: CGSize, options: GIFExportOptions,
        makeFrame: (Double, CGSize) -> CGImage?
    ) -> Data? {
        guard size.width.isFinite, size.height.isFinite, size.width > 0, size.height > 0,
              options.frameRate.isFinite, options.frameRate > 0,
              options.duration.isFinite, options.duration > 0,
              options.maxSizeMB.isFinite, options.maxSizeMB > 0 else { return nil }
        let duration = min(options.duration, 8)
        // ponytail: 32 streamed frames cap export work; increase after profiling long animations.
        let frameCount = max(2, min(32, Int(min(options.frameRate, 24) * duration)))
        let delay = duration / Double(frameCount)
        let byteLimit = min(options.maxSizeMB, 50) * 1024 * 1024

        // Finite retries fix the old recursive optimizer's minimum-size loop.
        for longestEdge in [CGFloat(640), 480, 320, 240] {
            let scale = min(1, longestEdge / max(size.width, size.height))
            let output = CGSize(width: max(1, floor(size.width * scale)),
                                height: max(1, floor(size.height * scale)))
            let data = NSMutableData()
            guard let destination = CGImageDestinationCreateWithData(
                data, UTType.gif.identifier as CFString, frameCount, nil
            ) else { return nil }
            CGImageDestinationSetProperties(destination, [
                kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFLoopCount: 0]
            ] as CFDictionary)
            for index in 0..<frameCount {
                let added = autoreleasepool { () -> Bool in
                    guard let frame = makeFrame(Double(index) / Double(frameCount), output) else { return false }
                    CGImageDestinationAddImage(destination, frame, [
                        kCGImagePropertyGIFDictionary: [
                            kCGImagePropertyGIFDelayTime: delay,
                            kCGImagePropertyGIFUnclampedDelayTime: delay
                        ]
                    ] as CFDictionary)
                    return true
                }
                guard added else { return nil }
            }
            guard CGImageDestinationFinalize(destination) else { return nil }
            if Double(data.length) <= byteLimit { return data as Data }
        }
        return nil
    }

    private func frame(
        from image: PlatformImage, phase: Double, animation: AnimationType, size: CGSize
    ) -> CGImage? {
        if animation == .faceWiggle { return PlatformGraphics.cgImage(from: image) }
        let rendered = PlatformGraphics.image(size: size, scale: 1) { context in
            let wave = sin(phase * .pi * 2)
            switch animation {
            case .fadeInOut, .heartAnimation:
                context.setAlpha(CGFloat(0.55 + 0.45 * (1 - cos(phase * .pi * 2)) / 2))
            case .slide:
                context.translateBy(x: size.width * CGFloat(wave) * 0.08, y: 0)
            case .zoom:
                let scale = 1 + CGFloat(wave) * 0.04
                context.translateBy(x: size.width / 2, y: size.height / 2)
                context.scaleBy(x: scale, y: scale)
                context.translateBy(x: -size.width / 2, y: -size.height / 2)
            case .textReveal:
                context.clip(to: CGRect(x: 0, y: 0, width: size.width,
                                        height: size.height * CGFloat(min(1, phase * 2 + 0.1))))
            case .faceWiggle:
                break
            }
            PlatformGraphics.draw(image, in: CGRect(origin: .zero, size: size), context: context)
        }
        return rendered.flatMap { PlatformGraphics.cgImage(from: $0) }
    }

    #if os(macOS)
    func saveGIF(_ gifData: Data, suggestedFilename: String = "card.gif") {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.gif]
        panel.nameFieldStringValue = suggestedFilename
        panel.canCreateDirectories = true
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            do {
                try gifData.write(to: url, options: .atomic)
            } catch {
                NSAlert(error: error).runModal()
            }
        }
    }
    #endif
}
