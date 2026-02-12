//
//  FaceImageTests.swift
//  My Funny ValentineTests
//
//  Created by Nathan Fennel on 2/12/26.
//

import Foundation
import SwiftData
import Testing
@testable import My_Funny_Valentine

struct FaceImageTests {
    
    @Test("FaceImage initializes with required values")
    func testFaceImageInitialization() async throws {
        let cardId = UUID()
        let imageData = TestData.sampleImageData()
        let thumbnailData = TestData.sampleImageData()
        
        let faceImage = FaceImage(
            cardId: cardId,
            imageData: imageData,
            thumbnailData: thumbnailData
        )
        
        #expect(faceImage.cardId == cardId)
        #expect(faceImage.imageData == imageData)
        #expect(faceImage.thumbnailData == thumbnailData)
        #expect(faceImage.position == .zero)
        #expect(faceImage.size == .zero)
    }
    
    @Test("FaceImage position can be set and retrieved")
    func testFaceImagePosition() async throws {
        let faceImage = FaceImage(
            cardId: UUID(),
            imageData: TestData.sampleImageData(),
            thumbnailData: TestData.sampleImageData(),
            position: CGPoint(x: 100, y: 200),
            size: CGSize(width: 300, height: 400)
        )
        
        #expect(faceImage.position.x == 100)
        #expect(faceImage.position.y == 200)
        #expect(faceImage.size.width == 300)
        #expect(faceImage.size.height == 400)
        
        // Test setting position
        faceImage.position = CGPoint(x: 50, y: 75)
        #expect(faceImage.position.x == 50)
        #expect(faceImage.position.y == 75)
        #expect(faceImage.positionX == 50)
        #expect(faceImage.positionY == 75)
    }
    
    @Test("FaceImage size can be set and retrieved")
    func testFaceImageSize() async throws {
        let faceImage = FaceImage(
            cardId: UUID(),
            imageData: TestData.sampleImageData(),
            thumbnailData: TestData.sampleImageData()
        )
        
        faceImage.size = CGSize(width: 150, height: 200)
        
        #expect(faceImage.size.width == 150)
        #expect(faceImage.size.height == 200)
        #expect(faceImage.sizeWidth == 150)
        #expect(faceImage.sizeHeight == 200)
    }
    
    @Test("FaceImage persists in SwiftData")
    func testFaceImagePersistence() async throws {
        try await Test.withModelContext { context in
            let cardId = UUID()
            let faceImage = TestData.sampleFaceImage(cardId: cardId)
            
            context.insert(faceImage)
            try context.save()
            
            let descriptor = FetchDescriptor<FaceImage>(
                predicate: #Predicate { $0.id == faceImage.id }
            )
            let fetched = try context.fetch(descriptor)
            
            #expect(fetched.count == 1)
            #expect(fetched[0].cardId == cardId)
            #expect(fetched[0].position == faceImage.position)
        }
    }
}
