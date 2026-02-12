//
//  MacOSUtilities.swift
//  My Funny Valentine
//
//  macOS-specific utilities and enhancements
//

#if os(macOS)
import AppKit
import SwiftUI
import UniformTypeIdentifiers

/// macOS-specific utilities
struct MacOSUtilities {
    /// Export image to file system (macOS only)
    static func exportImage(_ image: PlatformImage, to url: URL) throws {
        guard let tiffData = image.tiffRepresentation,
              let bitmapImage = NSBitmapImageRep(data: tiffData),
              let jpegData = bitmapImage.representation(using: .jpeg, properties: [.compressionFactor: 0.9]) else {
            throw NSError(domain: "MacOSUtilities", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to JPEG"])
        }
        
        try jpegData.write(to: url)
    }
    
    /// Show save panel for exporting image (macOS only)
    static func showSavePanel(for image: PlatformImage, completion: @escaping (URL?) -> Void) {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.jpeg, .png]
        savePanel.nameFieldStringValue = "ValentineCard.jpg"
        savePanel.canCreateDirectories = true
        
        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                do {
                    try exportImage(image, to: url)
                    completion(url)
                } catch {
                    completion(nil)
                }
            } else {
                completion(nil)
            }
        }
    }
}

/// View modifier for drag and drop support (macOS only)
struct DragDropModifier: ViewModifier {
    let onDrop: ([URL]) -> Void
    
    func body(content: Content) -> some View {
        content
            .onDrop(of: [.image, .fileURL], isTargeted: nil) { providers in
                var urls: [URL] = []
                let group = DispatchGroup()
                
                for provider in providers {
                    group.enter()
                    provider.loadItem(forTypeIdentifier: UTType.image.identifier, options: nil) { item, _ in
                        if let url = item as? URL {
                            urls.append(url)
                        }
                        group.leave()
                    }
                }
                
                group.notify(queue: .main) {
                    if !urls.isEmpty {
                        onDrop(urls)
                    }
                }
                
                return !urls.isEmpty
            }
    }
}

extension View {
    /// Add drag and drop support for images (macOS only)
    func dragDrop(onDrop: @escaping ([URL]) -> Void) -> some View {
        modifier(DragDropModifier(onDrop: onDrop))
    }
}

#endif
