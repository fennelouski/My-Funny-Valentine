//
//  Card+Layout.swift
//  My Funny Valentine
//

import Foundation
import SwiftUI

extension Card {
    /// Mutable layout interface for editing - syncs with layoutData
    var layout: CardLayoutEditing {
        CardLayoutEditing(card: self)
    }
}

/// Mutable wrapper for editing card layout in views
struct CardLayoutEditing {
    private let card: Card
    
    init(card: Card) {
        self.card = card
    }
    
    var backgroundColor: ColorData {
        get {
            guard let hex = card.getLayoutData()?.backgroundColor else { return ColorData(color: .white) }
            return ColorData(hex: hex) ?? ColorData(color: .white)
        }
        set {
            var data = card.getLayoutData() ?? CardLayoutData()
            data.backgroundColor = newValue.hexString
            card.setLayoutData(data)
        }
    }
    
    var textPositions: [TextPositionWithColorData] {
        get {
            (card.getLayoutData()?.textPositions ?? []).map { TextPositionWithColorData(textPosition: $0, card: card) }
        }
        set {
            var data = card.getLayoutData() ?? CardLayoutData()
            data.textPositions = newValue.map { $0.toTextPosition() }
            card.setLayoutData(data)
        }
    }
}

/// View-friendly TextPosition with ColorData
struct TextPositionWithColorData {
    var text: String
    var fontName: String
    var fontSize: CGFloat
    var color: ColorData
    var position: CGPoint
    var size: CGSize
    
    init(textPosition: TextPosition, card: Card) {
        self.text = textPosition.text
        self.fontName = textPosition.fontName
        self.fontSize = textPosition.fontSize
        self.color = ColorData(hex: textPosition.color) ?? ColorData(color: .black)
        self.position = textPosition.position
        self.size = textPosition.size
    }
    
    func toTextPosition() -> TextPosition {
        TextPosition(text: text, fontName: fontName, fontSize: fontSize, color: color.hexString, position: position, size: size)
    }
}
