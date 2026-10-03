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
    @State private var storage = Self.loadStorage()

    private static func loadStorage() -> Result<ModelContainer, Error> {
        let schema = Schema([
            Card.self, FaceImage.self, CardImage.self, StickerReference.self, UserPreferences.self
        ])
        do {
            let local: ModelConfiguration
            if ScreenshotSupport.shouldUseQAStore {
                let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
                    .appendingPathComponent("MyFunnyValentine-QA-\(ScreenshotSupport.qaStoreName)", isDirectory: true)
                try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
                local = ModelConfiguration(schema: schema, url: directory.appendingPathComponent("cards.store"), cloudKitDatabase: .none)
            } else {
                local = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false, cloudKitDatabase: .none)
            }
            return .success(try ModelContainer(for: schema, configurations: [local]))
        } catch {
            return .failure(error)
        }
    }

    var body: some Scene {
        WindowGroup {
            switch storage {
            case .success(let container):
                ContentView().modelContainer(container)
            case .failure(let error):
                ContentUnavailableView {
                    Label("Cards couldn't open", systemImage: "externaldrive.badge.exclamationmark")
                } description: {
                    Text("Try again to open your saved cards.")
                } actions: {
                    Button("Try again") { storage = Self.loadStorage() }
                    DisclosureGroup("Details") { Text(error.localizedDescription).textSelection(.enabled) }
                        .frame(maxWidth: 480)
                }
            }
        }
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
                Button("Preferences...") {
                    NotificationCenter.default.post(name: NSNotification.Name("ShowPreferences"), object: nil)
                }
                .keyboardShortcut(",", modifiers: .command)
            }
        }
        #endif
    }
}
