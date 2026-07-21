//
//  ScreenshotSupport.swift
//  My Funny Valentine
//
//  Debug-only hooks used to generate App Store marketing screenshots on
//  platforms that can't be driven by XCUITest. Compiled out of Release builds.
//
//  Usage (macOS):
//    open -a "My Funny Valentine.app" --args -screenshotTab 1 -seedSampleCards YES
//

import Foundation
import SwiftData

enum ScreenshotSupport {

    /// Tab to select on launch. Always 0 outside DEBUG builds.
    static var initialTab: Int {
        #if DEBUG
        if UserDefaults.standard.object(forKey: "screenshotTab") != nil {
            return UserDefaults.standard.integer(forKey: "screenshotTab")
        }
        #endif
        return 0
    }

    /// Lets UI tests and screenshot runs jump straight to the app with
    /// `-skipOnboarding YES`. Always false outside DEBUG builds.
    static var shouldSkipOnboarding: Bool {
        #if DEBUG
        return UserDefaults.standard.bool(forKey: "skipOnboarding")
        #else
        return false
        #endif
    }

    /// Forces the onboarding flow to show with `-showOnboarding YES`, even if
    /// it has been completed before. Always false outside DEBUG builds.
    static var shouldForceOnboarding: Bool {
        #if DEBUG
        return UserDefaults.standard.bool(forKey: "showOnboarding")
        #else
        return false
        #endif
    }

    /// Inserts a small set of demo cards when launched with `-seedSampleCards YES`.
    /// No-op in Release builds and when the store already has cards.
    static func seedSampleCardsIfRequested(in context: ModelContext) {
        #if DEBUG
        guard UserDefaults.standard.bool(forKey: "seedSampleCards") else { return }

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
}
