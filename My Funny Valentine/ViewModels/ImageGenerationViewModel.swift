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
    /// Set when the image came from Image Playground rather than the backend.
    @Published var generatedImage: PlatformImage?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var isCached: Bool = false
    @Published var remainingGenerations: Int = 3
    /// True when the last image came from Apple's on-device model.
    @Published var usedOnDeviceModel: Bool = false
    
    private let apiService = APIService.shared
    private let userId: String
    
    init(userId: String) {
        self.userId = userId
    }
    
    var characterCount: Int {
        descriptionText.count
    }
    
    /// On-device generation runs for free, so it isn't premium-gated.
    var canUseOnDeviceGeneration: Bool {
        OnDeviceImageGenerator.isSupported
    }

    var canGenerate: Bool {
        !descriptionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        characterCount <= 100 &&
        !isLoading &&
        (canUseOnDeviceGeneration || remainingGenerations > 0)
    }

    func generateImage() async {
        let trimmedDescription = descriptionText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedDescription.isEmpty, trimmedDescription.count <= 100 else {
            errorMessage = "Please enter description text (max 100 characters)"
            return
        }

        isLoading = true
        errorMessage = nil

        // Preferred: Image Playground on device. No network, no cost, no quota.
        if canUseOnDeviceGeneration {
            do {
                let image = try await OnDeviceImageGenerator.shared.image(
                    for: trimmedDescription,
                    style: selectedStyle
                )
                generatedImage = image
                generatedImageURL = nil
                usedOnDeviceModel = true
                isCached = false
                isLoading = false
                return
            } catch {
                // Apple Intelligence off or unsupported — try the backend.
                usedOnDeviceModel = false
            }
        }

        guard remainingGenerations > 0 else {
            errorMessage = "Image generation limit reached"
            isLoading = false
            return
        }

        do {
            let response = try await apiService.generateImage(
                description: trimmedDescription,
                userId: userId,
                style: selectedStyle
            )
            
            generatedImageURL = response.imageUrl
            generatedImage = nil
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
        
        isLoading = false
    }
    
    func clearError() {
        errorMessage = nil
    }
}
