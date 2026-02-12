//
//  UsageTrackerViewModel.swift
//  My Funny Valentine
//

import Foundation
import SwiftData
import SwiftUI

@MainActor
@Observable
class UsageTrackerViewModel {
    var aiRequestsUsed: Int = 0
    var imageGenerationsUsed: Int = 0
    var canUseAI: Bool = true
    var canGenerateImages: Bool = false
    
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func loadUsage(preferences: UserPreferences?) {
        guard let prefs = preferences else { return }
        aiRequestsUsed = prefs.aiRequestsUsed
        imageGenerationsUsed = prefs.imageGenerationsUsed
        
        let freeLimit = 3
        let premiumAILimit = 20
        let premiumImageLimit = 10
        
        let aiLimit = prefs.subscriptionStatus == .premium ? premiumAILimit : freeLimit
        canUseAI = aiRequestsUsed < aiLimit
        canGenerateImages = prefs.subscriptionStatus == .premium && imageGenerationsUsed < premiumImageLimit
    }
    
    func incrementAIUsage(preferences: UserPreferences?) {
        guard let prefs = preferences else { return }
        prefs.aiRequestsUsed += 1
        aiRequestsUsed = prefs.aiRequestsUsed
        do {
            try modelContext.save()
        } catch {}
    }
    
    func incrementImageUsage(preferences: UserPreferences?) {
        guard let prefs = preferences else { return }
        prefs.imageGenerationsUsed += 1
        imageGenerationsUsed = prefs.imageGenerationsUsed
        do {
            try modelContext.save()
        } catch {}
    }
}
