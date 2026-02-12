//
//  CloudKitService.swift
//  My Funny Valentine
//

import Foundation
import CloudKit

/// Service for CloudKit sync operations
/// Note: SwiftData with CloudKit handles most sync automatically when ModelConfiguration uses cloudKitDatabase
actor CloudKitService {
    static let shared = CloudKitService()
    
    private let container: CKContainer
    private let privateDatabase: CKDatabase
    
    init(containerIdentifier: String = "iCloud.com.nathanfennel.My-Funny-Valentine") {
        self.container = CKContainer(identifier: containerIdentifier)
        self.privateDatabase = container.privateCloudDatabase
    }
    
    /// Check if user is signed into iCloud
    func checkAccountStatus() async throws -> CKAccountStatus {
        try await container.accountStatus()
    }
    
    /// Fetch user record ID (for associating data with user)
    func fetchUserRecordID() async throws -> CKRecord.ID? {
        try await container.userRecordID()
    }
    
    /// Force a sync (SwiftData with CloudKit syncs automatically; this can trigger remote fetch)
    func syncIfNeeded() async {
        // SwiftData + CloudKit handles sync automatically
        // This method can be used to trigger NSPersistentCloudKitContainer events if needed
        // For now, we rely on automatic sync
    }
}
