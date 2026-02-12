//
//  PhotoPickerService.swift
//  My Funny Valentine
//
//  Created by Nathan Fennel on 2/12/26.
//

import Foundation
import Combine
import UIKit
import PhotosUI
import UniformTypeIdentifiers

/// Handles photo selection via PHPickerViewController and camera capture.
/// Uses modern PhotosUI for photo library access with limited permissions.
@MainActor
class PhotoPickerService: NSObject, ObservableObject {
    @Published var selectedImage: UIImage?
    @Published var selectedImages: [UIImage] = []
    @Published var isPresentingPicker = false
    @Published var isPresentingCamera = false
    @Published var error: Error?

    var onImageSelected: ((UIImage) -> Void)?
    var onImagesSelected: (([UIImage]) -> Void)?

    private var continuation: CheckedContinuation<UIImage?, Never>?

    /// Present photo picker - supports single or multiple selection
    func presentPhotoPicker(selectionLimit: Int = 1) {
        isPresentingPicker = true
    }

    /// Present camera (if available)
    func presentCamera() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            error = PhotoPickerError.cameraUnavailable
            return
        }
        isPresentingCamera = true
    }

    /// Create PhotosPicker configuration for SwiftUI
    static var supportedTypes: [UTType] {
        [.image]
    }
}

// MARK: - PHPickerViewControllerDelegate

extension PhotoPickerService: PHPickerViewControllerDelegate {
    nonisolated func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        Task { @MainActor in
            isPresentingPicker = false

            guard !results.isEmpty else {
                onImageSelected?(UIImage())
                return
            }

            var images: [UIImage] = []
            for result in results {
                if let image = await loadImage(from: result) {
                    images.append(image)
                }
            }

            if images.count == 1 {
                selectedImage = images[0]
                onImageSelected?(images[0])
            } else if !images.isEmpty {
                selectedImages = images
                onImagesSelected?(images)
            }
        }
    }

    private func loadImage(from result: PHPickerResult) async -> UIImage? {
        await withCheckedContinuation { continuation in
            result.itemProvider.loadObject(ofClass: UIImage.self) { object, _ in
                if let image = object as? UIImage {
                    continuation.resume(returning: image)
                    return
                }
                result.itemProvider.loadDataRepresentation(forTypeIdentifier: UTType.image.identifier) { data, _ in
                    if let data = data, let image = UIImage(data: data) {
                        continuation.resume(returning: image)
                    } else {
                        continuation.resume(returning: nil)
                    }
                }
            }
        }
    }
}

// MARK: - UIImagePickerControllerDelegate (Camera)

extension PhotoPickerService: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    nonisolated func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        Task { @MainActor in
            isPresentingCamera = false

            if let image = info[.originalImage] as? UIImage {
                selectedImage = image
                onImageSelected?(image)
            }
            picker.dismiss(animated: true)
        }
    }

    nonisolated func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        Task { @MainActor in
            isPresentingCamera = false
            picker.dismiss(animated: true)
        }
    }
}

// MARK: - Errors

enum PhotoPickerError: LocalizedError {
    case cameraUnavailable
    case photoAccessDenied

    var errorDescription: String? {
        switch self {
        case .cameraUnavailable: return "Camera is not available on this device."
        case .photoAccessDenied: return "Photo library access was denied."
        }
    }
}
