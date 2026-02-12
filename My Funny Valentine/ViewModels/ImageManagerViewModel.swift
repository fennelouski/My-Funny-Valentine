//
//  ImageManagerViewModel.swift
//  My Funny Valentine
//

import Foundation
import SwiftData
import SwiftUI

@MainActor
@Observable
class ImageManagerViewModel {
    var isLoading = false
    var errorMessage: String?
    
    private let modelContext: ModelContext
    private let imageService = ImageService.shared
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func addFaceImage(to card: Card, imageData: Data) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let processedData = try await imageService.processForStorage(imageData)
            let thumbnailData = try await imageService.generateThumbnail(from: processedData)
            
            let faceImage = FaceImage(
                cardId: card.id,
                imageData: processedData,
                thumbnailData: thumbnailData
            )
            faceImage.card = card
            modelContext.insert(faceImage)
            card.faces.append(faceImage)
            card.modifiedAt = Date()
            
            try modelContext.save()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func addCardImage(to card: Card, imageData: Data, source: ImageSource) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let processedData = try await imageService.processForStorage(imageData)
            
            let cardImage = CardImage(
                cardId: card.id,
                source: source,
                imageData: processedData
            )
            cardImage.card = card
            modelContext.insert(cardImage)
            card.images.append(cardImage)
            card.modifiedAt = Date()
            
            try modelContext.save()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func clearError() {
        errorMessage = nil
    }
}
