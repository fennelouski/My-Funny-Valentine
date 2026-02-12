//
//  CardDetailView.swift
//  My Funny Valentine
//

import SwiftUI
import SwiftData

struct CardDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let card: Card?
    
    @State private var saying: String = ""
    @State private var customText: String = ""
    
    private var isNewCard: Bool { card == nil }
    private var currentCard: Card {
        card ?? Card(saying: saying.isEmpty ? nil : saying)
    }
    
    var body: some View {
        Group {
            if let card {
                cardDetailContent(card: card)
            } else {
                newCardContent
            }
        }
        .navigationTitle(isNewCard ? "New Card" : "Edit Card")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    if isNewCard {
                        dismiss()
                    }
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    saveCard()
                }
                .fontWeight(.semibold)
            }
        }
    }
    
    @ViewBuilder
    private func cardDetailContent(card: Card) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                CardTileView(card: card, size: CGSize(width: 280, height: 380))
                    .padding(.top)
                
                VStack(alignment: .leading, spacing: 16) {
                    AppTextField(
                        title: "AI Saying",
                        text: $saying,
                        placeholder: "Add a saying..."
                    )
                    
                    AppTextField(
                        title: "Custom Text",
                        text: $customText,
                        placeholder: "Your custom message..."
                    )
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)
            }
            .padding(.bottom, 32)
        }
        .background(Color(.systemGroupedBackground))
        .onAppear {
            saying = card.saying ?? ""
            customText = card.customText ?? ""
        }
    }
    
    private var newCardContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                CardTileView(
                    card: Card(saying: saying.isEmpty ? "Preview" : saying, customText: customText.isEmpty ? nil : customText),
                    size: CGSize(width: 280, height: 380)
                )
                .padding(.top)
                
                VStack(alignment: .leading, spacing: 16) {
                    AppTextField(
                        title: "AI Saying",
                        text: $saying,
                        placeholder: "Add a saying..."
                    )
                    
                    AppTextField(
                        title: "Custom Text",
                        text: $customText,
                        placeholder: "Your custom message..."
                    )
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)
            }
            .padding(.bottom, 32)
        }
        .background(Color(.systemGroupedBackground))
    }
    
    private func saveCard() {
        if isNewCard {
            let newCard = Card(
                saying: saying.isEmpty ? nil : saying,
                customText: customText.isEmpty ? nil : customText
            )
            modelContext.insert(newCard)
        } else if let card {
            card.saying = saying.isEmpty ? nil : saying
            card.customText = customText.isEmpty ? nil : customText
            card.modifiedAt = Date()
        }
        try? modelContext.save()
        dismiss()
    }
}

#Preview("Edit") {
    NavigationStack {
        CardDetailView(card: Card(saying: "You're the best!"))
            .modelContainer(for: Card.self, inMemory: true)
    }
}

#Preview("New") {
    NavigationStack {
        CardDetailView(card: nil)
            .modelContainer(for: Card.self, inMemory: true)
    }
}
