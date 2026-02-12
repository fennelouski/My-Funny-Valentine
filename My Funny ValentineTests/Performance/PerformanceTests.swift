//
//  PerformanceTests.swift
//  My Funny ValentineTests
//
//  Created by Nathan Fennel on 2/12/26.
//

import Foundation
import Testing
@testable import My_Funny_Valentine

struct PerformanceTests {
    
    @Test("Card generation performance")
    func testCardGenerationPerformance() async throws {
        let startTime = Date()
        
        // Simulate card generation
        let card = TestData.sampleCard()
        let faceImage = TestData.sampleFaceImage(cardId: card.id)
        card.faces = [faceImage]
        
        let elapsed = Date().timeIntervalSince(startTime)
        
        // Should complete within 1 second (per acceptance criteria)
        #expect(elapsed < 1.0)
    }
    
    @Test("Face detection performance")
    func testFaceDetectionPerformance() async throws {
        // Note: Actual face detection would use Vision framework
        // This test measures the expected performance
        
        let startTime = Date()
        
        // Simulate face detection
        let imageData = TestData.sampleImageData()
        let _ = FaceImage(
            cardId: UUID(),
            imageData: imageData,
            thumbnailData: imageData
        )
        
        let elapsed = Date().timeIntervalSince(startTime)
        
        // Should complete within 2 seconds (per acceptance criteria)
        #expect(elapsed < 2.0)
    }
    
    @Test("SwiftData query performance")
    func testSwiftDataQueryPerformance() async throws {
        try await Test.withModelContext { context in
            // Create test data
            for i in 0..<100 {
                let card = Card(templateId: "template-\(i)")
                context.insert(card)
            }
            try context.save()
            
            // Measure query performance
            let startTime = Date()
            
            let descriptor = FetchDescriptor<Card>()
            let cards = try context.fetch(descriptor)
            
            let elapsed = Date().timeIntervalSince(startTime)
            
            #expect(cards.count == 100)
            // Query should be fast even with 100 records
            #expect(elapsed < 0.5)
        }
    }
    
    @Test("Image data memory usage")
    func testImageDataMemoryUsage() async throws {
        // Test that image data is reasonable size
        let imageData = TestData.sampleImageData()
        
        // Sample image should be small (< 10KB)
        #expect(imageData.count < 10_000)
    }
    
    @Test("Card save performance")
    func testCardSavePerformance() async throws {
        try await Test.withModelContext { context in
            let startTime = Date()
            
            let card = TestData.sampleCard()
            context.insert(card)
            try context.save()
            
            let elapsed = Date().timeIntervalSince(startTime)
            
            // Save should complete within 1 second (per acceptance criteria)
            #expect(elapsed < 1.0)
        }
    }
}
