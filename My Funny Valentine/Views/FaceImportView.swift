//
//  FaceImportView.swift
//  My Funny Valentine
//
//  Created by Nathan Fennel on 2/12/26.
//

import SwiftUI
import PhotosUI
import SwiftData

struct FaceImportView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var detectedFaces: [DetectedFace] = []
    @State private var isProcessing = false
    @State private var errorMessage: String?
    @State private var importedFaces: [FaceImage] = []
    @State private var currentStep: ImportStep = .firstFace
    @State private var showingFaceSelection = false

    enum ImportStep {
        case firstFace
        case secondFace
        case complete
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                if currentStep == .complete {
                    completionView
                } else {
                    importView
                }
            }
            .navigationTitle("Import Faces")
            .sheet(isPresented: $showingFaceSelection) {
                FaceSelectionView(faces: detectedFaces) { face in
                    saveFace(face)
                }
            }
        }
    }

    private var importView: some View {
        VStack(spacing: 20) {
            Text(currentStep == .firstFace ? "Import your photo" : "Import a loved one's photo (optional)")
                .font(.title2)
                .multilineTextAlignment(.center)
                .padding()

            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 300)
                    .cornerRadius(12)
                    .padding()
            }

            PhotosPicker(selection: $selectedItem, matching: .images) {
                Label("Select Photo", systemImage: "photo")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: 200)
                    .background(Color.pink)
                    .cornerRadius(10)
            }
            .onChange(of: selectedItem) { _, newItem in
                Task { await loadAndDetect(newItem) }
            }

            if isProcessing {
                ProgressView("Detecting faces...")
                    .padding()
            }

            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding()
            }

            if !importedFaces.isEmpty && currentStep == .firstFace {
                Button("Continue to Second Face") {
                    currentStep = .secondFace
                    resetSelection()
                }
                .buttonStyle(.borderedProminent)
                .padding()
            }

            if !importedFaces.isEmpty && currentStep == .secondFace {
                Button("Skip Second Face") {
                    generateCards()
                }
                .buttonStyle(.bordered)
                .padding()
            }
        }
        .padding()
    }

    private var completionView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)

            Text("Faces imported successfully!")
                .font(.title)

            Text("\(importedFaces.count) face(s) ready for card creation")
                .font(.subheadline)
                .foregroundColor(.secondary)

            NavigationLink("View Generated Cards") {
                CardLibraryView()
            }
            .buttonStyle(.borderedProminent)
            .padding()
        }
        .padding()
    }

    private func resetSelection() {
        selectedImage = nil
        selectedItem = nil
        detectedFaces = []
        errorMessage = nil
    }

    private func loadAndDetect(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        isProcessing = true
        errorMessage = nil
        defer { isProcessing = false }

        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else {
                errorMessage = "Could not load that photo. Please try another."
                return
            }
            selectedImage = image

            let faces = try await FaceDetectionService.shared.detectFaces(in: image)
            if faces.isEmpty {
                errorMessage = "No faces detected. Please try another photo."
            } else if faces.count == 1 {
                saveFace(faces[0])
            } else {
                detectedFaces = faces
                showingFaceSelection = true
            }
        } catch {
            errorMessage = "Face detection failed. Please try another photo."
        }
    }

    private func saveFace(_ face: DetectedFace) {
        // Faces are held in memory until cards are generated; CardGenerationService
        // creates its own persisted copies attached to each card.
        let faceImage = FaceImage(
            cardId: UUID(),
            imageData: face.imageData,
            thumbnailData: face.imageData,
            position: .zero,
            size: CGSize(width: 150, height: 150)
        )
        importedFaces.append(faceImage)

        if currentStep == .secondFace {
            generateCards()
        }
    }

    private func generateCards() {
        _ = CardGenerationService.shared.generateTemplateCards(
            faces: importedFaces,
            modelContext: modelContext
        )
        try? modelContext.save()
        currentStep = .complete
    }
}

struct FaceSelectionView: View {
    let faces: [DetectedFace]
    let onSelect: (DetectedFace) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Multiple faces detected. Select one:")
                        .font(.headline)
                        .padding()

                    ForEach(faces) { face in
                        if let uiImage = UIImage(data: face.imageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 150, height: 150)
                                .cornerRadius(12)
                                .padding(8)
                                .onTapGesture {
                                    onSelect(face)
                                    dismiss()
                                }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Select Face")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}
