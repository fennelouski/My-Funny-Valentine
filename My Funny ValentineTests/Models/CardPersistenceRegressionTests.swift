//
//  CardPersistenceRegressionTests.swift
//  My Funny ValentineTests
//
//  Guards the SwiftData crash where models storing CGPoint/CGSize directly
//  tripped "Composite Coder only supports Keyed Container" on save.
//

import Foundation
import CoreGraphics
import SwiftData
import Testing
@testable import My_Funny_Valentine

struct CardPersistenceRegressionTests {

    @Test("A card with faces, images, and stickers saves and reloads")
    func testFullCardGraphPersists() async throws {
        try await Test.withModelContext { context in
            let card = Card(saying: "Be mine")
            let cardId = card.id

            let face = FaceImage(
                cardId: cardId,
                imageData: TestData.sampleImageData(),
                thumbnailData: TestData.sampleImageData(),
                position: CGPoint(x: 12, y: 34),
                size: CGSize(width: 56, height: 78)
            )
            let image = CardImage(
                cardId: cardId,
                source: .photoImport,
                imageData: TestData.sampleImageData(),
                position: CGPoint(x: 1, y: 2),
                size: CGSize(width: 3, height: 4)
            )
            let sticker = StickerReference(
                cardId: cardId,
                stickerId: "heart",
                stickerData: TestData.sampleImageData(),
                position: CGPoint(x: 5, y: 6),
                size: CGSize(width: 7, height: 8)
            )

            card.faces = [face]
            card.images = [image]
            card.stickers = [sticker]

            context.insert(card)
            // Previously crashed here.
            try context.save()

            let descriptor = FetchDescriptor<Card>(
                predicate: #Predicate { $0.id == cardId }
            )
            let fetched = try #require(try context.fetch(descriptor).first)

            #expect(fetched.faces?.count == 1)
            #expect(fetched.images?.count == 1)
            #expect(fetched.stickers?.count == 1)

            // Geometry survives the round trip
            #expect(fetched.faces?.first?.position == CGPoint(x: 12, y: 34))
            #expect(fetched.faces?.first?.size == CGSize(width: 56, height: 78))
            #expect(fetched.images?.first?.position == CGPoint(x: 1, y: 2))
            #expect(fetched.images?.first?.source == .photoImport)
            #expect(fetched.stickers?.first?.size == CGSize(width: 7, height: 8))
        }
    }

    @Test("Mutating position through the computed property persists")
    func testGeometryMutationPersists() async throws {
        try await Test.withModelContext { context in
            let face = TestData.sampleFaceImage(cardId: UUID())
            context.insert(face)
            try context.save()

            face.position = CGPoint(x: 42, y: 99)
            face.size = CGSize(width: 11, height: 22)
            try context.save()

            let faceId = face.id
            let descriptor = FetchDescriptor<FaceImage>(
                predicate: #Predicate { $0.id == faceId }
            )
            let fetched = try #require(try context.fetch(descriptor).first)

            #expect(fetched.position == CGPoint(x: 42, y: 99))
            #expect(fetched.size == CGSize(width: 11, height: 22))
            #expect(fetched.positionX == 42)
            #expect(fetched.sizeHeight == 22)
        }
    }
}
