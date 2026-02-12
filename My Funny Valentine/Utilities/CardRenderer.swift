//
//  CardRenderer.swift
//  My Funny Valentine
//
//  Created by Nathan Fennel on 2/12/26.
//

import Foundation
import UIKit
import SwiftUI

class CardRenderer {
    static let shared = CardRenderer()
    
    private init() {}
    
    /// Render a Card to a UIImage
    func renderCard(_ card: Card, size: CGSize = CGSize(width: 1080, height: 1080)) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            // Get background color from layout or use default
            let backgroundColor = getBackgroundColor(from: card)
            backgroundColor.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            
            // Draw faces
            if let faces = card.faces {
                for face in faces {
                    if let faceImage = UIImage(data: face.imageData) {
                        let rect = CGRect(
                            x: face.position.x,
                            y: face.position.y,
                            width: face.size.width,
                            height: face.size.height
                        )
                        faceImage.draw(in: rect)
                    }
                }
            }
            
            // Draw card images
            if let images = card.images {
                for cardImage in images {
                    if let image = UIImage(data: cardImage.imageData) {
                        let rect = CGRect(
                            x: cardImage.position.x,
                            y: cardImage.position.y,
                            width: cardImage.size.width,
                            height: cardImage.size.height
                        )
                        
                        // Apply rotation if needed
                        if cardImage.rotation != 0 {
                            context.cgContext.saveGState()
                            let center = CGPoint(
                                x: rect.midX,
                                y: rect.midY
                            )
                            context.cgContext.translateBy(x: center.x, y: center.y)
                            context.cgContext.rotate(by: CGFloat(cardImage.rotation))
                            context.cgContext.translateBy(x: -center.x, y: -center.y)
                            image.draw(in: rect)
                            context.cgContext.restoreGState()
                        } else {
                            image.draw(in: rect)
                        }
                    }
                }
            }
            
            // Draw text
            if let layoutData = card.getLayoutData() {
                for textPosition in layoutData.textPositions {
                    drawText(textPosition, in: context.cgContext, size: size)
                }
            } else {
                // Fallback: draw saying or custom text
                if let saying = card.saying {
                    drawSimpleText(saying, in: context.cgContext, size: size)
                } else if let customText = card.customText {
                    drawSimpleText(customText, in: context.cgContext, size: size)
                }
            }
        }
    }
    
    /// Get background color from card layout or return default
    private func getBackgroundColor(from card: Card) -> UIColor {
        if let layoutData = card.getLayoutData() {
            return UIColor(hex: layoutData.backgroundColor) ?? .white
        }
        return .white
    }
    
    /// Draw text from TextPosition
    private func drawText(_ textPosition: TextPosition, in context: CGContext, size: CGSize) {
        let font = UIFont(name: textPosition.fontName, size: textPosition.fontSize) ?? UIFont.systemFont(ofSize: textPosition.fontSize)
        let color = UIColor(hex: textPosition.color) ?? .black
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color
        ]
        
        let attributedString = NSAttributedString(string: textPosition.text, attributes: attributes)
        let rect = CGRect(
            x: textPosition.position.x,
            y: textPosition.position.y,
            width: textPosition.size.width,
            height: textPosition.size.height
        )
        
        attributedString.draw(in: rect)
    }
    
    /// Draw simple text (fallback)
    private func drawSimpleText(_ text: String, in context: CGContext, size: CGSize) {
        let font = UIFont.systemFont(ofSize: 32)
        let color = UIColor.black
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color
        ]
        
        let attributedString = NSAttributedString(string: text, attributes: attributes)
        let textSize = attributedString.size()
        let rect = CGRect(
            x: (size.width - textSize.width) / 2,
            y: size.height * 0.8,
            width: textSize.width,
            height: textSize.height
        )
        
        attributedString.draw(in: rect)
    }
}

// UIColor extension for hex color support
extension UIColor {
    convenience init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }
        
        self.init(
            red: CGFloat(r) / 255,
            green: CGFloat(g) / 255,
            blue: CGFloat(b) / 255,
            alpha: CGFloat(a) / 255
        )
    }
}
