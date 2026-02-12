//
//  CloudKitSyncService.swift
//  My Funny Valentine
//
//  Created by Nathan Fennel on 2/12/26.
//

import Foundation
import CloudKit
import SwiftData
import Combine
import Network
import UIKit

enum SyncStatus {
    case idle
    case syncing
    case synced
    case error(SyncError)
    case offline
}

enum ConflictResolutionStrategy: String, CaseIterable {
    case lastWriteWins
    case manual
    case merge
}

enum SyncError: LocalizedError {
    case networkError
    case authenticationError
    case quotaExceeded
    case conflictDetected(Card)
    case corruptionError
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .networkError:
            return "Network error. Please check your connection."
        case .authenticationError:
            return "Please sign in to iCloud to sync your data."
        case .quotaExceeded:
            return "iCloud storage quota exceeded. Please free up space."
        case .conflictDetected:
            return "Conflict detected. Please resolve manually."
        case .corruptionError:
            return "Data corruption detected. Please contact support."
        case .unknown(let error):
            return "Sync error: \(error.localizedDescription)"
        }
    }
}

@MainActor
class CloudKitSyncService: ObservableObject {
    @Published var syncStatus: SyncStatus = .idle
    @Published var lastSyncDate: Date?
    @Published var isOnline: Bool = true
    
    private let container: CKContainer
    private let modelContext: ModelContext
    private var syncTask: Task<Void, Never>?
    private var networkMonitor: NetworkMonitor?
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.container = CKContainer(identifier: "iCloud.com.nathanfennel.My-Funny-Valentine")
        
        // Monitor network status
        self.networkMonitor = NetworkMonitor { [weak self] isOnline in
            Task { @MainActor in
                self?.isOnline = isOnline
                if isOnline && self?.syncStatus == .offline {
                    self?.syncStatus = .idle
                    self?.sync()
                } else if !isOnline {
                    self?.syncStatus = .offline
                }
            }
        }
        
