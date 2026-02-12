//
//  ConflictResolutionView.swift
//  My Funny Valentine
//
//  Created by Nathan Fennel on 2/12/26.
//

import SwiftUI
import SwiftData

struct ConflictResolutionView: View {
    let card: Card
    let localVersion: Card
    let cloudVersion: Card
    @ObservedObject var syncService: CloudKitSyncService
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedVersion: ConflictVersion = .local
    
    enum ConflictVersion {
        case local
        case cloud
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("This card was edited on multiple devices. Choose which version to keep:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Section("Local Version") {
                    CardConflictPreview(card: localVersion)
                    Button(action: {
                        selectedVersion = .local
                    }) {
                        HStack {
                            Text("Keep Local Version")
                            Spacer()
                            if selectedVersion == .local {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
                
                Section("Cloud Version") {
                    CardConflictPreview(card: cloudVersion)
                    Button(action: {
                        selectedVersion = .cloud
                    }) {
                        HStack {
                            Text("Keep Cloud Version")
                            Spacer()
                            if selectedVersion == .cloud {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
                
                Section {
                    Button(action: resolveConflict) {
                        HStack {
                            Spacer()
                            Text("Resolve Conflict")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Resolve Conflict")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func resolveConflict() {
        Task {
            do {
                // Apply the selected version
                if selectedVersion == .cloud {
                    // Update local card with cloud version data
                    card.templateId = cloudVersion.templateId
                    card.saying = cloudVersion.saying
                    card.customText = cloudVersion.customText
                    card.modifiedAt = cloudVersion.modifiedAt
                    if let cloudLayoutData = cloudVersion.getLayoutData() {
                        card.setLayoutData(cloudLayoutData)
                    }
                } else {
                    // Keep local version, sync it
                    card.updateModifiedDate()
                }
                
                try await syncService.resolveConflict(
                    card: card,
                    resolution: .manual
                )
                
                dismiss()
            } catch {
                // Handle error
                print("Error resolving conflict: \(error)")
            }
        }
    }
}

struct CardConflictPreview: View {
    let card: Card
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let saying = card.saying {
                Text("Saying: \(saying)")
                    .font(.subheadline)
            }
            
            if let customText = card.customText {
                Text("Custom Text: \(customText)")
                    .font(.subheadline)
            }
            
            Text("Modified: \(card.modifiedAt.formatted(date: .abbreviated, time: .shortened))")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    let modelContext = ModelContext(ModelContainer(for: Card.self))
    let card = Card()
    let localCard = Card()
    let cloudCard = Card()
    
    return ConflictResolutionView(
        card: card,
        localVersion: localCard,
        cloudVersion: cloudCard,
        syncService: CloudKitSyncService(modelContext: modelContext)
    )
}
