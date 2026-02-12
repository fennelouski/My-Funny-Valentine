//
//  SharingUsageExample.swift
//  My Funny Valentine
//
//  Example usage of sharing and export features
//

import SwiftUI
import UIKit

#if os(iOS)
// Example: Using SharePreviewView in a card detail view
struct SharingExampleCardDetailView: View {
    let card: Card
    @State private var showingSharePreview = false
    
    var body: some View {
        VStack {
            // Card content...
            
            Button("Share") {
                showingSharePreview = true
            }
        }
        .sheet(isPresented: $showingSharePreview) {
            if let cardImage = card.renderAsImage() {
                SharePreviewView(
                    cardImage: cardImage,
                    onShare: { destination in
                        // Handle share action
                        print("Sharing to \(destination)")
                    },
                    onCancel: {
                        showingSharePreview = false
                    },
                    onEdit: {
                        // Navigate to edit view
                        print("Edit card")
                    }
                )
            }
        }
    }
}

// Example: Direct sharing without preview
struct QuickShareButton: View {
    let card: Card
    
    var body: some View {
        Button("Quick Share") {
            shareCard()
        }
    }
    
    private func shareCard() {
        guard let cardImage = card.renderAsImage(),
              let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            return
        }
        
        ShareService.shared.shareImage(cardImage, from: rootViewController) { completed, error in
            if let error = error {
                print("Share failed: \(error)")
            } else if completed {
                print("Share completed")
            }
        }
    }
}

// Example: Save to Photos
struct SaveToPhotosButton: View {
    let card: Card
    @State private var isSaving = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        Button(action: saveToPhotos) {
            if isSaving {
                ProgressView()
            } else {
                Label("Save to Photos", systemImage: "photo.on.rectangle")
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func saveToPhotos() {
        guard let cardImage = card.renderAsImage() else { return }
        
        isSaving = true
        Task {
            do {
                try await ShareService.shared.saveToPhotos(cardImage)
                await MainActor.run {
                    isSaving = false
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}

// Example: Platform-specific sharing
struct PlatformShareButton: View {
    let card: Card
    
    var body: some View {
        VStack {
            Button("Share to Instagram") {
                shareToInstagram()
            }
            
            Button("Share to TikTok") {
                shareToTikTok()
            }
            
            Button("Share to Facebook") {
                shareToFacebook()
            }
        }
    }
    
    private func shareToInstagram() {
        guard let cardImage = card.optimizedImage(for: .instagram),
              let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            return
        }
        
        do {
            try ShareService.shared.shareToInstagram(cardImage, from: rootViewController)
        } catch {
            print("Instagram share failed: \(error)")
        }
    }
    
    private func shareToTikTok() {
        guard let cardImage = card.optimizedImage(for: .tiktok),
              let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            return
        }
        
        do {
            try ShareService.shared.shareToTikTok(cardImage, from: rootViewController)
        } catch {
            print("TikTok share failed: \(error)")
        }
    }
    
    private func shareToFacebook() {
        guard let cardImage = card.optimizedImage(for: .facebook),
              let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            return
        }
        
        do {
            try ShareService.shared.shareToFacebook(cardImage, from: rootViewController)
        } catch {
            print("Facebook share failed: \(error)")
        }
    }
}
#endif

#if os(macOS)
// Example: macOS GIF Export
import AppKit

struct MacCardDetailView: View {
    let card: Card
    @State private var showingGIFExport = false
    
    var body: some View {
        VStack {
            // Card content...
            
            Button("Export as GIF") {
                showingGIFExport = true
            }
        }
        .sheet(isPresented: $showingGIFExport) {
            if let cardImage = card.renderAsImage(),
               let nsImage = convertToNSImage(cardImage) {
                GIFExportView(
                    cardImage: nsImage,
                    onCancel: {
                        showingGIFExport = false
                    }
                )
            }
        }
    }
    
    private func convertToNSImage(_ uiImage: UIImage) -> NSImage? {
        guard let cgImage = uiImage.cgImage else { return nil }
        return NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
    }
}
#endif
