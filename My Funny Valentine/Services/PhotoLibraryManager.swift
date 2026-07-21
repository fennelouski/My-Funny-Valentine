//
//  PhotoLibraryManager.swift
//  My Funny Valentine
//
//  Created by Nathan Fennel on 2/12/26.
//

import Foundation

#if os(iOS) || os(visionOS)
import Photos
import UIKit
#endif

enum PhotoLibraryError: LocalizedError {
    case permissionDenied
    case saveFailed
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Photo library access was denied. Please enable access in Settings."
        case .saveFailed:
            return "Failed to save image to photo library."
        case .unknown(let error):
            return error.localizedDescription
        }
    }
}

/// Platform-agnostic photo library manager
class PhotoLibraryManager {
    static let shared = PhotoLibraryManager()
    
    private let platformService: PlatformPhotoLibraryProtocol
    
    private init() {
        self.platformService = PlatformPhotoLibraryFactory.createPhotoLibraryService()
    }
    
    #if os(iOS) || os(visionOS)
    /// Request photo library authorization (iOS/visionOS only)
    func requestAuthorization() async -> PHAuthorizationStatus {
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        return status
    }
    
    /// Check current authorization status (iOS/visionOS only)
    var authorizationStatus: PHAuthorizationStatus {
        PHPhotoLibrary.authorizationStatus(for: .addOnly)
    }
    #endif
    
    /// Save image to Photos library (platform-agnostic)
    func saveImage(_ image: PlatformImage) async throws {
        try await platformService.saveImage(image)
    }
    
    /// Save image data to Photos library (platform-agnostic)
    func saveImageData(_ imageData: Data) async throws {
        guard let image = PlatformImageUtils.image(from: imageData) else {
            throw PhotoLibraryError.saveFailed
        }
        try await saveImage(image)
    }
    
    /// Save image to a specific album (creates album if it doesn't exist) (platform-agnostic)
    func saveImageToAlbum(_ image: PlatformImage, albumName: String = "My Funny Valentine") async throws {
        try await platformService.saveImageToAlbum(image, albumName: albumName)
    }
}
