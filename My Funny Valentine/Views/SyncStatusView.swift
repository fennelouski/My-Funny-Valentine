//
//  SyncStatusView.swift
//  My Funny Valentine
//
//  Created by Nathan Fennel on 2/12/26.
//

import SwiftUI
import SwiftData

struct SyncStatusView: View {
    @ObservedObject var syncService: CloudKitSyncService
    
    var body: some View {
        HStack(spacing: 8) {
            statusIcon
            statusText
        }
        .font(.caption)
        .foregroundColor(statusColor)
    }
    
    @ViewBuilder
    private var statusIcon: some View {
        switch syncService.syncStatus {
        case .idle:
            Image(systemName: "icloud")
                .foregroundColor(.secondary)
        case .syncing:
            ProgressView()
                .scaleEffect(0.7)
        case .synced:
            Image(systemName: "checkmark.icloud.fill")
                .foregroundColor(.green)
        case .offline:
            Image(systemName: "wifi.slash")
                .foregroundColor(.orange)
        case .error:
            Image(systemName: "exclamationmark.icloud.fill")
                .foregroundColor(.red)
        }
    }
    
    private var statusText: some View {
        Group {
            switch syncService.syncStatus {
            case .idle:
                Text("Ready to sync")
            case .syncing:
                Text("Syncing...")
            case .synced:
                if let lastSync = syncService.lastSyncDate {
                    Text("Synced \(formatDate(lastSync))")
                } else {
                    Text("Synced")
                }
            case .offline:
                Text("Offline")
            case .error(let error):
                Text(error.localizedDescription)
            }
        }
    }
    
    private var statusColor: Color {
        switch syncService.syncStatus {
        case .idle:
            return .secondary
        case .syncing:
            return .blue
        case .synced:
            return .green
        case .offline:
            return .orange
        case .error:
            return .red
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// Compact version for use in navigation bars
struct SyncStatusBadge: View {
    @ObservedObject var syncService: CloudKitSyncService
    
    var body: some View {
        Button(action: {
            // Could navigate to sync settings
        }) {
            Group {
                switch syncService.syncStatus {
                case .idle:
                    Image(systemName: "icloud")
                case .syncing:
                    ProgressView()
                        .scaleEffect(0.6)
                case .synced:
                    Image(systemName: "checkmark.icloud.fill")
                        .foregroundColor(.green)
                case .offline:
                    Image(systemName: "wifi.slash")
                        .foregroundColor(.orange)
                case .error:
                    Image(systemName: "exclamationmark.icloud.fill")
                        .foregroundColor(.red)
                }
            }
            .font(.caption)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        SyncStatusView(syncService: CloudKitSyncService(modelContext: ModelContext(ModelContainer(for: Card.self))))
    }
    .padding()
}
