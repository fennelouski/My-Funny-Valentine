//
//  CardLibraryView.swift
//  My Funny Valentine
//
//  Created by Nathan Fennel on 2/12/26.
//

import SwiftUI
import SwiftData

struct CardLibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Card.modifiedAt, order: .reverse) private var cards: [Card]
    
    @State private var layoutMode: LayoutMode = .grid
    @State private var searchText = ""
    @State private var showingFaceImport = false
    
    enum LayoutMode {
        case grid
        case list
    }
    
    var filteredCards: [Card] {
        if searchText.isEmpty {
            return cards
        }
        return cards.filter { card in
            card.saying?.localizedCaseInsensitiveContains(searchText) ?? false ||
            card.customText?.localizedCaseInsensitiveContains(searchText) ?? false
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if cards.isEmpty {
                    emptyStateView
                } else {
                    cardListView
                }
            }
            .navigationTitle("My Cards")
            .searchable(text: $searchText, prompt: "Search cards")
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    Button(action: { layoutMode = layoutMode == .grid ? .list : .grid }) {
                        Image(systemName: layoutMode == .grid ? "list.bullet" : "square.grid.2x2")
                    }
                    
                    Button(action: { showingFaceImport = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingFaceImport) {
                FaceImportView()
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "heart.text.square")
                .font(.system(size: 80))
                .foregroundColor(.pink)
            
            Text("No Cards Yet")
                .font(.title)
            
            Text("Import your face to get started creating personalized Valentine's cards!")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Import Faces") {
                showingFaceImport = true
            }
            .buttonStyle(.borderedProminent)
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var cardListView: some View {
        Group {
            if layoutMode == .grid {
                gridView
            } else {
                listView
            }
        }
    }
    
    private var gridView: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 20) {
                ForEach(filteredCards) { card in
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
    
    private var listView: some View {
        List {
            ForEach(filteredCards) { card in
                NavigationLink {
                    CardPreviewView(card: card)
                } label: {
                    CardRowView(card: card)
                }
            }
            .onDelete(perform: deleteCards)
        }
    }
    
    private func deleteCards(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(filteredCards[index])
            }
            try? modelContext.save()
        }
    }
}

struct CardThumbnailView: View {
    let card: Card
    
    private let thumbnailSize = CGSize(width: 150, height: 225)
    
    var body: some View {
        VStack {
            if let thumbnail = CardGenerationService.shared.renderCard(card, size: thumbnailSize) {
                Image(uiImage: thumbnail)
                    .resizable()
                    .scaledToFit()
                    .frame(width: thumbnailSize.width, height: thumbnailSize.height)
                    .cornerRadius(8)
                    .shadow(radius: 5)
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: thumbnailSize.width, height: thumbnailSize.height)
            }
        }
    }
}

struct CardRowView: View {
    let card: Card
    
    var body: some View {
        HStack {
            if let thumbnail = CardGenerationService.shared.renderCard(
                card,
                size: CGSize(width: 80, height: 120)
            ) {
                Image(uiImage: thumbnail)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 120)
                    .cornerRadius(8)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(card.saying ?? card.customText ?? "Untitled Card")
                    .font(.headline)
                    .lineLimit(2)
                
                Text(card.modifiedAt, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}
