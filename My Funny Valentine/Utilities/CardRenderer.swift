import Foundation
import CoreGraphics
import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// The editor, thumbnails and exports all use this 400 × 600 coordinate space.
class CardRenderer {
    static let shared = CardRenderer()
    static let canvasSize = CGSize(width: 400, height: 600)

    private init() {}

    func renderCard(
        _ card: Card,
        size: CGSize = CGSize(width: 800, height: 1200),
        faceAnimationPhase: Double? = nil
    ) -> PlatformImage? {
        guard size.width.isFinite, size.height.isFinite,
              size.width > 0, size.height > 0,
              size.width * size.height <= 16_000_000 else { return nil }

        let template = TemplateManager.shared.getTemplate(id: card.templateId ?? "")
        let layout = card.getLayoutData()
        let background = layout.flatMap { PlatformColor.fromHex($0.backgroundColor) }
            ?? template.map { PlatformColor($0.backgroundColor.color) } ?? .white
        let canvas = Self.canvasSize

        return PlatformGraphics.image(size: size, scale: 1) { context in
            context.setFillColor(background.cgColor)
            context.fill(CGRect(origin: .zero, size: size))

            let scale = min(size.width / canvas.width, size.height / canvas.height)
            context.translateBy(
                x: (size.width - canvas.width * scale) / 2,
                y: (size.height - canvas.height * scale) / 2
            )
            context.scaleBy(x: scale, y: scale)
            context.clip(to: CGRect(origin: .zero, size: canvas))

            if let template, let image = artwork(named: template.imageName) {
                draw(image, in: CGRect(origin: .zero, size: canvas), context: context, fill: true)
            }

            for layer in card.images ?? [] {
                guard let image = PlatformImageUtils.image(from: layer.imageData) else { continue }
                draw(image, in: CGRect(origin: layer.position, size: layer.size),
                     rotation: layer.rotation, context: context)
            }
            for (index, face) in (card.faces ?? []).enumerated() {
                guard let image = PlatformImageUtils.image(from: face.imageData) else { continue }
                let slot = template?.facePositions.indices.contains(index) == true
                    ? template?.facePositions[index] : nil
                let rect = face.size.width > 0 && face.size.height > 0
                    ? CGRect(origin: face.position, size: face.size)
                    : slot.map { CGRect(origin: $0.position, size: $0.size) }
                        ?? CGRect(x: 140, y: 150, width: 120, height: 120)
                let rotation = faceAnimationPhase.map { sin($0 * .pi * 2) * 6 } ?? 0
                draw(image, in: rect, rotation: rotation, context: context)
            }

            for layer in card.stickers ?? [] {
                guard let data = layer.stickerData,
                      let image = PlatformImageUtils.image(from: data) else { continue }
                draw(image, in: CGRect(origin: layer.position, size: layer.size),
                     rotation: layer.rotation, context: context)
            }

            if let positions = layout?.textPositions, !positions.isEmpty {
                for text in positions {
                    drawText(text.text, in: CGRect(origin: text.position, size: text.size),
                             fontName: text.fontName, fontSize: text.fontSize,
                             color: PlatformColor.fromHex(text.color) ?? .black,
                             context: context)
                }
            } else {
                let text = [card.saying, card.customText]
                    .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }.joined(separator: "\n\n")
                var rect = template?.textAreas.first.map {
                    CGRect(origin: $0.position, size: $0.size)
                } ?? CGRect(x: 28, y: 150, width: 344, height: 300)
                if let x = layout?.textPositionX, let y = layout?.textPositionY {
                    rect.origin = CGPoint(x: x, y: y)
                    if template == nil { rect.size = CGSize(width: 400 - x - 24, height: 600 - y - 24) }
                }
                let components = background.cgColor.converted(
                    to: CGColorSpaceCreateDeviceRGB(), intent: .defaultIntent, options: nil
                )?.components ?? [1, 1, 1, 1]
                let linear = components.prefix(3).map { $0 <= 0.04045 ? $0 / 12.92 : pow(($0 + 0.055) / 1.055, 2.4) }
                let luminance = linear[0] * 0.2126 + linear[1] * 0.7152 + linear[2] * 0.0722
                drawText(text, in: rect, fontSize: 32, color: luminance > 0.179 ? .black : .white,
                         rotation: layout?.textRotation ?? 0, context: context)
            }
        }
    }

    private func artwork(named name: String) -> PlatformImage? {
        #if canImport(UIKit)
        if let image = UIImage(named: name) { return image }
        #elseif canImport(AppKit)
        if let image = NSImage(named: NSImage.Name(name)) { return image }
        #endif
        for ext in ["png", "jpg", "jpeg"] {
            if let url = Bundle.main.url(forResource: name, withExtension: ext),
               let data = try? Data(contentsOf: url),
               let image = PlatformImageUtils.image(from: data) { return image }
        }
        return nil
    }

    private func draw(
        _ image: PlatformImage, in rect: CGRect, rotation: Double = 0,
        context: CGContext, fill: Bool = false
    ) {
        let size = image.size
        guard rect.width.isFinite, rect.height.isFinite,
              rect.origin.x.isFinite, rect.origin.y.isFinite, rotation.isFinite,
              rect.width > 0, rect.height > 0, size.width > 0, size.height > 0 else { return }
        let scale = fill ? max(rect.width / size.width, rect.height / size.height)
            : min(rect.width / size.width, rect.height / size.height)
        let fitted = CGRect(x: rect.midX - size.width * scale / 2,
                            y: rect.midY - size.height * scale / 2,
                            width: size.width * scale, height: size.height * scale)
        context.saveGState()
        context.translateBy(x: rect.midX, y: rect.midY)
        context.rotate(by: CGFloat(rotation * .pi / 180))
        context.translateBy(x: -rect.midX, y: -rect.midY)
        PlatformGraphics.draw(image, in: fitted, context: context)
        context.restoreGState()
    }

    private func drawText(
        _ text: String, in bounds: CGRect, fontName: String? = nil,
        fontSize: CGFloat, color: PlatformColor, rotation: Double = 0, context: CGContext
    ) {
        guard !text.isEmpty, bounds.origin.x.isFinite, bounds.origin.y.isFinite,
              bounds.width.isFinite, bounds.height.isFinite, fontSize.isFinite, rotation.isFinite else { return }
        let rect = bounds.intersection(CGRect(origin: .zero, size: Self.canvasSize))
        guard !rect.isNull, rect.width > 0, rect.height > 0 else { return }
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        paragraph.lineBreakMode = .byWordWrapping
        var pointSize = min(max(fontSize, 8), 96)
        var attributed: NSAttributedString
        var measured: CGSize
        repeat {
            let font = fontName.flatMap { PlatformFont(name: $0, size: pointSize) }
                ?? PlatformFont.systemFont(ofSize: pointSize)
            attributed = NSAttributedString(string: text, attributes: [
                .font: font, .foregroundColor: color, .paragraphStyle: paragraph
            ])
            measured = PlatformGraphics.size(of: attributed, maxWidth: rect.width)
            if measured.height <= rect.height || pointSize <= 8 { break }
            pointSize -= 1
        } while true
        let textRect = CGRect(x: rect.minX, y: rect.minY + max(0, (rect.height - measured.height) / 2),
                              width: rect.width, height: min(rect.height, ceil(measured.height)))
        context.saveGState()
        context.translateBy(x: rect.midX, y: rect.midY)
        context.rotate(by: CGFloat(rotation * .pi / 180))
        context.translateBy(x: -rect.midX, y: -rect.midY)
        PlatformGraphics.draw(attributed, in: textRect, context: context)
        context.restoreGState()
    }
}
