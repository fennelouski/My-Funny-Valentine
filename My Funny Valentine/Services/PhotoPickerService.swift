//
//  PhotoPickerService.swift
//  My Funny Valentine
//
//  Created by Nathan Fennel on 2/12/26.
//

import Foundation
import Combine
import UniformTypeIdentifiers

#if os(iOS) || os(visionOS)
import UIKit
import PhotosUI
#elseif os(macOS)
import AppKit
#endif

/// Handles photo selection via platform-appropriate picker.
/// iOS/visionOS: PHPickerViewController and camera capture.
/// macOS: File picker (NSOpenPanel).
@MainActor
class PhotoPickerService: NSObject, ObservableObject {
    @Published var selectedImage: PlatformImage?
    @Published var selectedImages: [PlatformImage] = []
    @Published var isPresentingPicker = false
    #if os(iOS)
    @Published var isPresentingCamera = false
    #endif
    @Published var error: Error?

    var onImageSelected: ((PlatformImage) -> Void)?
    var onImagesSelected: (([PlatformImage]) -> Void)?

    #if os(iOS) || os(visionOS)
    private var continuation: CheckedContinuation<PlatformImage?, Never>?
    #endif

    /// Present photo picker - supports single or multiple selection
    func presentPhotoPicker(selectionLimit: Int = 1) {
        isPresentingPicker = true
    }

    #if os(iOS)
    /// Present camera (iOS only)
    func presentCamera() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            error = PhotoPickerError.cameraUnavailable
            return
        }
        isPresentingCamera = true
    }
    #endif

    /// Create PhotosPicker configuration for SwiftUI
    static var supportedTypes: [UTType] {
        [.image]
    }
}

#if os(iOS) || os(visionOS)
// MARK: - PHPickerViewControllerDelegate

extension PhotoPickerService: PHPickerViewControllerDelegate {
    nonisolated func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        Task { @MainActor in
            isPresentingPicker = false

            guard !results.isEmpty else {
                // Picker dismissed with no selection — nothing to hand back.
                return
            }

            var images: [PlatformImage] = []
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

    private func loadImage(from result: PHPickerResult) async -> PlatformImage? {
        await withCheckedContinuation { continuation in
            result.itemProvider.loadObject(ofClass: UIImage.self) { object, _ in
                if let image = object as? UIImage {
                    continuation.resume(returning: image as PlatformImage)
                    return
                }
                result.itemProvider.loadDataRepresentation(forTypeIdentifier: UTType.image.identifier) { data, _ in
                    if let data = data, let image = PlatformImageUtils.image(from: data) {
                        continuation.resume(returning: image)
                    } else {
                        continuation.resume(returning: nil)
                    }
                }
            }
        }
    }
}

// MARK: - UIImagePickerControllerDelegate (Camera - iOS only)

#if os(iOS)
extension PhotoPickerService: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    nonisolated func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        Task { @MainActor in
            isPresentingCamera = false

            if let image = info[.originalImage] as? UIImage {
                selectedImage = image as PlatformImage
                onImageSelected?(image as PlatformImage)
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
#endif
#endif

#if os(macOS)
// MARK: - macOS File Picker Support
// Note: macOS implementation would use NSOpenPanel
// This is a placeholder for future macOS-specific photo picker implementation
#endif

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
