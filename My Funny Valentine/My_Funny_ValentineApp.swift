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
        
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .automatic
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
        #if os(visionOS)
        .windowResizability(.contentSize)
        .defaultSize(width: 1200, height: 800)
        #endif
        #if os(macOS)
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
