import Foundation
import CoreGraphics
import ImageIO
import SwiftData
import Testing
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif
@testable import My_Funny_Valentine

@MainActor
struct CardRendererTests {
    @Test("Thumbnails and exports share the complete portrait canvas and degree rotations")
    func consistentRendering() throws {
        let red = try solid(.red)
        let blue = try solid(.blue, size: CGSize(width: 20, height: 80))
        let green = try solid(.green)
        let yellow = try solid(.yellow)
        let card = Card(saying: "Be mine", faces: [
            FaceImage(cardId: UUID(), imageData: red, thumbnailData: red,
                      position: CGPoint(x: 100, y: 200), size: CGSize(width: 80, height: 80))
        ], images: [
            CardImage(cardId: UUID(), source: .photoImport, imageData: yellow,
                      position: CGPoint(x: 80, y: 180), size: CGSize(width: 200, height: 200)),
            CardImage(cardId: UUID(), source: .photoImport, imageData: blue,
                      position: CGPoint(x: 220, y: 90), size: CGSize(width: 20, height: 80), rotation: 90)
        ], stickers: [
            StickerReference(cardId: UUID(), stickerId: "test", stickerData: green,
                             position: CGPoint(x: 300, y: 400), size: CGSize(width: 60, height: 60))
        ])
        let thumb = try #require(CardGenerationService.shared.renderCard(card, size: CGSize(width: 200, height: 300)))
        let full = try #require(CardRenderer.shared.renderCard(card, size: CGSize(width: 800, height: 1200)))
        let same = try #require(CardGenerationService.shared.renderCard(card, size: CGSize(width: 800, height: 1200)))
        let fullCG = try #require(PlatformGraphics.cgImage(from: full))
        #expect(fullCG.width == 800 && fullCG.height == 1200)
        #expect(PlatformImageUtils.pngData(from: full) == PlatformImageUtils.pngData(from: same))
        for image in [thumb, full] {
            let face = try pixel(image, at: CGPoint(x: 140, y: 240))
            #expect(face[0] > 220 && face[1] < 30 && face[2] < 30)
            let rotated = try pixel(image, at: CGPoint(x: 200, y: 130))
            #expect(rotated[2] > 220 && rotated[0] < 30)
            let sticker = try pixel(image, at: CGPoint(x: 330, y: 430))
            #expect(sticker[1] > 100 && sticker[0] < 30 && sticker[2] < 30)
        }
        #expect(CardRenderer.shared.renderCard(card, size: CGSize(width: CGFloat.infinity, height: 600)) == nil)
    }

    @Test("No-photo starters render and personalized GIFs move only the face")
    func starterAndGIF() throws {
        let schema = Schema([Card.self, FaceImage.self, CardImage.self, StickerReference.self, UserPreferences.self])
        let container = try ModelContainer(for: schema, configurations: [
            ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        ])
        let starters = CardGenerationService.shared.generateTemplateCards(faces: [], modelContext: container.mainContext)
        #expect(!starters.isEmpty)
        #expect(starters.allSatisfy { ($0.faces ?? []).isEmpty })
        for card in starters {
            #expect(CardRenderer.shared.renderCard(card, size: CGSize(width: 200, height: 300)) != nil)
        }
        let red = try solid(.red)
        let card = Card(saying: "Stay wonderful", faces: [
            FaceImage(cardId: UUID(), imageData: red, thumbnailData: red,
                      position: CGPoint(x: 100, y: 150), size: CGSize(width: 140, height: 100))
        ])
        let data = try #require(GIFExporter.shared.createAnimatedGIF(
            from: card, options: GIFExportOptions(frameRate: 12, duration: 2, animationType: .faceWiggle)
        ))
        let source = try #require(CGImageSourceCreateWithData(data as CFData, nil))
        #expect(CGImageSourceGetCount(source) == 24)
        let first = try #require(CGImageSourceCreateImageAtIndex(source, 0, nil))
        let quarter = try #require(CGImageSourceCreateImageAtIndex(source, 6, nil))
        #expect(first.width == 400 && first.height == 600)
        let firstBytes = try #require(first.dataProvider?.data) as Data
        let quarterBytes = try #require(quarter.dataProvider?.data) as Data
        #expect(firstBytes != quarterBytes)
        #expect(GIFExporter.shared.createAnimatedGIF(from: Card(), options: GIFExportOptions(animationType: .faceWiggle)) == nil)
        #expect(GIFExporter.shared.createAnimatedGIF(from: card, options: GIFExportOptions(frameRate: 0)) == nil)
        #expect(GIFExporter.shared.createAnimatedGIF(from: card, options: GIFExportOptions(maxSizeMB: 0.000001)) == nil)
    }

    private func solid(_ color: PlatformColor, size: CGSize = CGSize(width: 20, height: 20)) throws -> Data {
        let image = try #require(PlatformGraphics.image(size: size, scale: 1) { context in
            context.setFillColor(color.cgColor)
            context.fill(CGRect(origin: .zero, size: size))
        })
        return try #require(PlatformImageUtils.pngData(from: image))
    }

    private func pixel(_ image: PlatformImage, at logicalPoint: CGPoint) throws -> [UInt8] {
        let cgImage = try #require(PlatformGraphics.cgImage(from: image))
        let scale = CGFloat(cgImage.height) / CardRenderer.canvasSize.height
        let crop = try #require(cgImage.cropping(to: CGRect(
            x: logicalPoint.x * scale, y: logicalPoint.y * scale, width: 1, height: 1
        )))
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
}
