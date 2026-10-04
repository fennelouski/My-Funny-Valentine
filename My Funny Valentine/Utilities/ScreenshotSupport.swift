//
//  ScreenshotSupport.swift
//  My Funny Valentine
//
//  Debug-only hooks used to generate App Store marketing screenshots on
//  platforms that can't be driven by XCUITest. Compiled out of Release builds.
//
//  Usage (macOS):
//    --mfv-ui-tests --mfv-test-session <UUID> -screenshotTab 1
//

import Foundation
import SwiftData

@MainActor
enum ScreenshotSupport {

    static var qaStoreName: String {
        #if DEBUG
        return MFVRuntime.configuration.session?.uuidString ?? "invalid"
        #else
        return "unused"
        #endif
    }

    /// Native QA uses a separate persistent library; Release always uses the user's store.
    static var shouldUseQAStore: Bool {
        MFVRuntime.isPrivate
    }

    /// Tab to select on launch. Always 0 outside DEBUG builds.
    static var initialTab: Int {
        #if DEBUG
        if let raw = argument("-screenshotTab"), let tab = Int(raw), (0...4).contains(tab) {
            return tab
        }
        if MFVRuntime.preferences.object(forKey: "screenshotTab") != nil {
            return min(max(MFVRuntime.preferences.integer(forKey: "screenshotTab"), 0), 4)
        }
        #endif
        return 0
    }

    /// Lets UI tests and screenshot runs jump straight to the app with
    /// `-skipOnboarding YES`. Always false outside DEBUG builds.
    static var shouldSkipOnboarding: Bool {
        #if DEBUG
        return flag("skipOnboarding") ?? (MFVRuntime.configuration.mode == .ui)
        #else
        return false
        #endif
    }

    /// Forces the onboarding flow to show with `-showOnboarding YES`, even if
    /// it has been completed before. Always false outside DEBUG builds.
    static var shouldForceOnboarding: Bool {
        #if DEBUG
        return flag("showOnboarding") ?? false
        #else
        return false
        #endif
    }

    /// Inserts a small set of demo cards when launched with `-seedSampleCards YES`.
    /// No-op in Release builds and when the store already has cards.
    static func seedSampleCardsIfRequested(in context: ModelContext) {
        #if DEBUG
        guard flag("seedSampleCards") == true else { return }

        let existing = (try? context.fetch(FetchDescriptor<Card>())) ?? []
        guard existing.isEmpty else { return }

        let samples = [
            "You're the coffee to my heart.",
            "I love you more than tacos, and that's saying something.",
            "Roses are red, violets are blue, I really love coffee, but not as much as you.",
            "You're my favorite thing, right after pizza. Kidding. You're first.",
            "Of all the bookshops in all the world, I'm glad I found you.",
            "You make Mondays look boring."
        ]

        for saying in samples {
            context.insert(Card(saying: saying))
        }
        try? context.save()
        #endif
    }

    #if DEBUG
    private static func argument(_ name: String) -> String? {
        let arguments = ProcessInfo.processInfo.arguments
        let indices = arguments.indices.filter { arguments[$0] == name }
        guard indices.count == 1, let index = indices.first, arguments.indices.contains(index + 1) else { return nil }
        return arguments[index + 1]
    }

    private static func flag(_ name: String) -> Bool? {
        if let raw = argument("-" + name)?.lowercased() {
            if ["yes", "true", "1"].contains(raw) { return true }
            if ["no", "false", "0"].contains(raw) { return false }
            return nil
        }
        guard MFVRuntime.preferences.object(forKey: name) != nil else { return nil }
        return MFVRuntime.preferences.bool(forKey: name)
    }
    #endif
}
