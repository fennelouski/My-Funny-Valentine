//
//  CardListView.swift
//  My Funny Valentine
//

import SwiftUI
import SwiftData

struct CardListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Card.modifiedAt, order: .reverse) private var cards: [Card]
    
    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        NavigationStack {
            Group {
                if cards.isEmpty {
                    EmptyStateView(
                        title: "No Cards Yet",
                        message: "Create your first Valentine's card to get started. Tap the + button to begin.",
                        systemImage: "heart.rectangle.stack"
                    )
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(cards, id: \.id) { card in
                                NavigationLink(value: card) {
                                    CardTileView(card: card)
                                }
                                .contextMenu {
                                    Button(role: .destructive) {
                                        deleteCard(card)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("My Cards")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    NavigationLink {
                        CardDetailView(card: nil)
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
            .navigationDestination(for: Card.self) { card in
                CardDetailView(card: card)
            }
        }
    }
    
    private func deleteCard(_ card: Card) {
        modelContext.delete(card)
        try? modelContext.save()
    }
}

#Preview {
    CardListView()
        .modelContainer(for: Card.self, inMemory: true)
}
