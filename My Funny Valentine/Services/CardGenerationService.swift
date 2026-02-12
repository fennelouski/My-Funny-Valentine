//
//  CardGenerationService.swift
//  My Funny Valentine
//
//  Created by Nathan Fennel on 2/12/26.
//

import Foundation
import SwiftUI
import SwiftData
import UIKit

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
    
    func renderCard(_ card: Card, size: CGSize) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            // Draw background
            if let template = TemplateManager.shared.getTemplate(id: card.templateId ?? "") {
                template.backgroundColor.color.uiColor.setFill()
            } else {
                UIColor.white.setFill()
            }
            context.cgContext.fill(CGRect(origin: .zero, size: size))
            
            // Draw faces
            if let template = TemplateManager.shared.getTemplate(id: card.templateId ?? ""),
               let faces = card.faces {
                for (index, face) in faces.enumerated() {
                    if index < template.facePositions.count {
                        if let uiImage = UIImage(data: face.imageData) {
                            let rect = CGRect(
                                origin: face.position,
                                size: face.size
                            )
                            uiImage.draw(in: rect)
                        }
                    }
                }
            }
            
            // Draw text
            if let saying = card.saying, !saying.isEmpty {
                let font = UIFont.systemFont(ofSize: 24)
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: font,
                    .foregroundColor: UIColor.black
                ]
                
                let attributedString = NSAttributedString(string: saying, attributes: attributes)
                let textSize = attributedString.size()
                
                if let layoutData = card.getLayoutData() {
                    let textRect = CGRect(
                        origin: CGPoint(
                            x: layoutData.textPositionX ?? 200,
                            y: layoutData.textPositionY ?? 400
                        ),
                        size: textSize
                    )
                    attributedString.draw(in: textRect)
                }
            }
            
            // Draw custom text
            if let customText = card.customText, !customText.isEmpty {
                let font = UIFont.systemFont(ofSize: 20)
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: font,
                    .foregroundColor: UIColor.black
                ]
                
                let attributedString = NSAttributedString(string: customText, attributes: attributes)
                let textSize = attributedString.size()
                
                if let layoutData = card.getLayoutData() {
                    let textRect = CGRect(
                        origin: CGPoint(
                            x: layoutData.textPositionX ?? 200,
                            y: (layoutData.textPositionY ?? 400) + 50
                        ),
                        size: textSize
                    )
                    attributedString.draw(in: textRect)
                }
            }
            
            // Draw images
            if let images = card.images {
                for image in images {
                    if let uiImage = UIImage(data: image.imageData) {
                        let rect = CGRect(
                            origin: image.position,
                            size: image.size
                        )
                        uiImage.draw(in: rect)
                    }
                }
            }
        }
    }
}

extension Color {
    var uiColor: UIColor {
        UIColor(self)
    }
}
