//
//  LocalSayingsGeneratorTests.swift
//  My Funny ValentineTests
//

import Foundation
import Testing
@testable import My_Funny_Valentine

struct LocalSayingsGeneratorTests {

    @Test("Generates the requested number of sayings")
    func testGeneratesRequestedCount() async throws {
        let sayings = LocalSayingsGenerator.shared.sayings(for: "coffee", count: 10)
        #expect(sayings.count == 10)
    }

    @Test("Every saying mentions the inspiration")
    func testSayingsIncludeInspiration() async throws {
        let sayings = LocalSayingsGenerator.shared.sayings(for: "Tacos", count: 10)
        #expect(sayings.allSatisfy { $0.localizedCaseInsensitiveContains("tacos") })
    }

    @Test("Sayings are unique within a batch")
    func testSayingsAreUnique() async throws {
        let sayings = LocalSayingsGenerator.shared.sayings(for: "books", count: 10)
        #expect(Set(sayings).count == sayings.count)
    }

    @Test("Every saying starts capitalized and is non-empty")
    func testSayingsAreWellFormed() async throws {
        let sayings = LocalSayingsGenerator.shared.sayings(for: "cats", count: 10)

        for saying in sayings {
            let first = try #require(saying.first)
            #expect(first.isUppercase)
            #expect(saying.count > 5)
        }
    }

    @Test("Blank inspiration still produces sayings")
    func testBlankInspirationFallsBack() async throws {
        let sayings = LocalSayingsGenerator.shared.sayings(for: "   ", count: 5)
        #expect(sayings.count == 5)
        #expect(sayings.allSatisfy { !$0.isEmpty })
    }
}
