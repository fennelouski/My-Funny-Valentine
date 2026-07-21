//
//  CardGenerationService.swift
//  My Funny Valentine
//
//  Created by Nathan Fennel on 2/12/26.
//

import Foundation
import SwiftUI
import SwiftData
import CoreGraphics

class CardGenerationService {
    static let shared = CardGenerationService()
    
    private init() {}
    
    func generateTemplateCards(faces: [FaceImage], modelContext: ModelContext) -> [Card] {
        let templates = TemplateManager.shared.getAllTemplates()
        var cards: [Card] = []
        
        for template in templates {
            // Only use templates that match the number of faces we have
            let requiredFaces = template.facePositions.count
            if faces.count >= requiredFaces {
                let cardId = UUID()
                let cardFaces = Array(faces.prefix(requiredFaces))
                
                // Create card faces with cardId
                var cardFaceImages: [FaceImage] = []
                for (index, face) in cardFaces.enumerated() {
                    let facePosition = template.facePositions[index]
                    let cardFace = FaceImage(
                        cardId: cardId,
                        imageData: face.imageData,
                        thumbnailData: face.thumbnailData,
                        position: facePosition.position,
                        size: facePosition.size
                    )
                    cardFaceImages.append(cardFace)
                    modelContext.insert(cardFace)
                }
                
                // Create layout data
                let layoutData = CardLayoutData(
                    templateLayoutId: template.id,
                    textPositionX: template.textAreas.first?.position.x ?? 200,
                    textPositionY: template.textAreas.first?.position.y ?? 400,
                    textRotation: 0,
                    imagePlacements: []
                )
                
                let card = Card(
                    id: cardId,
                    templateId: template.id,
                    saying: template.textAreas.first?.defaultText,
                    faces: cardFaceImages,
                    images: [],
                    stickers: [],
                    layoutData: layoutData
                )
                
                cards.append(card)
                modelContext.insert(card)
            }
        }
        
        return cards
    }
    
    func renderCard(_ card: Card, size: CGSize) -> PlatformImage? {
        let template = TemplateManager.shared.getTemplate(id: card.templateId ?? "")

        return PlatformGraphics.image(size: size) { context in
            // Draw background
            let background = template.map { PlatformColor($0.backgroundColor.color) } ?? .white
            context.setFillColor(background.cgColor)
            context.fill(CGRect(origin: .zero, size: size))

            // Draw faces
            if let template, let faces = card.faces {
                for (index, face) in faces.enumerated() where index < template.facePositions.count {
                    if let image = PlatformImageUtils.image(from: face.imageData) {
                        let rect = CGRect(origin: face.position, size: face.size)
                        PlatformGraphics.draw(image, in: rect, context: context)
                    }
                }
            }

            let layoutData = card.getLayoutData()
            let textX = layoutData?.textPositionX ?? 200
            let textY = layoutData?.textPositionY ?? 400

            // Draw saying
            if let saying = card.saying, !saying.isEmpty {
                drawText(saying, fontSize: 24, at: CGPoint(x: textX, y: textY), maxWidth: size.width - textX, context: context)
            }

            // Draw custom text
            if let customText = card.customText, !customText.isEmpty {
                drawText(customText, fontSize: 20, at: CGPoint(x: textX, y: textY + 50), maxWidth: size.width - textX, context: context)
            }

            // Draw images
            if let images = card.images {
                for image in images {
                    if let platformImage = PlatformImageUtils.image(from: image.imageData) {
                        let rect = CGRect(origin: image.position, size: image.size)
                        PlatformGraphics.draw(platformImage, in: rect, context: context)
                    }
                }
            }
        }
    }

    private func drawText(
        _ text: String,
        fontSize: CGFloat,
        at origin: CGPoint,
        maxWidth: CGFloat,
        context: CGContext
    ) {
        let attributed = NSAttributedString(
            string: text,
            attributes: [
                .font: PlatformFont.systemFont(ofSize: fontSize),
                .foregroundColor: PlatformColor.black
            ]
        )
        let textSize = PlatformGraphics.size(of: attributed, maxWidth: max(maxWidth, 1))
        PlatformGraphics.draw(attributed, in: CGRect(origin: origin, size: textSize), context: context)
    }
}
