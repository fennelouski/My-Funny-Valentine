//
//  MockAPIService.swift
//  My Funny ValentineTests
//
//  Created by Nathan Fennel on 2/12/26.
//

import Foundation
@testable import My_Funny_Valentine

class MockAPIService {
    var generateSayingsResult: Result<SayingsResponse, APIError>?
    var generateImageResult: Result<ImageResponse, APIError>?
    var delay: TimeInterval = 0
    
    func generateSayings(
        inspiration: String,
        userId: String
    ) async throws -> SayingsResponse {
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
        return SayingsResponse(
            sayings: ["Test saying 1", "Test saying 2"],
            cached: false,
            timestamp: Int64(Date().timeIntervalSince1970),
            remainingRequests: 2,
            resetAt: nil
        )
    }
    
    func generateImage(
        description: String,
        style: ImageStyle,
        userId: String
    ) async throws -> ImageResponse {
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
        return ImageResponse(
            imageUrl: "https://example.com/image.png",
            cached: false,
            remainingGenerations: 9
        )
    }
}
