//
//  APIService.swift
//  My Funny Valentine
//

import Foundation

/// Service for backend API calls (Vercel serverless functions)
actor APIService {
    static let shared = APIService()
    
    private let baseURL: String
    private let session: URLSession

    /// Shipped as a placeholder. While it's still in place we treat the hosted
    /// backend as unconfigured and generate sayings on-device instead of
    /// stalling on a host that will never answer.
    static let placeholderBaseURL = "https://your-vercel-app.vercel.app"

    /// Set `APIBaseURL` in Info.plist to point the app at a deployed backend.
    static var configuredBaseURL: String {
        if let fromPlist = Bundle.main.object(forInfoDictionaryKey: "APIBaseURL") as? String,
           !fromPlist.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return fromPlist
        }
        return placeholderBaseURL
    }

    init(baseURL: String = APIService.configuredBaseURL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }

    /// True when a real backend is available to call.
    var isConfigured: Bool {
        baseURL != Self.placeholderBaseURL && !baseURL.isEmpty
    }
    
    /// Generate Valentine sayings via AI
    func generateSayings(inspiration: String, userId: String) async throws -> GenerateSayingsResponse {
        let url = URL(string: "\(baseURL)/api/generate-sayings")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(GenerateSayingsRequest(inspiration: inspiration, userId: userId))
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.httpError(statusCode: httpResponse.statusCode)
        }
        
        return try JSONDecoder().decode(GenerateSayingsResponse.self, from: data)
    }
    
    /// Generate image via AI (premium feature)
    func generateImage(description: String, userId: String, style: ImageStyle) async throws -> GenerateImageResponse {
        let url = URL(string: "\(baseURL)/api/generate-image")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(GenerateImageRequest(
            description: description,
            userId: userId,
            style: style.rawValue
        ))
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 403 {
                throw APIError.premiumRequired
            }
            if httpResponse.statusCode == 429 {
                throw APIError.rateLimitExceeded
            }
            throw APIError.httpError(statusCode: httpResponse.statusCode)
        }
        
        return try JSONDecoder().decode(GenerateImageResponse.self, from: data)
    }
    
    /// Validate subscription status
    func validateSubscription(userId: String, receipt: String? = nil) async throws -> ValidateSubscriptionResponse {
        let url = URL(string: "\(baseURL)/api/validate-subscription")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(ValidateSubscriptionRequest(userId: userId, receipt: receipt))
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.httpError(statusCode: httpResponse.statusCode)
        }
        
        return try JSONDecoder().decode(ValidateSubscriptionResponse.self, from: data)
    }
}

// MARK: - Request/Response Types

struct GenerateSayingsRequest: Encodable {
    let inspiration: String
    let userId: String
}

struct GenerateSayingsResponse: Decodable {
    let sayings: [String]
    let cached: Bool
    let timestamp: Double
    let remainingRequests: Int
}

struct GenerateImageRequest: Encodable {
    let description: String
    let userId: String
    let style: String
}

struct GenerateImageResponse: Decodable {
    let imageUrl: String
    let cached: Bool
    let remainingGenerations: Int
}

struct ValidateSubscriptionRequest: Encodable {
    let userId: String
    let receipt: String?
}

struct ValidateSubscriptionResponse: Decodable {
    let isPremium: Bool
    let expiresAt: Double?
    let remainingAIRequests: Int
    let remainingImageGenerations: Int
}

enum ImageStyle: String, Codable, CaseIterable {
    case valentine
    case romantic
    case funny

    var displayName: String {
        switch self {
        case .valentine: return "Valentine"
        case .romantic: return "Romantic"
        case .funny: return "Funny"
        }
    }
}

enum APIError: Error, Equatable {
    case invalidResponse
    case httpError(statusCode: Int)
    case premiumRequired
    case rateLimitExceeded
}
