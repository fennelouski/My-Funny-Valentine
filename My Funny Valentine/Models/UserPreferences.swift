//
//  UserPreferences.swift
//  My Funny Valentine
//

import Foundation
import SwiftData

private let freeDailyAILimit = 3
private let premiumMonthlyAILimit = 20
private let premiumMonthlyImageLimit = 10

@Model
final class UserPreferences {
    @Attribute(.unique) var userId: String
    var subscriptionStatusRawValue: String
    var subscriptionExpiresAt: Date?
    var aiRequestsUsed: Int
    var imageGenerationsUsed: Int
    var lastResetDate: Date
    var syncEnabled: Bool
    var conflictResolutionStrategyRawValue: String = ConflictResolutionStrategy.lastWriteWins.rawValue

    var subscriptionStatus: SubscriptionStatus {
        get { SubscriptionStatus(rawValue: subscriptionStatusRawValue) ?? .free }
        set { subscriptionStatusRawValue = newValue.rawValue }
    }

    var conflictResolutionStrategy: ConflictResolutionStrategy {
        get { ConflictResolutionStrategy(rawValue: conflictResolutionStrategyRawValue) ?? .lastWriteWins }
        set { conflictResolutionStrategyRawValue = newValue.rawValue }
    }
    
    var isPremium: Bool {
        subscriptionStatus == .premium && (subscriptionExpiresAt == nil || (subscriptionExpiresAt ?? .distantPast) > Date())
    }
    
    var remainingAIRequests: Int {
        max(0, effectiveAILimit - aiRequestsUsed)
    }
    
    var remainingImageGenerations: Int {
        guard isPremium else { return 0 }
        return max(0, premiumMonthlyImageLimit - imageGenerationsUsed)
    }
    
    private var effectiveAILimit: Int {
        if isPremium { return premiumMonthlyAILimit }
        return freeDailyAILimit
    }
    
    var aiRequestLimit: Int { effectiveAILimit }
    var imageGenerationLimit: Int { isPremium ? premiumMonthlyImageLimit : 0 }
    
    init(
        userId: String = "default",
        subscriptionStatus: SubscriptionStatus = .free,
        subscriptionExpiresAt: Date? = nil,
        aiRequestsUsed: Int = 0,
        imageGenerationsUsed: Int = 0,
        lastResetDate: Date = Date(),
        syncEnabled: Bool = true
    ) {
        self.userId = userId
        self.subscriptionStatusRawValue = subscriptionStatus.rawValue
        self.subscriptionExpiresAt = subscriptionExpiresAt
        self.aiRequestsUsed = aiRequestsUsed
        self.imageGenerationsUsed = imageGenerationsUsed
        self.lastResetDate = lastResetDate
        self.syncEnabled = syncEnabled
    }
    
    func resetUsageIfNeeded() {
        let calendar = Calendar.current
        let now = Date()
        if isPremium {
            if let nextReset = calendar.date(byAdding: .month, value: 1, to: lastResetDate), now >= nextReset {
                aiRequestsUsed = 0
                imageGenerationsUsed = 0
                lastResetDate = now
            }
        } else {
            if !calendar.isDateInToday(lastResetDate) {
                aiRequestsUsed = 0
                imageGenerationsUsed = 0
                lastResetDate = now
            }
        }
    }
    
    func recordAIRequest() {
        resetUsageIfNeeded()
        aiRequestsUsed += 1
    }
    
    func recordImageGeneration() {
        resetUsageIfNeeded()
        imageGenerationsUsed += 1
    }
    
    func canMakeAIRequest() -> Bool {
        resetUsageIfNeeded()
        return remainingAIRequests > 0
    }
    
    func canGenerateImage() -> Bool {
        resetUsageIfNeeded()
        return isPremium && remainingImageGenerations > 0
    }
}
