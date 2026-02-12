//
//  SettingsView.swift
//  My Funny Valentine
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var preferences: [UserPreferences]
    
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
    
    var body: some View {
        NavigationStack {
            List {
                // Subscription section
                Section("Subscription") {
                    HStack {
                        Label("Status", systemImage: "crown.fill")
                        Spacer()
                        Text(userPreferences.subscriptionStatus == .premium ? "Premium" : "Free")
                            .foregroundStyle(.secondary)
                    }
                    
                    if userPreferences.subscriptionStatus != .premium {
                        NavigationLink {
                            Text("Upgrade to Premium")
                        } label: {
                            Label("Upgrade", systemImage: "star.fill")
                        }
                    }
                }
                
                // Usage section
                Section("Usage") {
                    HStack {
                        Label("AI Requests", systemImage: "brain.head.profile")
                        Spacer()
                        Text("\(userPreferences.aiRequestsUsed) used")
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Label("Image Generations", systemImage: "photo.artframe")
                        Spacer()
                        Text("\(userPreferences.imageGenerationsUsed) used")
                            .foregroundStyle(.secondary)
                    }
                }
                
                // Sync section
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
                
                // About section
                Section("About") {
                    HStack {
                        Label("Version", systemImage: "info.circle")
                        Spacer()
                        Text("1.0")
                            .foregroundStyle(.secondary)
                    }
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
