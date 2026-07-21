//
//  HomeView.swift
//  My Funny Valentine
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Card.modifiedAt, order: .reverse) private var recentCards: [Card]

    @State private var showingFaceImport = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    welcomeSection
                    actionsSection

                    if recentCards.isEmpty {
                        emptyHint
                    } else {
                        recentCardsSection
                    }

                    Spacer(minLength: 40)
                }
                .padding(.vertical, 20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationDestination(for: Card.self) { card in
                CardDetailView(card: card)
            }
            .sheet(isPresented: $showingFaceImport) {
                FaceImportView()
            }
        }
    }

    private var welcomeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("My Funny Valentine")
                .font(.largeTitle)
                .fontWeight(.bold)
            Text("Create personalized Valentine's cards with AI")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal)
    }

    private var actionsSection: some View {
        VStack(spacing: 12) {
            NavigationLink {
                CardDetailView(card: nil)
            } label: {
                actionRow(
                    icon: "sparkles",
                    title: "Create a Card",
                    subtitle: "Write your own, or let AI suggest a saying",
                    prominent: true
                )
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("home.createCard")

            Button {
                showingFaceImport = true
            } label: {
                actionRow(
                    icon: "person.crop.square",
                    title: "Make Cards from a Photo",
                    subtitle: "Detect a face and build cards automatically",
                    prominent: false
                )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal)
    }

    private func actionRow(icon: String, title: String, subtitle: String, prominent: Bool) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(prominent ? .white.opacity(0.85) : Color.secondary)
                    .multilineTextAlignment(.leading)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(prominent ? .white.opacity(0.7) : Color.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            if prominent {
                LinearGradient(
                    colors: [
                        Color(red: 1, green: 0.4, blue: 0.5),
                        Color(red: 0.9, green: 0.2, blue: 0.4)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else {
                Color(.secondarySystemGroupedBackground)
            }
        }
        .foregroundStyle(prominent ? AnyShapeStyle(.white) : AnyShapeStyle(Color.primary))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var emptyHint: some View {
        VStack(spacing: 8) {
            Image(systemName: "heart.rectangle.stack")
                .font(.system(size: 40))
                .foregroundStyle(.pink.opacity(0.7))
            Text("No cards yet")
                .font(.headline)
            Text("Your cards will show up here once you make one.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .padding(.horizontal)
    }

    private var recentCardsSection: some View {
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
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

#Preview {
    HomeView()
        .modelContainer(for: Card.self, inMemory: true)
}
