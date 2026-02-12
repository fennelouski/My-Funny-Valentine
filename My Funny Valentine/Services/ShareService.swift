//
//  ShareService.swift
//  My Funny Valentine
//
//  Created by Nathan Fennel on 2/12/26.
//

import Foundation
import UIKit
import SwiftUI
import UniformTypeIdentifiers

enum ShareError: LocalizedError {
    case imageGenerationFailed
    case appNotInstalled(String)
    case shareFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .imageGenerationFailed:
            return "Failed to generate image for sharing."
        case .appNotInstalled(let appName):
            return "\(appName) is not installed. Please install it from the App Store."
        case .shareFailed(let error):
            return "Share failed: \(error.localizedDescription)"
        }
    }
}

class ShareService {
    static let shared = ShareService()
    
    private init() {}
    
    /// Check if an app is installed via URL scheme
    func isAppInstalled(urlScheme: String) -> Bool {
        guard let url = URL(string: "\(urlScheme)://") else { return false }
        return UIApplication.shared.canOpenURL(url)
    }
    
    /// Share image using iOS Share Sheet
    func shareImage(_ image: UIImage, from viewController: UIViewController, completion: ((Bool, Error?) -> Void)? = nil) {
        guard let imageData = image.jpegData(compressionQuality: 0.9) else {
            completion?(false, ShareError.imageGenerationFailed)
            return
        }
        
        let activityViewController = UIActivityViewController(
            activityItems: [image],
            applicationActivities: nil
        )
        
        // Exclude some activities if needed
        activityViewController.excludedActivityTypes = []
        
        // For iPad
        if let popover = activityViewController.popoverPresentationController {
            popover.sourceView = viewController.view
            if let view = viewController.view {
                popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
            }
            popover.permittedArrowDirections = []
        }
        
        activityViewController.completionWithItemsHandler = { activityType, completed, returnedItems, error in
            completion?(completed, error)
        }
        
        viewController.present(activityViewController, animated: true)
    }
    
    /// Share image optimized for Instagram
    func shareToInstagram(_ image: UIImage, from viewController: UIViewController, isPortrait: Bool = false) throws {
        guard isAppInstalled(urlScheme: "instagram") else {
            throw ShareError.appNotInstalled("Instagram")
        }
        
        guard let optimizedData = ImageOptimizer.shared.optimizeForInstagram(image, isPortrait: isPortrait) else {
            throw ShareError.imageGenerationFailed
        }
        
        // Save to temporary file
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("instagram_share.jpg")
        try? FileManager.default.removeItem(at: tempURL)
        try optimizedData.write(to: tempURL)
        
        // Open Instagram with document interaction
        let documentController = UIDocumentInteractionController(url: tempURL)
        documentController.uti = UTType.jpeg.identifier
        
        if let popover = documentController.popoverPresentationController {
            popover.sourceView = viewController.view
            popover.sourceRect = CGRect(x: viewController.view.bounds.midX, y: viewController.view.bounds.midY, width: 0, height: 0)
        }
        
        documentController.presentOpenInMenu(from: .zero, in: viewController.view, animated: true)
    }
    
    /// Share image optimized for Facebook
    func shareToFacebook(_ image: UIImage, from viewController: UIViewController) throws {
        // Facebook sharing is typically done through the standard share sheet
        // But we can optimize the image first
        guard let optimizedData = ImageOptimizer.shared.optimize(image, for: .facebook),
              let optimizedImage = UIImage(data: optimizedData) else {
            throw ShareError.imageGenerationFailed
        }
        
        shareImage(optimizedImage, from: viewController)
    }
    
    /// Share image optimized for TikTok
    func shareToTikTok(_ image: UIImage, from viewController: UIViewController) throws {
        guard isAppInstalled(urlScheme: "snssdk1233") else {
            throw ShareError.appNotInstalled("TikTok")
        }
        
        guard let optimizedData = ImageOptimizer.shared.optimizeForTikTok(image) else {
            throw ShareError.imageGenerationFailed
        }
        
        // Save to temporary file
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("tiktok_share.jpg")
        try? FileManager.default.removeItem(at: tempURL)
        try optimizedData.write(to: tempURL)
        
        // Open TikTok with document interaction
        let documentController = UIDocumentInteractionController(url: tempURL)
        documentController.uti = UTType.jpeg.identifier
        
        if let popover = documentController.popoverPresentationController {
            popover.sourceView = viewController.view
            popover.sourceRect = CGRect(x: viewController.view.bounds.midX, y: viewController.view.bounds.midY, width: 0, height: 0)
        }
        
        documentController.presentOpenInMenu(from: .zero, in: viewController.view, animated: true)
    }
    
    /// Share image optimized for email
    func shareToEmail(_ image: UIImage, from viewController: UIViewController) {
        guard let optimizedData = ImageOptimizer.shared.optimize(image, for: .email),
              let optimizedImage = UIImage(data: optimizedData) else {
            // Fallback to regular share if optimization fails
            shareImage(image, from: viewController)
            return
        }
        
        shareImage(optimizedImage, from: viewController)
    }
    
    /// Share image optimized for Messages
    func shareToMessages(_ image: UIImage, from viewController: UIViewController) {
        guard let optimizedData = ImageOptimizer.shared.optimize(image, for: .messages),
              let optimizedImage = UIImage(data: optimizedData) else {
            shareImage(image, from: viewController)
            return
        }
        
        shareImage(optimizedImage, from: viewController)
    }
    
    /// Save image to Photos library
    func saveToPhotos(_ image: UIImage) async throws {
        try await PhotoLibraryManager.shared.saveImage(image)
    }
    
    /// Save image to Photos library in album
    func saveToPhotosAlbum(_ image: UIImage, albumName: String = "My Funny Valentine") async throws {
        try await PhotoLibraryManager.shared.saveImageToAlbum(image, albumName: albumName)
    }
}