        // Check initial sync status
        checkAccountStatus()
    }
    
    // MARK: - Account Status
    
    func checkAccountStatus() {
        Task {
            do {
                let status = try await container.accountStatus()
                switch status {
                case .available:
                    await sync()
                case .noAccount:
                    syncStatus = .error(.authenticationError)
                case .restricted:
                    syncStatus = .error(.authenticationError)
                case .couldNotDetermine:
                    syncStatus = .error(.authenticationError)
                case .temporarilyUnavailable:
                    syncStatus = .offline
                @unknown default:
                    syncStatus = .error(.authenticationError)
                }
            } catch {
                syncStatus = .error(.unknown(error))
            }
        }
    }
    
    // MARK: - Sync Operations
    
    func sync() {
        guard case .idle = syncStatus else { return }
        guard isOnline else {
            syncStatus = .offline
            return
        }
        
        syncTask?.cancel()
        syncTask = Task {
            await performSync()
        }
    }
    
    private func performSync() async {
        syncStatus = .syncing
        
        do {
            // Check account status first
            let accountStatus = try await container.accountStatus()
            guard accountStatus == .available else {
                syncStatus = .error(.authenticationError)
                return
            }
            
            // Perform sync operations
            try await syncCards()
            try await syncFaceImages()
            try await syncCardImages()
            try await syncUserPreferences()
            
            // Update sync status
            lastSyncDate = Date()
            syncStatus = .synced
            
            // Schedule next sync check
            Task {
                try? await Task.sleep(nanoseconds: 30_000_000_000) // 30 seconds
                if case .synced = syncStatus {
                    syncStatus = .idle
                }
            }
            
        } catch let error as CKError {
            handleCloudKitError(error)
        } catch {
            syncStatus = .error(.unknown(error))
        }
    }
    
    // MARK: - Sync Individual Data Types
    
    private func syncCards() async throws {
        let descriptor = FetchDescriptor<Card>(
            predicate: #Predicate<Card> { !$0.syncedToCloud }
        )
        
        let unsyncedCards = try modelContext.fetch(descriptor)
        
        for card in unsyncedCards {
            try await syncCard(card)
        }
    }
    
    private func syncCard(_ card: Card) async throws {
        let database = container.privateCloudDatabase
        let recordID = CKRecord.ID(recordName: card.id.uuidString)
        
        do {
            // Try to fetch existing record
            let existingRecord = try await database.record(for: recordID)
            
            // Check for conflicts
            if let existingModified = existingRecord.modificationDate,
               card.modifiedAt > existingModified {
                // Local is newer, update CloudKit
                try await updateCardRecord(card, in: database, recordID: recordID)
            } else {
                // CloudKit is newer or same, check if we need to resolve conflict
                if let existingModified = existingRecord.modificationDate,
                   abs(card.modifiedAt.timeIntervalSince(existingModified)) > 1.0 {
                    throw SyncError.conflictDetected(card)
                }
            }
        } catch let error as CKError where error.code == .unknownItem {
            // Record doesn't exist, create it
            try await createCardRecord(card, in: database, recordID: recordID)
        }
        
        card.syncedToCloud = true
        try modelContext.save()
    }
    
    private func createCardRecord(_ card: Card, in database: CKDatabase, recordID: CKRecord.ID) async throws {
        let record = CKRecord(recordType: "Card", recordID: recordID)
        record["id"] = card.id.uuidString
        record["templateId"] = card.templateId
        record["saying"] = card.saying
        record["customText"] = card.customText
        record["createdAt"] = card.createdAt
        record["modifiedAt"] = card.modifiedAt
        
        if let layoutData = card.layoutData {
            record["layoutData"] = layoutData
        }
        
        _ = try await database.save(record)
    }
    
    private func updateCardRecord(_ card: Card, in database: CKDatabase, recordID: CKRecord.ID) async throws {
        let record = try await database.record(for: recordID)
        record["templateId"] = card.templateId
        record["saying"] = card.saying
        record["customText"] = card.customText
        record["modifiedAt"] = card.modifiedAt
        
        if let layoutData = card.layoutData {
            record["layoutData"] = layoutData
        }
        
        _ = try await database.save(record)
    }
    
    private func syncFaceImages() async throws {
        let descriptor = FetchDescriptor<FaceImage>(
            predicate: #Predicate<FaceImage> { !$0.syncedToCloud }
        )
        
        let unsyncedImages = try modelContext.fetch(descriptor)
        
        for image in unsyncedImages {
            try await syncFaceImage(image)
        }
    }
    
    private func syncFaceImage(_ image: FaceImage) async throws {
        let database = container.privateCloudDatabase
        let recordID = CKRecord.ID(recordName: image.id.uuidString)
        
        let record = CKRecord(recordType: "FaceImage", recordID: recordID)
        record["id"] = image.id.uuidString
        record["cardId"] = image.cardId.uuidString
        record["detectedAt"] = image.detectedAt
        record["position"] = ["x": image.position.x, "y": image.position.y]
        record["size"] = ["width": image.size.width, "height": image.size.height]
        
        // Upload image asset (compress if needed)
        if let imageData = image.imageData {
            let compressedData = compressImage(imageData) ?? imageData
            let asset = CKAsset(fileURL: try saveTemporaryAsset(data: compressedData, filename: "\(image.id).jpg"))
            record["imageData"] = asset
        }
        
        // Generate thumbnail if not already present
        var thumbnailData = image.thumbnailData
        if thumbnailData == nil, let imageData = image.imageData {
            thumbnailData = generateThumbnail(from: imageData)
        }
        
        if let thumbnailData = thumbnailData {
            let thumbnailAsset = CKAsset(fileURL: try saveTemporaryAsset(data: thumbnailData, filename: "\(image.id)_thumb.jpg"))
            record["thumbnailData"] = thumbnailAsset
        }
        
        _ = try await database.save(record)
        image.syncedToCloud = true
        try modelContext.save()
    }
    
    private func syncCardImages() async throws {
        let descriptor = FetchDescriptor<CardImage>(
            predicate: #Predicate<CardImage> { !$0.syncedToCloud }
        )
        
        let unsyncedImages = try modelContext.fetch(descriptor)
        
        for image in unsyncedImages {
            try await syncCardImage(image)
        }
    }
    
    private func syncCardImage(_ image: CardImage) async throws {
        let database = container.privateCloudDatabase
        let recordID = CKRecord.ID(recordName: image.id.uuidString)
        
        let record = CKRecord(recordType: "CardImage", recordID: recordID)
        record["id"] = image.id.uuidString
        record["cardId"] = image.cardId.uuidString
        record["source"] = image.source.rawValue
        record["position"] = ["x": image.position.x, "y": image.position.y]
        record["size"] = ["width": image.size.width, "height": image.size.height]
        record["rotation"] = image.rotation
        
        // Upload image asset (compress if needed)
        if let imageData = image.imageData {
            let compressedData = compressImage(imageData) ?? imageData
            let asset = CKAsset(fileURL: try saveTemporaryAsset(data: compressedData, filename: "\(image.id).jpg"))
            record["imageData"] = asset
        }
        
        // Generate thumbnail if not already present
        var thumbnailData = image.thumbnailData
        if thumbnailData == nil, let imageData = image.imageData {
            thumbnailData = generateThumbnail(from: imageData)
        }
        
        if let thumbnailData = thumbnailData {
            let thumbnailAsset = CKAsset(fileURL: try saveTemporaryAsset(data: thumbnailData, filename: "\(image.id)_thumb.jpg"))
            record["thumbnailData"] = thumbnailAsset
        }
        
        _ = try await database.save(record)
        image.syncedToCloud = true
        try modelContext.save()
    }
    
    private func syncUserPreferences() async throws {
        let descriptor = FetchDescriptor<UserPreferences>()
        let preferences = try modelContext.fetch(descriptor).first
        
        guard let prefs = preferences else { return }
        
        let database = container.privateCloudDatabase
        let recordID = CKRecord.ID(recordName: prefs.userId)
        
        let record = CKRecord(recordType: "UserPreferences", recordID: recordID)
        record["userId"] = prefs.userId
        record["subscriptionStatus"] = prefs.subscriptionStatus.rawValue
        record["aiRequestsUsed"] = prefs.aiRequestsUsed
        record["imageGenerationsUsed"] = prefs.imageGenerationsUsed
        record["lastResetDate"] = prefs.lastResetDate
        record["syncEnabled"] = prefs.syncEnabled
        record["conflictResolutionStrategy"] = prefs.conflictResolutionStrategy.rawValue
        
        _ = try await database.save(record)
    }
    
    // MARK: - Asset Handling
    
    private func saveTemporaryAsset(data: Data, filename: String) throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(filename)
        try data.write(to: fileURL)
        return fileURL
    }
    
    // Compress image data before uploading to reduce storage usage
    private func compressImage(_ imageData: Data, maxSizeKB: Int = 500) -> Data? {
        guard let image = UIImage(data: imageData) else { return nil }
        
        var compression: CGFloat = 0.8
        var compressedData = image.jpegData(compressionQuality: compression)
        
        // Reduce quality until under max size
        while let data = compressedData,
              data.count > maxSizeKB * 1024,
              compression > 0.1 {
            compression -= 0.1
            compressedData = image.jpegData(compressionQuality: compression)
        }
        
        return compressedData ?? imageData
    }
    
    // Generate thumbnail for faster loading
    private func generateThumbnail(from imageData: Data, maxDimension: CGFloat = 200) -> Data? {
        guard let image = UIImage(data: imageData) else { return nil }
        
        let size = image.size
        let aspectRatio = size.width / size.height
        var thumbnailSize: CGSize
        
        if size.width > size.height {
            thumbnailSize = CGSize(width: maxDimension, height: maxDimension / aspectRatio)
        } else {
            thumbnailSize = CGSize(width: maxDimension * aspectRatio, height: maxDimension)
        }
        
        UIGraphicsBeginImageContextWithOptions(thumbnailSize, false, 0.0)
        defer { UIGraphicsEndImageContext() }
        
        image.draw(in: CGRect(origin: .zero, size: thumbnailSize))
        let thumbnail = UIGraphicsGetImageFromCurrentImageContext()
        
        return thumbnail?.jpegData(compressionQuality: 0.7)
    }
    
    // MARK: - Error Handling
    
    private func handleCloudKitError(_ error: CKError) {
        switch error.code {
        case .networkUnavailable, .networkFailure:
            syncStatus = .offline
        case .notAuthenticated, .permissionFailure:
            syncStatus = .error(.authenticationError)
        case .quotaExceeded:
            syncStatus = .error(.quotaExceeded)
        case .serverRecordChanged:
            syncStatus = .error(.conflictDetected(Card())) // Will be handled by conflict resolution
        case .corruptedRecord:
            syncStatus = .error(.corruptionError)
        default:
            syncStatus = .error(.unknown(error))
        }
    }
    
    // MARK: - Conflict Resolution
    
    func resolveConflict(card: Card, resolution: ConflictResolutionStrategy) async throws {
        // Implementation for conflict resolution
        // This will be called from ConflictResolutionView
        try await syncCard(card)
    }
}

// MARK: - Network Monitor

class NetworkMonitor {
    private var monitor: NWPathMonitor?
    private var queue: DispatchQueue?
    var onStatusChange: ((Bool) -> Void)?
    
    init(onStatusChange: @escaping (Bool) -> Void) {
        self.onStatusChange = onStatusChange
        
        monitor = NWPathMonitor()
        queue = DispatchQueue(label: "NetworkMonitor")
        
        monitor?.pathUpdateHandler = { [weak self] path in
            let isOnline = path.status == .satisfied
            DispatchQueue.main.async {
                self?.onStatusChange?(isOnline)
            }
        }
        
        monitor?.start(queue: queue!)
    }
    
    deinit {
        monitor?.cancel()
    }
}
