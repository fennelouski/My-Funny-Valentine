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
    case cardOpening
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

    /// The complete layered scene moves, even when no personal photo was added.
    func createCardAnimation(from snapshot: CardRenderSnapshot, duration: Double = 3) -> Data? {
        let options = GIFExportOptions(frameRate: 10, duration: duration, animationType: .cardOpening)
        return encodeGIF(size: CardRenderer.canvasSize, options: options) { phase, size in
            CardRenderer.shared.render(snapshot, size: size, phase: phase,
                                       opening: CardMotion.opening(phase: phase))
                .flatMap { PlatformGraphics.cgImage(from: $0) }
        }
    }

    /// UI export yields between native frames, preserving actor-safe font/image
    /// access and allowing share-sheet dismissal to cancel unfinished work.
    func createCardAnimationCancellable(from snapshot: CardRenderSnapshot, duration: Double = 3) async throws -> Data? {
        let options = GIFExportOptions(frameRate: 10, duration: duration, animationType: .cardOpening)
        return try await encodeGIFCancellable(size: CardRenderer.canvasSize, options: options) { phase, size in
            CardRenderer.shared.render(snapshot, size: size, phase: phase,
                                       opening: CardMotion.opening(phase: phase))
                .flatMap { PlatformGraphics.cgImage(from: $0) }
        }
    }

    /// Each frame comes from the same renderer as the editor. Only faces move.
    func createAnimatedGIF(
        from card: Card,
        options: GIFExportOptions = GIFExportOptions(animationType: .faceWiggle)
    ) -> Data? {
        if options.animationType == .cardOpening {
            let snapshot = CardRenderer.shared.snapshot(of: card)
            return encodeGIF(size: CardRenderer.canvasSize, options: options) { phase, size in
                CardRenderer.shared.render(snapshot, size: size, phase: phase, opening: CardMotion.opening(phase: phase))
                    .flatMap { PlatformGraphics.cgImage(from: $0) }
            }
        }
        guard options.animationType != .faceWiggle || !(card.faces ?? []).isEmpty else { return nil }
        let snapshot = CardRenderer.shared.snapshot(of: card)
        return encodeGIF(size: CardRenderer.canvasSize, options: options) { phase, size in
            let image = CardRenderer.shared.render(
                snapshot, size: size,
                phase: options.animationType == .faceWiggle ? phase : nil
            )
            guard let image else { return nil }
            return self.frame(from: image, phase: phase, animation: options.animationType, size: size)
        }
    }

    /// Compatibility path for an already flattened card image.
    func createAnimatedGIF(from image: PlatformImage, options: GIFExportOptions = GIFExportOptions()) -> Data? {
        guard options.animationType != .faceWiggle, options.animationType != .cardOpening else { return nil }
        return encodeGIF(size: image.size, options: options) { phase, size in
            self.frame(from: image, phase: phase, animation: options.animationType, size: size)
        }
    }

    private struct EncodingPlan {
        let frameCount: Int
        let delay: Double
        let byteLimit: Double
    }

    private func encodingPlan(size: CGSize, options: GIFExportOptions) -> EncodingPlan? {
        guard size.width.isFinite, size.height.isFinite, size.width > 0, size.height > 0,
              options.frameRate.isFinite, options.frameRate > 0,
              options.duration.isFinite, options.duration > 0,
              options.maxSizeMB.isFinite, options.maxSizeMB > 0 else { return nil }
        let duration = min(options.duration, 8)
        // ponytail: 32 streamed frames cap export work; increase after profiling long animations.
        let frameCount = max(2, min(32, Int(min(options.frameRate, 24) * duration)))
        return EncodingPlan(frameCount: frameCount, delay: duration / Double(frameCount),
                            byteLimit: min(options.maxSizeMB, 50) * 1024 * 1024)
    }

    private func gifAttempt(size: CGSize, longestEdge: CGFloat, plan: EncodingPlan)
        -> (data: NSMutableData, destination: CGImageDestination, output: CGSize)? {
        let scale = min(1, longestEdge / max(size.width, size.height))
        let output = CGSize(width: max(1, floor(size.width * scale)),
                            height: max(1, floor(size.height * scale)))
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            data, UTType.gif.identifier as CFString, plan.frameCount, nil
        ) else { return nil }
        CGImageDestinationSetProperties(destination, [
            kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFLoopCount: 0]
        ] as CFDictionary)
        return (data, destination, output)
    }

    private func appendFrame(at index: Int, plan: EncodingPlan, output: CGSize,
                             destination: CGImageDestination, makeFrame: (Double, CGSize) -> CGImage?) -> Bool {
        autoreleasepool {
            guard let frame = makeFrame(Double(index) / Double(plan.frameCount), output) else { return false }
            CGImageDestinationAddImage(destination, frame, [
                kCGImagePropertyGIFDictionary: [
                    kCGImagePropertyGIFDelayTime: plan.delay,
                    kCGImagePropertyGIFUnclampedDelayTime: plan.delay
                ]
            ] as CFDictionary)
            return true
        }
    }

    private func encodeGIF(
        size: CGSize, options: GIFExportOptions,
        makeFrame: (Double, CGSize) -> CGImage?
    ) -> Data? {
        guard let plan = encodingPlan(size: size, options: options) else { return nil }
        // Finite retries fix the old recursive optimizer's minimum-size loop.
        for longestEdge in [CGFloat(640), 480, 320, 240] {
            guard let attempt = gifAttempt(size: size, longestEdge: longestEdge, plan: plan) else { return nil }
            for index in 0..<plan.frameCount {
                guard !Task.isCancelled,
                      appendFrame(at: index, plan: plan, output: attempt.output,
                                  destination: attempt.destination, makeFrame: makeFrame) else { return nil }
            }
            guard CGImageDestinationFinalize(attempt.destination) else { return nil }
            if Double(attempt.data.length) <= plan.byteLimit { return attempt.data as Data }
        }
        return nil
    }

    private func encodeGIFCancellable(
        size: CGSize, options: GIFExportOptions,
        makeFrame: (Double, CGSize) -> CGImage?
    ) async throws -> Data? {
        try Task.checkCancellation()
        guard let plan = encodingPlan(size: size, options: options) else { return nil }
        for longestEdge in [CGFloat(640), 480, 320, 240] {
            try Task.checkCancellation()
            guard let attempt = gifAttempt(size: size, longestEdge: longestEdge, plan: plan) else { return nil }
            for index in 0..<plan.frameCount {
                await Task.yield()
                try Task.checkCancellation()
                guard appendFrame(at: index, plan: plan, output: attempt.output,
                                  destination: attempt.destination, makeFrame: makeFrame) else { return nil }
            }
            await Task.yield()
            try Task.checkCancellation()
            guard CGImageDestinationFinalize(attempt.destination) else { return nil }
            try Task.checkCancellation()
            if Double(attempt.data.length) <= plan.byteLimit { return attempt.data as Data }
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
            case .faceWiggle, .cardOpening:
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
