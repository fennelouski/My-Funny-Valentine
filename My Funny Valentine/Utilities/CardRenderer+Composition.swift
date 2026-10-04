import Foundation
import CoreGraphics
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

extension CardRenderer {
    func drawComposition(_ card: CardRenderSnapshot, context: CGContext, phase: Double?, opening: Double) {
        guard let design = card.composition else { return }
        let family = design.family
        let background = color(family.backgroundHex)
        let ink = color(family.inkHex)
        let accent = color(family.accentHex)
        let motion = design.motionEnabled ? (phase ?? 0) : 0
        let wave = CGFloat(sin(motion * .pi * 2))
        let variant = CGFloat(design.variant)

        // The inside is real card content, revealed by the same affine fold in
        // native previews, GIF frames and the standalone browser's baked frames.
        if opening > 0 {
            context.setFillColor(color("#FFF7FA").cgColor)
            context.fill(CGRect(x: 0, y: 0, width: 400, height: 600))
            heart(in: CGRect(x: 174, y: 34, width: 52, height: 48), color: accent, context: context)
            let insideText = card.note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? card.saying : card.note
            drawText(insideText, in: CGRect(x: 40, y: 104, width: 320, height: 390),
                     fontName: "Georgia", fontSize: 30, color: color("#4E2036"), context: context)
            context.setStrokeColor(accent.withAlphaComponent(0.25).cgColor)
            context.setLineWidth(1)
            context.stroke(CGRect(x: 20, y: 20, width: 360, height: 560))
        }
        guard opening < 0.995 else { return }
        context.saveGState()
        defer { context.restoreGState() }
        context.scaleBy(x: max(0.005, 1 - opening), y: 1)
        context.setFillColor(background.cgColor)
        context.fill(CGRect(x: 0, y: 0, width: 400, height: 600))

        var artRect = CGRect(x: 42, y: 42, width: 316, height: 310)
        var wordsRect = CGRect(x: 32, y: 398, width: 336, height: 155)
        var fontSize: CGFloat = 38
        var textColor = ink
        switch family {
        case .comic:
            let center = CGPoint(x: 200 + (variant - 2) * 12, y: 200)
            context.setFillColor(accent.cgColor)
            for index in 0..<18 {
                let angle = CGFloat(index) * .pi / 9 + wave * 0.025
                context.beginPath()
                context.move(to: center)
                context.addLine(to: CGPoint(x: center.x + cos(angle) * 430, y: center.y + sin(angle) * 430))
                context.addLine(to: CGPoint(x: center.x + cos(angle + 0.065) * 430, y: center.y + sin(angle + 0.065) * 430))
                context.closePath()
                context.fillPath()
            }
            artRect = CGRect(x: 34 + variant * 3, y: 46, width: 324 - variant * 6, height: 300)
            panel(artRect.insetBy(dx: -7, dy: -7), fill: .white, stroke: ink, width: 5, radius: 4, context: context)
            panel(CGRect(x: 20, y: 380, width: 360, height: 190), fill: .white, stroke: ink, width: 5, radius: 22, context: context)
            wordsRect = CGRect(x: 36, y: 398, width: 328, height: 150)
            fontSize = 42 + variant * 2
        case .cosmic:
            for index in 0..<58 {
                let x = CGFloat((index * 97 + design.variant * 31) % 380 + 10)
                let y = CGFloat((index * 71) % 570 + 15)
                let radius: CGFloat = index % 7 == 0 ? 2.8 : 1
                context.setFillColor(ink.withAlphaComponent(index % 3 == 0 ? 0.5 : 0.85).cgColor)
                context.fillEllipse(in: CGRect(x: x, y: y, width: radius * 2, height: radius * 2))
            }
            artRect = CGRect(x: 58 - variant * 4, y: 66, width: 284 + variant * 8, height: 284 + variant * 8)
            context.setStrokeColor(accent.cgColor)
            context.setLineWidth(3)
            context.strokeEllipse(in: artRect.insetBy(dx: -18, dy: 20))
            let angle = motion * .pi * 2 + Double(design.variant)
            heart(in: CGRect(x: 190 + CGFloat(cos(angle)) * 167, y: 190 + CGFloat(sin(angle)) * 100,
                             width: 24, height: 22), color: accent, context: context)
        case .loveLetter:
            artRect = CGRect(x: 54, y: 55 + variant * 5, width: 292, height: 250)
            panel(CGRect(x: 30, y: 30, width: 340, height: 536), fill: color("#FFEDF2"), stroke: nil,
                  radius: 6, context: context)
            context.setFillColor(accent.withAlphaComponent(0.14).cgColor)
            context.beginPath()
            context.move(to: CGPoint(x: 30, y: 566)); context.addLine(to: CGPoint(x: 200, y: 420))
            context.addLine(to: CGPoint(x: 370, y: 566)); context.closePath(); context.fillPath()
            heart(in: CGRect(x: 177, y: 320, width: 46, height: 42), color: accent, context: context)
            wordsRect = CGRect(x: 48, y: 376, width: 304, height: 140)
            fontSize = 32 + variant * 2
        case .photoBooth:
            artRect = CGRect(x: 52, y: 38, width: 296, height: 345)
            for side in [CGFloat(54), 334] {
                for row in 0..<10 {
                    panel(CGRect(x: side, y: CGFloat(row) * 37 + 32, width: 12, height: 19),
                          fill: accent, stroke: nil, radius: 2, context: context)
                }
            }
            wordsRect = CGRect(x: 34, y: 424, width: 332, height: 128)
            fontSize = 42 + variant * 2
        case .confetti:
            for index in 0..<42 {
                let x = CGFloat((index * 53 + design.variant * 29) % 370 + 8)
                let y = CGFloat((index * 113) % 570 + 8) + wave * CGFloat(index % 3 + 1) * 3
                context.saveGState()
                context.translateBy(x: x, y: y)
                context.rotate(by: CGFloat(index) * 0.43 + wave * 0.08)
                context.setFillColor(color(["#D33364", "#274ECB", "#F6AE33"][index % 3]).cgColor)
                if index % 2 == 0 { context.fill(CGRect(x: 0, y: 0, width: 9, height: 19)) }
                else { context.fillEllipse(in: CGRect(x: 0, y: 0, width: 9, height: 9)) }
                context.restoreGState()
            }
            artRect = CGRect(x: 70, y: 56 + variant * 6, width: 260, height: 260)
            wordsRect = CGRect(x: 30, y: 360, width: 340, height: 170)
            fontSize = 46 + variant * 2
        case .popUp:
            for index in (0..<4).reversed() {
                let inset = CGFloat(index) * (16 + variant * 2)
                heart(in: CGRect(x: 45 + inset, y: 36 + inset + variant * 4, width: 310 - inset * 2, height: 290 - inset),
                      color: accent.withAlphaComponent(0.2 + CGFloat(4 - index) * 0.18), context: context)
            }
            artRect = CGRect(x: 100 - variant * 6, y: 110 + wave * 5 + variant * 4, width: 200 + variant * 12, height: 190)
            wordsRect = CGRect(x: 30, y: 380, width: 340, height: 170)
            fontSize = 36 + variant * 2
        }

        // Artwork is clipped as a deliberate print/photo window, never used as
        // an invented foreground matte for the person.
        let data = card.images.first?.data ?? card.templateArtwork
        if let data, let image = PlatformImageUtils.image(from: data) {
            // These six checked-in originals have their complete illustrated
            // subject above a blank note area. Fit that subject inside the
            // print window; imported photos retain centered aspect-fill.
            let bundledOriginals = ["starter_pizza", "starter_space", "starter_birds",
                                    "starter_dino", "starter_disco", "starter_sweets"]
            let fitBundledSubject = card.images.isEmpty &&
                bundledOriginals.contains(card.template?.imageName ?? "")
            if family == .photoBooth {
                let frames: [(CGRect, Double)]
                switch design.variant {
                case 0:
                    frames = (0..<3).map { (CGRect(x: 90, y: 32 + CGFloat($0) * 117, width: 220, height: 106), 0) }
                case 1:
                    frames = [(CGRect(x: 48, y: 38, width: 230, height: 180), -8),
                              (CGRect(x: 125, y: 214, width: 230, height: 170), 7)]
                case 2:
                    frames = (0..<4).map { (CGRect(x: 48 + CGFloat($0 % 2) * 157, y: 40 + CGFloat($0 / 2) * 175,
                                                  width: 147, height: 155), 0) }
                case 3:
                    frames = [(CGRect(x: 45, y: 44, width: 310, height: 310), 0)]
                default:
                    frames = [(CGRect(x: 58, y: 42, width: 240, height: 165), 5),
                              (CGRect(x: 90, y: 218, width: 240, height: 165), -5)]
                }
                for (rect, rotation) in frames {
                    context.saveGState()
                    context.translateBy(x: rect.midX, y: rect.midY)
                    context.rotate(by: CGFloat(rotation * .pi / 180))
                    context.translateBy(x: -rect.midX, y: -rect.midY)
                    panel(rect.insetBy(dx: -7, dy: -7), fill: .white, stroke: nil, radius: 2, context: context)
                    clippedImage(image, rect: rect, ellipse: false,
                                 fitBundledSubject: fitBundledSubject, context: context)
                    context.restoreGState()
                }
            } else {
                clippedImage(image, rect: artRect, ellipse: family == .cosmic || family == .confetti,
                             fitBundledSubject: fitBundledSubject, context: context)
            }
        } else {
            heart(in: artRect.insetBy(dx: 32, dy: 40), color: accent, context: context)
        }
        for (index, face) in card.faces.enumerated() {
            guard let image = PlatformImageUtils.image(from: face.data) else { continue }
            let rect = faceRect(at: index, count: card.faces.count, artwork: artRect)
            draw(image, in: rect, rotation: phase == nil ? 0 : Double(wave * 6), context: context)
        }
        for layer in card.stickers {
            guard let image = PlatformImageUtils.image(from: layer.data) else { continue }
            draw(image, in: layer.rect, rotation: layer.rotation, context: context)
        }
        if family == .loveLetter { textColor = color("#741B37") }
        drawText(card.saying, in: wordsRect, fontName: family.fontName, fontSize: fontSize,
                 color: textColor, context: context)
        if !card.note.isEmpty {
            drawText(card.note.count <= 40 ? card.note : "A note waits inside", in: CGRect(x: 38, y: 556, width: 324, height: 28),
                     fontName: "Georgia", fontSize: 14, color: textColor, context: context)
        }
        if opening > 0 {
            context.setFillColor(ink.withAlphaComponent(CGFloat(opening * 0.25)).cgColor)
            context.fill(CGRect(x: 390, y: 0, width: 10, height: 600))
        }
    }

