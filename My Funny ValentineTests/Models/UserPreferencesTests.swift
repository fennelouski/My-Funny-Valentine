//
//  UserPreferencesTests.swift
//  My Funny ValentineTests
//
//  Created by Nathan Fennel on 2/12/26.
//

import Foundation
import SwiftData
import Testing
@testable import My_Funny_Valentine

struct UserPreferencesTests {
    
    @Test("UserPreferences initializes with default values")
    func testUserPreferencesInitialization() async throws {
        let userId = "test-user-123"
        let prefs = UserPreferences(userId: userId)
        
        #expect(prefs.userId == userId)
        #expect(prefs.subscriptionStatus == .free)
        #expect(prefs.aiRequestsUsed == 0)
        #expect(prefs.imageGenerationsUsed == 0)
        #expect(prefs.syncEnabled == true)
        #expect(prefs.isPremium == false)
    }
    
    @Test("UserPreferences free tier limits")
    func testFreeTierLimits() async throws {
        let prefs = UserPreferences(
            userId: "test-user",
            subscriptionStatus: .free
        )
        
        #expect(prefs.aiRequestLimit == 3)
        #expect(prefs.imageGenerationLimit == 0)
        #expect(prefs.remainingAIRequests == 3)
        #expect(prefs.remainingImageGenerations == 0)
    }
    
    @Test("UserPreferences premium tier limits")
    func testPremiumTierLimits() async throws {
        let prefs = UserPreferences(
            userId: "test-user",
            subscriptionStatus: .premium
        )
        
        #expect(prefs.aiRequestLimit == 20)
        #expect(prefs.imageGenerationLimit == 10)
        #expect(prefs.remainingAIRequests == 20)
        #expect(prefs.remainingImageGenerations == 10)
        #expect(prefs.isPremium == true)
    }
    
    @Test("UserPreferences tracks usage correctly")
    func testUsageTracking() async throws {
        let prefs = UserPreferences(
            userId: "test-user",
            subscriptionStatus: .free,
            aiRequestsUsed: 1,
            imageGenerationsUsed: 0
        )
        
        #expect(prefs.remainingAIRequests == 2)
        #expect(prefs.canMakeAIRequest() == true)
        
        prefs.aiRequestsUsed = 3
        #expect(prefs.remainingAIRequests == 0)
        #expect(prefs.canMakeAIRequest() == false)
    }
    
    @Test("UserPreferences canGenerateImage only for premium")
    func testImageGenerationAccess() async throws {
        let freePrefs = UserPreferences(
            userId: "test-user",
            subscriptionStatus: .free
        )
        #expect(freePrefs.canGenerateImage() == false)
        
        let premiumPrefs = UserPreferences(
            userId: "test-user",
            subscriptionStatus: .premium
        )
        #expect(premiumPrefs.canGenerateImage() == true)
        
        premiumPrefs.imageGenerationsUsed = 10
        #expect(premiumPrefs.canGenerateImage() == false)
    }
    
    @Test("UserPreferences resets daily for free tier")
    func testFreeTierDailyReset() async throws {
        let yesterday = Date.testDate().addingDays(-1)
        let prefs = UserPreferences(
            userId: "test-user",
            subscriptionStatus: .free,
            aiRequestsUsed: 3,
            lastResetDate: yesterday
        )
        
        // Simulate reset check
        prefs.resetUsageIfNeeded()
        
        // Should reset if not same day
        let calendar = Calendar.current
        if !calendar.isDate(prefs.lastResetDate, inSameDayAs: Date()) {
            #expect(prefs.aiRequestsUsed == 0)
        }
    }
    
    @Test("UserPreferences resets monthly for premium tier")
    func testPremiumTierMonthlyReset() async throws {
        let lastMonth = Date.testDate().addingMonths(-1)
        let prefs = UserPreferences(
            userId: "test-user",
            subscriptionStatus: .premium,
            aiRequestsUsed: 20,
            imageGenerationsUsed: 10,
            lastResetDate: lastMonth
        )
        
        prefs.resetUsageIfNeeded()
        
        // Should reset if a month has passed
        let calendar = Calendar.current
        if let nextReset = calendar.date(byAdding: .month, value: 1, to: prefs.lastResetDate),
           Date() >= nextReset {
            #expect(prefs.aiRequestsUsed == 0)
            #expect(prefs.imageGenerationsUsed == 0)
        }
    }
    
    @Test("UserPreferences recordAIRequest increments usage")
    func testRecordAIRequest() async throws {
        let prefs = UserPreferences(
            userId: "test-user",
            subscriptionStatus: .free
        )
        
        #expect(prefs.aiRequestsUsed == 0)
        prefs.recordAIRequest()
        #expect(prefs.aiRequestsUsed == 1)
        
        prefs.recordAIRequest()
        #expect(prefs.aiRequestsUsed == 2)
    }
    
    @Test("UserPreferences recordImageGeneration increments usage")
    func testRecordImageGeneration() async throws {
        let prefs = UserPreferences(
            userId: "test-user",
            subscriptionStatus: .premium
        )
        
        #expect(prefs.imageGenerationsUsed == 0)
        prefs.recordImageGeneration()
        #expect(prefs.imageGenerationsUsed == 1)
    }
    
    @Test("UserPreferences persists in SwiftData")
    func testUserPreferencesPersistence() async throws {
        try await Test.withModelContext { context in
            let prefs = TestData.sampleUserPreferences()
            
            context.insert(prefs)
            try context.save()
            
            let prefsUserId = prefs.userId
            let descriptor = FetchDescriptor<UserPreferences>(
                predicate: #Predicate { $0.userId == prefsUserId }
            )
            let fetched = try context.fetch(descriptor)
            
            #expect(fetched.count == 1)
            #expect(fetched[0].userId == prefs.userId)
            #expect(fetched[0].subscriptionStatus == prefs.subscriptionStatus)
        }
    }
}
