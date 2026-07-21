//
//  Template.swift
//  My Funny Valentine
//
//  Created by Nathan Fennel on 2/12/26.
//

import Foundation
import SwiftUI

nonisolated struct CardTemplate: Identifiable, Codable {
    var id: String
    var name: String
    var category: TemplateCategory
    var imageName: String
    var facePositions: [FacePosition]
    var textAreas: [TextArea]
    var backgroundColor: ColorData
    
    init(
        id: String,
        name: String,
        category: TemplateCategory,
        imageName: String,
        facePositions: [FacePosition] = [],
        textAreas: [TextArea] = [],
        backgroundColor: ColorData = ColorData(color: .white)
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.imageName = imageName
        self.facePositions = facePositions
        self.textAreas = textAreas
        self.backgroundColor = backgroundColor
    }
}

nonisolated enum TemplateCategory: String, Codable {
    case romantic
    case funny
    case cute
    case classic
    case modern
}

nonisolated struct FacePosition: Codable {
    var position: CGPoint
    var size: CGSize
    var index: Int // 0 for first face, 1 for second face
    
    init(position: CGPoint, size: CGSize, index: Int = 0) {
        self.position = position
        self.size = size
        self.index = index
    }
}

nonisolated struct TextArea: Codable {
    var position: CGPoint
    var size: CGSize
    var defaultText: String?
    var maxLength: Int
    
    init(position: CGPoint, size: CGSize, defaultText: String? = nil, maxLength: Int = 100) {
        self.position = position
        self.size = size
        self.defaultText = defaultText
        self.maxLength = maxLength
    }
}

class TemplateManager {
    static let shared = TemplateManager()
    
    private var templates: [CardTemplate] = []
    
    private init() {
        loadTemplates()
    }
    
