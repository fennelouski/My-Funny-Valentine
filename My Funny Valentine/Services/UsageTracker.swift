//
//  UsageTracker.swift
//  My Funny Valentine
//
//  Created by Nathan Fennel on 2/12/26.
//

import Foundation
import Combine
import SwiftData

@MainActor
class UsageTracker: ObservableObject {
    static let shared = UsageTracker()
    
    @Published var aiRequestsUsed: Int = 0
    @Published var imageGenerationsUsed: Int = 0
    @Published var remainingAIRequests: Int = 3
    @Published var remainingImageGenerations: Int = 0
    
    private var modelContext: ModelContext?
    private var userPreferences: UserPreferences?
    
    private init() {}
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        loadUsage()
    }
    
    // MARK: - Load Usage
    
    func loadUsage() {
        guard let modelContext = modelContext else { return }
        
        let descriptor = FetchDescriptor<UserPreferences>(
            predicate: #Predicate { _ in true },
            sortBy: [SortDescriptor(\.userId)]
        )
        
        do {
            let preferences = try modelContext.fetch(descriptor)
            userPreferences = preferences.first ?? UserPreferences()
            
            // Check if reset is needed
            checkAndResetIfNeeded()
            
            updatePublishedValues()
        } catch {
            print("Error loading usage: \(error)")
        }
    }
    
    // MARK: - Check and Reset
    
    private func checkAndResetIfNeeded() {
        guard let prefs = userPreferences else { return }
        
        let calendar = Calendar.current
        let now = Date()
        
        if prefs.isPremium {
            // Monthly reset for premium users
            if let lastReset = prefs.lastResetDate,
               let nextReset = calendar.date(byAdding: .month, value: 1, to: lastReset),
               now >= nextReset {
                resetUsage()
            }
        } else {
            // Daily reset for free users
            if let lastReset = prefs.lastResetDate,
               !calendar.isDateInToday(lastReset) {
                resetUsage()
            }
        }
    }
    
    private func resetUsage() {
        guard let prefs = userPreferences else { return }
        
        prefs.aiRequestsUsed = 0
        prefs.imageGenerationsUsed = 0
        prefs.lastResetDate = Date()
        
        savePreferences()
        updatePublishedValues()
    }
    
    // MARK: - Check Limits
    
    func canMakeAIRequest() -> Bool {
        guard let prefs = userPreferences else { return false }
        checkAndResetIfNeeded()
        return prefs.remainingAIRequests > 0
    }
    
    func canGenerateImage() -> Bool {
        guard let prefs = userPreferences else { return false }
        checkAndResetIfNeeded()
        return prefs.isPremium && prefs.remainingImageGenerations > 0
    }
    
    // MARK: - Record Usage
    
    func recordAIRequest() {
        guard let prefs = userPreferences else { return }
        checkAndResetIfNeeded()
        
        prefs.aiRequestsUsed += 1
        savePreferences()
        updatePublishedValues()
    }
    
    func recordImageGeneration() {
        guard let prefs = userPreferences else { return }
        checkAndResetIfNeeded()
        
        prefs.imageGenerationsUsed += 1
        savePreferences()
        updatePublishedValues()
    }
    
    // MARK: - Update Published Values
    
    private func updatePublishedValues() {
        guard let prefs = userPreferences else { return }
        
        aiRequestsUsed = prefs.aiRequestsUsed
        imageGenerationsUsed = prefs.imageGenerationsUsed
        remainingAIRequests = prefs.remainingAIRequests
        remainingImageGenerations = prefs.remainingImageGenerations
    }
    
    // MARK: - Save Preferences
    
    private func savePreferences() {
        guard let modelContext = modelContext else { return }
        
        do {
            if let prefs = userPreferences, modelContext.model(for: prefs.persistentModelID) == nil {
                modelContext.insert(prefs)
            }
            try modelContext.save()
        } catch {
            print("Error saving preferences: \(error)")
        }
    }
    
    // MARK: - Refresh
    
    func refresh() {
        loadUsage()
    }
}
