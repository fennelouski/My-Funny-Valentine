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
            let requiredFaces = template.minimumFaceCount ?? template.facePositions.count
            if faces.count >= requiredFaces {
                let cardId = UUID()
                let cardFaces = Array(faces.prefix(template.facePositions.count))
                
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
                    backgroundColor: template.backgroundColor.hexString,
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
        CardRenderer.shared.renderCard(card, size: size)
    }
}
