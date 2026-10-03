import XCTest

/// Captures real native screens for later marketing composition.
/// Run only on owned QA devices; --uitesting uses a separate persistent library.
final class ScreenshotUITests: XCTestCase {
    private var app: XCUIApplication!
    private var capturedScenes: [String] = []
    private var qaStoreName = ""

    override func setUpWithError() throws {
        continueAfterFailure = false
        capturedScenes = []
        qaStoreName = "gallery-\(UUID().uuidString)"
    }

    @MainActor
    func testCaptureAppStoreScreenshots() throws {
        launch(tab: 0)
        let pizza = app.buttons["starter.starter_pizza_1"]
        try require(pizza, "Home must show the starter gallery")
        try capture("01-All-Cards", showing: [
            app.buttons["home.createCard"],
            app.descendants(matching: .any)["home.collection"].firstMatch,
            pizza
        ])

        try tap(pizza, "Open the pizza starter")
        try assertEditor(message: "You had me at pizza.")
        let personalNote = "Love, Alex"
        let note = try textInput(identifier: "cardDetail.note", placeholder: "Love, me")
        try reveal(note)
        try tap(note, "Personalize the note")
        XCTAssertTrue((note.value as? String ?? "").isEmpty || note.value as? String == "Love, me")
        note.typeText(personalNote)
        XCTAssertEqual(note.value as? String, personalNote)

        // Closing the preview can restore note-field focus. Scroll before
        // checking dismissal so the editor's native gesture handles the keyboard.
        if app.keyboards.firstMatch.exists {
            try openSharePreview()
            try closeSharePreview()
        }
        try scrollToTop()
        try waitForKeyboardToClose()
        try assertEditor(message: "You had me at pizza.")
        try capture("02-Personalized-Pizza", showing: [
            try visiblePreview(), app.buttons["cardDetail.save"]
        ])

        try openSharePreview()
        try capture("03-Ready-To-Send-PNG", showing: [
            try visiblePreview(), app.buttons["cardDetail.sharePNG"]
        ])
        try closeSharePreview()
        try saveEditor()

        let collections: [(title: String, template: String, message: String, scene: String)] = [
            ("Cosmic love", "starter_space_1", "You're the center of my universe.", "04-Cosmic-Love"),
            ("Lovebirds", "starter_birds_1", "You're my favorite person to perch beside.", "05-Lovebirds"),
            ("Dino-mite", "starter_dino_1", "You're dino-mite, Valentine.", "06-Dino-Mite"),
            ("Disco date", "starter_disco_1", "You and me? Same groove.", "07-Disco-Date"),
            ("Sweet tooth", "starter_sweets_1", "I'm sweet on you.", "08-Sweet-Tooth")
        ]
        for collection in collections {
            try chooseCollection(collection.title)
            let starter = app.buttons["starter.\(collection.template)"]
            try reveal(starter)
            try tap(starter, "Open \(collection.title)")
            try assertEditor(message: collection.message)
            try capture(collection.scene, showing: [
                try visiblePreview(), app.buttons["cardDetail.save"]
            ])
            // Populate the QA library through Save, rather than fake seed cards.
            try saveEditor()
        }

        // The existing launch hook selects the same native tab/sidebar route
        // on Mac and iOS, avoiding assumptions about sidebar AX element types.
        launch(tab: 1)
        try require(app.buttons["library.newCard"], "My Cards must open")
        let savedPizza = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", personalNote)).firstMatch
        try reveal(savedPizza)
        try tap(savedPizza, "Reopen the card created by this run")
        try assertEditor(message: "You had me at pizza.")
        let reopenedNote = try textInput(identifier: "cardDetail.note", placeholder: "Love, me")
        XCTAssertEqual(reopenedNote.value as? String, personalNote, "The personalized card must survive relaunch")
        // Saving the reopened card moves it to the front of the recent library.
        try saveEditor()
        try scrollToTop()
        try capture("09-My-Cards", showing: [app.buttons["library.newCard"], savedPizza])

        try tap(savedPizza, "Open a saved card to find a saying")
        try assertEditor(message: "You had me at pizza.")
        let findWords = app.buttons["cardDetail.generateWithAI"]
        try reveal(findWords)
        try tap(findWords, "Open Find the words")
        let inspiration = try textInput(identifier: "", placeholder: "e.g., love, friendship, humor")
        try tap(inspiration, "Enter inspiration")
        inspiration.typeText("pizza")
        XCTAssertEqual(inspiration.value as? String, "pizza")
        try tap(app.buttons["sayings.generate"], "Generate real sayings")
        let firstSaying = app.buttons.matching(identifier: "sayings.row").firstMatch
        try require(firstSaying, "Generation must return usable sayings", timeout: 120)
        XCTAssertGreaterThan(firstSaying.label.trimmingCharacters(in: .whitespacesAndNewlines).count, 10)
        if app.keyboards.firstMatch.exists {
            let results = try currentScrollView()
            results.swipeUp()
            results.swipeDown()
        }
        try waitForKeyboardToClose()
        try tap(firstSaying, "Select a saying")
        XCTAssertTrue(app.buttons["sayings.done"].isEnabled)
        try capture("10-Find-The-Words", showing: [firstSaying, app.buttons["sayings.done"]])
        try tap(app.buttons["sayings.done"], "Use the selected saying in the draft")
        // Leave the earlier saved card intact; no existing QA records are deleted.
        try tap(app.buttons["cardDetail.cancel"], "Discard this final exploratory edit")

        XCTAssertEqual(capturedScenes.count, 10)
        XCTAssertEqual(Set(capturedScenes).count, 10, "Every attachment must name a distinct scene")
    }

