//
//  ImageEditorView.swift
//  My Funny Valentine
//
//  Created by Nathan Fennel on 2/12/26.
//

import SwiftUI

/// Image placement, resize, rotate, and layer management for card editor.
struct ImageEditorView: View {
    let image: UIImage
    let onRemove: () -> Void
    @State private var scale: CGFloat = 1.0
    @State private var rotation: Double = 0
    @State private var position: CGSize = .zero
    @State private var lastScale: CGFloat = 1.0
    @State private var isDragging = false

    var body: some View {
        ZStack(alignment: .center) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(width: 150, height: 150)
                .scaleEffect(scale)
                .rotationEffect(.degrees(rotation))
                .offset(position)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            position = CGSize(
                                width: position.width + value.translation.width,
                                height: position.height + value.translation.height
                            )
                        }
                )
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            scale = lastScale * value
                        }
                        .onEnded { _ in
                            lastScale = scale
                        }
                )
                .rotationEffect(.degrees(rotation))
                .onTapGesture(count: 2) {
                    withAnimation {
                        rotation += 90
                    }
                }

            VStack {
                HStack {
                    Spacer()
                    Button {
                        onRemove()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.white)
                            .shadow(radius: 2)
                    }
                    .padding(4)
                }
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// Editable image layer with position, size, rotation controls
struct EditableImageLayer: View {
    let imageData: Data
    let position: CGPoint
    let size: CGSize
    let rotation: Double
    let onUpdate: (CGPoint, CGSize, Double) -> Void
    let onRemove: () -> Void

    @State private var currentPosition: CGPoint
    @State private var currentSize: CGSize
    @State private var currentRotation: Double

    init(
        imageData: Data,
        position: CGPoint,
        size: CGSize,
        rotation: Double,
        onUpdate: @escaping (CGPoint, CGSize, Double) -> Void,
        onRemove: @escaping () -> Void
    ) {
        self.imageData = imageData
        self.position = position
        self.size = size
        self.rotation = rotation
        self.onUpdate = onUpdate
        self.onRemove = onRemove
        _currentPosition = State(initialValue: position)
        _currentSize = State(initialValue: size)
        _currentRotation = State(initialValue: rotation)
    }

    var body: some View {
        if let uiImage = UIImage(data: imageData) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFit()
                .frame(width: currentSize.width, height: currentSize.height)
                .rotationEffect(.degrees(currentRotation))
                .position(currentPosition)
                .overlay(alignment: .topTrailing) {
                    Button(action: onRemove) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.white)
                            .shadow(radius: 2)
                    }
                    .offset(x: 20, y: -20)
                }
        }
    }
}

#Preview {
    if let image = UIImage(systemName: "person.fill") {
        ImageEditorView(image: image, onRemove: {})
            .frame(width: 300, height: 300)
    }
}
