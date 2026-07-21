//
//  AIGenerationViewModel.swift
//  My Funny Valentine
//
//  Created by Nathan Fennel on 2/12/26.
//

import Foundation
import Combine
import SwiftUI

@MainActor
class AIGenerationViewModel: ObservableObject {
    @Published var inspirationText: String = ""
    @Published var generatedSayings: [String] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var selectedSaying: String?
    @Published var isCached: Bool = false
    @Published var remainingRequests: Int = 3
    /// True when the last batch came from Apple's on-device model.
    @Published var usedOnDeviceModel: Bool = false
    
    private let apiService = APIService.shared
    private let cacheService = CacheService.shared
    private let userId: String
    
    init(userId: String) {
        self.userId = userId
    }
    
    var characterCount: Int {
        inspirationText.count
    }
    
    var canGenerate: Bool {
        !inspirationText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        characterCount <= 50 &&
        !isLoading
    }
    
    func generateSayings() async {
        let trimmedInspiration = inspirationText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedInspiration.isEmpty, trimmedInspiration.count <= 50 else {
            errorMessage = "Please enter inspiration text (max 50 characters)"
            return
        }
        
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        // Preferred: Apple's on-device model. Free, private, works offline, and
        // costs no rate-limited backend request.
        if OnDeviceSayingsGenerator.isAvailable {
            do {
                generatedSayings = try await OnDeviceSayingsGenerator.shared
                    .sayings(for: trimmedInspiration)
                isCached = false
                usedOnDeviceModel = true
                return
            } catch {
                // Fall through to the backend / template tiers.
                usedOnDeviceModel = false
            }
        }

        // Without a deployed backend, generate from templates so the feature
        // still works.
        guard await apiService.isConfigured else {
            useLocalSayings(for: trimmedInspiration)
            return
        }

        // Check cache before spending a request
        if let cachedSayings = cacheService.getCachedSayings(for: trimmedInspiration) {
            generatedSayings = cachedSayings
            isCached = true
            return
        }

        do {
            let response = try await apiService.generateSayings(
                inspiration: trimmedInspiration,
                userId: userId
            )

            generatedSayings = response.sayings
            isCached = response.cached
            remainingRequests = response.remainingRequests

            // Cache the response
            cacheService.cacheSayings(response.sayings, for: trimmedInspiration)

        } catch APIError.rateLimitExceeded {
            errorMessage = "Rate limit exceeded. Please try again later."
        } catch APIError.premiumRequired {
            errorMessage = "Premium subscription required"
        } catch APIError.httpError(let statusCode) {
            if statusCode == 429 {
                errorMessage = "Rate limit exceeded. Please try again later."
            } else {
                errorMessage = "Server error (status: \(statusCode))"
            }
        } catch {
            // Offline or unreachable: fall back rather than dead-ending the user.
            useLocalSayings(for: trimmedInspiration)
        }
    }

    /// Fresh on-device batch. Deliberately uncached so tapping Generate again
    /// gives a different set.
    private func useLocalSayings(for inspiration: String) {
        generatedSayings = LocalSayingsGenerator.shared.sayings(for: inspiration)
        isCached = false
        usedOnDeviceModel = false
    }
    
    func selectSaying(_ saying: String) {
        selectedSaying = saying
    }
    
    func clearError() {
        errorMessage = nil
    }
}
