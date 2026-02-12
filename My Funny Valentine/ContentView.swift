//
//  ContentView.swift
//  My Funny Valentine
//
//  Main app entry with tab navigation
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        #if os(macOS)
        // macOS: Use NavigationSplitView for better macOS UX
        NavigationSplitView {
            List(selection: $selectedTab) {
                Label("Home", systemImage: "heart.fill")
                    .tag(0)
                Label("My Cards", systemImage: "rectangle.stack.fill")
                    .tag(1)
                Label("Settings", systemImage: "gearshape.fill")
                    .tag(2)
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
                    SettingsView()
                default:
                    HomeView()
                }
            }
        }
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
