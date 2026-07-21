//
//  CardImageImportView.swift
//  My Funny Valentine
//
//  Created by Nathan Fennel on 2/12/26.
//

import SwiftUI
import SwiftData
import PhotosUI

/// Main view for importing images to a card - combines photo picker, face detection,
/// smart cutout, stickers, and Image Playground.
struct CardImageImportView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let card: Card

    @State private var selectedImage: PlatformImage?
    @State private var detectedFaces: [DetectedFace] = []
    @State private var selectedFaceIds: Set<UUID> = []
    @State private var isDetectingFaces = false
    @State private var showFaceSelection = false
    @State private var generatedImageURL: URL?
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Drop zone for smart cutout
                    DropTargetView(isActive: true) { image in
                        handleImportedImage(image, source: .smartCutout)
                    }
                    .frame(height: 120)
                    .overlay {
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [8]))
                            .foregroundStyle(.secondary)
                    }
                    .overlay {
                        VStack {
                            Image(systemName: "square.and.arrow.down")
                                .font(.largeTitle)
                                .foregroundStyle(.secondary)
                            Text("Drag cutout from Photos")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    // Import options
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Add Images")
                            .font(.headline)

                        PhotoPickerView(selectedImage: $selectedImage) { image in
                            handleImportedImage(image, source: .photoImport)
                        }

                        ImagePlaygroundButton(generatedImageURL: $generatedImageURL) { image in
                            handleImportedImage(image, source: .imagePlayground)
                        }
                    }

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
                .padding()
            }
            .navigationTitle("Add Images")
            .appInlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .onChange(of: selectedImage) { _, newValue in
                if let image = newValue {
                    runFaceDetection(on: image)
                }
            }
            .sheet(isPresented: $showFaceSelection) {
                if let image = selectedImage {
                    FaceSelectionSheet(
                        image: image,
                        detectedFaces: detectedFaces,
                        selectedFaceIds: $selectedFaceIds,
                        onConfirm: { addSelectedFaces(to: card) },
                        onSkip: { addFullImage(to: card, source: .photoImport) }
                    )
                }
            }
        }
    }

    private func runFaceDetection(on image: PlatformImage) {
        isDetectingFaces = true
        Task {
            do {
                let faces = try await FaceDetectionService.shared.detectFaces(in: image)
                await MainActor.run {
                    detectedFaces = faces
                    selectedFaceIds = Set(faces.prefix(2).map(\.id))
                    isDetectingFaces = false
                    showFaceSelection = !faces.isEmpty
                }
            } catch {
                await MainActor.run {
                    detectedFaces = []
                    isDetectingFaces = false
                    showFaceSelection = true
                }
            }
        }
    }

    private func handleImportedImage(_ image: PlatformImage, source: ImageSource) {
        selectedImage = image

        // For cutout and Image Playground, add directly without face detection
        if source == .smartCutout || source == .imagePlayground {
            addImageToCard(image, source: source)
            return
        }

        // For photos, run face detection
        runFaceDetection(on: image)
    }

    private func addSelectedFaces(to card: Card) {
        for faceId in selectedFaceIds {
            if let face = detectedFaces.first(where: { $0.id == faceId }) {
                addFaceToCard(face, card: card)
            }
        }
        dismiss()
    }

    private func addFaceToCard(_ face: DetectedFace, card: Card) {
        Task {
            do {
                let (imageData, thumbnailData) = try await ImageManager.shared.storeImageData(
                    face.imageData,
                    id: face.id,
                    preserveTransparency: true
                )

                await MainActor.run {
                    let faceImage = FaceImage(
                        cardId: card.id,
                        imageData: imageData,
                        thumbnailData: thumbnailData,
                        position: .zero,
                        size: CGSize(width: 120, height: 120)
                    )
                    modelContext.insert(faceImage)
                    if card.faces == nil {
                        card.faces = []
                    }
                    card.faces?.append(faceImage)
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func addFullImage(to card: Card, source: ImageSource) {
        guard let image = selectedImage else { return }
        addImageToCard(image, source: source)
        dismiss()
    }

    private func addImageToCard(_ image: PlatformImage, source: ImageSource) {
        let id = UUID()
        Task {
            do {
                let (imageData, _) = try await ImageManager.shared.storeImage(image, id: id)

                await MainActor.run {
                    let cardImage = CardImage(
                        cardId: card.id,
                        source: source,
                        imageData: imageData,
                        position: CGPoint(x: 150, y: 150),
                        size: CGSize(width: 200, height: 200)
                    )
                    modelContext.insert(cardImage)
                    if card.images == nil {
                        card.images = []
                    }
                    card.images?.append(cardImage)
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

struct FaceSelectionSheet: View {
    let image: PlatformImage
    let detectedFaces: [DetectedFace]
    @Binding var selectedFaceIds: Set<UUID>
    let onConfirm: () -> Void
    let onSkip: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                DetectedFaceSelectionView(
                    detectedFaces: detectedFaces,
                    selectedFaceIds: $selectedFaceIds,
                    onManualSelect: { onSkip() }
                )

                HStack {
                    Button("Use Full Photo") {
                        onSkip()
                    }
                    .buttonStyle(.bordered)

                    Button("Add Selected Faces") {
                        onConfirm()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
            .navigationTitle("Select Faces")
            .appInlineNavigationTitle()
        }
    }
}