    @MainActor
    private func launch(tab: Int) {
        app?.terminate()
        app = XCUIApplication()
        app.launchArguments = [
            "--uitesting", "-screenshotTab", String(tab),
            "-qaStoreName", qaStoreName,
            "-skipOnboarding", "YES", "-showOnboarding", "NO", "-seedSampleCards", "NO"
        ]
        app.launch()
    }

    @MainActor
    private func assertEditor(message: String) throws {
        try require(app.buttons["cardDetail.cancel"], "The card editor must open")
        try require(app.buttons["cardDetail.save"], "The editor must offer Save")
        XCTAssertTrue(app.buttons["cardDetail.save"].isEnabled)
        let field = try textInput(identifier: "cardDetail.message", placeholder: "You're my favorite person.")
        XCTAssertEqual(field.value as? String, message, "The chosen starter must reach the editor")
        _ = try visiblePreview()
        XCTAssertFalse(app.staticTexts["Card unavailable"].exists)
        XCTAssertFalse(app.alerts.firstMatch.exists)
    }

    @MainActor
    private func textInput(identifier: String, placeholder: String) throws -> XCUIElement {
        var candidates: [XCUIElement] = []
        if !identifier.isEmpty {
            let group = app.descendants(matching: .any)[identifier].firstMatch
            candidates = [app.textFields[identifier], app.textViews[identifier], group.textFields.firstMatch, group.textViews.firstMatch]
        }
        candidates += [app.textFields[placeholder], app.textViews[placeholder]]
        if let field = candidates.first(where: { $0.exists }) { return field }
        let fallback = app.textFields[placeholder]
        try require(fallback, "Expected text input: \(placeholder)")
        return fallback
    }

    @MainActor
    private func chooseCollection(_ title: String) throws {
        try scrollToTop()
        let picker = app.descendants(matching: .any)["home.collection"].firstMatch
        try tap(picker, "Open the collection picker")
        #if os(macOS)
        let primary = app.menuItems[title].firstMatch
        #else
        let primary = app.buttons[title].firstMatch
        #endif
        if primary.waitForExistence(timeout: 3) {
            try tap(primary, "Choose \(title)")
        } else {
            try tap(app.staticTexts[title].firstMatch, "Choose \(title) from the native menu")
        }
    }

    @MainActor
    private func openSharePreview() throws {
        try tap(app.buttons["cardDetail.share"], "Prepare the actual PNG")
        try require(app.buttons["cardDetail.sharePNG"], "PNG export must finish", timeout: 20)
        XCTAssertFalse(app.alerts.firstMatch.exists)
    }

    @MainActor
    private func closeSharePreview() throws {
        try tap(app.buttons["Done"].firstMatch, "Close Ready to send")
        try require(app.buttons["cardDetail.save"], "Return to the card draft")
    }

