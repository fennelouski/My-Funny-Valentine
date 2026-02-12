//
//  DropTargetView.swift
//  My Funny Valentine
//
//  Created by Nathan Fennel on 2/12/26.
//

import SwiftUI
import UIKit
import UniformTypeIdentifiers

/// UIViewRepresentable wrapper for UIDropInteraction to accept smart cutouts from Photos app.
/// Handles drag-and-drop of images with transparency (cutouts).
struct DropTargetView: UIViewRepresentable {
    let onImageDropped: (UIImage) -> Void
    let isActive: Bool

    init(isActive: Bool = true, onImageDropped: @escaping (UIImage) -> Void) {
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
    var onImageDropped: ((UIImage) -> Void)?
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

            if provider.hasItemConformingToTypeIdentifier(UTType.png.identifier) {
                provider.loadDataRepresentation(forTypeIdentifier: UTType.png.identifier) { [weak self] data, _ in
                    if let data = data, let image = UIImage(data: data) {
                        DispatchQueue.main.async {
                            self?.onImageDropped?(image)
                        }
                    }
                }
                return
            }

            if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                provider.loadDataRepresentation(forTypeIdentifier: UTType.image.identifier) { [weak self] data, _ in
                    if let data = data, let image = UIImage(data: data) {
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
