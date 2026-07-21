//
//  ScreenshotUITests.swift
//  My Funny ValentineUITests
//
//  Drives the app through its main screens and attaches screenshots, so
//  App Store marketing images can be regenerated on any device size:
//
//    xcodebuild test -scheme "My Funny Valentine" \
//      -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' \
//      -only-testing:"My Funny ValentineUITests/ScreenshotUITests"
//
//  Then export with: xcrun xcresulttool export attachments --path <xcresult>
//

import XCTest

final class ScreenshotUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        // Seed a populated library so marketing shots aren't near-empty.
        app.launchArguments = ["--uitesting", "-seedSampleCards", "YES", "-skipOnboarding", "YES"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    @MainActor
    func testCaptureAppStoreScreenshots() throws {
        // Walk the real creation flow once, capturing the AI generator on the way.
        createCard(inspiration: "coffee", captureGenerator: true)

        // 01 — Home with recent cards
        goToTab("Home")
        capture("01-Home")

        // 02 — Card editor with live preview
        let createCard = app.buttons["home.createCard"]
        if createCard.waitForExistence(timeout: 5) {
            createCard.tap()
            let sayingField = app.textFields["Add a saying..."]
            if sayingField.waitForExistence(timeout: 5) {
                sayingField.tap()
                sayingField.typeText("You're the coffee to my heart.")
            }
            capture("02-CardEditor")
            dismissEditor()
        }

        // 03 — Card library
        goToTab("My Cards")
        capture("04-MyCards")

        // 04 — Settings
        goToTab("Settings")
        capture("05-Settings")
    }

    @MainActor
    func testCaptureOnboardingScreenshot() throws {
        // Relaunch forcing the welcome flow; the suite default skips it.
        app.terminate()
        app.launchArguments = ["--uitesting", "-showOnboarding", "YES"]
        app.launch()

        let next = app.buttons["onboarding.next"]
        guard next.waitForExistence(timeout: 10) else {
            XCTFail("Onboarding did not appear")
            return
        }
        capture("00-Welcome")
    }

    // MARK: - Flow helpers

    @MainActor
    private func createCard(inspiration: String, captureGenerator: Bool) {
        goToTab("Home")

        let createCard = app.buttons["home.createCard"]
        guard createCard.waitForExistence(timeout: 10) else { return }
        createCard.tap()

        let generate = app.buttons["cardDetail.generateWithAI"]
        guard generate.waitForExistence(timeout: 10) else { return }
        generate.tap()

        let inspirationField = app.textFields["e.g., love, friendship, humor"]
        guard inspirationField.waitForExistence(timeout: 10) else { return }
        inspirationField.tap()
        // Trailing newline submits and dismisses the keyboard, so screenshots
        // show the full results list.
        inspirationField.typeText(inspiration + "\n")

        let generateSayings = app.buttons["sayings.generate"]
        guard generateSayings.waitForExistence(timeout: 5) else { return }
        generateSayings.tap()

        let saying = app.buttons.matching(identifier: "sayings.row").firstMatch
        guard saying.waitForExistence(timeout: 10) else { return }

        if captureGenerator {
            capture("03-AISayings")
        }

        waitUntilHittable(saying)
        saying.tap()

        let done = app.buttons["sayings.done"]
        if done.waitForExistence(timeout: 5) {
            done.tap()
        }

        let save = app.buttons["cardDetail.save"]
        if save.waitForExistence(timeout: 5), save.isEnabled {
            save.tap()
        }
    }

    @MainActor
    private func dismissEditor() {
        let cancel = app.buttons["Cancel"].firstMatch
        if cancel.exists, cancel.isHittable {
            cancel.tap()
        }
    }

    @MainActor
    private func goToTab(_ name: String) {
        let tab = app.tabBars.buttons[name]
        if tab.waitForExistence(timeout: 5), tab.isHittable {
            tab.tap()
            return
        }
        // macOS/iPad sidebar layouts expose the same labels as buttons
        let sidebarItem = app.buttons[name].firstMatch
        if sidebarItem.exists, sidebarItem.isHittable {
            sidebarItem.tap()
        }
    }

    @MainActor
    private func waitUntilHittable(_ element: XCUIElement, timeout: TimeInterval = 10) {
        expectation(for: NSPredicate(format: "isHittable == true"), evaluatedWith: element)
        waitForExpectations(timeout: timeout)
    }

    // MARK: - Capture

    @MainActor
    private func capture(_ name: String) {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
