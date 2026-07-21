//
//  ImageManager.swift
//  My Funny Valentine
//
//  Created by Nathan Fennel on 2/12/26.
//

import Foundation
import UIKit
import CoreGraphics
import UniformTypeIdentifiers

/// Manages image storage, compression, thumbnails, and caching for the app.
/// Stores images in app documents directory with CloudKit sync support.
actor ImageManager {
    static let shared = ImageManager()

    private let fileManager = FileManager.default
    private let maxImageSizeBytes = 10 * 1024 * 1024 // 10MB
    private let maxTotalStorageBytes = 100 * 1024 * 1024 // 100MB
    private let thumbnailSize = CGSize(width: 200, height: 200)
    private let jpegCompressionQuality: CGFloat = 0.8

    private var memoryCache: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        cache.countLimit = 50
        cache.totalCostLimit = 50 * 1024 * 1024 // 50MB
        return cache
    }()

    private init() {}

    // MARK: - Storage Paths

    private var documentsDirectory: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    private var imagesDirectory: URL {
        documentsDirectory.appendingPathComponent("Images", isDirectory: true)
    }

    private var thumbnailsDirectory: URL {
        documentsDirectory.appendingPathComponent("Thumbnails", isDirectory: true)
    }

    // MARK: - Public API

    /// Store an image and return the compressed data along with thumbnail data
    func storeImage(_ image: UIImage, id: UUID) async throws -> (imageData: Data, thumbnailData: Data) {
        try ensureDirectoriesExist()

        let imageData = try compressImage(image)
        let thumbnailData = try generateThumbnail(from: image)

        // Validate size limits
        guard imageData.count <= maxImageSizeBytes else {
            throw ImageManagerError.imageTooLarge
        }

        try await checkStorageLimit(beforeAdding: imageData.count)

        let imageURL = imagesDirectory.appendingPathComponent("\(id.uuidString).jpg")
        let thumbnailURL = thumbnailsDirectory.appendingPathComponent("\(id.uuidString).jpg")

        try imageData.write(to: imageURL)
        try thumbnailData.write(to: thumbnailURL)

        cacheImage(image, for: id)
        return (imageData, thumbnailData)
    }

    /// Store image data directly (e.g., from cutout with transparency - use PNG)
    func storeImageData(_ data: Data, id: UUID, preserveTransparency: Bool = false) async throws -> (imageData: Data, thumbnailData: Data) {
        try ensureDirectoriesExist()

        guard let image = UIImage(data: data) else {
            throw ImageManagerError.invalidImageData
        }

        let imageData: Data
        if preserveTransparency, let pngData = image.pngData() {
            imageData = pngData
        } else {
            imageData = try compressImage(image)
        }

        let thumbnailData = try generateThumbnail(from: image)

        guard imageData.count <= maxImageSizeBytes else {
            throw ImageManagerError.imageTooLarge
        }

        try await checkStorageLimit(beforeAdding: imageData.count)

        let ext = preserveTransparency ? "png" : "jpg"
        let imageURL = imagesDirectory.appendingPathComponent("\(id.uuidString).\(ext)")
        let thumbnailURL = thumbnailsDirectory.appendingPathComponent("\(id.uuidString).jpg")

        try imageData.write(to: imageURL)
        try thumbnailData.write(to: thumbnailURL)

        cacheImage(image, for: id)
        return (imageData, thumbnailData)
    }

    /// Load image from storage or cache
    func loadImage(id: UUID) async -> UIImage? {
        if let cached = memoryCache.object(forKey: id.uuidString as NSString) {
            return cached
        }

        let imageURL = imagesDirectory.appendingPathComponent("\(id.uuidString).jpg")
        let pngURL = imagesDirectory.appendingPathComponent("\(id.uuidString).png")

        if fileManager.fileExists(atPath: imageURL.path),
           let data = try? Data(contentsOf: imageURL),
           let image = UIImage(data: data) {
            cacheImage(image, for: id)
            return image
        }

        if fileManager.fileExists(atPath: pngURL.path),
           let data = try? Data(contentsOf: pngURL),
           let image = UIImage(data: data) {
            cacheImage(image, for: id)
            return image
        }

        return nil
    }

    /// Delete image from storage
    func deleteImage(id: UUID) async throws {
        let imageURL = imagesDirectory.appendingPathComponent("\(id.uuidString).jpg")
        let pngURL = imagesDirectory.appendingPathComponent("\(id.uuidString).png")
        let thumbnailURL = thumbnailsDirectory.appendingPathComponent("\(id.uuidString).jpg")

        try? fileManager.removeItem(at: imageURL)
        try? fileManager.removeItem(at: pngURL)
        try? fileManager.removeItem(at: thumbnailURL)

        memoryCache.removeObject(forKey: id.uuidString as NSString)
    }

    /// Get current storage usage
    func getStorageUsage() async -> (used: Int64, limit: Int64) {
        var totalSize: Int64 = 0
        if let enumerator = fileManager.enumerator(at: imagesDirectory, includingPropertiesForKeys: [.fileSizeKey]) {
            for case let fileURL as URL in enumerator {
                if let size = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                    totalSize += Int64(size)
                }
            }
        }
        if let enumerator = fileManager.enumerator(at: thumbnailsDirectory, includingPropertiesForKeys: [.fileSizeKey]) {
            for case let fileURL as URL in enumerator {
                if let size = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                    totalSize += Int64(size)
                }
            }
        }
        return (totalSize, Int64(maxTotalStorageBytes))
    }

    /// Clear memory cache (e.g., on memory warning)
    func clearMemoryCache() {
        memoryCache.removeAllObjects()
    }

    // MARK: - Private Helpers

    private func ensureDirectoriesExist() throws {
        if !fileManager.fileExists(atPath: imagesDirectory.path) {
            try fileManager.createDirectory(at: imagesDirectory, withIntermediateDirectories: true)
        }
        if !fileManager.fileExists(atPath: thumbnailsDirectory.path) {
            try fileManager.createDirectory(at: thumbnailsDirectory, withIntermediateDirectories: true)
        }
    }

    private func compressImage(_ image: UIImage) throws -> Data {
        guard let data = image.jpegData(compressionQuality: jpegCompressionQuality) else {
            throw ImageManagerError.compressionFailed
        }
        return data
    }

    private func generateThumbnail(from image: UIImage) throws -> Data {
        let renderer = UIGraphicsImageRenderer(size: thumbnailSize)
        let thumbnail = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: thumbnailSize))
        }
        guard let data = thumbnail.jpegData(compressionQuality: 0.7) else {
            throw ImageManagerError.compressionFailed
        }
        return data
    }

    private func checkStorageLimit(beforeAdding size: Int) async throws {
        let (used, _) = await getStorageUsage()
        guard Int64(size) + used <= maxTotalStorageBytes else {
            throw ImageManagerError.storageLimitReached
        }
    }

    private func cacheImage(_ image: UIImage, for id: UUID) {
        memoryCache.setObject(image, forKey: id.uuidString as NSString, cost: image.jpegData(compressionQuality: 0.8)?.count ?? 0)
    }
}

// MARK: - Errors

enum ImageManagerError: LocalizedError {
    case imageTooLarge
    case invalidImageData
    case compressionFailed
    case storageLimitReached

    var errorDescription: String? {
        switch self {
        case .imageTooLarge: return "Image is too large. Maximum size is 10MB."
        case .invalidImageData: return "Invalid image data."
        case .compressionFailed: return "Failed to compress image."
        case .storageLimitReached: return "Storage limit reached. Please delete some images."
        }
    }
}
