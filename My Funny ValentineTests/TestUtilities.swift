//
//  TestUtilities.swift
//  My Funny ValentineTests
//
//  Created by Nathan Fennel on 2/12/26.
//

import Foundation
import SwiftData
import Testing
#if canImport(UIKit)
import UIKit
#endif
@testable import My_Funny_Valentine

// MARK: - Test Model Container

extension ModelContainer {
    static func testContainer() throws -> ModelContainer {
        let schema = Schema([
            Card.self,
            FaceImage.self,
            CardImage.self,
            StickerReference.self,
            UserPreferences.self,
        ])
        
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )
        
        return try ModelContainer(for: schema, configurations: [configuration])
    }
}

// MARK: - Test Data Helpers

struct TestData {
    static func sampleImageData() -> Data {
        // Create a minimal PNG image data (1x1 pixel)
        #if canImport(UIKit)
        let size = CGSize(width: 1, height: 1)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            UIColor.red.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
        return image.pngData() ?? Data()
        #else
        // Fallback for non-UI environments
        return Data([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]) // PNG header
        #endif
    }
    
    static func sampleCard() -> Card {
        Card(
            templateId: "template-1",
            saying: "Test saying",
            customText: "Custom text",
            syncedToCloud: false
        )
    }
    
    static func sampleFaceImage(cardId: UUID) -> FaceImage {
        FaceImage(
            cardId: cardId,
            imageData: sampleImageData(),
            thumbnailData: sampleImageData(),
            position: CGPoint(x: 100, y: 100),
            size: CGSize(width: 200, height: 200)
        )
    }
    
    static func sampleCardImage(cardId: UUID) -> CardImage {
        CardImage(
            cardId: cardId,
            source: .photoImport,
            imageData: sampleImageData(),
            position: CGPoint(x: 50, y: 50),
            size: CGSize(width: 150, height: 150)
        )
    }
    
    static func sampleStickerReference(cardId: UUID) -> StickerReference {
        StickerReference(
            cardId: cardId,
            imageData: sampleImageData(),
            position: CGPoint(x: 75, y: 75),
            size: CGSize(width: 80, height: 80)
        )
    }
    
    static func sampleUserPreferences() -> UserPreferences {
        UserPreferences(
            userId: "test-user-123",
            subscriptionStatus: .free,
            aiRequestsUsed: 0,
            imageGenerationsUsed: 0
        )
    }
}

// MARK: - Async Test Helpers

extension Test {
    static func withModelContext<T>(
        _ test: (ModelContext) async throws -> T
    ) async throws -> T {
        let container = try ModelContainer.testContainer()
        let context = ModelContext(container)
        return try await test(context)
    }
}

// MARK: - Date Helpers

extension Date {
    static func testDate(year: Int = 2026, month: Int = 2, day: Int = 12) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = 12
        components.minute = 0
        components.second = 0
        return Calendar.current.date(from: components) ?? Date()
    }
    
    func addingDays(_ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: self) ?? self
    }
    
    func addingMonths(_ months: Int) -> Date {
        Calendar.current.date(byAdding: .month, value: months, to: self) ?? self
    }
}
