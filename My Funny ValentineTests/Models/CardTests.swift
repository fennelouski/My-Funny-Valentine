//
//  CardTests.swift
//  My Funny ValentineTests
//
//  Created by Nathan Fennel on 2/12/26.
//

import Foundation
import SwiftData
import Testing
@testable import My_Funny_Valentine

struct CardTests {
    
    @Test("Card initializes with default values")
    func testCardInitialization() async throws {
        let card = Card()
        
        #expect(card.id != UUID())
        #expect(card.templateId == nil)
        #expect(card.saying == nil)
        #expect(card.customText == nil)
        #expect(card.syncedToCloud == false)
        #expect(card.faces?.isEmpty ?? true)
        #expect(card.images?.isEmpty ?? true)
        #expect(card.stickers?.isEmpty ?? true)
    }
    
    @Test("Card initializes with custom values")
    func testCardCustomInitialization() async throws {
        let templateId = "template-123"
        let saying = "Test saying"
        let customText = "Custom text"
        let card = Card(
            templateId: templateId,
            saying: saying,
            customText: customText,
            syncedToCloud: true
        )
        
        #expect(card.templateId == templateId)
        #expect(card.saying == saying)
        #expect(card.customText == customText)
        #expect(card.syncedToCloud == true)
    }
    
    @Test("Card updateModifiedDate updates modifiedAt and unsets syncedToCloud")
    func testUpdateModifiedDate() async throws {
        let card = Card()
        let originalModifiedAt = card.modifiedAt
        card.syncedToCloud = true
        
        // Wait a small amount to ensure date difference
        try await Task.sleep(nanoseconds: 10_000_000) // 0.01 seconds
        
        card.updateModifiedDate()
        
        #expect(card.modifiedAt > originalModifiedAt)
        #expect(card.syncedToCloud == false)
    }
    
    @Test("Card relationships work correctly")
    func testCardRelationships() async throws {
        try await Test.withModelContext { context in
            let card = TestData.sampleCard()
            let faceImage = TestData.sampleFaceImage(cardId: card.id)
            let cardImage = TestData.sampleCardImage(cardId: card.id)
            let sticker = TestData.sampleStickerReference(cardId: card.id)
            
            card.faces = [faceImage]
            card.images = [cardImage]
            card.stickers = [sticker]
            
            context.insert(card)
            try context.save()
            
            let cardId = card.id
            let descriptor = FetchDescriptor<Card>(
                predicate: #Predicate { $0.id == cardId }
            )
            let fetchedCards = try context.fetch(descriptor)
            
            #expect(fetchedCards.count == 1)
            let fetchedCard = fetchedCards[0]
            #expect(fetchedCard.faces?.count == 1)
            #expect(fetchedCard.images?.count == 1)
            #expect(fetchedCard.stickers?.count == 1)
        }
    }
    
    @Test("Card layout data can be set and retrieved")
    func testCardLayoutData() async throws {
        let card = Card()
        let layoutData = CardLayoutData(
            backgroundColor: "#FF0000",
            textPositions: [
                TextPosition(
                    text: "Hello",
                    fontName: "Arial",
                    fontSize: 16,
                    color: "#000000",
                    position: CGPoint(x: 10, y: 10),
                    size: CGSize(width: 100, height: 50)
                )
            ],
            imagePositions: [],
            stickerPositions: []
        )
        
        card.setLayoutData(layoutData)
        
        let retrieved = card.getLayoutData()
        #expect(retrieved != nil)
        #expect(retrieved?.backgroundColor == "#FF0000")
        #expect(retrieved?.textPositions.count == 1)
    }
}
