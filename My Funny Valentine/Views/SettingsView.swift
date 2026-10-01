//
//  SettingsView.swift
//  My Funny Valentine
//

import SwiftUI
import SwiftData

enum SettingsSection: String, CaseIterable, Identifiable {
    case generation, iCloud, about

    var id: Self { self }
    var sidebarTag: Int {
        switch self {
        case .generation: 2
        case .iCloud: 3
        case .about: 4
        }
    }
    var title: LocalizedStringKey {
        switch self {
        case .generation: "Generation"
        case .iCloud: "iCloud Sync"
        case .about: "About"
        }
    }
    var symbol: String {
        switch self {
        case .generation: "sparkles"
        case .iCloud: "icloud"
        case .about: "info.circle"
        }
    }
    var tint: Color {
        switch self {
        case .generation: .pink
        case .iCloud: .blue
        case .about: .purple
        }
    }
}

struct SettingsSectionLabel: View {
    let section: SettingsSection
    let isSelected: Bool

    var body: some View {
        if isSelected {
            Label(section.title, systemImage: section.symbol)
                .fixedSize(horizontal: false, vertical: true)
        } else {
            Label {
                Text(section.title)
                    .fixedSize(horizontal: false, vertical: true)
            } icon: {
                Image(systemName: section.symbol)
                    .foregroundStyle(section.tint)
            }
        }
    }
}

struct SettingsView: View {
    /// macOS borrows the app's existing sidebar; the Settings tab owns navigation elsewhere.
    var section: SettingsSection? = nil
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Query private var preferences: [UserPreferences]
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    @State private var selectedSection: SettingsSection? = .generation
    @State private var preferredCompactColumn: NavigationSplitViewColumn = .sidebar
    @State private var syncEnabled: Bool = true
    @State private var sampleCard = Card(saying: "You're my favorite person.")

    private var activeSection: SettingsSection { section ?? selectedSection ?? .generation }

    private var userPreferences: UserPreferences {
        if let prefs = preferences.first {
            return prefs
        }
        let prefs = UserPreferences()
        modelContext.insert(prefs)
        return prefs
    }

    private var appVersion: String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = info?["CFBundleVersion"] as? String ?? "1"
        return "\(short) (\(build))"
    }

    var body: some View {
        Group {
            if section != nil {
                detail
            } else {
                NavigationSplitView(preferredCompactColumn: $preferredCompactColumn) {
                    List(SettingsSection.allCases, selection: $selectedSection) { section in
                        NavigationLink(value: section) {
                            SettingsSectionLabel(section: section, isSelected: selectedSection == section)
                        }
                        .accessibilityIdentifier("settings.section.\(section.rawValue)")
                    }
                    .navigationTitle("Settings")
                    .navigationSplitViewColumnWidth(
                        min: dynamicTypeSize.isAccessibilitySize ? 360 : 220,
                        ideal: dynamicTypeSize.isAccessibilitySize ? 420 : 260,
                        max: dynamicTypeSize.isAccessibilitySize ? 460 : .infinity
                    )
                } detail: {
                    detail
                }
                .navigationSplitViewStyle(.balanced)
            }
        }
        .onAppear {
            syncEnabled = userPreferences.syncEnabled
        }
    }

    private var detail: some View {
        Form {
            switch activeSection {
            case .generation:
                Section("Card sample") {
                    CardTileView(card: sampleCard, size: CGSize(width: 180, height: 240))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .accessibilityIdentifier("settings.cardSample")
                }

                Section {
                    generationStatus("Sayings", symbol: "sparkles", value: OnDeviceSayingsGenerator.isAvailable ? "On device" : "Built-in")
                    generationStatus("Artwork", symbol: "photo.artframe", value: OnDeviceImageGenerator.isSupported ? "On device" : "Unavailable")

                    if let reason = OnDeviceSayingsGenerator.unavailableReason {
                        Text(reason)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Generation")
                } footer: {
                    Text("Cards are generated on your device. Nothing you type or photograph is sent anywhere.")
                }
            case .iCloud:
                Section("iCloud Sync") {
                    Toggle(isOn: $syncEnabled) {
                        Label("Sync Enabled", systemImage: "icloud")
                    }
                    .accessibilityIdentifier("settings.syncEnabled")
                    .onChange(of: syncEnabled) { _, newValue in
                        userPreferences.syncEnabled = newValue
                        try? modelContext.save()
                    }
                }
            case .about:
                Section("About") {
                    HStack {
                        Label("Version", systemImage: "info.circle")
                        Spacer()
                        Text(appVersion)
                            .foregroundStyle(.secondary)
                    }

                    Button {
                        hasCompletedOnboarding = false
                    } label: {
                        Label("Show Welcome Again", systemImage: "sparkles.rectangle.stack")
                    }
                    .accessibilityIdentifier("settings.replayOnboarding")
                }
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .frame(maxWidth: 760)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            LinearGradient(
                colors: [activeSection.tint.opacity(0.10), .clear],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .background(Color.appGroupedBackground)
        }
        .navigationTitle(activeSection.title)
        .appInlineNavigationTitle()
    }

    @ViewBuilder
    private func generationStatus(_ title: LocalizedStringKey, symbol: String, value: LocalizedStringKey) -> some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 8) {
                Label(title, systemImage: symbol)
                Text(value).foregroundStyle(.secondary)
            }
        } else {
            HStack(alignment: .firstTextBaseline) {
                Label(title, systemImage: symbol)
                Spacer()
                Text(value).foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [Card.self, UserPreferences.self], inMemory: true)
}
