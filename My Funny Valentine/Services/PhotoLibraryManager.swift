//
//  PhotoLibraryManager.swift
//  My Funny Valentine
//
//  Created by Nathan Fennel on 2/12/26.
//

import Foundation
import Photos
import UIKit

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

class PhotoLibraryManager {
    static let shared = PhotoLibraryManager()
    
    private init() {}
    
    /// Request photo library authorization
    func requestAuthorization() async -> PHAuthorizationStatus {
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        return status
    }
    
    /// Check current authorization status
    var authorizationStatus: PHAuthorizationStatus {
        PHPhotoLibrary.authorizationStatus(for: .addOnly)
    }
    
    /// Save image to Photos library
    func saveImage(_ image: UIImage) async throws {
        let status = authorizationStatus
        
        guard status == .authorized || status == .limited else {
            // Request authorization if not granted
            let newStatus = await requestAuthorization()
            guard newStatus == .authorized || newStatus == .limited else {
                throw PhotoLibraryError.permissionDenied
            }
        }
        
        do {
            try await PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            }
        } catch {
            throw PhotoLibraryError.unknown(error)
        }
    }
    
    /// Save image data to Photos library
    func saveImageData(_ imageData: Data) async throws {
        guard let image = UIImage(data: imageData) else {
            throw PhotoLibraryError.saveFailed
        }
        try await saveImage(image)
    }
    
    /// Save image to a specific album (creates album if it doesn't exist)
    func saveImageToAlbum(_ image: UIImage, albumName: String = "My Funny Valentine") async throws {
        let status = authorizationStatus
        
        guard status == .authorized || status == .limited else {
            let newStatus = await requestAuthorization()
            guard newStatus == .authorized || newStatus == .limited else {
                throw PhotoLibraryError.permissionDenied
            }
        }
        
        do {
            var albumPlaceholder: PHObjectPlaceholder?
            
            // Find or create album
            try await PHPhotoLibrary.shared().performChanges {
                let fetchOptions = PHFetchOptions()
                fetchOptions.predicate = NSPredicate(format: "title = %@", albumName)
                let collection = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
                
                if let existingAlbum = collection.firstObject {
                    // Album exists, add to it
                    let assetRequest = PHAssetChangeRequest.creationRequestForAsset(from: image)
                    let albumChangeRequest = PHAssetCollectionChangeRequest(for: existingAlbum)
                    albumChangeRequest?.addAssets([assetRequest.placeholderForCreatedAsset!] as NSArray)
                } else {
                    // Create new album
                    let albumChangeRequest = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: albumName)
                    albumPlaceholder = albumChangeRequest.placeholderForCreatedAssetCollection
                    
                    let assetRequest = PHAssetChangeRequest.creationRequestForAsset(from: image)
                    albumChangeRequest.addAssets([assetRequest.placeholderForCreatedAsset!] as NSArray)
                }
            }
        } catch {
            throw PhotoLibraryError.unknown(error)
        }
    }
}
