//
//  OnDeviceImageGenerator.swift
//  My Funny Valentine
//
//  Generates card artwork with Image Playground, on device. No network, no
//  per-image cost, and the prompt never leaves the device.
//

import Foundation
import CoreGraphics

#if canImport(ImagePlayground)
import ImagePlayground
#endif

nonisolated struct OnDeviceImageGenerator {
    static let shared = OnDeviceImageGenerator()

    private init() {}

    /// Whether the OS is new enough to attempt on-device image generation.
    /// Actual readiness is only known when `ImageCreator()` is constructed.
    static var isSupported: Bool {
        #if canImport(ImagePlayground)
        if #available(iOS 18.4, macOS 15.4, visionOS 2.4, *) {
            return true
        }
        #endif
        return false
    }

    /// Generates one image for `description`. Throws when Image Playground is
    /// unavailable so callers can fall back to the hosted backend.
    func image(for description: String, style: ImageStyle) async throws -> PlatformImage {
        #if canImport(ImagePlayground)
        if #available(iOS 18.4, macOS 15.4, visionOS 2.4, *) {
            // Throws .notSupported / .unavailable when Apple Intelligence is
            // off or the device isn't eligible.
            let creator = try await ImageCreator()

            let requested = Self.playgroundStyle(for: style)
            let resolvedStyle = creator.availableStyles.contains(requested)
                ? requested
                : (creator.availableStyles.first ?? requested)

            let stream = creator.images(
                for: [.text(Self.prompt(for: description, style: style))],
                style: resolvedStyle,
                limit: 1
            )

            for try await created in stream {
                let cgImage = created.cgImage
                return PlatformGraphics.makeImage(
                    from: cgImage,
                    size: CGSize(width: cgImage.width, height: cgImage.height)
                )
            }

            throw OnDeviceGenerationError.emptyResult
        }
        #endif
        throw OnDeviceGenerationError.unavailable
    }

    /// Nudges the generation toward the card style the user picked.
    private static func prompt(for description: String, style: ImageStyle) -> String {
        switch style {
        case .valentine:
            return "\(description), Valentine's Day theme, hearts, romantic, festive"
        case .romantic:
            return "\(description), romantic and dreamy, soft warm light"
        case .funny:
            return "\(description), playful and humorous, lighthearted"
        }
    }

    #if canImport(ImagePlayground)
    @available(iOS 18.4, macOS 15.4, visionOS 2.4, *)
    private static func playgroundStyle(for style: ImageStyle) -> ImagePlaygroundStyle {
        switch style {
        case .valentine: return .illustration
        case .romantic: return .illustration
        case .funny: return .animation
        }
    }
    #endif
}
