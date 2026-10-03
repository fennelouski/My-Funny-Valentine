//
//  ContentView.swift
//  My Funny Valentine
//
//  Main app entry with tab navigation
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = true
    @State private var selectedTab = ScreenshotSupport.initialTab

    /// Set when onboarding is dismissed in this session, so a forced run
    /// (`-showOnboarding`) can still be completed rather than looping forever.
    @State private var dismissedOnboarding = false
    @State private var replayWelcome = false
    @State private var showingNewCard = false

    private var showOnboarding: Bool {
        if dismissedOnboarding { return false }
        if ScreenshotSupport.shouldForceOnboarding { return true }
        if ScreenshotSupport.shouldSkipOnboarding { return false }
        return replayWelcome
    }

    var body: some View {
        Group {
            if showOnboarding {
                OnboardingView {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        hasCompletedOnboarding = true
                        dismissedOnboarding = true
                    }
                }
            } else {
                content
            }
        }
        .sheet(isPresented: $showingNewCard) {
            NavigationStack { CardDetailView(card: nil) }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NewCard"))) { _ in
            showingNewCard = true
        }
        .task {
            ScreenshotSupport.seedSampleCardsIfRequested(in: modelContext)
            if !showOnboarding { hasCompletedOnboarding = true }
        }
        .onChange(of: hasCompletedOnboarding) { _, completed in
            // "Show Welcome Again" in Settings replays the flow mid-session.
            if !completed { dismissedOnboarding = false; replayWelcome = true }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("BrowseStarters"))) { _ in
            selectedTab = 0
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ShowPreferences"))) { _ in
            // Keep the current settings category when Preferences is invoked again.
            if !(2...4).contains(selectedTab) { selectedTab = 2 }
        }
    }

    @ViewBuilder
    private var content: some View {
        #if os(macOS)
        // macOS: Use NavigationSplitView for better macOS UX
        NavigationSplitView {
            List(selection: $selectedTab) {
                Label("Home", systemImage: "heart.fill")
                    .tag(0)
                Label("My Cards", systemImage: "rectangle.stack.fill")
                    .tag(1)
                Section("Settings") {
                    ForEach(SettingsSection.allCases) { section in
                        SettingsSectionLabel(section: section, isSelected: selectedTab == section.sidebarTag)
                            .tag(section.sidebarTag)
                            .accessibilityIdentifier("settings.section.\(section.rawValue)")
                    }
                }
            }
            .navigationSplitViewColumnWidth(min: 200, ideal: 250)
        } detail: {
            Group {
                switch selectedTab {
                case 0:
                    HomeView()
                case 1:
                    CardListView()
                case 2:
                    SettingsView(section: .generation)
                case 3:
                    SettingsView(section: .iCloud)
                case 4:
                    SettingsView(section: .about)
                default:
                    HomeView()
                }
            }
        }
        .frame(minWidth: 720, idealWidth: 1280, minHeight: 560, idealHeight: 800)
        #else
        // iOS/visionOS: Use TabView
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "heart.fill")
                }
                .tag(0)
            
            CardListView()
                .tabItem {
                    Label("My Cards", systemImage: "rectangle.stack.fill")
                }
                .tag(1)
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(2)
        }
        .tint(.pink)
        #endif
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Card.self, UserPreferences.self], inMemory: true)
}
