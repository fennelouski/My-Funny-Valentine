//
//  ImageGenerationViewModel.swift
//  My Funny Valentine
//
//  Created by Nathan Fennel on 2/12/26.
//

import Foundation
import Combine
import SwiftUI

@MainActor
class ImageGenerationViewModel: ObservableObject {
    @Published var descriptionText: String = ""
    @Published var selectedStyle: ImageStyle = .valentine
    @Published var generatedImageURL: String?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var isCached: Bool = false
    @Published var remainingGenerations: Int = 3
    @Published private(set) var isBackendConfigured = false
    
    private let apiService: APIService
    private let userId: String
    
    init(userId: String, apiService: APIService = .shared) {
        self.userId = userId
        self.apiService = apiService
    }
    
    var characterCount: Int {
        descriptionText.count
    }
    
    func loadAvailability() async {
        isBackendConfigured = await apiService.isConfigured
    }

    var canGenerate: Bool {
        !descriptionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        characterCount <= 100 &&
        !isLoading &&
        isBackendConfigured && remainingGenerations > 0
    }

    func generateImage() async {
        let trimmedDescription = descriptionText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedDescription.isEmpty, trimmedDescription.count <= 100 else {
            errorMessage = "Please enter description text (max 100 characters)"
            return
        }

        // Apple artwork uses the system sheet. This optional hosted path must
        // never request the shipped placeholder endpoint.
        await loadAvailability()
        guard isBackendConfigured else {
            errorMessage = "Choose a photo or a starter card."
            return
        }

        guard remainingGenerations > 0 else {
            errorMessage = "Image generation limit reached"
            return
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let response = try await apiService.generateImage(
                description: trimmedDescription,
                userId: userId,
                style: selectedStyle
            )
            
            generatedImageURL = response.imageUrl
            isCached = response.cached
            remainingGenerations = response.remainingGenerations

        } catch APIError.rateLimitExceeded {
            errorMessage = "Image generation limit reached"
        } catch APIError.premiumRequired {
            errorMessage = "Artwork generation isn't available on this device right now."
        } catch APIError.httpError(let statusCode) {
            if statusCode == 429 {
                errorMessage = "Image generation limit reached"
            } else if statusCode == 403 {
                errorMessage = "Artwork generation isn't available on this device right now."
            } else {
                errorMessage = "Server error (status: \(statusCode))"
            }
        } catch {
            errorMessage = "An unexpected error occurred: \(error.localizedDescription)"
        }
        
    }
    
    func clearError() {
        errorMessage = nil
    }
}
