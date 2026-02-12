//
//  FaceSelectionView.swift
//  My Funny Valentine
//
//  Created by Nathan Fennel on 2/12/26.
//

import SwiftUI

/// Displays detected faces and allows user to select up to 2 for card generation.
/// Falls back to manual selection if detection fails.
struct DetectedFaceSelectionView: View {
    let detectedFaces: [DetectedFace]
    @Binding var selectedFaceIds: Set<UUID>
    let maxSelection: Int
    let onManualSelect: (() -> Void)?

    init(
        detectedFaces: [DetectedFace],
        selectedFaceIds: Binding<Set<UUID>>,
        maxSelection: Int = 2,
        onManualSelect: (() -> Void)? = nil
    ) {
        self.detectedFaces = detectedFaces
        self._selectedFaceIds = selectedFaceIds
        self.maxSelection = maxSelection
        self.onManualSelect = onManualSelect
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Select up to \(maxSelection) faces")
                .font(.headline)

            if detectedFaces.isEmpty {
                noFacesView
            } else {
                faceGrid
            }
        }
    }

    private var noFacesView: some View {
        VStack(spacing: 12) {
            Image(systemName: "face.smiling")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("No faces detected")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            if let onManualSelect {
                Button("Select manually") {
                    onManualSelect()
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
    }

    private var faceGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 12) {
            ForEach(detectedFaces) { face in
                FacePreviewCell(
                    face: face,
                    isSelected: selectedFaceIds.contains(face.id),
                    canSelect: selectedFaceIds.count < maxSelection || selectedFaceIds.contains(face.id)
                ) {
                    toggleSelection(face.id)
                }
            }
        }
    }

    private func toggleSelection(_ id: UUID) {
        if selectedFaceIds.contains(id) {
            selectedFaceIds.remove(id)
        } else if selectedFaceIds.count < maxSelection {
            selectedFaceIds.insert(id)
        }
    }
}

struct FacePreviewCell: View {
    let face: DetectedFace
    let isSelected: Bool
    let canSelect: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            if let uiImage = UIImage(data: face.imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 3)
                    )
                    .overlay(
                        Group {
                            if isSelected {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.white)
                                    .background(Circle().fill(Color.accentColor))
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                        .padding(4)
                    )
            }
        }
        .buttonStyle(.plain)
        .opacity(canSelect ? 1 : 0.5)
        .disabled(!canSelect)
    }
}

#Preview {
    DetectedFaceSelectionView(
        detectedFaces: [],
        selectedFaceIds: .constant([])
    )
}
