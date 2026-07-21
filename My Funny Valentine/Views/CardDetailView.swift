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
    @State private var showingSayingsGenerator = false
    @State private var showingImageGenerator = false
    @State private var artworkData: Data?

    private var isNewCard: Bool { card == nil }

    /// Card used to drive the live preview as the user types.
    private var previewCard: Card {
        Card(
            saying: saying.isEmpty ? nil : saying,
            customText: customText.isEmpty ? nil : customText
        )
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                CardTileView(card: previewCard, size: CGSize(width: 280, height: 380))
                    .padding(.top)

                if let artworkData, let artwork = PlatformImage(data: artworkData) {
                    VStack(spacing: 8) {
                        PlatformImageUtils.swiftUIImage(from: artwork)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                        Button(role: .destructive) {
                            self.artworkData = nil
                        } label: {
                            Label("Remove artwork", systemImage: "trash")
                                .font(.caption)
                        }
                        .buttonStyle(.borderless)
                    }
                    .padding(.horizontal)
                }

                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        AppTextField(
                            title: "Saying",
                            text: $saying,
                            placeholder: "Add a saying..."
                        )

                        Button {
                            showingSayingsGenerator = true
                        } label: {
                            Label("Generate with AI", systemImage: "sparkles")
                                .font(.subheadline.weight(.medium))
                        }
                        .buttonStyle(.borderless)
                        .tint(.pink)
                        .accessibilityIdentifier("cardDetail.generateWithAI")
                    }

                    AppTextField(
                        title: "Custom Text",
                        text: $customText,
                        placeholder: "Your custom message..."
                    )

                    Button {
                        showingImageGenerator = true
                    } label: {
                        Label("Generate artwork", systemImage: "photo.badge.plus")
                            .font(.subheadline.weight(.medium))
                    }
                    .buttonStyle(.borderless)
                    .tint(.pink)
                    .accessibilityIdentifier("cardDetail.generateArtwork")
                }
                .padding()
                .background(Color.appSecondaryGroupedBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)
            }
            .padding(.bottom, 32)
        }
        .background(Color.appGroupedBackground)
        .navigationTitle(isNewCard ? "New Card" : "Edit Card")
        .appInlineNavigationTitle()
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    saveCard()
                }
                .fontWeight(.semibold)
                .disabled(saying.isEmpty && customText.isEmpty && artworkData == nil)
                .accessibilityIdentifier("cardDetail.save")
            }
        }
        .sheet(isPresented: $showingSayingsGenerator) {
            SayingsGenerationView(userId: UserPreferencesService.deviceUserId()) { selected in
                saying = selected
            }
        }
        .sheet(isPresented: $showingImageGenerator) {
            ImageGenerationView(
                userId: UserPreferencesService.deviceUserId()
            ) { data in
                artworkData = data
            }
        }
        .onAppear {
            guard let card else { return }
            saying = card.saying ?? ""
            customText = card.customText ?? ""
        }
    }

    private func saveCard() {
        let target: Card
        if let card {
            card.saying = saying.isEmpty ? nil : saying
            card.customText = customText.isEmpty ? nil : customText
            card.updateModifiedDate()
            target = card
        } else {
            let newCard = Card(
                saying: saying.isEmpty ? nil : saying,
                customText: customText.isEmpty ? nil : customText
            )
            modelContext.insert(newCard)
            target = newCard
        }

        if let artworkData {
            let artwork = CardImage(
                cardId: target.id,
                source: .imagePlayground,
                imageData: artworkData
            )
            modelContext.insert(artwork)
            if target.images == nil { target.images = [] }
            target.images?.append(artwork)
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
