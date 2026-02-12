//
//  SharePreviewView.swift
//  My Funny Valentine
//
//  Created by Nathan Fennel on 2/12/26.
//

import SwiftUI
import UIKit

enum ShareDestination: String, CaseIterable {
    case instagram = "Instagram"
    case facebook = "Facebook"
    case tiktok = "TikTok"
    case email = "Email"
    case messages = "Messages"
    case photos = "Save to Photos"
    case general = "More Options"
    
    var icon: String {
        switch self {
        case .instagram:
            return "camera.fill"
        case .facebook:
            return "person.2.fill"
        case .tiktok:
            return "video.fill"
        case .email:
            return "envelope.fill"
        case .messages:
            return "message.fill"
        case .photos:
            return "photo.on.rectangle"
        case .general:
            return "square.and.arrow.up"
        }
    }
}

enum ShareFormat {
    case image
    case pdf
    case gif // macOS only
}

struct SharePreviewView: View {
    let cardImage: UIImage
    let onShare: (ShareDestination) -> Void
    let onCancel: () -> Void
    let onEdit: (() -> Void)?
    
    @State private var selectedDestination: ShareDestination? = nil
    @State private var selectedFormat: ShareFormat = .image
    @State private var isPortrait: Bool = false
    @State private var showingShareSheet = false
    @State private var shareError: Error? = nil
    @State private var showingError = false
    @State private var isSaving = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Card Preview
                Image(uiImage: cardImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 400)
                    .cornerRadius(12)
                    .shadow(radius: 8)
                    .padding()
                
                // Format Selection (if multiple formats available)
                #if os(macOS)
                Picker("Format", selection: $selectedFormat) {
                    Text("Image").tag(ShareFormat.image)
                    Text("GIF").tag(ShareFormat.gif)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                #endif
                
                // Instagram format option
                if selectedDestination == .instagram {
                    Toggle("Portrait Format", isOn: $isPortrait)
                        .padding(.horizontal)
                }
                
                // Share Destinations Grid
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        ForEach(ShareDestination.allCases, id: \.self) { destination in
                            ShareDestinationButton(
                                destination: destination,
                                isSelected: selectedDestination == destination
                            ) {
                                selectedDestination = destination
                                handleShare(destination: destination)
                            }
                        }
                    }
                    .padding()
                }
                
                Spacer()
            }
            .navigationTitle("Share Card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onCancel()
                    }
                }
                
                if let onEdit = onEdit {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Edit") {
                            onEdit()
                        }
                    }
                }
            }
            .alert("Share Error", isPresented: $showingError, presenting: shareError) { error in
                Button("OK", role: .cancel) { }
            } message: { error in
                Text(error.localizedDescription)
            }
            .sheet(isPresented: $showingShareSheet) {
                if let destination = selectedDestination {
                    shareSheetForDestination(destination)
                }
            }
        }
    }
    
    private func handleShare(destination: ShareDestination) {
        switch destination {
        case .photos:
            Task {
                await saveToPhotos()
            }
        case .general:
            showingShareSheet = true
        default:
            do {
                try shareToSpecificDestination(destination)
            } catch {
                shareError = error
                showingError = true
            }
        }
    }
    
    private func shareToSpecificDestination(_ destination: ShareDestination) throws {
        // Get the root view controller
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            throw ShareError.shareFailed(NSError(domain: "ShareService", code: -1))
        }
        
        switch destination {
        case .instagram:
            try ShareService.shared.shareToInstagram(cardImage, from: rootViewController, isPortrait: isPortrait)
        case .facebook:
            try ShareService.shared.shareToFacebook(cardImage, from: rootViewController)
        case .tiktok:
            try ShareService.shared.shareToTikTok(cardImage, from: rootViewController)
        case .email:
            ShareService.shared.shareToEmail(cardImage, from: rootViewController)
        case .messages:
            ShareService.shared.shareToMessages(cardImage, from: rootViewController)
        default:
            break
        }
    }
    
    private func shareSheetForDestination(_ destination: ShareDestination) -> ShareSheet {
        let optimizedImage: UIImage
        switch destination {
        case .instagram:
            if let data = ImageOptimizer.shared.optimizeForInstagram(cardImage, isPortrait: isPortrait),
               let image = UIImage(data: data) {
                optimizedImage = image
            } else {
                optimizedImage = cardImage
            }
        case .facebook:
            if let data = ImageOptimizer.shared.optimize(cardImage, for: .facebook),
               let image = UIImage(data: data) {
                optimizedImage = image
            } else {
                optimizedImage = cardImage
            }
        case .tiktok:
            if let data = ImageOptimizer.shared.optimizeForTikTok(cardImage),
               let image = UIImage(data: data) {
                optimizedImage = image
            } else {
                optimizedImage = cardImage
            }
        default:
            optimizedImage = cardImage
        }
        
        return ShareSheet(items: [optimizedImage]) { completed, error in
            showingShareSheet = false
            if completed {
                onCancel() // Dismiss preview on successful share
            }
        }
    }
    
    private func saveToPhotos() async {
        isSaving = true
        do {
            try await ShareService.shared.saveToPhotos(cardImage)
            // Show success message
            DispatchQueue.main.async {
                isSaving = false
                onCancel() // Dismiss on success
            }
        } catch {
            DispatchQueue.main.async {
                isSaving = false
                shareError = error
                showingError = true
            }
        }
    }
}

struct ShareDestinationButton: View {
    let destination: ShareDestination
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: destination.icon)
                    .font(.system(size: 32))
                    .foregroundColor(isSelected ? .white : .primary)
                
                Text(destination.rawValue)
                    .font(.caption)
                    .foregroundColor(isSelected ? .white : .primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(isSelected ? Color.accentColor : Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}
