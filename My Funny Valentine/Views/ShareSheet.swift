//
//  ShareSheet.swift
//  My Funny Valentine
//
//  Created by Nathan Fennel on 2/12/26.
//

import SwiftUI

#if os(iOS)
import UIKit

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    let excludedActivityTypes: [UIActivity.ActivityType]?
    let completion: ((Bool, Error?) -> Void)?
    
    init(
        items: [Any],
        excludedActivityTypes: [UIActivity.ActivityType]? = nil,
        completion: ((Bool, Error?) -> Void)? = nil
    ) {
        self.items = items
        self.excludedActivityTypes = excludedActivityTypes
        self.completion = completion
    }
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
        
        if let excludedTypes = excludedActivityTypes {
            controller.excludedActivityTypes = excludedTypes
        }
        
        // For iPad - will be configured by the presenting view controller
        if let popover = controller.popoverPresentationController {
            popover.permittedArrowDirections = []
        }
        
        controller.completionWithItemsHandler = { activityType, completed, returnedItems, error in
            completion?(completed, error)
        }
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // No updates needed
    }
}

#elseif os(macOS)
import AppKit

struct ShareSheet: NSViewRepresentable {
    let items: [Any]
    let completion: ((Bool, Error?) -> Void)?
    
    init(
        items: [Any],
        excludedActivityTypes: [Any]? = nil, // Not used on macOS
        completion: ((Bool, Error?) -> Void)? = nil
    ) {
        self.items = items
        self.completion = completion
    }
    
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        // Show sharing picker when view appears
        DispatchQueue.main.async {
            if nsView.window != nil {
                let sharingServicePicker = NSSharingServicePicker(items: items)
                let rect = NSRect(x: nsView.bounds.midX, y: nsView.bounds.midY, width: 0, height: 0)
                sharingServicePicker.show(relativeTo: rect, of: nsView, preferredEdge: .minY)
                // Note: NSSharingServicePicker doesn't provide completion callbacks
                completion?(true, nil)
            }
        }
    }
}

#elseif os(visionOS)
// visionOS uses SwiftUI ShareLink - no need for custom ShareSheet wrapper
struct ShareSheet: View {
    let items: [Any]
    let completion: ((Bool, Error?) -> Void)?
    
    init(
        items: [Any],
        excludedActivityTypes: [Any]? = nil,
        completion: ((Bool, Error?) -> Void)? = nil
    ) {
        self.items = items
        self.completion = completion
    }
    
    var body: some View {
        // On visionOS, use ShareLink directly in views
        Text("Share")
            .onAppear {
                completion?(true, nil)
            }
    }
}
#endif

// Convenience extension for sharing images
extension View {
    #if os(iOS)
    func shareSheet(isPresented: Binding<Bool>, items: [Any], excludedActivityTypes: [UIActivity.ActivityType]? = nil, completion: ((Bool, Error?) -> Void)? = nil) -> some View {
        self.sheet(isPresented: isPresented) {
            ShareSheet(items: items, excludedActivityTypes: excludedActivityTypes, completion: completion)
        }
    }
    #else
    func shareSheet(isPresented: Binding<Bool>, items: [Any], excludedActivityTypes: [Any]? = nil, completion: ((Bool, Error?) -> Void)? = nil) -> some View {
        self.sheet(isPresented: isPresented) {
            ShareSheet(items: items, excludedActivityTypes: excludedActivityTypes, completion: completion)
        }
    }
    #endif
}
