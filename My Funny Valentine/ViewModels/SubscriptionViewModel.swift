//
//  SubscriptionViewModel.swift
//  My Funny Valentine
//

import Foundation
import SwiftUI

@MainActor
@Observable
class SubscriptionViewModel {
    var isPremium: Bool = false
    var isLoading: Bool = false
    var errorMessage: String?
    var remainingAIRequests: Int = 3
    var remainingImageGenerations: Int = 0
    
    private let subscriptionManager = SubscriptionManager.shared
    
    init() {
        isPremium = subscriptionManager.isPremium
    }
    
    func loadStatus() async {
        await subscriptionManager.checkSubscriptionStatus()
        isPremium = subscriptionManager.isPremium
        errorMessage = subscriptionManager.errorMessage
        isLoading = subscriptionManager.isLoading
        
        // Update usage limits based on subscription
        if isPremium {
            remainingAIRequests = 20
            remainingImageGenerations = 10
        } else {
            remainingAIRequests = 3
            remainingImageGenerations = 0
        }
    }
    
    func purchase() async {
        isLoading = true
        errorMessage = nil
        do {
            try await subscriptionManager.purchasePremium()
            await loadStatus()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    func restorePurchases() async {
        do {
            try await subscriptionManager.restorePurchases()
        } catch {
            errorMessage = error.localizedDescription
        }
        await loadStatus()
    }
}
