//
//  SyncSettingsView.swift
//  My Funny Valentine
//
//  Created by Nathan Fennel on 2/12/26.
//

import SwiftUI
import SwiftData

struct SyncSettingsView: View {
    @ObservedObject var syncService: CloudKitSyncService
    @Environment(\.modelContext) private var modelContext
    @Query private var preferences: [UserPreferences]
    
    @State private var syncEnabled: Bool = true
    @State private var conflictResolution: ConflictResolutionStrategy = .lastWriteWins
    @State private var showingManualSync = false
    
    var userPreferences: UserPreferences? {
        preferences.first
    }
    
    var body: some View {
        Form {
            Section {
                SyncStatusView(syncService: syncService)
                
                if let lastSync = syncService.lastSyncDate {
                    HStack {
                        Text("Last Sync")
                        Spacer()
                        Text(lastSync.formatted(date: .abbreviated, time: .shortened))
                            .foregroundColor(.secondary)
                    }
                }
            } header: {
                Text("Sync Status")
            }
            
            Section {
                Toggle("Enable iCloud Sync", isOn: $syncEnabled)
                    .onChange(of: syncEnabled) { oldValue, newValue in
                        updateSyncEnabled(newValue)
                    }
                
                Button(action: {
                    syncService.sync()
                    showingManualSync = true
                }) {
                    HStack {
                        Text("Sync Now")
                        Spacer()
                        if case .syncing = syncService.syncStatus {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                    }
                }
                .disabled(!syncEnabled || {
                    if case .syncing = syncService.syncStatus { return true }
                    return false
                }())
            } header: {
                Text("Sync Options")
            } footer: {
                Text("When enabled, your cards will automatically sync across all your devices.")
            }
            
            Section {
                Picker("Conflict Resolution", selection: $conflictResolution) {
                    Text("Last Write Wins").tag(ConflictResolutionStrategy.lastWriteWins)
                    Text("Manual Resolution").tag(ConflictResolutionStrategy.manual)
                    Text("Merge Changes").tag(ConflictResolutionStrategy.merge)
                }
                .onChange(of: conflictResolution) { oldValue, newValue in
                    updateConflictResolution(newValue)
                }
            } header: {
                Text("Conflict Resolution")
            } footer: {
                Text("Choose how to handle conflicts when the same card is edited on multiple devices.")
            }
            
            Section {
                if case .error(let error) = syncService.syncStatus {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Sync Error", systemImage: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                        Text(error.localizedDescription)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Button("Retry Sync") {
                            syncService.sync()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding(.vertical, 4)
                }
            } header: {
                Text("Troubleshooting")
            }
            
            Section {
                HStack {
                    Text("Storage Usage")
                    Spacer()
                    Text("Calculating...")
                        .foregroundColor(.secondary)
                }
                
                // Note: CloudKit storage usage requires additional API calls
                // This is a placeholder for future implementation
            } header: {
                Text("Storage")
            } footer: {
                Text("iCloud provides 1GB of free storage. Your cards use approximately 100KB each.")
            }
        }
        .navigationTitle("iCloud Sync")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Syncing", isPresented: $showingManualSync) {
            Button("OK") { }
        } message: {
            Text("Your data is being synced. This may take a few moments.")
        }
        .onAppear {
            loadPreferences()
        }
    }
    
    private func loadPreferences() {
        if let prefs = userPreferences {
            syncEnabled = prefs.syncEnabled
            conflictResolution = prefs.conflictResolutionStrategy
        }
    }
    
    private func updateSyncEnabled(_ enabled: Bool) {
        if let prefs = userPreferences {
            prefs.syncEnabled = enabled
            try? modelContext.save()
        } else {
            // Create new preferences if they don't exist
            let newPrefs = UserPreferences(
                userId: UUID().uuidString,
                syncEnabled: enabled
            )
            modelContext.insert(newPrefs)
            try? modelContext.save()
        }
        
        if enabled {
            syncService.sync()
        }
    }
    
    private func updateConflictResolution(_ strategy: ConflictResolutionStrategy) {
        if let prefs = userPreferences {
            prefs.conflictResolutionStrategy = strategy
            try? modelContext.save()
        }
    }
}

#Preview {
    NavigationStack {
        SyncSettingsView(
            syncService: CloudKitSyncService(
                modelContext: ModelContext(ModelContainer(for: UserPreferences.self))
            )
        )
    }
}
