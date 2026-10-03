import XCTest

#if os(iOS)
import UIKit

final class SettingsNavigationUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    @MainActor
    func testCategoriesAndTruthfulLocalStorage() throws {
        // Use an owned empty simulator. These arguments select the normal Settings tab.
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting", "-screenshotTab", "2", "-skipOnboarding", "YES"]
        app.launch()
        capture("settings-categories", in: app)
        openSection("generation", in: app)
        XCTAssertTrue(app.descendants(matching: .any)["settings.cardSample"].firstMatch.waitForExistence(timeout: 5))
        capture("settings-generation", in: app)

        openSection("iCloud", in: app)
        XCTAssertTrue(app.staticTexts["Saved on this device"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.switches["settings.syncEnabled"].exists)
        capture("settings-storage", in: app)

        openSection("about", in: app)
        XCTAssertTrue(app.buttons["settings.replayOnboarding"].waitForExistence(timeout: 5))
        capture("settings-about", in: app)
        openSection("iCloud", in: app)
        XCTAssertTrue(app.staticTexts["Saved on this device"].waitForExistence(timeout: 5))

        app.terminate()
        app.launch()
        openSection("iCloud", in: app)
        XCTAssertTrue(app.staticTexts["Saved on this device"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.switches["settings.syncEnabled"].exists)
    }

    @MainActor
    func testCaptureWideLargeTextSettings() throws {
        XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication()
        app.launchArguments = [
            "--uitesting", "-screenshotTab", "2", "-skipOnboarding", "YES",
            "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"
        ]
        app.launch()
        openSection("generation", in: app)
        let sample = app.descendants(matching: .any)["settings.cardSample"].firstMatch
        XCTAssertTrue(sample.waitForExistence(timeout: 5))
        let sidebar = app.descendants(matching: .any)["settings.section.generation"].firstMatch
        XCTAssertTrue(sidebar.isHittable, "Wide settings keep the categories beside the detail")
        XCTAssertGreaterThanOrEqual(sample.frame.minX, sidebar.frame.maxX)
        capture("settings-wide-large-generation", in: app)
        openSection("iCloud", in: app)
        XCTAssertTrue(app.staticTexts["Saved on this device"].isHittable)
        capture("settings-wide-large-storage", in: app)
        openSection("about", in: app)
        XCTAssertTrue(app.buttons["settings.replayOnboarding"].isHittable)
        capture("settings-wide-large-about", in: app)
    }

    @MainActor private func openSection(_ section: String, in app: XCUIApplication) {
        let row = app.descendants(matching: .any)["settings.section.\(section)"].firstMatch
        if !row.isHittable {
            let back = app.navigationBars.buttons.matching(identifier: "BackButton")
                .allElementsBoundByIndex.first { $0.isHittable }
            back?.tap()
        }
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        XCTAssertTrue(row.isHittable)
        row.tap()
    }

    @MainActor private func capture(_ name: String, in app: XCUIApplication) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
#endif
