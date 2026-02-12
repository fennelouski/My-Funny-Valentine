//
//  My_Funny_ValentineTests.swift
//  My Funny ValentineTests
//
//  Created by Nathan Fennel on 2/12/26.
//

import Foundation
import Testing
@testable import My_Funny_Valentine

struct My_Funny_ValentineTests {

    @Test("App test suite runs successfully")
    func testAppTestSuite() async throws {
        // This is a placeholder test to verify the test suite is set up correctly
        #expect(true)
    }
    
    @Test("Test utilities work correctly")
    func testTestUtilities() async throws {
        let imageData = TestData.sampleImageData()
        #expect(imageData.isEmpty == false)
        
        let card = TestData.sampleCard()
        #expect(card.templateId != nil)
    }
}
