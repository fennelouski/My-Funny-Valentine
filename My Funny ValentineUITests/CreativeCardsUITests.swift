import XCTest

#if os(iOS)
/// Uses a release-owner allocated private UUID and exact native controls.
/// Device execution and visual approval are recorded separately. No provider, Photos, print job or share destination is used.
@MainActor
final class CreativeCardsUITests: XCTestCase {
    private var app: XCUIApplication!
    private var session = UUID()
    private var captureIndex = 0
    private enum DriverError: Error { case missing(String), ambiguous(String) }

    override func setUpWithError() throws {
        continueAfterFailure = false
        session = UUID()
        captureIndex = 0
        app = XCUIApplication()
        app.launchArguments = ["--mfv-ui-tests", "--mfv-test-session", session.uuidString]
    }

    override func tearDownWithError() throws { app?.terminate() }

    func testSixStarterFamiliesOpenAndClose() throws {
        try launchPrivate()
        let families = [
            ("Comic crush", "pizza", "comic"), ("Cosmic love", "space", "cosmic"),
            ("Love letters", "birds", "loveLetter"), ("Pop-up hearts", "dino", "popUp"),
            ("Photo booth", "disco", "photoBooth"), ("Confetti party", "sweets", "confetti")
        ]
        for (title, world, family) in families {
            try tap(app.buttons["starter.starter_" + world + "_1"], "Open " + title)
            try require(app.buttons["cardDetail.save"], "Editable starter")
            XCTAssertTrue(app.buttons["cardDetail.save"].isEnabled)
            XCTAssertFalse(app.staticTexts["Card unavailable"].exists)
            let preview = try previewButton()
            XCTAssertEqual(preview.value as? String, "Front")
            capture(title + " front")
            if family == "comic" {
                preview.swipeLeft()
                try waitForValue(preview, "Inside")
                capture("Horizontal drag opens actual card")
                try tap(app.buttons["cardDetail.openCard"], "Close after horizontal opening")
                try waitForValue(preview, "Front")
            }
            try tap(app.buttons["cardDetail.openCard"], "Open actual " + title + " inside")
            try waitForValue(preview, "Inside")
            capture(title + " inside")
            try tap(app.buttons["cardDetail.openCard"], "Close " + title)
            try waitForValue(preview, "Front")
            let selected = app.buttons["cardDetail.style." + family]
            try reveal(selected)
            XCTAssertTrue(selected.isSelected, "The starter must use its genuine family")
            XCTAssertFalse(app.buttons["cardDetail.generateWithAI"].isEnabled)
            XCTAssertFalse(app.buttons["cardDetail.photo"].isEnabled)
            try tap(app.buttons["cardDetail.cancel"], "Leave detached starter")
            try waitForAbsence(app.buttons["cardDetail.save"])
        }
    }

