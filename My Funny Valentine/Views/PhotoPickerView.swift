//
//  PhotoPickerView.swift
//  My Funny Valentine
//
//  Created by Nathan Fennel on 2/12/26.
//

import SwiftUI
import PhotosUI

#if os(iOS) || os(visionOS)
import UIKit
#endif

/// SwiftUI photo picker using PhotosUI (PHPickerViewController under the hood).
/// Supports single photo selection, plus camera capture on iOS.
struct PhotoPickerView: View {
    @Binding var selectedImage: PlatformImage?
    @State private var selectedItem: PhotosPickerItem?
    @State private var showCamera = false
    let onImageSelected: ((PlatformImage) -> Void)?

    init(selectedImage: Binding<PlatformImage?>, onImageSelected: ((PlatformImage) -> Void)? = nil) {
        self._selectedImage = selectedImage
        self.onImageSelected = onImageSelected
    }

    var body: some View {
        VStack(spacing: 16) {
            PhotosPicker(
                selection: $selectedItem,
                matching: .images,
                photoLibrary: .shared()
            ) {
                Label("Choose from Photo Library", systemImage: "photo.on.rectangle.angled")
            }
            .onChange(of: selectedItem) { _, newValue in
                Task {
                    await loadImage(from: newValue)
                }
            }

            #if os(iOS)
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                Button {
                    showCamera = true
                } label: {
                    Label("Take Photo", systemImage: "camera")
                }
            }
            #endif
        }
        .photosPickerStyle(.compact)
        #if os(iOS)
        .fullScreenCover(isPresented: $showCamera) {
            CameraView { image in
                selectedImage = image
                onImageSelected?(image)
            }
        }
        #endif
    }

    private func loadImage(from item: PhotosPickerItem?) async {
        guard let item else { return }
        if let data = try? await item.loadTransferable(type: Data.self),
           let image = PlatformImageUtils.image(from: data) {
            await MainActor.run {
                selectedImage = image
                onImageSelected?(image)
            }
        }
    }
}

#if os(iOS)
/// Camera capture view using UIImagePickerController
struct CameraView: UIViewControllerRepresentable {
    let onImageCaptured: (PlatformImage) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView

        init(_ parent: CameraView) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.onImageCaptured(image)
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
#endif

#Preview {
    PhotoPickerView(selectedImage: .constant(nil))
}
