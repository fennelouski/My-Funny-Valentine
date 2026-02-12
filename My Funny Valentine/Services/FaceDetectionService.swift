//
//  FaceDetectionService.swift
//  My Funny Valentine
//
//  Created by Nathan Fennel on 2/12/26.
//

import Foundation
import UIKit
import Vision
import CoreImage

/// On-device face detection using Vision framework. Processes images locally - no network calls.
actor FaceDetectionService {
    static let shared = FaceDetectionService()

    /// Padding around detected face (as multiplier of face bounding box)
    private let facePadding: CGFloat = 0.3

    private init() {}

    /// Detect faces in an image and return extracted face regions
    func detectFaces(in image: UIImage) async throws -> [DetectedFace] {
        guard let cgImage = image.cgImage else {
            throw FaceDetectionError.invalidImage
        }

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNDetectFaceRectanglesRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let results = request.results as? [VNFaceObservation] else {
                    continuation.resume(returning: [])
                    return
                }

                let detectedFaces = results.compactMap { observation -> DetectedFace? in
                    self.extractFaceRegion(from: cgImage, observation: observation, originalImage: image)
                }

                continuation.resume(returning: detectedFaces)
            }

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    /// Extract face region from image with padding and orientation correction
    private func extractFaceRegion(from cgImage: CGImage, observation: VNFaceObservation, originalImage: UIImage) -> DetectedFace? {
        let imageWidth = CGFloat(cgImage.width)
        let imageHeight = CGFloat(cgImage.height)

        // Vision returns normalized coordinates (0-1), convert to image coordinates
        let boundingBox = observation.boundingBox
        let x = boundingBox.origin.x * imageWidth
        let y = (1 - boundingBox.origin.y - boundingBox.height) * imageHeight // Flip Y for UIKit
        let width = boundingBox.width * imageWidth
        let height = boundingBox.height * imageHeight

        // Add padding
        let paddingX = width * facePadding
        let paddingY = height * facePadding
        var rect = CGRect(
            x: max(0, x - paddingX),
            y: max(0, y - paddingY),
            width: min(imageWidth - (x - paddingX), width + 2 * paddingX),
            height: min(imageHeight - (y - paddingY), height + 2 * paddingY)
        )

        // Ensure we don't exceed image bounds
        if rect.origin.x + rect.width > imageWidth {
            rect.size.width = imageWidth - rect.origin.x
        }
        if rect.origin.y + rect.height > imageHeight {
            rect.size.height = imageHeight - rect.origin.y
        }

        guard let croppedCGImage = cgImage.cropping(to: rect) else { return nil }

        // Apply orientation correction if needed
        let orientedImage = orientImage(UIImage(cgImage: croppedCGImage), with: originalImage.imageOrientation)
        guard let faceImageData = orientedImage.pngData() else { return nil }

        return DetectedFace(
            id: UUID(),
            imageData: faceImageData,
            boundingBox: rect,
            confidence: observation.confidence
        )
    }

    /// Apply same orientation as source image
    private func orientImage(_ image: UIImage, with orientation: UIImage.Orientation) -> UIImage {
        guard orientation != .up else { return image }

        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        image.draw(in: CGRect(origin: .zero, size: image.size))
        let orientedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return orientedImage ?? image
    }
}

// MARK: - DetectedFace Model

struct DetectedFace: Identifiable {
    let id: UUID
    let imageData: Data
    let boundingBox: CGRect
    let confidence: Float
}

// MARK: - Errors

enum FaceDetectionError: LocalizedError {
    case invalidImage
    case noFacesDetected

    var errorDescription: String? {
        switch self {
        case .invalidImage: return "Could not process image."
        case .noFacesDetected: return "No faces were detected in the image."
        }
    }
}
