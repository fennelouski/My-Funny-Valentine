import Foundation
import CoreGraphics
import ImageIO
import Testing
#if canImport(UIKit)
import UIKit
#endif
@testable import My_Funny_Valentine

@MainActor
struct FaceDetectionGeometryTests {
    @Test("A fictional portrait produces bounded PNG face crops with honest matte status")
    func portraitFaceCutout() async throws {
        let bundle = Bundle(for: FaceDetectionFixtureBundle.self)
        let url = try #require(bundle.url(forResource: "qa-face-source", withExtension: "png"))
        let image = try #require(PlatformImageUtils.image(from: Data(contentsOf: url)))
        let source = try #require(FaceDetectionService.normalizedCGImage(from: image))
        let imageBounds = CGRect(x: 0, y: 0, width: source.width, height: source.height)
        let faces = try await FaceDetectionService.shared.detectFaces(in: image)
        try #require(!faces.isEmpty)
        #if targetEnvironment(simulator)
        let inference = "iOS Simulator: supported Vision CPU"
        #elseif os(macOS)
        let inference = "macOS: default Vision compute devices"
        #else
        let inference = "native device: default Vision compute devices"
        #endif
        print("Face fixture — \(inference); faces=\(faces.count); foregroundMattes=\(faces.filter(\.hasForegroundMask).count)")

        for face in faces {
            #expect(!face.boundingBox.isEmpty)
            #expect(face.boundingBox.intersection(imageBounds) == face.boundingBox)
            #expect(face.imageData.starts(with: [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]))
            let encoded = try #require(CGImageSourceCreateWithData(face.imageData as CFData, nil))
            let crop = try #require(CGImageSourceCreateImageAtIndex(encoded, 0, nil))
            #expect(CGFloat(crop.width) == face.boundingBox.width)
            #expect(CGFloat(crop.height) == face.boundingBox.height)

            // Segmentation can be unavailable; a claimed matte must contain actual transparency.
            if face.hasForegroundMask {
                let alpha = try alphaExtremes(crop)
                #expect(alpha.minimum < 250)
                #expect(alpha.maximum > 10)
            }
        }
    }

    @Test("Padded face boxes stay inside the oriented photo at both corners")
    func cropBounds() {
        let size = CGSize(width: 100, height: 200)
        #expect(FaceDetectionService.paddedFaceBounds(CGRect(x: 0.02, y: 0.8, width: 0.2, height: 0.2), imageSize: size)
                == CGRect(x: 0, y: 0, width: 28, height: 52))
        #expect(FaceDetectionService.paddedFaceBounds(CGRect(x: 0.8, y: 0.02, width: 0.2, height: 0.2), imageSize: size)
                == CGRect(x: 74, y: 144, width: 26, height: 56))
        #expect(FaceDetectionService.paddedFaceBounds(CGRect(x: 2, y: 2, width: 0.1, height: 0.1), imageSize: size) == nil)
        #expect(FaceDetectionService.paddedFaceBounds(CGRect(x: 0, y: 0, width: 0, height: 1), imageSize: size) == nil)
    }

    private func alphaExtremes(_ image: CGImage) throws -> (minimum: UInt8, maximum: UInt8) {
        var pixels = [UInt8](repeating: 0, count: 64 * 64 * 4)
        return try pixels.withUnsafeMutableBytes { buffer in
            let context = try #require(CGContext(data: buffer.baseAddress, width: 64, height: 64,
                                                bitsPerComponent: 8, bytesPerRow: 64 * 4,
                                                space: CGColorSpaceCreateDeviceRGB(),
                                                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
            context.draw(image, in: CGRect(x: 0, y: 0, width: 64, height: 64))
            let alpha = stride(from: 3, to: buffer.count, by: 4).map { buffer[$0] }
            return (alpha.min() ?? 255, alpha.max() ?? 0)
        }
    }

    #if canImport(UIKit)
    @Test("Native normalization applies rotation and mirroring before Vision sees pixels")
    func photoOrientation() throws {
        let image = try #require(PlatformGraphics.image(size: CGSize(width: 4, height: 2), scale: 1) { context in
            context.setFillColor(UIColor.red.cgColor)
            context.fill(CGRect(x: 0, y: 0, width: 2, height: 2))
            context.setFillColor(UIColor.blue.cgColor)
            context.fill(CGRect(x: 2, y: 0, width: 2, height: 2))
        })
        let original = try #require(image.cgImage)
        let rotated = UIImage(cgImage: original, scale: 1, orientation: .right)
        let sharedImage = try #require(PlatformGraphics.cgImage(from: rotated))
        #expect(sharedImage.width == 2 && sharedImage.height == 4)
        let png = try #require(PlatformImageUtils.pngData(from: rotated))
        let encodedSource = try #require(CGImageSourceCreateWithData(png as CFData, nil))
        let encoded = try #require(CGImageSourceCreateImageAtIndex(encodedSource, 0, nil))
        #expect(encoded.width == 2 && encoded.height == 4)
        let normalized = try #require(FaceDetectionService.normalizedCGImage(from: rotated))
        #expect(normalized.width == 2 && normalized.height == 4)
        let top = try pixel(normalized, x: 0, y: 0)
        let bottom = try pixel(normalized, x: 0, y: 3)
        #expect(top[0] > 220 && top[2] < 30)
        #expect(bottom[2] > 220 && bottom[0] < 30)
        let mirrored = UIImage(cgImage: original, scale: 1, orientation: .upMirrored)
        let normalizedMirror = try #require(FaceDetectionService.normalizedCGImage(from: mirrored))
        let left = try pixel(normalizedMirror, x: 0, y: 0)
        #expect(left[2] > 220 && left[0] < 30)
    }

    private func pixel(_ image: CGImage, x: Int, y: Int) throws -> [UInt8] {
        let crop = try #require(image.cropping(to: CGRect(x: x, y: y, width: 1, height: 1)))
        var bytes = [UInt8](repeating: 0, count: 4)
        try bytes.withUnsafeMutableBytes { buffer in
            let context = try #require(CGContext(data: buffer.baseAddress, width: 1, height: 1,
                                                 bitsPerComponent: 8, bytesPerRow: 4,
                                                 space: CGColorSpaceCreateDeviceRGB(),
                                                 bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
            context.draw(crop, in: CGRect(x: 0, y: 0, width: 1, height: 1))
        }
        return bytes
    }
    #endif
}

private final class FaceDetectionFixtureBundle: NSObject {}
