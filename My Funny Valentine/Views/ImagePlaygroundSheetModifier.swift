import SwiftUI

#if canImport(ImagePlayground)
import ImagePlayground
#endif

/// The system owns generation, device readiness, and Apple usage limits.
/// Photos and starter cards remain usable when Image Playground is unavailable.
struct ImagePlaygroundButton: View {
    @Binding var generatedImageURL: URL?
    var concept: String = ""
    var sourceImage: Image? = nil
    let onImageImported: (PlatformImage) -> Void

    var body: some View {
        #if canImport(ImagePlayground)
        if #available(iOS 18.1, macOS 15.1, visionOS 2.4, *) {
            ImagePlaygroundButtonContent(
                generatedImageURL: $generatedImageURL,
                concept: concept,
                sourceImage: sourceImage,
                onImageImported: onImageImported
            )
        }
        #endif
    }
}

#if canImport(ImagePlayground)
@available(iOS 18.1, macOS 15.1, visionOS 2.4, *)
private struct ImagePlaygroundButtonContent: View {
    @Environment(\.supportsImagePlayground) private var supportsImagePlayground
    @Binding var generatedImageURL: URL?
    let concept: String
    let sourceImage: Image?
    let onImageImported: (PlatformImage) -> Void
    @State private var showImagePlayground = false
    @State private var importFailed = false

    var body: some View {
        if supportsImagePlayground {
            Button {
                showImagePlayground = true
            } label: {
                Label("Image Playground", systemImage: "sparkles")
                    .frame(minHeight: 44)
            }
            .accessibilityIdentifier("artwork.imagePlayground")
            .imagePlaygroundSheet(
                isPresented: $showImagePlayground,
                concepts: concept.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? [] : [.text(concept)],
                sourceImage: sourceImage
            ) { url in
                // The URL is temporary. Read its pixels before the system ends
                // the session, then let the caller persist them with the card.
                guard let data = try? Data(contentsOf: url),
                      let image = PlatformImage(data: data) else {
                    importFailed = true
                    return
                }
                generatedImageURL = url
                onImageImported(image)
            }
            .alert("Couldn't add artwork", isPresented: $importFailed) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Try Image Playground again, or choose a photo.")
            }
        }
    }
}
#endif
