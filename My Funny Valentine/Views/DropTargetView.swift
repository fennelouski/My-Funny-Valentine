//
//  DropTargetView.swift
//  My Funny Valentine
//
//  Created by Nathan Fennel on 2/12/26.
//

import SwiftUI
import UniformTypeIdentifiers

#if os(iOS) || os(visionOS)
import UIKit

/// UIViewRepresentable wrapper for UIDropInteraction to accept smart cutouts from Photos app.
/// Handles drag-and-drop of images with transparency (cutouts).
struct DropTargetView: UIViewRepresentable {
    let onImageDropped: (PlatformImage) -> Void
    let isActive: Bool

    init(isActive: Bool = true, onImageDropped: @escaping (PlatformImage) -> Void) {
        self.isActive = isActive
        self.onImageDropped = onImageDropped
    }

    func makeUIView(context: Context) -> DropTargetUIView {
        let view = DropTargetUIView()
        view.onImageDropped = onImageDropped
        return view
    }

    func updateUIView(_ uiView: DropTargetUIView, context: Context) {
        uiView.onImageDropped = onImageDropped
        uiView.isDropTargetActive = isActive
    }
}

class DropTargetUIView: UIView {
    var onImageDropped: ((PlatformImage) -> Void)?
    var isDropTargetActive: Bool = true

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupDropInteraction()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupDropInteraction()
    }

    private func setupDropInteraction() {
        let dropInteraction = UIDropInteraction(delegate: self)
        addInteraction(dropInteraction)
    }
}

extension DropTargetUIView: UIDropInteractionDelegate {
    func dropInteraction(_ interaction: UIDropInteraction, canHandle session: UIDropSession) -> Bool {
        guard isDropTargetActive else { return false }
        return session.canLoadObjects(ofClass: UIImage.self) ||
               session.hasItemsConforming(toTypeIdentifiers: [UTType.image.identifier])
    }

    func dropInteraction(_ interaction: UIDropInteraction, sessionDidUpdate session: UIDropSession) -> UIDropProposal {
        return UIDropProposal(operation: .copy)
    }

    func dropInteraction(_ interaction: UIDropInteraction, performDrop session: UIDropSession) {
        for item in session.items {
            let provider = item.itemProvider

            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { [weak self] object, _ in
                    if let image = object as? UIImage {
                        DispatchQueue.main.async {
                            self?.onImageDropped?(image)
                        }
                    }
                }
                return
            }

            // Prefer PNG so Photos "smart cutout" transparency survives the drop
            for type in [UTType.png, UTType.image] where provider.hasItemConformingToTypeIdentifier(type.identifier) {
                provider.loadDataRepresentation(forTypeIdentifier: type.identifier) { [weak self] data, _ in
                    if let data, let image = UIImage(data: data) {
                        DispatchQueue.main.async {
                            self?.onImageDropped?(image)
                        }
                    }
                }
                return
            }
        }
    }
}

#elseif os(macOS)

/// SwiftUI drop target for macOS. Accepts image data dragged from Finder,
/// Photos, or other apps.
struct DropTargetView: View {
    let onImageDropped: (PlatformImage) -> Void
    let isActive: Bool

    @State private var isTargeted = false

    init(isActive: Bool = true, onImageDropped: @escaping (PlatformImage) -> Void) {
        self.isActive = isActive
        self.onImageDropped = onImageDropped
    }

    var body: some View {
        Color.clear
            .contentShape(Rectangle())
            .overlay {
                if isTargeted {
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.accentColor, style: StrokeStyle(lineWidth: 2, dash: [6]))
                }
            }
            .dropDestination(for: Data.self) { items, _ in
                guard isActive,
                      let data = items.first,
                      let image = PlatformImageUtils.image(from: data) else { return false }
                onImageDropped(image)
                return true
            } isTargeted: { targeted in
                isTargeted = targeted && isActive
            }
    }
}

#endif
