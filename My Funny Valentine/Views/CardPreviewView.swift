//
//  CardPreviewView.swift
//  My Funny Valentine
//
//  Created by Nathan Fennel on 2/12/26.
//

import SwiftUI
import SwiftData

struct CardPreviewView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var card: Card
    
    @State private var scale: CGFloat = 1.0
    @State private var showingShareSheet = false
    @State private var showingDeleteConfirmation = false
    
    private let cardSize = CGSize(width: 400, height: 600)
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.opacity(0.9)
                    .ignoresSafeArea()
                
                ScrollView([.horizontal, .vertical]) {
                    cardPreview
                        .scaleEffect(scale)
                        .padding()
                }
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            scale = value
                        }
                )
            }
            .navigationTitle("Card Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
                ToolbarItemGroup(placement: .primaryAction) {
                    Button(action: { showingShareSheet = true }) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    
                    NavigationLink {
                        CardEditorView(card: card)
                    } label: {
                        Image(systemName: "pencil")
                    }
                    
                    Button(action: { showingDeleteConfirmation = true }) {
                        Image(systemName: "trash")
                    }
                    .foregroundColor(.red)
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                ShareSheet(items: [exportCard()])
            }
            .alert("Delete Card", isPresented: $showingDeleteConfirmation) {
                Button("Delete", role: .destructive) {
                    deleteCard()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to delete this card?")
            }
        }
    }
    
    private var cardPreview: some View {
        Canvas { context, size in
            // Draw background
            card.layout.backgroundColor.color.uiColor.setFill()
            context.cgContext.fill(CGRect(origin: .zero, size: cardSize))
            
            // Draw faces
            if let template = TemplateManager.shared.getTemplate(id: card.templateId ?? "") {
                for (index, facePosition) in template.facePositions.enumerated() {
                    if index < (card.faces ?? []).count {
                        let faceImage = (card.faces ?? [])[index]
                        if let uiImage = UIImage(data: faceImage.imageData) {
                            let rect = CGRect(
                                origin: facePosition.position,
                                size: facePosition.size
                            )
                            context.draw(Image(uiImage: uiImage), in: rect)
                        }
                    }
                }
            }
            
            // Draw text
            for textPosition in card.layout.textPositions {
                if !textPosition.text.isEmpty {
                    let font = UIFont(name: textPosition.fontName, size: textPosition.fontSize) ?? UIFont.systemFont(ofSize: textPosition.fontSize)
                    let attributes: [NSAttributedString.Key: Any] = [
                        .font: font,
                        .foregroundColor: textPosition.color.color.uiColor
                    ]
                    
                    let attributedString = NSAttributedString(string: textPosition.text, attributes: attributes)
                    let textSize = attributedString.size()
                    let textRect = CGRect(
                        origin: CGPoint(
                            x: textPosition.position.x - textSize.width / 2,
                            y: textPosition.position.y - textSize.height / 2
                        ),
                        size: textSize
                    )
                    
                    attributedString.draw(in: textRect)
                }
            }
            
            // Draw images
            for image in card.images ?? [] {
                if let uiImage = UIImage(data: image.imageData) {
                    let rect = CGRect(
                        origin: image.position,
                        size: image.size
                    )
                    context.draw(Image(uiImage: uiImage), in: rect)
                }
            }
            
            // Draw stickers
            for sticker in card.stickers ?? [] {
                if let data = sticker.stickerData, let uiImage = UIImage(data: data) {
                    let rect = CGRect(
                        origin: sticker.position,
                        size: sticker.size
                    )
                    context.draw(Image(uiImage: uiImage), in: rect)
                }
            }
        }
        .frame(width: cardSize.width, height: cardSize.height)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 10)
    }
    
    private func exportCard() -> UIImage {
        return CardGenerationService.shared.renderCard(card, size: cardSize) ?? UIImage()
    }
    
    private func deleteCard() {
        modelContext.delete(card)
        try? modelContext.save()
        dismiss()
    }
}
