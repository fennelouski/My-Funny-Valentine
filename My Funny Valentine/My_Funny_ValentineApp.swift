//
//  My_Funny_ValentineApp.swift
//  My Funny Valentine
//
//  Created by Nathan Fennel on 2/12/26.
//

import SwiftUI
import SwiftData
import CloudKit

@main
struct My_Funny_ValentineApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Card.self,
            FaceImage.self,
            CardImage.self,
            StickerReference.self,
            UserPreferences.self,
        ])
        
        // Prefer CloudKit-backed storage, but never crash on launch when it
        // isn't available (no iCloud account, entitlement problems, etc.).
        let cloudConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .automatic
        )
        if let container = try? ModelContainer(for: schema, configurations: [cloudConfiguration]) {
            return container
        }

        let localConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .none
        )
        if let container = try? ModelContainer(for: schema, configurations: [localConfiguration]) {
            return container
        }

        // Last resort so the app still opens; cards won't survive a relaunch.
        do {
            return try ModelContainer(
                for: schema,
                configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)]
            )
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
        #if os(macOS)
        // Matches an App Store Mac screenshot size (2560x1600 at 2x).
        .defaultSize(width: 1280, height: 800)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Card") {
                    // Handle new card creation
                    NotificationCenter.default.post(name: NSNotification.Name("NewCard"), object: nil)
                }
                .keyboardShortcut("n", modifiers: .command)
            }
            
            CommandGroup(after: .toolbar) {
                Button("Export Card...") {
                    NotificationCenter.default.post(name: NSNotification.Name("ExportCard"), object: nil)
                }
                .keyboardShortcut("e", modifiers: [.command, .shift])
                
                Divider()
                
                Button("Preferences...") {
                    NotificationCenter.default.post(name: NSNotification.Name("ShowPreferences"), object: nil)
                }
                .keyboardShortcut(",", modifiers: .command)
            }
        }
        #endif
    }
}
