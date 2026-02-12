//
//  UserPreferences.swift
//  My Funny Valentine
//

import Foundation
import SwiftData

@Model
final class UserPreferences {
    @Attribute(.unique) var userId: String
    var subscriptionStatusRawValue: String
    var aiRequestsUsed: Int
    var imageGenerationsUsed: Int
    var lastResetDate: Date
    var syncEnabled: Bool
    
    var subscriptionStatus: SubscriptionStatus {
        get { SubscriptionStatus(rawValue: subscriptionStatusRawValue) ?? .free }
        set { subscriptionStatusRawValue = newValue.rawValue }
    }
    
    init(
        userId: String = "default",
        subscriptionStatus: SubscriptionStatus = .free,
        aiRequestsUsed: Int = 0,
        imageGenerationsUsed: Int = 0,
        lastResetDate: Date = Date(),
        syncEnabled: Bool = true
    ) {
        self.userId = userId
        self.subscriptionStatusRawValue = subscriptionStatus.rawValue
        self.aiRequestsUsed = aiRequestsUsed
        self.imageGenerationsUsed = imageGenerationsUsed
        self.lastResetDate = lastResetDate
        self.syncEnabled = syncEnabled
    }
}
