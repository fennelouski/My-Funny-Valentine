//
//  ImageService.swift
//  My Funny Valentine
//

import Foundation
import UIKit
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
        guard let image = UIImage(data: imageData) else {
            throw ImageServiceError.invalidImageData
        }
        
        let resized = resize(image, maxDimension: maxImageDimension)
        guard let data = resized.jpegData(compressionQuality: jpegCompressionQuality) else {
            throw ImageServiceError.compressionFailed
        }
        
        return data
    }
    
    /// Generate thumbnail from image data
    func generateThumbnail(from imageData: Data) throws -> Data {
        guard let image = UIImage(data: imageData) else {
            throw ImageServiceError.invalidImageData
        }
        
        let thumbnail = resize(image, maxDimension: thumbnailDimension)
        guard let data = thumbnail.jpegData(compressionQuality: 0.7) else {
            throw ImageServiceError.compressionFailed
        }
        
        return data
    }
    
    /// Resize image maintaining aspect ratio
    func resize(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        let ratio = min(maxDimension / size.width, maxDimension / size.height)
        
        if ratio >= 1 { return image }
        
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}

enum ImageServiceError: Error {
    case invalidImageData
    case compressionFailed
}
