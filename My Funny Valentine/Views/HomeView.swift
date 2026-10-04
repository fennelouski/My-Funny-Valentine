import SwiftUI
import SwiftData

struct HomeView: View {
    @Query(sort: \Card.modifiedAt, order: .reverse) private var recentCards: [Card]
    @State private var collection = "all"
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private let collections = [
        ("all", "All cards"), ("pizza", "Comic crush"), ("space", "Cosmic love"),
        ("birds", "Love letters"), ("dino", "Pop-up hearts"), ("disco", "Photo booth"), ("sweets", "Confetti party")
    ]
    private var starters: [CardTemplate] {
        let templates = TemplateManager.shared.getStarterTemplates()
        if collection != "all" {
            return templates.filter { $0.id.hasPrefix("starter_\(collection)_") }
        }
        // Show the range of artwork immediately, then the other messages in each world.
        let groups = collections.dropFirst().map { world in
            templates.filter { $0.id.hasPrefix("starter_\(world.0)_") }
        }
        return (0..<(groups.map(\.count).max() ?? 0)).flatMap { index in
            groups.compactMap { $0.indices.contains(index) ? $0[index] : nil }
        }
    }

    private var writeButton: some View {
        Button { NotificationCenter.default.post(name: NSNotification.Name("NewCard"), object: nil) } label: {
            Label("Write", systemImage: "square.and.pencil")
                .fixedSize(horizontal: true, vertical: true)
                .frame(minHeight: 44)
        }
        .buttonStyle(.bordered)
        .accessibilityIdentifier("home.createCard")
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    if dynamicTypeSize.isAccessibilitySize {
                        VStack(alignment: .leading, spacing: 20) {
                            writeButton
                            Text("Pick a card.\nMake it yours.")
                                .font(.title2.bold())
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    } else {
                        HStack(alignment: .top) {
                            Text("Pick a card.\nMake it yours.")
                                .font(.largeTitle.bold())
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer(minLength: 12)
                            writeButton
                        }
                    }
                    if !recentCards.isEmpty {
                        Text("Your latest").font(.title2.bold())
                        ScrollView(.horizontal) {
                            HStack(spacing: 16) {
                                ForEach(recentCards.prefix(5)) { card in
                                    NavigationLink {
                                        CardDetailView(card: card)
                                    } label: { CardTileView(card: card, size: CGSize(width: 100, height: 150)) }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.bottom, 8)
                        }
                    }

                    Picker("Collection", selection: $collection) {
                        ForEach(collections, id: \.0) { item in
                            Text(item.1).tag(item.0)
                        }
                    }
                    .pickerStyle(.menu)
                    .accessibilityIdentifier("home.collection")

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 144, maximum: 220), spacing: 16)], spacing: 20) {
                        ForEach(starters) { template in
                            StarterCardLink(template: template)
                        }
                    }


                }
                .padding(20)
                .frame(maxWidth: 1100)
                .frame(maxWidth: .infinity)
            }
            .background(Color.appGroupedBackground)
            .navigationTitle("My Funny Valentine")
            .appInlineNavigationTitle()
        }
    }
}

private struct StarterCardLink: View {
    let template: CardTemplate
    @State private var draft: Card

    init(template: CardTemplate) {
        self.template = template
        _draft = State(initialValue: TemplateManager.shared.makeDraft(from: template))
    }

    var body: some View {
        NavigationLink {
            CardDetailView(card: nil, starter: draft)
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                GeometryReader { geometry in
                    CardTileView(card: draft, size: geometry.size)
                }
                .aspectRatio(2.0 / 3.0, contentMode: .fit)
                if let family = draft.getLayoutData()?.composition?.family {
                    Label(family.title, systemImage: family.symbol)
                        .font(.subheadline.bold())
                        .fixedSize(horizontal: false, vertical: true)
                        .foregroundStyle(.primary)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(template.textAreas.first?.defaultText ?? template.name)
        .accessibilityHint("Personalize this card")
        .accessibilityIdentifier("starter.\(template.id)")
    }
}
