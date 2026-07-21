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
        app.launchArguments = ["--uitesting", "-skipOnboarding", "YES"]
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

        // Sayings should appear even with no backend configured. Two on-device
        // tiers can serve this: Apple's foundation model (thematic, so it may
        // not echo the inspiration word) or the template generator (which
        // always does). Assert the user-visible contract, not which tier ran.
        let firstSaying = app.buttons.matching(identifier: "sayings.row").firstMatch
        XCTAssertTrue(firstSaying.waitForExistence(timeout: 30), "Sayings should be generated on-device")
        XCTAssertGreaterThan(
            firstSaying.label.trimmingCharacters(in: .whitespacesAndNewlines).count,
            10,
            "Generated saying should be a real message, got: \(firstSaying.label)"
        )

        let chosen = firstSaying.label
        // The results list can still be settling (or behind the keyboard) right
        // after generating, so wait until the row is actually tappable.
        expectation(
            for: NSPredicate(format: "isHittable == true"),
            evaluatedWith: firstSaying
        )
        waitForExpectations(timeout: 10)
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
