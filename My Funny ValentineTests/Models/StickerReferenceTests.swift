//
//  StickerReferenceTests.swift
//  My Funny ValentineTests
//
//  Created by Nathan Fennel on 2/12/26.
//

import Foundation
import CoreGraphics
import SwiftData
import Testing
@testable import My_Funny_Valentine

struct StickerReferenceTests {

    @Test("StickerReference initializes with required values")
    func testStickerReferenceInitialization() async throws {
        let cardId = UUID()
        let stickerData = TestData.sampleImageData()

        let sticker = StickerReference(
            cardId: cardId,
            stickerId: "sticker-1",
            stickerData: stickerData
        )

        #expect(sticker.cardId == cardId)
        #expect(sticker.stickerId == "sticker-1")
        #expect(sticker.stickerData == stickerData)
        #expect(sticker.position == .zero)
        #expect(sticker.size == .zero)
        #expect(sticker.rotation == 0)
    }

    @Test("StickerReference position can be set and retrieved")
    func testStickerReferencePosition() async throws {
        let sticker = StickerReference(
            cardId: UUID(),
            stickerId: "sticker-1",
            stickerData: TestData.sampleImageData(),
            position: CGPoint(x: 100, y: 150),
            size: CGSize(width: 100, height: 100)
        )

        #expect(sticker.position.x == 100)
        #expect(sticker.position.y == 150)
        #expect(sticker.size.width == 100)
        #expect(sticker.size.height == 100)

        sticker.position = CGPoint(x: 200, y: 250)
        #expect(sticker.position.x == 200)
        #expect(sticker.position.y == 250)
    }

    @Test("StickerReference rotation can be set")
    func testStickerReferenceRotation() async throws {
        let sticker = StickerReference(
            cardId: UUID(),
            stickerId: "sticker-1",
            stickerData: TestData.sampleImageData(),
            rotation: 45
        )

        #expect(sticker.rotation == 45)

        sticker.rotation = 90
        #expect(sticker.rotation == 90)
    }

    @Test("StickerReference persists in SwiftData")
    func testStickerReferencePersistence() async throws {
        try await Test.withModelContext { context in
            let cardId = UUID()
            let sticker = TestData.sampleStickerReference(cardId: cardId)

            context.insert(sticker)
            try context.save()

            let stickerId = sticker.id
            let descriptor = FetchDescriptor<StickerReference>(
                predicate: #Predicate { $0.id == stickerId }
            )
            let fetched = try context.fetch(descriptor)

            #expect(fetched.count == 1)
            #expect(fetched[0].cardId == cardId)
            #expect(fetched[0].position == sticker.position)
        }
    }
}
