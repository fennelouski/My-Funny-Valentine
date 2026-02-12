//
//  SubscriptionManager.swift
//  My Funny Valentine
//
//  Created by Nathan Fennel on 2/12/26.
//

import Foundation
import StoreKit
import SwiftData
import UIKit
import Combine

@MainActor
class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()
    
    @Published var isPremium: Bool = false
    @Published var subscriptionStatus: SubscriptionStatus = .free
    @Published var subscriptionExpiresAt: Date?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let productId = "com.nathanfennel.My-Funny-Valentine.premium"
    private var updateListenerTask: Task<Void, Never>?
    private var modelContext: ModelContext?
    
    private init() {
        // Start listening for transaction updates
        updateListenerTask = listenForTransactions()
        
        // Check subscription status on init
        Task {
            await checkSubscriptionStatus()
        }
    }
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }
    
    // MARK: - Subscription Status
    
    func checkSubscriptionStatus() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Check current entitlements
            for await result in Transaction.currentEntitlements {
                if case .verified(let transaction) = result {
                    if transaction.productID == productId {
                        // Check if subscription is still valid
                        if let expirationDate = transaction.expirationDate {
                            if expirationDate > Date() {
                                await updateSubscriptionStatus(.premium, expiresAt: expirationDate)
                                return
                            } else {
                                await updateSubscriptionStatus(.expired, expiresAt: expirationDate)
                                return
                            }
                        } else {
                            // Non-expiring subscription (shouldn't happen for monthly)
                            await updateSubscriptionStatus(.premium, expiresAt: nil)
                            return
                        }
                    }
                }
            }
            
            // No active subscription found
            await updateSubscriptionStatus(.free, expiresAt: nil)
        } catch {
            print("Error checking subscription status: \(error)")
            errorMessage = "Failed to check subscription status"
        }
    }
    
    private func updateSubscriptionStatus(_ status: SubscriptionStatus, expiresAt: Date?) async {
        subscriptionStatus = status
        subscriptionExpiresAt = expiresAt
        isPremium = status == .premium && (expiresAt == nil || expiresAt! > Date())
        
        // Update UserPreferences model
        await updateUserPreferences(status: status, expiresAt: expiresAt)
    }
    
    private func updateUserPreferences(status: SubscriptionStatus, expiresAt: Date?) async {
        guard let modelContext = modelContext else { return }
        
        let descriptor = FetchDescriptor<UserPreferences>(
            predicate: #Predicate { _ in true },
            sortBy: [SortDescriptor(\.userId)]
        )
        
        do {
            let preferences = try modelContext.fetch(descriptor)
            let userPrefs: UserPreferences
            
            if let existing = preferences.first {
                userPrefs = existing
            } else {
                userPrefs = UserPreferences()
                modelContext.insert(userPrefs)
            }
            
            userPrefs.status = status
            userPrefs.subscriptionExpiresAt = expiresAt
            
            try modelContext.save()
        } catch {
            print("Error updating UserPreferences: \(error)")
        }
    }
    
    // MARK: - Purchase Flow
    
    func purchasePremium() async throws {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Load products
            let products = try await Product.products(for: [productId])
            
            guard let product = products.first else {
                throw SubscriptionError.productNotFound
            }
            
            // Purchase the product
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    // Transaction verified, update subscription status
                    await transaction.finish()
                    await checkSubscriptionStatus()
                case .unverified(_, let error):
                    throw SubscriptionError.verificationFailed(error)
                }
            case .userCancelled:
                throw SubscriptionError.userCancelled
            case .pending:
                throw SubscriptionError.pending
            @unknown default:
                throw SubscriptionError.unknown
            }
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    // MARK: - Restore Purchases
    
    func restorePurchases() async throws {
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await AppStore.sync()
            await checkSubscriptionStatus()
        } catch {
            errorMessage = "Failed to restore purchases: \(error.localizedDescription)"
            throw error
        }
    }
    
    // MARK: - Manage Subscription
    
    func manageSubscription() {
        if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
            Task {
                await UIApplication.shared.open(url)
            }
        }
    }
    
    // MARK: - Transaction Listener
    
    private func listenForTransactions() -> Task<Void, Never> {
        return Task.detached { [weak self] in
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    if transaction.productID == self?.productId {
                        await self?.checkSubscriptionStatus()
                        await transaction.finish()
                    } else {
                        await transaction.finish()
                    }
                }
            }
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
}

// MARK: - Subscription Errors

enum SubscriptionError: LocalizedError {
    case productNotFound
    case userCancelled
    case pending
    case verificationFailed(Error)
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .productNotFound:
            return "Subscription product not found. Please try again later."
        case .userCancelled:
            return "Purchase was cancelled."
        case .pending:
            return "Purchase is pending approval."
        case .verificationFailed(let error):
            return "Failed to verify purchase: \(error.localizedDescription)"
        case .unknown:
            return "An unknown error occurred."
        }
    }
}