    func loadTemplates() {
        // Define 10-15 templates
        templates = [
            // Romantic templates
            CardTemplate(
                id: "romantic_1",
                name: "Classic Hearts",
                category: .romantic,
                imageName: "template_romantic_1",
                facePositions: [
                    FacePosition(position: CGPoint(x: 100, y: 200), size: CGSize(width: 150, height: 150), index: 0),
                    FacePosition(position: CGPoint(x: 250, y: 200), size: CGSize(width: 150, height: 150), index: 1)
                ],
                textAreas: [
                    TextArea(position: CGPoint(x: 200, y: 400), size: CGSize(width: 200, height: 100), defaultText: "Be My Valentine", maxLength: 50)
                ],
                backgroundColor: ColorData(color: .pink)
            ),
            CardTemplate(
                id: "romantic_2",
                name: "Elegant Roses",
                category: .romantic,
                imageName: "template_romantic_2",
                facePositions: [
                    FacePosition(position: CGPoint(x: 200, y: 150), size: CGSize(width: 200, height: 200), index: 0)
                ],
                textAreas: [
                    TextArea(position: CGPoint(x: 200, y: 400), size: CGSize(width: 200, height: 100), maxLength: 50)
                ],
                backgroundColor: ColorData(color: .red)
            ),
            CardTemplate(
                id: "romantic_3",
                name: "Love Letter",
                category: .romantic,
                imageName: "template_romantic_3",
                facePositions: [
                    FacePosition(position: CGPoint(x: 150, y: 250), size: CGSize(width: 100, height: 100), index: 0),
                    FacePosition(position: CGPoint(x: 250, y: 250), size: CGSize(width: 100, height: 100), index: 1)
                ],
                textAreas: [
                    TextArea(position: CGPoint(x: 200, y: 100), size: CGSize(width: 300, height: 120), maxLength: 100)
                ],
                backgroundColor: ColorData(color: .white)
            ),
            CardTemplate(
                id: "romantic_4",
                name: "Cupid's Arrow",
                category: .romantic,
                imageName: "template_romantic_4",
                facePositions: [
                    FacePosition(position: CGPoint(x: 200, y: 200), size: CGSize(width: 200, height: 200), index: 0)
                ],
                textAreas: [
                    TextArea(position: CGPoint(x: 200, y: 450), size: CGSize(width: 200, height: 80), maxLength: 50)
                ],
                backgroundColor: ColorData(color: .pink)
            ),
            CardTemplate(
                id: "romantic_5",
                name: "Starry Night",
                category: .romantic,
                imageName: "template_romantic_5",
                facePositions: [
                    FacePosition(position: CGPoint(x: 100, y: 200), size: CGSize(width: 150, height: 150), index: 0),
                    FacePosition(position: CGPoint(x: 250, y: 200), size: CGSize(width: 150, height: 150), index: 1)
                ],
                textAreas: [
                    TextArea(position: CGPoint(x: 200, y: 400), size: CGSize(width: 200, height: 100), maxLength: 50)
                ],
                backgroundColor: ColorData(color: .purple)
            ),
            
            // Funny templates
            CardTemplate(
                id: "funny_1",
                name: "Comic Style",
                category: .funny,
                imageName: "template_funny_1",
                facePositions: [
                    FacePosition(position: CGPoint(x: 200, y: 200), size: CGSize(width: 200, height: 200), index: 0)
                ],
                textAreas: [
                    TextArea(position: CGPoint(x: 200, y: 450), size: CGSize(width: 200, height: 100), defaultText: "Will you be my Valentine?", maxLength: 50)
                ],
                backgroundColor: ColorData(color: .yellow)
            ),
            CardTemplate(
                id: "funny_2",
                name: "Meme Style",
                category: .funny,
                imageName: "template_funny_2",
                facePositions: [
                    FacePosition(position: CGPoint(x: 150, y: 150), size: CGSize(width: 100, height: 100), index: 0),
                    FacePosition(position: CGPoint(x: 250, y: 150), size: CGSize(width: 100, height: 100), index: 1)
                ],
                textAreas: [
                    TextArea(position: CGPoint(x: 200, y: 300), size: CGSize(width: 200, height: 80), maxLength: 50),
                    TextArea(position: CGPoint(x: 200, y: 400), size: CGSize(width: 200, height: 80), maxLength: 50)
                ],
                backgroundColor: ColorData(color: .white)
            ),
            CardTemplate(
                id: "funny_3",
                name: "Silly Hearts",
                category: .funny,
                imageName: "template_funny_3",
                facePositions: [
                    FacePosition(position: CGPoint(x: 200, y: 250), size: CGSize(width: 200, height: 200), index: 0)
                ],
                textAreas: [
                    TextArea(position: CGPoint(x: 200, y: 100), size: CGSize(width: 200, height: 100), maxLength: 50)
                ],
                backgroundColor: ColorData(color: .orange)
            ),
            
            // Cute templates
            CardTemplate(
                id: "cute_1",
                name: "Kawaii Style",
                category: .cute,
                imageName: "template_cute_1",
                facePositions: [
                    FacePosition(position: CGPoint(x: 200, y: 200), size: CGSize(width: 180, height: 180), index: 0)
                ],
                textAreas: [
                    TextArea(position: CGPoint(x: 200, y: 420), size: CGSize(width: 200, height: 100), maxLength: 50)
                ],
                backgroundColor: ColorData(color: .pink)
            ),
            CardTemplate(
                id: "cute_2",
                name: "Animal Friends",
                category: .cute,
                imageName: "template_cute_2",
                facePositions: [
                    FacePosition(position: CGPoint(x: 100, y: 200), size: CGSize(width: 150, height: 150), index: 0),
                    FacePosition(position: CGPoint(x: 250, y: 200), size: CGSize(width: 150, height: 150), index: 1)
                ],
                textAreas: [
                    TextArea(position: CGPoint(x: 200, y: 400), size: CGSize(width: 200, height: 100), maxLength: 50)
                ],
                backgroundColor: ColorData(color: .blue)
            ),
            CardTemplate(
                id: "cute_3",
                name: "Sweet Treats",
                category: .cute,
                imageName: "template_cute_3",
                facePositions: [
                    FacePosition(position: CGPoint(x: 200, y: 250), size: CGSize(width: 200, height: 200), index: 0)
                ],
                textAreas: [
                    TextArea(position: CGPoint(x: 200, y: 100), size: CGSize(width: 200, height: 100), maxLength: 50)
                ],
                backgroundColor: ColorData(color: .pink)
            ),
            
            // Classic templates
            CardTemplate(
                id: "classic_1",
                name: "Vintage Valentine",
                category: .classic,
                imageName: "template_classic_1",
                facePositions: [
                    FacePosition(position: CGPoint(x: 200, y: 200), size: CGSize(width: 200, height: 200), index: 0)
                ],
                textAreas: [
                    TextArea(position: CGPoint(x: 200, y: 450), size: CGSize(width: 200, height: 100), maxLength: 50)
                ],
                backgroundColor: ColorData(color: .white)
            ),
            CardTemplate(
                id: "classic_2",
                name: "Traditional",
                category: .classic,
                imageName: "template_classic_2",
                facePositions: [
                    FacePosition(position: CGPoint(x: 150, y: 200), size: CGSize(width: 150, height: 150), index: 0),
                    FacePosition(position: CGPoint(x: 250, y: 200), size: CGSize(width: 150, height: 150), index: 1)
                ],
                textAreas: [
                    TextArea(position: CGPoint(x: 200, y: 400), size: CGSize(width: 200, height: 100), maxLength: 50)
                ],
                backgroundColor: ColorData(color: .red)
            ),
            
            // Modern templates
            CardTemplate(
                id: "modern_1",
                name: "Minimalist",
                category: .modern,
                imageName: "template_modern_1",
                facePositions: [
                    FacePosition(position: CGPoint(x: 200, y: 250), size: CGSize(width: 200, height: 200), index: 0)
                ],
                textAreas: [
                    TextArea(position: CGPoint(x: 200, y: 100), size: CGSize(width: 200, height: 100), maxLength: 50)
                ],
                backgroundColor: ColorData(color: .white)
            ),
            CardTemplate(
                id: "modern_2",
                name: "Geometric",
                category: .modern,
                imageName: "template_modern_2",
                facePositions: [
                    FacePosition(position: CGPoint(x: 200, y: 200), size: CGSize(width: 200, height: 200), index: 0)
                ],
                textAreas: [
                    TextArea(position: CGPoint(x: 200, y: 450), size: CGSize(width: 200, height: 100), maxLength: 50)
                ],
                backgroundColor: ColorData(color: .black)
            )
        ]
    }
    
    func getAllTemplates() -> [CardTemplate] {
        return templates
    }
    
    func getTemplates(category: TemplateCategory) -> [CardTemplate] {
        return templates.filter { $0.category == category }
    }
    
    func getTemplate(id: String) -> CardTemplate? {
        return templates.first { $0.id == id }
    }
}
