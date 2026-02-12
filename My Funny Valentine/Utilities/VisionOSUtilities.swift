//
//  VisionOSUtilities.swift
//  My Funny Valentine
//
//  visionOS-specific utilities and enhancements
//

#if os(visionOS)
import SwiftUI
import RealityKit

/// visionOS-specific utilities
struct VisionOSUtilities {
    /// Configure window placement for visionOS
    static func configureWindowPlacement() -> WindowPlacement {
        // Use automatic placement for best spatial experience
        return .automatic
    }
    
    /// Get recommended window size for visionOS
    static var recommendedWindowSize: CGSize {
        // visionOS windows can be resized by users
        // Provide a good default size
        return CGSize(width: 1200, height: 800)
    }
}

/// View modifier for spatial interactions (visionOS only)
struct SpatialInteractionModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            // visionOS automatically handles spatial interactions
            // This modifier can be extended for custom spatial behaviors
    }
}

extension View {
    /// Add spatial interaction support (visionOS only)
    func spatialInteraction() -> some View {
        modifier(SpatialInteractionModifier())
    }
}

/// Helper for 3D card previews (visionOS only)
struct Card3DPreview: View {
    let card: Card // Assuming Card model exists
    
    var body: some View {
        // Placeholder for 3D card preview
        // Can be extended with RealityKit for 3D rendering
        Text("3D Card Preview")
            .font(.title)
    }
}

#endif
