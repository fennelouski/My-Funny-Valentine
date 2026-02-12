//
//  CardViewModel.swift
//  My Funny Valentine
//

import Foundation
import SwiftData
import SwiftUI

@MainActor
@Observable
class CardViewModel {
    var cards: [Card] = []
    var selectedCard: Card?
    var isLoading = false
    var errorMessage: String?
    
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func loadCards() {
        let descriptor = FetchDescriptor<Card>(sortBy: [SortDescriptor(\.modifiedAt, order: .reverse)])
        do {
            cards = try modelContext.fetch(descriptor)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func createCard(templateId: String? = nil, saying: String? = nil) -> Card {
        let card = Card(templateId: templateId, saying: saying)
        modelContext.insert(card)
        do {
            try modelContext.save()
            loadCards()
        } catch {
            errorMessage = error.localizedDescription
        }
        return card
    }
    
    func updateCard(_ card: Card) {
        card.modifiedAt = Date()
        do {
            try modelContext.save()
            loadCards()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func deleteCard(_ card: Card) {
        modelContext.delete(card)
        if selectedCard?.id == card.id {
            selectedCard = nil
        }
        do {
            try modelContext.save()
            loadCards()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func selectCard(_ card: Card?) {
        selectedCard = card
    }
    
    func clearError() {
        errorMessage = nil
    }
}