    func testSavedMotionChoiceAndLocalExportSheet() throws {
        try launchPrivate()
        try tap(app.buttons["starter.starter_birds_1"], "Personalize a love letter")
        let message = "A little card for my favorite person"
        let note = "You make ordinary days wonderful. Love, Sam."
        try replaceText(identifier: "cardDetail.message", placeholder: "You're my favorite person.", with: message)
        try replaceText(identifier: "cardDetail.note", placeholder: "Love, me", with: note)
        let motion = app.switches["cardDetail.motion"].firstMatch
        try reveal(motion)
        try require(motion, "Saved motion preference")
        XCTAssertEqual(motion.value as? String, "1")
        let nested = motion.descendants(matching: .switch).allElementsBoundByIndex.filter { $0.isHittable }
        guard nested.count <= 1 else { capture("Ambiguous motion switch"); throw DriverError.ambiguous("Motion switch") }
        try tap(nested.first ?? motion, "Disable only card motion")
        try waitForValue(motion, "0")
        try tap(app.buttons["cardDetail.save"], "Save personal card")
        try waitForAbsence(app.buttons["cardDetail.save"])
        app.terminate()
        try launchPrivate()
        let saved = app.buttons.matching(NSPredicate(format: "label == %@", message + ". " + note)).firstMatch
        try tap(saved, "Reopen actual saved personal card")
        let reopenedNote = try textInput(identifier: "cardDetail.note", placeholder: "Love, me")
        XCTAssertEqual(reopenedNote.value as? String, note)
        try reveal(motion)
        XCTAssertEqual(motion.value as? String, "0", "Motion choice survives the same private session relaunch")
        try tap(app.buttons["cardDetail.openCard"], "Open calm saved card")
        try waitForValue(try previewButton(), "Inside")
        capture("Saved inside with motion off")

        try tap(app.buttons["cardDetail.share"], "Prepare actual front PNG")
        try require(app.buttons["cardDetail.sharePNG"], "Actual front export", timeout: 30)
        capture("Native local export sheet")
        try tap(app.buttons["cardDetail.animateCard"], "Render a full-card GIF without a face")
        try require(app.buttons["cardDetail.shareGIF"], "Actual full-card GIF finished", timeout: 45)
        for kind in ["inside", "pdf", "sticker", "html"] {
            try tap(app.buttons["cardDetail.export." + kind], "Render " + kind)
            let share = app.buttons["cardDetail.share." + kind]
            try require(share, "Actual " + kind + " file finished", timeout: 45)
            XCTAssertTrue(share.isEnabled)
            capture(kind + " file ready")
        }
        XCTAssertFalse(app.alerts.firstMatch.exists)
        XCTAssertFalse(app.buttons["cardDetail.print"].isEnabled, "Private QA must not create a print job")
        try tap(app.buttons["cardDetail.sharePNG"], "Present actual system sharing options")
        let activity = app.otherElements["ActivityListView"]
        try require(activity, "Actual native sharing chooser", timeout: 15)
        capture("Actual native PNG sharing chooser")
        let dismissal = app.otherElements.matching(identifier: "PopoverDismissRegion")
            .allElementsBoundByIndex.first { $0.frame == app.frame }
        guard let dismissal else { throw DriverError.missing("System sharing dismissal region") }
        let sharingScroll = app.scrollViews["cardShare.scroll"]
        let dismissalPoint = CGPoint(x: sharingScroll.frame.minX + sharingScroll.frame.width * 0.1,
                                     y: sharingScroll.frame.minY + sharingScroll.frame.height * 0.1)
        XCTAssertFalse(activity.frame.contains(dismissalPoint), "Dismiss outside the actual native chooser")
        dismissal.coordinate(withNormalizedOffset: CGVector(
            dx: (dismissalPoint.x - app.frame.minX) / app.frame.width,
            dy: (dismissalPoint.y - app.frame.minY) / app.frame.height)).tap()
        try waitForAbsence(activity)
        try tap(app.buttons["Done"].firstMatch, "Dismiss local export options")
        try require(app.buttons["cardDetail.save"], "Same saved draft after export")
        try tap(app.buttons["cardDetail.cancel"], "Leave the saved card intact")
    }

    func testPersonalizedCardMarketingCapture() throws {
        try launchPrivate()
        try tap(app.buttons["starter.starter_birds_1"], "Personalize an actual starter for capture")
        try replaceText(identifier: "cardDetail.message", placeholder: "You're my favorite person.",
                        with: "A little card for my favorite person")
        try replaceText(identifier: "cardDetail.note", placeholder: "Love, me",
                        with: "You make ordinary days wonderful. Love, Sam.")
        let preview = try previewButton()
        let scroll = app.scrollViews["cardDetail.scroll"]
        for _ in 0..<8 {
            if preview.frame.minY > app.buttons["cardDetail.save"].frame.maxY + 4
                && preview.frame.maxY < app.frame.maxY - 16 { break }
            scroll.swipeDown()
        }
        XCTAssertTrue(preview.frame.minY > app.buttons["cardDetail.save"].frame.maxY + 4)
        XCTAssertTrue(preview.frame.maxY < app.frame.maxY - 16)
        capture("Personalized full front for marketing")
        try tap(app.buttons["cardDetail.openCard"], "Open actual personalized note for capture")
        try waitForValue(preview, "Inside")
        capture("Personalized full inside for marketing")
        try tap(app.buttons["cardDetail.cancel"], "Leave only the private capture draft")
    }

    /// The release owner runs this method with the allocated Simulator's actual
    /// appearance and content-size settings, then restores its previous values.
    func testReadableControlsAtCurrentAppearanceAndTextSize() throws {
        try launchPrivate()
        let write = app.buttons["home.createCard"]
        XCTAssertTrue(write.isHittable && app.frame.contains(write.frame), "Write is reachable on first launch")
        capture("Readable first viewport")
        try tap(app.buttons["starter.starter_pizza_1"], "Open card at current text size")
        try require(app.buttons["cardDetail.save"], "Save remains available")
        capture("Readable preview and editor title")
        let style = app.buttons["cardDetail.style.cosmic"]
        try reveal(style)
        try tap(style, "Choose Cosmic love at current text size")
        XCTAssertTrue(style.isSelected)
        let motion = app.switches["cardDetail.motion"].firstMatch
        try reveal(motion)
        try require(motion, "Motion control remains reachable")
        capture("Readable styles and motion control")
        try tap(app.buttons["cardDetail.cancel"], "Cancel private accessibility draft")
    }

    func testInvalidPrivateSessionRemainsBlank() throws {
        app.launchArguments = ["--mfv-ui-tests", "--mfv-test-session", "not-a-valid-uuid"]
        app.launch()
        capture("Rejected private request before interaction")
        try require(app.staticTexts["mfv.private.invalid"], "Invalid explicit request stays blank")
        XCTAssertFalse(app.buttons["home.createCard"].exists)
        XCTAssertFalse(app.buttons["home.collection"].exists)
        XCTAssertFalse(app.tabBars.firstMatch.exists)
    }

