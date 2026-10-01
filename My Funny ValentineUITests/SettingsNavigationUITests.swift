import XCTest

#if os(iOS)
import UIKit

final class SettingsNavigationUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    @MainActor
    func testCategoriesAndSavedSyncPreference() throws {
        // Use an owned empty simulator. These arguments select the normal Settings tab.
        let app = XCUIApplication()
        app.launchArguments = ["-screenshotTab", "2", "-skipOnboarding", "YES"]
        app.launch()
        capture("settings-categories", in: app)
        openSection("generation", in: app)
        XCTAssertTrue(app.descendants(matching: .any)["settings.cardSample"].firstMatch.waitForExistence(timeout: 5))
        capture("settings-generation", in: app)

        openSection("iCloud", in: app)
        let sync = app.switches["settings.syncEnabled"]
        XCTAssertTrue(sync.waitForExistence(timeout: 5))
        let originalValue = sync.value as? String
        // SwiftUI exposes the whole row as a switch; hit the native control at its trailing edge.
        sync.coordinate(withNormalizedOffset: CGVector(dx: 0.94, dy: 0.5)).tap()
        let changed = XCTNSPredicateExpectation(predicate: NSPredicate(format: "value != %@", originalValue ?? ""), object: sync)
        XCTAssertEqual(XCTWaiter.wait(for: [changed], timeout: 3), .completed)
        let savedValue = sync.value as? String
        XCTAssertNotEqual(savedValue, originalValue)
        XCTAssertFalse(app.staticTexts["Synced"].exists)
        capture("settings-icloud", in: app)

        openSection("about", in: app)
        XCTAssertTrue(app.buttons["settings.replayOnboarding"].waitForExistence(timeout: 5))
        capture("settings-about", in: app)
        openSection("iCloud", in: app)
        XCTAssertEqual(sync.value as? String, savedValue)

        app.terminate()
        app.launch()
        openSection("iCloud", in: app)
        XCTAssertEqual(sync.value as? String, savedValue, "The saved preference survives relaunch")
        // Leave the owned sandbox with the same preference it started with.
        sync.coordinate(withNormalizedOffset: CGVector(dx: 0.94, dy: 0.5)).tap()
        let restored = XCTNSPredicateExpectation(predicate: NSPredicate(format: "value == %@", originalValue ?? ""), object: sync)
        XCTAssertEqual(XCTWaiter.wait(for: [restored], timeout: 3), .completed)
        XCTAssertEqual(sync.value as? String, originalValue)
    }

    @MainActor
    func testCaptureWideLargeTextSettings() throws {
        XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication()
        app.launchArguments = [
            "-screenshotTab", "2", "-skipOnboarding", "YES",
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
        XCTAssertTrue(app.switches["settings.syncEnabled"].isHittable)
        capture("settings-wide-large-icloud", in: app)
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
