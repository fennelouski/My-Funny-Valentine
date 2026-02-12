//
//  ImagePlaygroundSheetModifier.swift
//  My Funny Valentine
//
//  Created by Nathan Fennel on 2/12/26.
//

import SwiftUI

#if canImport(ImagePlayground)
import ImagePlayground
#endif

/// Provides Image Playground integration when Apple Intelligence is available.
/// Gracefully handles when unavailable (older devices, AI disabled).
struct ImagePlaygroundButton: View {
    @Binding var generatedImageURL: URL?
    let onImageImported: (UIImage) -> Void

    var body: some View {
        #if canImport(ImagePlayground)
        if #available(iOS 18.1, *) {
            ImagePlaygroundButtonContent(
                generatedImageURL: $generatedImageURL,
                onImageImported: onImageImported
            )
        } else {
            unsupportedView
        }
        #else
        unsupportedView
        #endif
    }

    private var unsupportedView: some View {
        Button {} label: {
            Label("Image Playground (Unavailable)", systemImage: "apple.logo")
                .foregroundStyle(.secondary)
        }
        .disabled(true)
    }
}

#if canImport(ImagePlayground)
@available(iOS 18.1, *)
private struct ImagePlaygroundButtonContent: View {
    @Environment(\.supportsImagePlayground) private var supportsImagePlayground
    @Binding var generatedImageURL: URL?
    @State private var showImagePlayground = false
    let onImageImported: (UIImage) -> Void

    var body: some View {
        Group {
            if supportsImagePlayground {
                Button {
                    showImagePlayground = true
                } label: {
                    Label("Add from Image Playground", systemImage: "apple.logo")
                }
                .imagePlaygroundSheet(isPresented: $showImagePlayground) { url in
                    generatedImageURL = url
                    if let url, let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
                        onImageImported(image)
                    }
                }
            } else {
                Button {} label: {
                    Label("Image Playground (Requires Apple Intelligence)", systemImage: "apple.logo")
                        .foregroundStyle(.secondary)
                }
                .disabled(true)
            }
        }
    }
}
#endif
