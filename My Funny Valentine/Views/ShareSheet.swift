//
//  ShareSheet.swift
//  My Funny Valentine
//
//  Created by Nathan Fennel on 2/12/26.
//

import SwiftUI
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

// Convenience extension for sharing images
extension View {
    func shareSheet(isPresented: Binding<Bool>, items: [Any], excludedActivityTypes: [UIActivity.ActivityType]? = nil, completion: ((Bool, Error?) -> Void)? = nil) -> some View {
        self.sheet(isPresented: isPresented) {
            ShareSheet(items: items, excludedActivityTypes: excludedActivityTypes, completion: completion)
        }
    }
}
