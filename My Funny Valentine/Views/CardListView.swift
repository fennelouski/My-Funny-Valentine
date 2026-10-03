import SwiftUI
import SwiftData

struct CardListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Card.modifiedAt, order: .reverse) private var cards: [Card]
    @State private var pendingDelete: Card?
    @State private var showingDelete = false
    @State private var errorMessage: String?
    @State private var showingError = false

    var body: some View {
        NavigationStack {
            Group {
                if cards.isEmpty {
                    ContentUnavailableView {
                        Label("Your cards live here", systemImage: "heart.rectangle.stack")
                    } actions: {
                        Button("Choose a card") {
                            NotificationCenter.default.post(name: NSNotification.Name("BrowseStarters"), object: nil)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 144, maximum: 220), spacing: 16)], spacing: 20) {
                            ForEach(cards) { card in
                                NavigationLink {
                                    CardDetailView(card: card)
                                } label: {
                                    GeometryReader { geometry in
                                        CardTileView(card: card, size: geometry.size)
                                    }
                                    .aspectRatio(2.0 / 3.0, contentMode: .fit)
                                }
                                .buttonStyle(.plain)
                                .contextMenu {
                                    Button(role: .destructive) {
                                        pendingDelete = card
                                        showingDelete = true
                                    } label: { Label("Delete", systemImage: "trash") }
                                }
                            }
                        }
                        .padding(20)
                        .frame(maxWidth: 1100)
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .background(Color.appGroupedBackground)
            .navigationTitle("My Cards")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { NotificationCenter.default.post(name: NSNotification.Name("NewCard"), object: nil) } label: { Label("Write a card", systemImage: "square.and.pencil") }
                        .accessibilityIdentifier("library.newCard")
                }
            }
            .confirmationDialog("Delete this card?", isPresented: $showingDelete, titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    guard let card = pendingDelete else { return }
                    modelContext.delete(card)
                    do { try modelContext.save() }
                    catch { modelContext.rollback(); errorMessage = error.localizedDescription; showingError = true }
                    pendingDelete = nil
                }
            }
            .alert("Couldn't delete card", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: { Text(errorMessage ?? "Please try again.") }
        }
    }
}
