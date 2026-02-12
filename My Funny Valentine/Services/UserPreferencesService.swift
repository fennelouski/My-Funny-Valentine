//
//  UserPreferencesService.swift
//  My Funny Valentine
//
//  Created by Nathan Fennel on 2/12/26.
//

import Foundation
import Combine
import SwiftData

@MainActor
class UserPreferencesService: ObservableObject {
    @Published var preferences: UserPreferences?
    
    private var modelContext: ModelContext?
    
    init(modelContext: ModelContext? = nil) {
        self.modelContext = modelContext
        loadPreferences()
    }
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        loadPreferences()
    }
    
    private func loadPreferences() {
        guard let modelContext = modelContext else { return }
        
        let descriptor = FetchDescriptor<UserPreferences>()
        if let existing = try? modelContext.fetch(descriptor).first {
            preferences = existing
        } else {
            // Create default preferences
            let userId = getOrCreateUserId()
            let newPreferences = UserPreferences(userId: userId)
            modelContext.insert(newPreferences)
            preferences = newPreferences
            try? modelContext.save()
        }
        
        // Reset usage if needed
        preferences?.resetUsageIfNeeded()
    }
    
    private func getOrCreateUserId() -> String {
        if let userId = UserDefaults.standard.string(forKey: "userId") {
            return userId
        }
        
        let userId = UUID().uuidString
        UserDefaults.standard.set(userId, forKey: "userId")
        return userId
    }
    
    func updateSubscriptionStatus(_ status: SubscriptionStatus) {
        preferences?.subscriptionStatus = status
        preferences?.resetUsageIfNeeded()
        savePreferences()
    }
    
    func recordAIRequest() {
        preferences?.recordAIRequest()
        savePreferences()
    }
    
    func recordImageGeneration() {
        preferences?.recordImageGeneration()
        savePreferences()
    }
    
    func canMakeAIRequest() -> Bool {
        preferences?.canMakeAIRequest() ?? false
    }
    
    func canGenerateImage() -> Bool {
        preferences?.canGenerateImage() ?? false
    }
    
    func getRemainingAIRequests() -> Int {
        preferences?.remainingAIRequests ?? 0
    }
    
    func getRemainingImageGenerations() -> Int {
        preferences?.remainingImageGenerations ?? 0
    }
    
    var isPremium: Bool {
        preferences?.isPremium ?? false
    }
    
    var userId: String {
        preferences?.userId ?? getOrCreateUserId()
    }
    
    private func savePreferences() {
        guard let modelContext = modelContext else { return }
        try? modelContext.save()
    }
}
