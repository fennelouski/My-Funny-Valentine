//
//  PlatformSharing.swift
//  My Funny Valentine
//
//  Platform-agnostic sharing abstraction
//

import Foundation
import SwiftUI

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

/// Protocol for platform-specific sharing implementations
protocol PlatformSharingProtocol {
    func shareImage(_ image: PlatformImage, completion: ((Bool, Error?) -> Void)?)
    func canShare() -> Bool
}

#if os(iOS)
/// iOS sharing implementation using UIActivityViewController
class iOSSharingService: PlatformSharingProtocol {
    private weak var viewController: UIViewController?
    
    init(viewController: UIViewController) {
        self.viewController = viewController
    }
    
    func shareImage(_ image: PlatformImage, completion: ((Bool, Error?) -> Void)?) {
        guard let viewController = viewController else {
            completion?(false, ShareError.shareFailed(NSError(domain: "PlatformSharing", code: -1, userInfo: [NSLocalizedDescriptionKey: "ViewController not available"])))
            return
        }
        
        let activityViewController = UIActivityViewController(
            activityItems: [image],
            applicationActivities: nil
        )
        
        // For iPad
        if let popover = activityViewController.popoverPresentationController {
            popover.sourceView = viewController.view
            if let view = viewController.view {
                popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
            }
            popover.permittedArrowDirections = []
        }
        
        activityViewController.completionWithItemsHandler = { _, completed, _, error in
            completion?(completed, error)
        }
        
        viewController.present(activityViewController, animated: true)
    }
    
    func canShare() -> Bool {
        return viewController != nil
    }
}
#endif

#if os(macOS)
/// macOS sharing implementation using NSSharingServicePicker
class macOSSharingService: PlatformSharingProtocol {
    private let view: NSView
    
    init(view: NSView) {
        self.view = view
    }
    
    func shareImage(_ image: PlatformImage, completion: ((Bool, Error?) -> Void)?) {
        guard let window = view.window else {
            completion?(false, ShareError.shareFailed(NSError(domain: "PlatformSharing", code: -1, userInfo: [NSLocalizedDescriptionKey: "Window not available"])))
            return
        }
        
        let sharingServicePicker = NSSharingServicePicker(items: [image])
        
        if let bounds = view.window?.contentView?.bounds {
            sharingServicePicker.show(relativeTo: .zero, of: view, preferredEdge: .minY)
        } else {
            // Fallback: show at center of window
            let rect = NSRect(x: window.frame.midX, y: window.frame.midY, width: 0, height: 0)
            sharingServicePicker.show(relativeTo: rect, of: view, preferredEdge: .minY)
        }
        
        // Note: NSSharingServicePicker doesn't provide completion callbacks
        // We'll call completion immediately as a best-effort approach
        completion?(true, nil)
    }
    
    func canShare() -> Bool {
        return view.window != nil
    }
}
#endif

#if os(visionOS)
/// visionOS sharing implementation using SwiftUI ShareLink
class VisionOSSharingService: PlatformSharingProtocol {
    func shareImage(_ image: PlatformImage, completion: ((Bool, Error?) -> Void)?) {
        // On visionOS, sharing is handled via SwiftUI ShareLink
        // This is a placeholder - actual sharing will be done via ShareLink in views
        completion?(true, nil)
    }
    
    func canShare() -> Bool {
        return true
    }
}
#endif

/// Platform-agnostic sharing service factory
struct PlatformSharingFactory {
    #if os(iOS)
    static func createSharingService(viewController: UIViewController) -> PlatformSharingProtocol {
        return iOSSharingService(viewController: viewController)
    }
    #elseif os(macOS)
    static func createSharingService(view: NSView) -> PlatformSharingProtocol {
        return macOSSharingService(view: view)
    }
    #elseif os(visionOS)
    static func createSharingService() -> PlatformSharingProtocol {
        return VisionOSSharingService()
    }
    #endif
}
