//
//  ImageService.swift
//  My Funny Valentine
//

import Foundation
import CoreGraphics
import CoreImage
import UniformTypeIdentifiers

/// Service for image operations (resize, compress, thumbnail generation)
actor ImageService {
    static let shared = ImageService()

    private let maxImageDimension: CGFloat = 1200
    private let thumbnailDimension: CGFloat = 200
    private let jpegCompressionQuality: CGFloat = 0.8

    private init() {}

    /// Resize and compress image for storage
    func processForStorage(_ imageData: Data) throws -> Data {
        guard let image = PlatformImageUtils.image(from: imageData) else {
            throw ImageServiceError.invalidImageData
        }

        let resized = resize(image, maxDimension: maxImageDimension)
        guard let data = PlatformImageUtils.jpegData(from: resized, compressionQuality: jpegCompressionQuality) else {
            throw ImageServiceError.compressionFailed
        }

        return data
    }

    /// Generate thumbnail from image data
    func generateThumbnail(from imageData: Data) throws -> Data {
        guard let image = PlatformImageUtils.image(from: imageData) else {
            throw ImageServiceError.invalidImageData
        }

        let thumbnail = resize(image, maxDimension: thumbnailDimension)
        guard let data = PlatformImageUtils.jpegData(from: thumbnail, compressionQuality: 0.7) else {
            throw ImageServiceError.compressionFailed
        }

        return data
    }

    /// Resize image maintaining aspect ratio
    func resize(_ image: PlatformImage, maxDimension: CGFloat) -> PlatformImage {
        PlatformImageUtils.resized(image, maxDimension: maxDimension)
    }
}

enum ImageServiceError: Error {
    case invalidImageData
    case compressionFailed
}