    @MainActor
    private func saveEditor() throws {
        try tap(app.buttons["cardDetail.save"], "Save this card")
        let closed = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: app.buttons["cardDetail.save"])
        XCTAssertEqual(XCTWaiter.wait(for: [closed], timeout: 10), .completed, "Save must close the editor")
        XCTAssertFalse(app.alerts.firstMatch.exists)
    }

    @MainActor
    private func visiblePreview() throws -> XCUIElement {
        let previews = app.descendants(matching: .any).matching(identifier: "cardDetail.preview")
        try require(previews.firstMatch, "A rendered card preview must exist")
        guard let preview = previews.allElementsBoundByIndex.first(where: { $0.isHittable }) else {
            throw CaptureError.missing("The card preview is offscreen")
        }
        XCTAssertGreaterThan(preview.frame.width, 160)
        XCTAssertGreaterThan(preview.frame.height, 200)
        return preview
    }

    @MainActor
    private func reveal(_ element: XCUIElement) throws {
        for _ in 0..<6 {
            if element.exists && element.isHittable { return }
            try scroll(down: true)
        }
        try require(element, "The expected control must exist after scrolling")
        XCTAssertTrue(element.isHittable, "The expected control must be visible")
    }

    @MainActor
    private func scrollToTop() throws {
        for _ in 0..<3 { try scroll(down: false) }
    }

    @MainActor
    private func scroll(down: Bool) throws {
        let scrollView = try currentScrollView()
        #if os(macOS)
        scrollView.scroll(byDeltaX: 0, deltaY: down ? -500 : 500)
        #else
        if down { scrollView.swipeUp() } else { scrollView.swipeDown() }
        #endif
    }

    @MainActor
    private func currentScrollView() throws -> XCUIElement {
        if isVisible(app.buttons["sayings.generate"]) || isVisible(app.buttons["sayings.done"]) {
            return try visibleScrollView(
                app.scrollViews.containing(.button, identifier: "sayings.row"),
                reason: "The visible sayings result list must receive the scroll"
            )
        }
        if isVisible(app.buttons["cardDetail.sharePNG"]) {
            return try visibleScrollView(
                app.scrollViews.matching(identifier: "cardShare.scroll"),
                reason: "The visible share preview must receive the scroll"
            )
        }
        if isVisible(app.buttons["cardDetail.save"]) {
            return try visibleScrollView(
                app.scrollViews.matching(identifier: "cardDetail.scroll"),
                reason: "The visible card editor must receive the scroll"
            )
        }
        if isVisible(app.descendants(matching: .any)["home.collection"].firstMatch)
            || isVisible(app.buttons["library.newCard"]) {
            return try visibleScrollView(
                app.scrollViews,
                reason: "The visible gallery or library must receive the scroll"
            )
        }
        throw CaptureError.missing("No current scrollable screen is visible")
    }

    @MainActor
    private func isVisible(_ element: XCUIElement) -> Bool {
        element.exists && element.isHittable
    }

    @MainActor
    private func visibleScrollView(_ query: XCUIElementQuery, reason: String) throws -> XCUIElement {
        let visible = query.allElementsBoundByIndex.filter {
            $0.exists && $0.isHittable && $0.frame.width > 0 && $0.frame.height > 0
        }
        // The outer gallery is larger than its horizontal recent-card strip.
        guard let scrollView = visible.max(by: {
            $0.frame.width * $0.frame.height < $1.frame.width * $1.frame.height
        }) else { throw CaptureError.missing(reason) }
        return scrollView
    }

    @MainActor
    private func waitForKeyboardToClose() throws {
        let closed = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: app.keyboards.firstMatch)
        guard XCTWaiter.wait(for: [closed], timeout: 5) == .completed else {
            throw CaptureError.missing("The keyboard must close before a marketing capture")
        }
    }

    @MainActor
    private func require(_ element: XCUIElement, _ reason: String, timeout: TimeInterval = 10) throws {
        guard element.waitForExistence(timeout: timeout) else { throw CaptureError.missing(reason) }
    }

    @MainActor
    private func tap(_ element: XCUIElement, _ reason: String) throws {
        try require(element, reason)
        let hittable = XCTNSPredicateExpectation(predicate: NSPredicate(format: "isHittable == true"), object: element)
        guard XCTWaiter.wait(for: [hittable], timeout: 5) == .completed else { throw CaptureError.missing(reason) }
        XCTAssertTrue(element.isEnabled, reason)
        element.tap()
    }

    @MainActor
    private func capture(_ name: String, showing elements: [XCUIElement]) throws {
        for element in elements {
            try require(element, "\(name) must show its expected content")
            XCTAssertTrue(element.isHittable, "\(name) must show its expected content onscreen")
        }
        XCTAssertFalse(app.alerts.firstMatch.exists, "Do not capture an error as a product scene")
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
        capturedScenes.append(name)
    }

    private enum CaptureError: Error {
        case missing(String)
    }
}
