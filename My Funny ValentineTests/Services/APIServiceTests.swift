//
//  APIServiceTests.swift
//  My Funny ValentineTests
//
//  Created by Nathan Fennel on 2/12/26.
//

import Foundation
import Testing
@testable import My_Funny_Valentine

/// Serialized because the stubbed responses live in shared `URLProtocol` state.
@Suite(.serialized)
struct APIServiceTests {

    private let baseURL = "https://api.test.invalid"

    private func makeService() -> APIService {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        return APIService(baseURL: baseURL, session: URLSession(configuration: configuration))
    }

    private func stub(statusCode: Int, json: String) {
        MockURLProtocol.responseHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: statusCode,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data(json.utf8))
        }
    }

    @Test("APIService generates sayings successfully")
    func testGenerateSayingsSuccess() async throws {
        stub(statusCode: 200, json: """
        {
          "sayings": ["You're my favorite", "Be mine"],
          "cached": false,
          "timestamp": 1707782400,
          "remainingRequests": 2
        }
        """)

        let response = try await makeService().generateSayings(inspiration: "love", userId: "test-user")

        #expect(response.sayings.count == 2)
        #expect(response.sayings.first == "You're my favorite")
        #expect(response.cached == false)
        #expect(response.remainingRequests == 2)
    }

    @Test("APIService surfaces server errors for sayings")
    func testGenerateSayingsServerError() async throws {
        stub(statusCode: 400, json: #"{"error":"bad request"}"#)

        await #expect(throws: APIError.self) {
            _ = try await makeService().generateSayings(inspiration: "love", userId: "test-user")
        }
    }

    @Test("APIService generates an image successfully")
    func testGenerateImageSuccess() async throws {
        stub(statusCode: 200, json: """
        {
          "imageUrl": "https://example.com/image.png",
          "cached": false,
          "remainingGenerations": 9
        }
        """)

        let response = try await makeService().generateImage(
            description: "two cats",
            userId: "test-user",
            style: .valentine
        )

        #expect(response.imageUrl == "https://example.com/image.png")
        #expect(response.remainingGenerations == 9)
    }

    @Test("APIService reports premium requirement for images")
    func testGenerateImageSubscriptionRequired() async throws {
        stub(statusCode: 403, json: #"{"error":"premium required"}"#)

        await #expect(throws: APIError.premiumRequired) {
            _ = try await makeService().generateImage(
                description: "two cats",
                userId: "test-user",
                style: .valentine
            )
        }
    }

    @Test("APIService reports rate limiting for images")
    func testGenerateImageRateLimited() async throws {
        stub(statusCode: 429, json: #"{"error":"rate limited"}"#)

        await #expect(throws: APIError.rateLimitExceeded) {
            _ = try await makeService().generateImage(
                description: "two cats",
                userId: "test-user",
                style: .valentine
            )
        }
    }

    @Test("APIService treats the placeholder endpoint as unconfigured")
    func testPlaceholderEndpointIsNotConfigured() async throws {
        let placeholder = APIService(baseURL: APIService.placeholderBaseURL)
        #expect(await placeholder.isConfigured == false)

        let real = APIService(baseURL: "https://example.com")
        #expect(await real.isConfigured == true)
    }
}

// MARK: - URLProtocol stub

final class MockURLProtocol: URLProtocol {
    nonisolated(unsafe) static var responseHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = Self.responseHandler else {
            client?.urlProtocolDidFinishLoading(self)
            return
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
