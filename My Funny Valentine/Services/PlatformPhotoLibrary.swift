//
//  PlatformPhotoLibrary.swift
//  My Funny Valentine
//
//  Platform-agnostic photo library abstraction
//

import Foundation
import SwiftUI

#if os(iOS) || os(visionOS)
import PhotosUI
import Photos
#elseif os(macOS)
import AppKit
#endif

/// Protocol for platform-specific photo library operations
protocol PlatformPhotoLibraryProtocol {
    func requestAuthorization() async -> Bool
    func saveImage(_ image: PlatformImage) async throws
    func saveImageToAlbum(_ image: PlatformImage, albumName: String) async throws
}

#if os(iOS) || os(visionOS)
/// iOS/visionOS photo library implementation using Photos framework
class iOSPhotoLibraryService: PlatformPhotoLibraryProtocol {
    func requestAuthorization() async -> Bool {
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        return status == .authorized || status == .limited
    }
    
    func saveImage(_ image: PlatformImage) async throws {
        let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        
        guard status == .authorized || status == .limited else {
            let newStatus = await requestAuthorization()
            guard newStatus else {
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
    
    func saveImageToAlbum(_ image: PlatformImage, albumName: String = "My Funny Valentine") async throws {
        let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        
        guard status == .authorized || status == .limited else {
            let newStatus = await requestAuthorization()
            guard newStatus else {
                throw PhotoLibraryError.permissionDenied
            }
        }
        
        do {
            var albumPlaceholder: PHObjectPlaceholder?
            
            try await PHPhotoLibrary.shared().performChanges {
                let fetchOptions = PHFetchOptions()
                fetchOptions.predicate = NSPredicate(format: "title = %@", albumName)
                let collection = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
                
                if let existingAlbum = collection.firstObject {
                    let assetRequest = PHAssetChangeRequest.creationRequestForAsset(from: image)
                    let albumChangeRequest = PHAssetCollectionChangeRequest(for: existingAlbum)
                    albumChangeRequest?.addAssets([assetRequest.placeholderForCreatedAsset!] as NSArray)
                } else {
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
#endif

#if os(macOS)
/// macOS photo library implementation using file system
class macOSPhotoLibraryService: PlatformPhotoLibraryProtocol {
    func requestAuthorization() async -> Bool {
        // On macOS, we save to user's Pictures folder
        // No special permission needed for user's own Pictures folder
        return true
    }
    
    func saveImage(_ image: PlatformImage) async throws {
        try await saveImageToAlbum(image, albumName: "My Funny Valentine")
    }
    
    func saveImageToAlbum(_ image: PlatformImage, albumName: String = "My Funny Valentine") async throws {
        guard let picturesURL = FileManager.default.urls(for: .picturesDirectory, in: .userDomainMask).first else {
            throw PhotoLibraryError.saveFailed
        }
        
        let albumURL = picturesURL.appendingPathComponent(albumName)
        
        // Create album directory if it doesn't exist
        if !FileManager.default.fileExists(atPath: albumURL.path) {
            try FileManager.default.createDirectory(at: albumURL, withIntermediateDirectories: true)
        }
        
        // Generate filename with timestamp
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let filename = "ValentineCard_\(formatter.string(from: Date())).jpg"
        let fileURL = albumURL.appendingPathComponent(filename)
        
        // Convert NSImage to JPEG data
        guard let tiffData = image.tiffRepresentation,
              let bitmapImage = NSBitmapImageRep(data: tiffData),
              let jpegData = bitmapImage.representation(using: .jpeg, properties: [.compressionFactor: 0.9]) else {
            throw PhotoLibraryError.saveFailed
        }
        
        // Write to file
        do {
            try jpegData.write(to: fileURL)
        } catch {
            throw PhotoLibraryError.unknown(error)
        }
    }
}
#endif

/// Platform-agnostic photo library service factory
struct PlatformPhotoLibraryFactory {
    #if os(iOS) || os(visionOS)
    static func createPhotoLibraryService() -> PlatformPhotoLibraryProtocol {
        return iOSPhotoLibraryService()
    }
    #elseif os(macOS)
    static func createPhotoLibraryService() -> PlatformPhotoLibraryProtocol {
        return macOSPhotoLibraryService()
    }
    #endif
}
