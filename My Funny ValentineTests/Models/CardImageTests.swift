//
//  CardImageTests.swift
//  My Funny ValentineTests
//
//  Created by Nathan Fennel on 2/12/26.
//

import Foundation
import CoreGraphics
import SwiftData
import Testing
@testable import My_Funny_Valentine

struct CardImageTests {
    
    @Test("CardImage initializes with required values")
    func testCardImageInitialization() async throws {
        let cardId = UUID()
        let imageData = TestData.sampleImageData()
        
        let cardImage = CardImage(
            cardId: cardId,
            source: .photoImport,
            imageData: imageData
        )
        
        #expect(cardImage.cardId == cardId)
        #expect(cardImage.source == .photoImport)
        #expect(cardImage.imageData == imageData)
        #expect(cardImage.position == .zero)
        #expect(cardImage.size == CGSize(width: 200, height: 200))
        #expect(cardImage.rotation == 0)
        #expect(cardImage.syncedToCloud == false)
    }
    
    @Test("CardImage supports all image sources")
    func testCardImageSources() async throws {
        let cardId = UUID()
        let imageData = TestData.sampleImageData()
        
        let sources: [ImageSource] = [.imagePlayground, .sticker, .smartCutout, .photoImport]
        
        for source in sources {
            let cardImage = CardImage(
                cardId: cardId,
                source: source,
                imageData: imageData
            )
            #expect(cardImage.source == source)
            #expect(cardImage.source.rawValue == source.rawValue)
        }
    }
    
    @Test("CardImage position and rotation can be set")
    func testCardImagePositionAndRotation() async throws {
        let cardImage = CardImage(
            cardId: UUID(),
            source: .photoImport,
            imageData: TestData.sampleImageData(),
            position: CGPoint(x: 50, y: 100),
            size: CGSize(width: 150, height: 150),
            rotation: 45
        )
        
        #expect(cardImage.position.x == 50)
        #expect(cardImage.position.y == 100)
        #expect(cardImage.size.width == 150)
        #expect(cardImage.size.height == 150)
        #expect(cardImage.rotation == 45)
        
        cardImage.position = CGPoint(x: 75, y: 125)
        cardImage.rotation = 90
        
        #expect(cardImage.position.x == 75)
        #expect(cardImage.position.y == 125)
        #expect(cardImage.rotation == 90)
    }
    
    @Test("CardImage persists in SwiftData")
    func testCardImagePersistence() async throws {
        try await Test.withModelContext { context in
            let cardId = UUID()
            let cardImage = TestData.sampleCardImage(cardId: cardId)
            
            context.insert(cardImage)
            try context.save()
            
            let imageId = cardImage.id
            let descriptor = FetchDescriptor<CardImage>(
                predicate: #Predicate { $0.id == imageId }
            )
            let fetched = try context.fetch(descriptor)
            
            #expect(fetched.count == 1)
            #expect(fetched[0].cardId == cardId)
            #expect(fetched[0].source == .photoImport)
        }
    }
}
