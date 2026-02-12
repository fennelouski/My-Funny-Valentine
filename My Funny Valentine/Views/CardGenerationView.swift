//
//  CardGenerationView.swift
//  My Funny Valentine
//
//  Created by Nathan Fennel on 2/12/26.
//

import SwiftUI
import SwiftData

struct CardGenerationView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let faces: [FaceImage]
    @State private var generatedCards: [Card] = []
    @State private var isGenerating = false
    
    var body: some View {
        NavigationView {
            VStack {
                if isGenerating {
                    ProgressView("Generating cards...")
                        .padding()
                } else if generatedCards.isEmpty {
                    Text("No cards generated")
                        .foregroundColor(.secondary)
                } else {
                    cardGridView
                }
            }
            .navigationTitle("Generated Cards")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                generateCards()
            }
        }
    }
    
    private var cardGridView: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 20) {
                ForEach(generatedCards) { card in
                    NavigationLink {
                        CardPreviewView(card: card)
                    } label: {
                        CardThumbnailView(card: card)
                    }
                }
            }
            .padding()
        }
    }
    
    private func generateCards() {
        isGenerating = true
        generatedCards = CardGenerationService.shared.generateTemplateCards(
            faces: faces,
            modelContext: modelContext
        )
        isGenerating = false
    }
}
