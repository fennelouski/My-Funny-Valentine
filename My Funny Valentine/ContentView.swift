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
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Card.self, UserPreferences.self], inMemory: true)
}