    private func launchPrivate() throws {
        app.launch()
        capture("Private bootstrap before interaction")
        let marker = app.descendants(matching: .any)["mfv.private.ui." + session.uuidString].firstMatch
        try require(marker, "Valid private UI marker")
        XCTAssertFalse(app.staticTexts["mfv.private.unit"].exists)
        XCTAssertFalse(app.staticTexts["mfv.private.invalid"].exists)
        try require(app.buttons["home.createCard"], "Actual card library")
    }

    private func previewButton() throws -> XCUIElement {
        let button = app.descendants(matching: .any).matching(NSPredicate(format: "identifier == %@ AND label BEGINSWITH %@", "cardDetail.preview", "Card preview. ")).firstMatch
        try require(button, "Genuine rendered preview")
        return button
    }

    private func textInput(identifier: String, placeholder: String) throws -> XCUIElement {
        let group = app.descendants(matching: .any)[identifier].firstMatch
        let candidates = [app.textFields[identifier], app.textViews[identifier],
                          group.textFields.firstMatch, group.textViews.firstMatch,
                          app.textFields[placeholder], app.textViews[placeholder]]
        guard let input = candidates.first(where: { $0.exists }) else {
            capture("Missing text field " + identifier); throw DriverError.missing(identifier)
        }
        return input
    }

    private func replaceText(identifier: String, placeholder: String, with text: String) throws {
        let input = try textInput(identifier: identifier, placeholder: placeholder)
        try tap(input, "Edit " + identifier)
        let old = input.value as? String ?? ""
        if !old.isEmpty && old != placeholder {
            input.press(forDuration: 1.1)
            let selectAll = app.buttons["Select All"]
            if selectAll.waitForExistence(timeout: 3) { selectAll.tap() }
            else {
                let menuItem = app.menuItems["Select All"]
                try require(menuItem, "Select complete editable text")
                menuItem.tap()
            }
        }
        input.typeText(text)
        XCTAssertEqual(input.value as? String, text)
        let done = app.buttons["editor.dismissKeyboard"].firstMatch
        try tap(done, "Dismiss only editor keyboard")
        let keyboard = app.keyboards.firstMatch
        try waitForAbsence(keyboard)
    }

    private func reveal(_ element: XCUIElement) throws {
        for _ in 0..<8 {
            if element.exists && element.isHittable { return }
            let preferred = [app.scrollViews["cardShare.scroll"], app.scrollViews["cardDetail.scroll"]]
            guard let scroll = (preferred + app.scrollViews.allElementsBoundByIndex).first(where: { $0.exists && $0.isHittable }) else {
                capture("No scroll for " + element.identifier); throw DriverError.missing("Visible scroll")
            }
            if element.exists && element.frame.minY < scroll.frame.minY { scroll.swipeDown() }
            else { scroll.swipeUp() }
        }
        capture("Unreachable " + element.identifier)
        throw DriverError.missing(element.identifier)
    }

    private func tap(_ element: XCUIElement, _ name: String) throws {
        try require(element, name)
        try reveal(element)
        capture("Before " + name)
        guard element.isEnabled else { throw DriverError.missing("Disabled " + name) }
        element.tap()
    }

    private func require(_ element: XCUIElement, _ reason: String, timeout: TimeInterval = 10) throws {
        guard element.waitForExistence(timeout: timeout) else {
            capture("Missing " + reason); XCTFail(reason); throw DriverError.missing(reason)
        }
    }

    private func waitForValue(_ element: XCUIElement, _ value: String) throws {
        let expectation = XCTNSPredicateExpectation(predicate: NSPredicate(format: "value == %@", value), object: element)
        guard XCTWaiter.wait(for: [expectation], timeout: 8) == .completed else {
            capture("Value did not reach " + value); XCTFail("Expected " + value); throw DriverError.missing("Value " + value)
        }
    }

    private func waitForAbsence(_ element: XCUIElement) throws {
        let expectation = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: element)
        guard XCTWaiter.wait(for: [expectation], timeout: 10) == .completed else {
            capture("Modal or keyboard still present"); XCTFail("Expected dismissal"); throw DriverError.missing("Dismissal")
        }
    }

    private func capture(_ name: String) {
        captureIndex += 1
        let prefix = String(format: "%02d-", captureIndex) + name
        let image = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        image.name = prefix; image.lifetime = .keepAlways; add(image)
        let accessibility = XCTAttachment(string: app.debugDescription)
        accessibility.name = prefix + "-AX"; accessibility.lifetime = .keepAlways; add(accessibility)
    }
}
#endif