    /// New compositions arrange the people together. The classic renderer still
    /// uses each saved face's original position and size.
    private func faceRect(at index: Int, count: Int, artwork: CGRect) -> CGRect {
        if count == 1 {
            return CGRect(x: artwork.midX - 54, y: artwork.midY - 60, width: 108, height: 120)
        }
        let columns = Int(ceil(sqrt(Double(count))))
        let rows = Int(ceil(Double(count) / Double(columns)))
        let area = artwork.insetBy(dx: 8, dy: 8)
        let gap = min(12, min(area.width / CGFloat(columns), area.height / CGFloat(rows)) * 0.12)
        let width = min(108, (area.width - CGFloat(columns - 1) * gap) / CGFloat(columns),
                        (area.height - CGFloat(rows - 1) * gap) / CGFloat(rows) * 0.9)
        let height = width / 0.9
        let row = index / columns
        let column = index % columns
        let rowCount = min(columns, count - row * columns)
        let rowWidth = CGFloat(rowCount) * width + CGFloat(rowCount - 1) * gap
        let totalHeight = CGFloat(rows) * height + CGFloat(rows - 1) * gap
        return CGRect(x: area.midX - rowWidth / 2 + CGFloat(column) * (width + gap),
                      y: area.midY - totalHeight / 2 + CGFloat(row) * (height + gap),
                      width: width, height: height)
    }

