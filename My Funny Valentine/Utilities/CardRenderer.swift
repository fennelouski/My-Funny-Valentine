//
//  CardRenderer.swift
//  My Funny Valentine
//
//  Created by Nathan Fennel on 2/12/26.
//

import Foundation
import CoreGraphics
import SwiftUI

class CardRenderer {
    static let shared = CardRenderer()

    private init() {}

    /// Render a Card to an image
    func renderCard(_ card: Card, size: CGSize = CGSize(width: 1080, height: 1080)) -> PlatformImage? {
        PlatformGraphics.image(size: size) { context in
            // Background
            let backgroundColor = getBackgroundColor(from: card)
            context.setFillColor(backgroundColor.cgColor)
            context.fill(CGRect(origin: .zero, size: size))

            // Faces
            if let faces = card.faces {
                for face in faces {
                    if let faceImage = PlatformImageUtils.image(from: face.imageData) {
                        let rect = CGRect(
                            x: face.position.x,
                            y: face.position.y,
                            width: face.size.width,
                            height: face.size.height
                        )
                        PlatformGraphics.draw(faceImage, in: rect, context: context)
                    }
                }
            }

            // Card images
            if let images = card.images {
                for cardImage in images {
                    guard let image = PlatformImageUtils.image(from: cardImage.imageData) else { continue }
                    let rect = CGRect(
                        x: cardImage.position.x,
                        y: cardImage.position.y,
                        width: cardImage.size.width,
                        height: cardImage.size.height
                    )

                    if cardImage.rotation != 0 {
                        context.saveGState()
                        let center = CGPoint(x: rect.midX, y: rect.midY)
                        context.translateBy(x: center.x, y: center.y)
                        context.rotate(by: CGFloat(cardImage.rotation))
                        context.translateBy(x: -center.x, y: -center.y)
                        PlatformGraphics.draw(image, in: rect, context: context)
                        context.restoreGState()
                    } else {
                        PlatformGraphics.draw(image, in: rect, context: context)
                    }
                }
            }

            // Text
            if let layoutData = card.getLayoutData(), !layoutData.textPositions.isEmpty {
                for textPosition in layoutData.textPositions {
                    drawText(textPosition, in: context)
                }
            } else if let text = card.saying ?? card.customText {
                drawSimpleText(text, in: context, size: size)
            }
        }
    }

    /// Get background color from card layout or return default
    private func getBackgroundColor(from card: Card) -> PlatformColor {
        if let layoutData = card.getLayoutData() {
            return PlatformColor.fromHex(layoutData.backgroundColor) ?? .white
        }
        return .white
    }

    private func drawText(_ textPosition: TextPosition, in context: CGContext) {
        let font = PlatformFont(name: textPosition.fontName, size: textPosition.fontSize)
            ?? PlatformFont.systemFont(ofSize: textPosition.fontSize)
        let color = PlatformColor.fromHex(textPosition.color) ?? .black

        let attributed = NSAttributedString(
            string: textPosition.text,
            attributes: [.font: font, .foregroundColor: color]
        )
        let rect = CGRect(
            x: textPosition.position.x,
            y: textPosition.position.y,
            width: textPosition.size.width,
            height: textPosition.size.height
        )

        PlatformGraphics.draw(attributed, in: rect, context: context)
    }

    private func drawSimpleText(_ text: String, in context: CGContext, size: CGSize) {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center

        let attributed = NSAttributedString(
            string: text,
            attributes: [
                .font: PlatformFont.systemFont(ofSize: 48),
                .foregroundColor: PlatformColor.black,
                .paragraphStyle: paragraph
            ]
        )

        let inset = size.width * 0.1
        let maxWidth = size.width - (inset * 2)
        let textSize = PlatformGraphics.size(of: attributed, maxWidth: maxWidth)
        let rect = CGRect(
            x: inset,
            y: (size.height - textSize.height) / 2,
            width: maxWidth,
            height: textSize.height
        )

        PlatformGraphics.draw(attributed, in: rect, context: context)
    }
}
