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
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)
            }
            .padding(.bottom, 32)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(isNewCard ? "New Card" : "Edit Card")
        .navigationBarTitleDisplayMode(.inline)
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
                .disabled(saying.isEmpty && customText.isEmpty)
                .accessibilityIdentifier("cardDetail.save")
            }
        }
        .sheet(isPresented: $showingSayingsGenerator) {
            SayingsGenerationView(userId: UserPreferencesService.deviceUserId()) { selected in
                saying = selected
            }
        }
        .onAppear {
            guard let card else { return }
            saying = card.saying ?? ""
            customText = card.customText ?? ""
        }
    }

    private func saveCard() {
        if let card {
            card.saying = saying.isEmpty ? nil : saying
            card.customText = customText.isEmpty ? nil : customText
            card.updateModifiedDate()
        } else {
            let newCard = Card(
                saying: saying.isEmpty ? nil : saying,
                customText: customText.isEmpty ? nil : customText
            )
            modelContext.insert(newCard)
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
