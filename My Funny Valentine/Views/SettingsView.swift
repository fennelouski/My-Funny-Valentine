//
//  SettingsView.swift
//  My Funny Valentine
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var preferences: [UserPreferences]
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    @State private var syncEnabled: Bool = true
    @State private var syncStatus: String = "Synced"

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
        NavigationStack {
            List {
                Section {
                    HStack(alignment: .firstTextBaseline) {
                        Label("Sayings", systemImage: "sparkles")
                        Spacer()
                        Text(OnDeviceSayingsGenerator.isAvailable ? "On device" : "Built-in")
                            .foregroundStyle(.secondary)
                    }

                    HStack(alignment: .firstTextBaseline) {
                        Label("Artwork", systemImage: "photo.artframe")
                        Spacer()
                        Text(OnDeviceImageGenerator.isSupported ? "On device" : "Unavailable")
                            .foregroundStyle(.secondary)
                    }

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

                Section("iCloud Sync") {
                    Toggle(isOn: $syncEnabled) {
                        Label("Sync Enabled", systemImage: "icloud")
                    }
                    .onChange(of: syncEnabled) { _, newValue in
                        userPreferences.syncEnabled = newValue
                        try? modelContext.save()
                    }

                    HStack {
                        Label("Status", systemImage: "checkmark.icloud")
                        Spacer()
                        Text(syncStatus)
                            .foregroundStyle(.secondary)
                    }
                }

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
            .navigationTitle("Settings")
            .onAppear {
                syncEnabled = userPreferences.syncEnabled
            }
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: UserPreferences.self, inMemory: true)
}
