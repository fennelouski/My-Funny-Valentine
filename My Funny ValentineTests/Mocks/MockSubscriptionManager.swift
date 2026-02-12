//
//  MockSubscriptionManager.swift
//  My Funny ValentineTests
//
//  Created by Nathan Fennel on 2/12/26.
//

import Foundation
import StoreKit
@testable import My_Funny_Valentine

@MainActor
class MockSubscriptionManager: ObservableObject {
    @Published var isPremium: Bool = false
    @Published var subscriptionStatus: SubscriptionStatus = .free
    @Published var subscriptionExpiresAt: Date?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    var purchaseResult: Result<Void, Error>?
    var restoreResult: Result<Void, Error>?
    
    func checkSubscriptionStatus() async {
        isLoading = true
        defer { isLoading = false }
        
        // Simulate async operation
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Use current state
    }
    
    func purchasePremium() async throws {
        isLoading = true
        defer { isLoading = false }
        
        if let result = purchaseResult {
            switch result {
            case .success:
                isPremium = true
                subscriptionStatus = .premium
                subscriptionExpiresAt = Date().addingTimeInterval(30 * 24 * 60 * 60) // 30 days
            case .failure(let error):
                throw error
            }
        } else {
            // Default success
            isPremium = true
            subscriptionStatus = .premium
            subscriptionExpiresAt = Date().addingTimeInterval(30 * 24 * 60 * 60)
        }
    }
    
    func restorePurchases() async throws {
        isLoading = true
        defer { isLoading = false }
        
        if let result = restoreResult {
            switch result {
            case .success:
                await checkSubscriptionStatus()
            case .failure(let error):
                throw error
            }
        } else {
            // Default success
            await checkSubscriptionStatus()
        }
    }
    
    func manageSubscription() {
        // Mock implementation
    }
}
