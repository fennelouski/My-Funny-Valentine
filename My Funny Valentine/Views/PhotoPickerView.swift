//
//  PhotoPickerView.swift
//  My Funny Valentine
//
//  Created by Nathan Fennel on 2/12/26.
//

import SwiftUI
import PhotosUI

/// SwiftUI photo picker using PhotosUI (PHPickerViewController under the hood).
/// Supports single photo selection and camera capture.
struct PhotoPickerView: View {
    @Binding var selectedImage: UIImage?
    @State private var selectedItem: PhotosPickerItem?
    @State private var showCamera = false
    let onImageSelected: ((UIImage) -> Void)?

    init(selectedImage: Binding<UIImage?>, onImageSelected: ((UIImage) -> Void)? = nil) {
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

            Button {
                showCamera = true
            } label: {
                Label("Take Photo", systemImage: "camera")
            }
            .disabled(!UIImagePickerController.isSourceTypeAvailable(.camera))
        }
        .photosPickerStyle(.compact)
        .fullScreenCover(isPresented: $showCamera) {
            CameraView { image in
                selectedImage = image
                onImageSelected?(image)
            }
        }
    }

    private func loadImage(from item: PhotosPickerItem?) async {
        guard let item else { return }
        if let data = try? await item.loadTransferable(type: Data.self),
           let image = UIImage(data: data) {
            await MainActor.run {
                selectedImage = image
                onImageSelected?(image)
            }
        }
    }
}

/// Camera capture view using UIImagePickerController
struct CameraView: UIViewControllerRepresentable {
    let onImageCaptured: (UIImage) -> Void
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

#Preview {
    PhotoPickerView(selectedImage: .constant(nil))
}