    func drawSticker(_ card: CardRenderSnapshot, context: CGContext) {
        let family = card.composition?.family ?? .loveLetter
        heart(in: CGRect(x: 35, y: 52, width: 330, height: 310), color: color(family.accentHex), context: context)
        if let face = card.faces.first, let image = PlatformImageUtils.image(from: face.data) {
            draw(image, in: CGRect(x: 110, y: 116, width: 180, height: 190), context: context)
        }
        panel(CGRect(x: 20, y: 345, width: 360, height: 172), fill: .white, stroke: nil, radius: 28, context: context)
        drawText(card.saying, in: CGRect(x: 38, y: 362, width: 324, height: 134),
                 fontName: family.fontName, fontSize: 34, color: color("#4E2036"), context: context)
    }

    private func color(_ hex: String) -> PlatformColor { PlatformColor.fromHex(hex) ?? .black }
    private func panel(_ rect: CGRect, fill: PlatformColor, stroke: PlatformColor?, width: CGFloat = 1,
                       radius: CGFloat, context: CGContext) {
        let path = CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)
        context.addPath(path); context.setFillColor(fill.cgColor); context.fillPath()
        if let stroke { context.addPath(path); context.setStrokeColor(stroke.cgColor); context.setLineWidth(width); context.strokePath() }
    }
    private func clippedImage(_ image: PlatformImage, rect: CGRect, ellipse: Bool,
                              fitBundledSubject: Bool = false, context: CGContext) {
        context.saveGState()
        if ellipse { context.addEllipse(in: rect) }
        else { context.addPath(CGPath(roundedRect: rect, cornerWidth: 5, cornerHeight: 5, transform: nil)) }
        context.clip()
        if fitBundledSubject, image.size.width > 0, image.size.height > 0 {
            // Each inspected 1024 × 1536 original places its meaningful subject
            // within y0...1088; the lower stationery area is not the subject.
            // Uniformly fit that top 17:16 region without changing source bytes.
            // The existing circular/rounded print mask remains intentional.
            let subjectHeight = min(image.size.height, image.size.width * 17 / 16)
            let scale = min(rect.width / image.size.width, rect.height / subjectHeight)
            let fitted = CGRect(x: rect.midX - image.size.width * scale / 2,
                                y: rect.midY - subjectHeight * scale / 2,
                                width: image.size.width * scale, height: image.size.height * scale)
            PlatformGraphics.draw(image, in: fitted, context: context)
        } else {
            draw(image, in: rect, context: context, fill: true)
        }
        context.restoreGState()
    }
    private func heart(in rect: CGRect, color: PlatformColor, context: CGContext) {
        let x = rect.minX, y = rect.minY, w = rect.width, h = rect.height
        context.beginPath(); context.move(to: CGPoint(x: x + w / 2, y: y + h))
        context.addCurve(to: CGPoint(x: x, y: y + h * 0.32), control1: CGPoint(x: x + w * 0.3, y: y + h * 0.8), control2: CGPoint(x: x, y: y + h * 0.6))
        context.addCurve(to: CGPoint(x: x + w / 2, y: y + h * 0.17), control1: CGPoint(x: x, y: y - h * 0.07), control2: CGPoint(x: x + w * 0.4, y: y - h * 0.13))
        context.addCurve(to: CGPoint(x: x + w, y: y + h * 0.32), control1: CGPoint(x: x + w * 0.6, y: y - h * 0.13), control2: CGPoint(x: x + w, y: y - h * 0.07))
        context.addCurve(to: CGPoint(x: x + w / 2, y: y + h), control1: CGPoint(x: x + w, y: y + h * 0.6), control2: CGPoint(x: x + w * 0.7, y: y + h * 0.8))
        context.closePath(); context.setFillColor(color.cgColor); context.fillPath()
    }
}
