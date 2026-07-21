//
//  OnboardingUITests.swift
//  My Funny ValentineUITests
//
//  Covers the first-launch flow. Other suites pass -skipOnboarding so they can
//  test the app proper; these force it on with -showOnboarding.
//

import XCTest

final class OnboardingUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting", "-showOnboarding", "YES"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    @MainActor
    func testOnboardingAppearsOnFirstLaunch() throws {
        XCTAssertTrue(
            app.buttons["onboarding.next"].waitForExistence(timeout: 10),
            "Onboarding should be shown before the user has completed it"
        )
        XCTAssertTrue(
            app.staticTexts["My Funny Valentine"].exists,
            "First page should introduce the app"
        )
    }

    @MainActor
    func testCanPageThroughToTheEnd() throws {
        let next = app.buttons["onboarding.next"]
        XCTAssertTrue(next.waitForExistence(timeout: 5))

        // Back is hidden on the first page.
        XCTAssertFalse(app.buttons["onboarding.back"].isEnabled, "Back should be disabled on page one")

        next.tap()
        XCTAssertTrue(app.buttons["onboarding.back"].isEnabled, "Back should enable after advancing")

        next.tap()

        // Final page swaps the label and drops Skip.
        XCTAssertTrue(
            app.buttons["Make my first card"].waitForExistence(timeout: 5),
            "Last page should offer the primary call to action"
        )
        XCTAssertFalse(app.buttons["onboarding.skip"].isEnabled, "Skip should be gone on the last page")
    }

    @MainActor
    func testBackReturnsToPreviousPage() throws {
        let next = app.buttons["onboarding.next"]
        XCTAssertTrue(next.waitForExistence(timeout: 5))
        next.tap()

        let back = app.buttons["onboarding.back"]
        XCTAssertTrue(back.isEnabled)
        back.tap()

        XCTAssertFalse(back.isEnabled, "Returning to page one should disable Back again")
    }

    @MainActor
    func testFinishingLandsOnHome() throws {
        let next = app.buttons["onboarding.next"]
        XCTAssertTrue(next.waitForExistence(timeout: 5))

        next.tap()
        next.tap()

        let start = app.buttons["Make my first card"]
        XCTAssertTrue(start.waitForExistence(timeout: 5))
        start.tap()

        XCTAssertTrue(
            app.buttons["home.createCard"].waitForExistence(timeout: 10),
            "Finishing onboarding should land on Home, ready to make a card"
        )
    }

    @MainActor
    func testSkipGoesStraightToHome() throws {
        let skip = app.buttons["onboarding.skip"]
        XCTAssertTrue(skip.waitForExistence(timeout: 5))
        skip.tap()

        XCTAssertTrue(
            app.buttons["home.createCard"].waitForExistence(timeout: 10),
            "Skipping should land on Home"
        )
    }
}
