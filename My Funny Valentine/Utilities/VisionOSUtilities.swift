#if os(visionOS)
import SwiftUI
import SwiftData

struct CardVisionWindow: View {
    let cardID: UUID?

    var body: some View {
        Group {
            if let cardID {
                SavedCardVisionView(cardID: cardID)
            } else {
                ContentUnavailableView("Choose a card", systemImage: "heart.rectangle.stack",
                                       description: Text("Open a saved card from My Cards."))
            }
        }
        .frame(minWidth: 420, minHeight: 660)
    }
}

private struct SavedCardVisionView: View {
    @Query private var cards: [Card]
    @SceneStorage("cardPreview.opening") private var opening = 0.0
    @State private var showingEditor = false
    @Environment(\.dismissWindow) private var dismissWindow
    let cardID: UUID

    init(cardID: UUID) {
        self.cardID = cardID
        _cards = Query(filter: #Predicate<Card> { $0.id == cardID })
    }

    var body: some View {
        Group {
            if let card = cards.first {
                GeometryReader { geometry in
                    let width = max(180, min(geometry.size.width - 64, (geometry.size.height - 110) * 2 / 3))
                    CardStageView(snapshot: CardRenderer.shared.snapshot(of: card),
                                  size: CGSize(width: width, height: width * 1.5), opening: $opening,
                                  motionEnabled: card.getLayoutData()?.composition?.motionEnabled ?? false)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .ornament(attachmentAnchor: .scene(.bottom), contentAlignment: .top) {
                    HStack(spacing: 12) {
                        Button("Edit card", systemImage: "pencil") { showingEditor = true }
                        Button("Close window", systemImage: "xmark") {
                            dismissWindow(id: "card-preview", value: cardID)
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .padding(12)
                    .glassBackgroundEffect(in: Capsule())
                }
                .sheet(isPresented: $showingEditor) {
                    NavigationStack { CardDetailView(card: card) }
                }
            } else {
                ContentUnavailableView("Card no longer available", systemImage: "heart.rectangle.stack",
                                       description: Text("Choose another saved card from My Cards."))
            }
        }
    }
}
#endif
