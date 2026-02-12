//
//  HomeView.swift
//  My Funny Valentine
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Card.modifiedAt, order: .reverse) private var recentCards: [Card]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Welcome section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("My Funny Valentine")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Text("Create personalized Valentine's cards with AI")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal)
                    
                    // Recent cards
                    if !recentCards.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Recent Cards")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    ForEach(recentCards.prefix(5), id: \.id) { card in
                                        NavigationLink(value: card) {
                                            CardTileView(card: card)
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    
                    Spacer(minLength: 40)
                }
                .padding(.vertical, 20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationDestination(for: Card.self) { card in
                CardDetailView(card: card)
            }
        }
    }
}

#Preview {
    HomeView()
        .modelContainer(for: Card.self, inMemory: true)
}
