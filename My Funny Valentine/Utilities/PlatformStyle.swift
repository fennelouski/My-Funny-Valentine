//
//  PlatformStyle.swift
//  My Funny Valentine
//
//  Semantic colors and navigation helpers that resolve per platform, so views
//  don't have to reach for UIKit-only system colors.
//

import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

extension Color {
    /// Page background behind grouped content.
    static var appGroupedBackground: Color {
        #if os(macOS)
        Color(nsColor: .windowBackgroundColor)
        #else
        Color(uiColor: .systemGroupedBackground)
        #endif
    }

    /// Card/section surface sitting on top of `appGroupedBackground`.
    static var appSecondaryGroupedBackground: Color {
        #if os(macOS)
        Color(nsColor: .controlBackgroundColor)
        #else
        Color(uiColor: .secondarySystemGroupedBackground)
        #endif
    }

    /// Primary window/content background.
    static var appBackground: Color {
        #if os(macOS)
        Color(nsColor: .windowBackgroundColor)
        #else
        Color(uiColor: .systemBackground)
        #endif
    }

    /// Subtle filled surface (chips, rows, progress tracks).
    static var appFill: Color {
        #if os(macOS)
        Color(nsColor: .controlBackgroundColor)
        #else
        Color(uiColor: .systemGray6)
        #endif
    }

    /// Slightly stronger fill than `appFill`.
    static var appSecondaryFill: Color {
        #if os(macOS)
        Color.gray.opacity(0.25)
        #else
        Color(uiColor: .systemGray5)
        #endif
    }
}

extension View {
    /// Applies an inline navigation title on platforms that support it.
    @ViewBuilder
    func appInlineNavigationTitle() -> some View {
        #if os(iOS) || os(visionOS)
        self.navigationBarTitleDisplayMode(.inline)
        #else
        self
        #endif
    }
}
