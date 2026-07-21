//
//  ShareService.swift
//  My Funny Valentine
//
//  Created by Nathan Fennel on 2/12/26.
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

enum ShareError: LocalizedError {
    case imageGenerationFailed
    case appNotInstalled(String)
    case shareFailed(Error)
    case platformNotSupported
    
    var errorDescription: String? {
        switch self {
        case .imageGenerationFailed:
            return "Failed to generate image for sharing."
        case .appNotInstalled(let appName):
            return "\(appName) is not installed. Please install it from the App Store."
        case .shareFailed(let error):
            return "Share failed: \(error.localizedDescription)"
        case .platformNotSupported:
            return "This sharing method is not supported on this platform."
        }
    }
}

class ShareService {
    static let shared = ShareService()
    
    private init() {}
    
    #if os(iOS)
    /// Check if an app is installed via URL scheme (iOS only)
    func isAppInstalled(urlScheme: String) -> Bool {
        guard let url = URL(string: "\(urlScheme)://") else { return false }
        return UIApplication.shared.canOpenURL(url)
    }
    #endif
    
    /// Share image using platform-appropriate sharing mechanism
    func shareImage(_ image: PlatformImage, completion: ((Bool, Error?) -> Void)? = nil) {
        #if os(iOS)
        // iOS sharing requires a view controller, so this method signature is kept for compatibility
        // But we'll use the platform abstraction internally
        completion?(false, ShareError.platformNotSupported)
        #elseif os(macOS)
        // macOS sharing requires a view
        completion?(false, ShareError.platformNotSupported)
        #elseif os(visionOS)
        // visionOS uses SwiftUI ShareLink
        completion?(false, ShareError.platformNotSupported)
        #endif
    }
    
    #if os(iOS)
    /// Share image using iOS Share Sheet (iOS-specific)
    func shareImage(_ image: PlatformImage, from viewController: UIViewController, completion: ((Bool, Error?) -> Void)? = nil) {
        guard PlatformImageUtils.jpegData(from: image, compressionQuality: 0.9) != nil else {
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
    #endif
    
    #if os(iOS)
    /// Share image optimized for Instagram (iOS only)
    func shareToInstagram(_ image: PlatformImage, from viewController: UIViewController, isPortrait: Bool = false) throws {
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
        
        // Note: UIDocumentInteractionController doesn't have popoverPresentationController
        // It uses presentOpenInMenu which handles its own presentation
        documentController.presentOpenInMenu(from: .zero, in: viewController.view, animated: true)
    }
    
    /// Share image optimized for Facebook (iOS only)
    func shareToFacebook(_ image: PlatformImage, from viewController: UIViewController) throws {
        // Facebook sharing is typically done through the standard share sheet
        // But we can optimize the image first
        guard let optimizedData = ImageOptimizer.shared.optimize(image, for: .facebook),
              let optimizedImage = PlatformImageUtils.image(from: optimizedData) else {
            throw ShareError.imageGenerationFailed
        }
        
        shareImage(optimizedImage, from: viewController)
    }
    
    /// Share image optimized for TikTok (iOS only)
    func shareToTikTok(_ image: PlatformImage, from viewController: UIViewController) throws {
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
        
        documentController.presentOpenInMenu(from: .zero, in: viewController.view, animated: true)
    }
    
    /// Share image optimized for email (iOS only)
    func shareToEmail(_ image: PlatformImage, from viewController: UIViewController) {
        guard let optimizedData = ImageOptimizer.shared.optimize(image, for: .email),
              let optimizedImage = PlatformImageUtils.image(from: optimizedData) else {
            // Fallback to regular share if optimization fails
            shareImage(image, from: viewController)
            return
        }
        
        shareImage(optimizedImage, from: viewController)
    }
    
    /// Share image optimized for Messages (iOS only)
    func shareToMessages(_ image: PlatformImage, from viewController: UIViewController) {
        guard let optimizedData = ImageOptimizer.shared.optimize(image, for: .messages),
              let optimizedImage = PlatformImageUtils.image(from: optimizedData) else {
            shareImage(image, from: viewController)
            return
        }
        
        shareImage(optimizedImage, from: viewController)
    }
    #endif
    
    /// Save image to Photos library (platform-agnostic)
    func saveToPhotos(_ image: PlatformImage) async throws {
        let photoLibraryService = PlatformPhotoLibraryFactory.createPhotoLibraryService()
        try await photoLibraryService.saveImage(image)
    }
    
    /// Save image to Photos library in album (platform-agnostic)
    func saveToPhotosAlbum(_ image: PlatformImage, albumName: String = "My Funny Valentine") async throws {
        let photoLibraryService = PlatformPhotoLibraryFactory.createPhotoLibraryService()
        try await photoLibraryService.saveImageToAlbum(image, albumName: albumName)
    }
}
