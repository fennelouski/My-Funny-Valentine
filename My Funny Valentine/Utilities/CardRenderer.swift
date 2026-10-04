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
    private var artworkBytes: [String: Data] = [:]

    private init() {}

    func snapshot(of card: Card) -> CardRenderSnapshot {
        let template = TemplateManager.shared.getTemplate(id: card.templateId ?? "")
        let layout = card.getLayoutData()
        let layers = (card.images ?? []).map {
            CardRenderSnapshot.ImageLayer(data: $0.imageData, rect: CGRect(origin: $0.position, size: $0.size), rotation: $0.rotation)
        }
        let faces = (card.faces ?? []).enumerated().map { index, face in
            let slot = template?.facePositions.indices.contains(index) == true ? template?.facePositions[index] : nil
            let rect = face.size.width > 0 && face.size.height > 0
                ? CGRect(origin: face.position, size: face.size)
                : slot.map { CGRect(origin: $0.position, size: $0.size) }
                    ?? CGRect(x: 140, y: 150, width: 120, height: 120)
            return CardRenderSnapshot.ImageLayer(data: face.imageData, rect: rect, rotation: 0)
        }
        let stickers = (card.stickers ?? []).compactMap { layer -> CardRenderSnapshot.ImageLayer? in
            guard let data = layer.stickerData else { return nil }
            return .init(data: data, rect: CGRect(origin: layer.position, size: layer.size), rotation: layer.rotation)
        }
        return CardRenderSnapshot(
            saying: layout?.textPositions.isEmpty == false
                ? (layout?.textPositions.map(\.text).joined(separator: "\n\n") ?? "") : (card.saying ?? ""),
            note: card.customText ?? "", template: template,
            templateArtwork: template.flatMap { artworkData(named: $0.imageName) },
            layout: layout, images: layers, faces: faces, stickers: stickers
        )
    }

    func renderCard(
        _ card: Card,
        size: CGSize = CGSize(width: 800, height: 1200),
        faceAnimationPhase: Double? = nil
    ) -> PlatformImage? {
        render(snapshot(of: card), size: size, phase: faceAnimationPhase)
    }

    func render(
        _ snapshot: CardRenderSnapshot, size: CGSize = CGSize(width: 800, height: 1200),
        phase: Double? = nil, opening: Double = 0, sticker: Bool = false
    ) -> PlatformImage? {
        guard size.width.isFinite, size.height.isFinite, size.width > 0, size.height > 0,
              size.width * size.height <= 16_000_000, opening.isFinite,
              phase == nil || phase?.isFinite == true else { return nil }
        return PlatformGraphics.image(size: size, scale: 1) { context in
            if !sticker {
                let background = opening > 0 ? PlatformColor.fromHex("#FFF7FA")
                    : snapshot.composition.flatMap { PlatformColor.fromHex($0.family.backgroundHex) }
                        ?? snapshot.layout.flatMap { PlatformColor.fromHex($0.backgroundColor) }
                        ?? snapshot.template.map { PlatformColor($0.backgroundColor.color) }
                context.setFillColor((background ?? .white).cgColor)
                context.fill(CGRect(origin: .zero, size: size))
            }
            let scale = min(size.width / Self.canvasSize.width, size.height / Self.canvasSize.height)
            context.translateBy(x: (size.width - Self.canvasSize.width * scale) / 2,
                                y: (size.height - Self.canvasSize.height * scale) / 2)
            context.scaleBy(x: scale, y: scale)
            draw(snapshot, context: context, phase: phase, opening: opening, sticker: sticker)
        }
    }

    /// Top-left-origin drawing also works in a PDF context without flattening text.
    func draw(_ snapshot: CardRenderSnapshot, context: CGContext, phase: Double? = nil,
              opening: Double = 0, sticker: Bool = false) {
        context.saveGState()
        defer { context.restoreGState() }
        context.clip(to: CGRect(origin: .zero, size: Self.canvasSize))
        if sticker {
            drawSticker(snapshot, context: context)
        } else if snapshot.composition != nil {
            drawComposition(snapshot, context: context, phase: phase, opening: min(max(opening, 0), 1))
        } else {
            let amount = min(max(opening, 0), 1)
            if amount > 0 {
                context.setFillColor((PlatformColor.fromHex("#FFF7FA") ?? .white).cgColor)
                context.fill(CGRect(origin: .zero, size: Self.canvasSize))
                drawText(snapshot.note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? snapshot.saying : snapshot.note,
                         in: CGRect(x: 40, y: 70, width: 320, height: 460), fontName: "Georgia", fontSize: 30,
                         color: PlatformColor.fromHex("#4E2036") ?? .black, context: context)
            }
            if amount < 0.995 {
                context.saveGState()
                context.scaleBy(x: max(0.005, 1 - amount), y: 1)
                drawLegacy(snapshot, context: context, phase: phase)
                context.restoreGState()
            }
        }
    }

    private func drawLegacy(_ snapshot: CardRenderSnapshot, context: CGContext, phase: Double?) {
        let template = snapshot.template
        let layout = snapshot.layout
        let background = layout.flatMap { PlatformColor.fromHex($0.backgroundColor) }
            ?? template.map { PlatformColor($0.backgroundColor.color) } ?? .white
        context.setFillColor(background.cgColor)
        context.fill(CGRect(origin: .zero, size: Self.canvasSize))
        if let data = snapshot.templateArtwork, let image = PlatformImageUtils.image(from: data) {
            draw(image, in: CGRect(origin: .zero, size: Self.canvasSize), context: context, fill: true)
        }
        for layer in snapshot.images {
            guard let image = PlatformImageUtils.image(from: layer.data) else { continue }
            draw(image, in: layer.rect, rotation: layer.rotation, context: context)
        }
        for face in snapshot.faces {
            guard let image = PlatformImageUtils.image(from: face.data) else { continue }
            draw(image, in: face.rect, rotation: phase.map { sin($0 * .pi * 2) * 6 } ?? 0, context: context)
        }
        for layer in snapshot.stickers {
            guard let image = PlatformImageUtils.image(from: layer.data) else { continue }
            draw(image, in: layer.rect, rotation: layer.rotation, context: context)
        }
        if let positions = layout?.textPositions, !positions.isEmpty {
            for text in positions {
                drawText(text.text, in: CGRect(origin: text.position, size: text.size), fontName: text.fontName,
                         fontSize: text.fontSize, color: PlatformColor.fromHex(text.color) ?? .black, context: context)
            }
        } else {
            let text = [snapshot.saying, snapshot.note].map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }.joined(separator: "\n\n")
            var rect = template?.textAreas.first.map { CGRect(origin: $0.position, size: $0.size) }
                ?? CGRect(x: 28, y: 150, width: 344, height: 300)
            if let x = layout?.textPositionX, let y = layout?.textPositionY {
                rect.origin = CGPoint(x: x, y: y)
                if template == nil { rect.size = CGSize(width: 400 - x - 24, height: 600 - y - 24) }
            }
            let c = background.rgbaComponents
            let linear = [c.red, c.green, c.blue].map { $0 <= 0.04045 ? $0 / 12.92 : pow(($0 + 0.055) / 1.055, 2.4) }
            let luminance = linear[0] * 0.2126 + linear[1] * 0.7152 + linear[2] * 0.0722
            drawText(text, in: rect, fontSize: 32, color: luminance > 0.179 ? .black : .white,
                     rotation: layout?.textRotation ?? 0, context: context)
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

    private func artworkData(named name: String) -> Data? {
        if let cached = artworkBytes[name] { return cached }
        guard let image = artwork(named: name), let data = PlatformImageUtils.pngData(from: image) else { return nil }
        artworkBytes[name] = data
        return data
    }

    func draw(
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

    func drawText(
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
