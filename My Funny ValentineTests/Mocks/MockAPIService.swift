//
//  MockAPIService.swift
//  My Funny ValentineTests
//
//  Created by Nathan Fennel on 2/12/26.
//

import Foundation
@testable import My_Funny_Valentine

class MockAPIService {
    var generateSayingsResult: Result<GenerateSayingsResponse, APIError>?
    var generateImageResult: Result<GenerateImageResponse, APIError>?
    var delay: TimeInterval = 0

    func generateSayings(
        inspiration: String,
        userId: String
    ) async throws -> GenerateSayingsResponse {
        if delay > 0 {
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }

        if let result = generateSayingsResult {
            switch result {
            case .success(let response):
                return response
            case .failure(let error):
                throw error
            }
        }

        // Default success response
        return GenerateSayingsResponse(
            sayings: ["Test saying 1", "Test saying 2"],
            cached: false,
            timestamp: Date().timeIntervalSince1970,
            remainingRequests: 2
        )
    }

    func generateImage(
        description: String,
        style: ImageStyle,
        userId: String
    ) async throws -> GenerateImageResponse {
        if delay > 0 {
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }

        if let result = generateImageResult {
            switch result {
            case .success(let response):
                return response
            case .failure(let error):
                throw error
            }
        }

        // Default success response
        return GenerateImageResponse(
            imageUrl: "https://example.com/image.png",
            cached: false,
            remainingGenerations: 9
        )
    }
}
