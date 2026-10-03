import XCTest

final class StarterCardUITests: XCTestCase {
    @MainActor
    func testGalleryDraftCancelSaveReopenAndShare() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting", "-hasCompletedOnboarding", "NO"]
        app.launch()
        let starter = app.buttons["starter.starter_pizza_1"]
        XCTAssertTrue(starter.waitForExistence(timeout: 10), "First launch should show usable cards immediately")
        starter.tap()
        let cancel = app.buttons["cardDetail.cancel"]
        XCTAssertTrue(cancel.waitForExistence(timeout: 5))
        cancel.tap()
        XCTAssertTrue(starter.waitForExistence(timeout: 5))
        starter.tap()

        let note = app.textFields["Love, me"]
        if !note.isHittable { app.swipeUp() }
        XCTAssertTrue(note.waitForExistence(timeout: 5))
        note.tap()
        let marker = "For you \(UUID().uuidString.prefix(8))"
        note.typeText(marker)
        app.buttons["cardDetail.save"].tap()
        XCTAssertTrue(app.staticTexts["Your latest"].waitForExistence(timeout: 10))

        app.terminate()
        app.launchArguments = ["--uitesting", "-skipOnboarding", "YES"]
        app.launch()
        let saved = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", marker)).firstMatch
        XCTAssertTrue(saved.waitForExistence(timeout: 10), "Saved card should survive relaunch")
        saved.tap()
        XCTAssertTrue(app.buttons["cardDetail.share"].waitForExistence(timeout: 5))
        app.buttons["cardDetail.share"].tap()
        XCTAssertTrue(app.buttons["cardDetail.sharePNG"].waitForExistence(timeout: 5), "Actual PNG export should be ready")
        app.buttons["Done"].tap()
        app.buttons["cardDetail.cancel"].tap()
    }
}
