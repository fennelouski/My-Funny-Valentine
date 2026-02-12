//
//  FaceImportView.swift
//  My Funny Valentine
//
//  Created by Nathan Fennel on 2/12/26.
//

import SwiftUI
import PhotosUI

struct FaceImportView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var photoPicker = PhotoPickerService()
    @State private var detectedFaces: [VNFaceObservation] = []
    @State private var selectedFaceIndex: Int = 0
    @State private var isProcessing = false
    @State private var errorMessage: String?
    @State private var importedFaces: [FaceImage] = []
    @State private var currentStep: ImportStep = .firstFace
    @State private var showingFaceSelection = false
    @State private var sourceImage: UIImage?
    
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
                FaceSelectionView(
                    faces: detectedFaces,
                    sourceImage: sourceImage,
                    selectedIndex: $selectedFaceIndex,
                    onSelect: { observation in
                        extractAndSaveFace(observation: observation)
                    }
                )
            }
        }
    }
    
    private var importView: some View {
        VStack(spacing: 20) {
            Text(currentStep == .firstFace ? "Import your photo" : "Import a loved one's photo (optional)")
                .font(.title2)
                .multilineTextAlignment(.center)
                .padding()
            
            if let image = photoPicker.selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 300)
                    .cornerRadius(12)
                    .padding()
            }
            
            PhotosPicker(
                selection: $photoPicker.selectedItem,
                matching: .images
            ) {
                Label("Select Photo", systemImage: "photo")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: 200)
                    .background(Color.pink)
                    .cornerRadius(10)
            }
            .onChange(of: photoPicker.selectedItem) { _, newItem in
                Task {
                    await photoPicker.loadImage(from: newItem)
                    if let image = photoPicker.selectedImage {
                        detectFaces(in: image)
                    }
                }
            }
            
            if isProcessing {
                ProgressView("Detecting faces...")
                    .padding()
            }
            
            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .padding()
            }
            
            if !importedFaces.isEmpty && currentStep == .firstFace {
                Button("Continue to Second Face") {
                    currentStep = .secondFace
                    photoPicker.selectedImage = nil
                    photoPicker.selectedItem = nil
                    detectedFaces = []
                    errorMessage = nil
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
    
    private func detectFaces(in image: UIImage) {
        isProcessing = true
        errorMessage = nil
        sourceImage = image
        
        FaceDetectionService.shared.detectFaces(in: image) { observations in
            DispatchQueue.main.async {
                isProcessing = false
                
                if observations.isEmpty {
                    errorMessage = "No faces detected. Please try another photo."
                } else if observations.count == 1 {
                    // Auto-select if only one face
                    extractAndSaveFace(observation: observations[0])
                } else {
                    // Show selection interface for multiple faces
                    detectedFaces = observations
                    showingFaceSelection = true
                }
            }
        }
    }
    
    private func extractAndSaveFace(observation: VNFaceObservation) {
        guard let sourceImage = sourceImage else { return }
        
        guard let extractedFace = FaceDetectionService.shared.extractFace(
            from: sourceImage,
            observation: observation
        ) else {
            errorMessage = "Failed to extract face. Please try again."
            return
        }
        
        guard let thumbnail = FaceDetectionService.shared.createThumbnail(from: extractedFace) else {
            errorMessage = "Failed to create thumbnail. Please try again."
            return
        }
        
        guard let faceData = extractedFace.jpegData(compressionQuality: 0.8),
              let thumbData = thumbnail.jpegData(compressionQuality: 0.8) else {
            errorMessage = "Failed to process image. Please try again."
            return
        }
        
        // Create a temporary card ID for storing faces before card generation
        let tempCardId = UUID()
        let faceImage = FaceImage(
            cardId: tempCardId,
            imageData: faceData,
            thumbnailData: thumbData,
            position: .zero,
            size: CGSize(width: 150, height: 150)
        )
        
        importedFaces.append(faceImage)
        modelContext.insert(faceImage)
        
        // If this was the second face, generate cards
        if currentStep == .secondFace {
            generateCards()
        }
    }
    
    private func generateCards() {
        // Generate cards with imported faces
        let generatedCards = CardGenerationService.shared.generateTemplateCards(
            faces: importedFaces,
            modelContext: modelContext
        )
        
        // Update face cardIds to match their actual cards
        for (index, card) in generatedCards.enumerated() {
            if let faces = card.faces {
                for face in faces {
                    face.cardId = card.id
                }
            }
        }
        
        try? modelContext.save()
        currentStep = .complete
    }
}

struct FaceSelectionView: View {
    let faces: [VNFaceObservation]
    let sourceImage: UIImage?
    @Binding var selectedIndex: Int
    let onSelect: (VNFaceObservation) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Multiple faces detected. Select one:")
                        .font(.headline)
                        .padding()
                    
                    if let image = sourceImage {
                        ForEach(Array(faces.enumerated()), id: \.offset) { index, observation in
                            FaceThumbnailView(
                                image: image,
                                observation: observation,
                                isSelected: index == selectedIndex
                            )
                            .onTapGesture {
                                selectedIndex = index
                                onSelect(observation)
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

struct FaceThumbnailView: View {
    let image: UIImage
    let observation: VNFaceObservation
    let isSelected: Bool
    
    var body: some View {
        VStack {
            if let faceImage = FaceDetectionService.shared.extractFace(
                from: image,
                observation: observation
            ) {
                Image(uiImage: faceImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150, height: 150)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.pink : Color.clear, lineWidth: 3)
                    )
            }
        }
        .padding()
        .background(isSelected ? Color.pink.opacity(0.1) : Color.clear)
        .cornerRadius(12)
    }
}

import Vision
