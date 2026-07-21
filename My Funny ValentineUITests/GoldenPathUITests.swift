//
//  GoldenPathUITests.swift
//  My Funny ValentineUITests
//
//  Covers the core flow: Home -> Create a Card -> generate a saying -> Save.
//

import XCTest

final class GoldenPathUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    @MainActor
    func testHomeOffersCardCreation() throws {
        let createCard = app.buttons["home.createCard"]
        XCTAssertTrue(createCard.waitForExistence(timeout: 5), "Home should offer a way to create a card")
    }

    @MainActor
    func testCreateCardWithGeneratedSaying() throws {
        let createCard = app.buttons["home.createCard"]
        XCTAssertTrue(createCard.waitForExistence(timeout: 5))
        createCard.tap()

        // Open the saying generator
        let generate = app.buttons["cardDetail.generateWithAI"]
        XCTAssertTrue(generate.waitForExistence(timeout: 5), "Card editor should offer AI generation")
        generate.tap()

        // Enter inspiration and generate
        let inspiration = app.textFields["e.g., love, friendship, humor"]
        XCTAssertTrue(inspiration.waitForExistence(timeout: 5), "Generator should ask for inspiration")
        inspiration.tap()
        inspiration.typeText("coffee")

        let generateSayings = app.buttons["sayings.generate"]
        XCTAssertTrue(generateSayings.waitForExistence(timeout: 5))
        generateSayings.tap()

        // Sayings should appear even with no backend configured (on-device fallback)
        let firstSaying = app.buttons.containing(
            NSPredicate(format: "label CONTAINS[c] %@", "coffee")
        ).firstMatch
        XCTAssertTrue(firstSaying.waitForExistence(timeout: 10), "Sayings should be generated on-device")

        let chosen = firstSaying.label
        firstSaying.tap()

        let done = app.buttons["sayings.done"]
        XCTAssertTrue(done.waitForExistence(timeout: 5))
        XCTAssertTrue(done.isEnabled, "Done should enable once a saying is selected")
        done.tap()

        // Saying lands in the editor, and the card can be saved
        let save = app.buttons["cardDetail.save"]
        XCTAssertTrue(save.waitForExistence(timeout: 5))
        XCTAssertTrue(save.isEnabled, "Save should enable once the card has a saying")
        save.tap()

        // Back on Home, the new card shows up in Recent Cards
        XCTAssertTrue(
            app.staticTexts["Recent Cards"].waitForExistence(timeout: 10),
            "Saved card should appear on Home. Chosen saying: \(chosen)"
        )
    }
}
