//
//  CardEditorView.swift
//  My Funny Valentine
//
//  Created by Nathan Fennel on 2/12/26.
//

import SwiftUI
import SwiftData

struct CardEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var card: Card
    
    @State private var selectedElement: UUID?
    @State private var showingTextEditor = false
    @State private var showingFontPicker = false
    @State private var showingColorPicker = false
    @State private var showingImageImport = false
    @State private var undoStack: [Card] = []
    @State private var redoStack: [Card] = []
    
    private let cardSize = CGSize(width: 400, height: 600)
    
    var body: some View {
        NavigationView {
            HStack(spacing: 0) {
                // Toolbar
                editorToolbar
                    .frame(width: 80)
                    .background(Color.appFill)
                
                // Canvas
                cardCanvas
                    .frame(maxWidth: .infinity)
                
                // Property Inspector
                propertyInspector
                    .frame(width: 300)
                    .background(Color.appFill)
            }
            .navigationTitle("Edit Card")
            .appInlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        saveCard()
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingTextEditor) {
                TextEditorView(card: card)
            }
            .sheet(isPresented: $showingImageImport) {
                CardImageImportView(card: card)
            }
        }
    }
    
    private var editorToolbar: some View {
        VStack(spacing: 20) {
            Button(action: undo) {
                Image(systemName: "arrow.uturn.backward")
                    .font(.title2)
            }
            .disabled(undoStack.isEmpty)
            
            Button(action: redo) {
                Image(systemName: "arrow.uturn.forward")
                    .font(.title2)
            }
            .disabled(redoStack.isEmpty)
            
            Divider()
            
            Button(action: { showingTextEditor = true }) {
                Image(systemName: "textformat")
                    .font(.title2)
            }
            
            Button(action: { showingImageImport = true }) {
                Image(systemName: "photo")
                    .font(.title2)
            }
            
            Button(action: addSticker) {
                Image(systemName: "face.smiling")
                    .font(.title2)
            }
            
            Divider()
            
            Button(action: { card.layout.backgroundColor = ColorData(color: .random) }) {
                Image(systemName: "paintpalette")
                    .font(.title2)
            }
        }
        .padding()
    }
    
    private var cardCanvas: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                card.layout.backgroundColor.color
                    .ignoresSafeArea()
                
                // Render card elements
                Canvas { context, size in
                    // Draw faces
                    if let template = TemplateManager.shared.getTemplate(id: card.templateId ?? "") {
                        for (index, facePosition) in template.facePositions.enumerated() {
                            if index < (card.faces ?? []).count {
                                let faceImage = (card.faces ?? [])[index]
                                if let uiImage = PlatformImage(data: faceImage.imageData) {
                                    let rect = CGRect(
                                        origin: facePosition.position,
                                        size: facePosition.size
                                    )
                                    context.draw(PlatformImageUtils.swiftUIImage(from: uiImage), in: rect)
                                }
                            }
                        }
                    }
                    
                    // Draw text
                    for textPosition in card.layout.textPositions {
                        if !textPosition.text.isEmpty {
                            let font = Font.custom(textPosition.fontName, size: textPosition.fontSize)
                            let text = Text(textPosition.text)
                                .font(font)
                                .foregroundColor(textPosition.color.color)
                            
                            context.draw(text, at: textPosition.position)
                        }
                    }
                    
                    // Draw images
                    for image in card.images ?? [] {
                        if let uiImage = PlatformImage(data: image.imageData) {
                            let rect = CGRect(
                                origin: image.position,
                                size: image.size
                            )
                            context.draw(PlatformImageUtils.swiftUIImage(from: uiImage), in: rect)
                        }
                    }
                    
                    // Draw stickers
                    for sticker in card.stickers ?? [] {
                        if let data = sticker.stickerData, let uiImage = PlatformImage(data: data) {
                            let rect = CGRect(
                                origin: sticker.position,
                                size: sticker.size
                            )
                            context.draw(PlatformImageUtils.swiftUIImage(from: uiImage), in: rect)
                        }
                    }
                }
                .frame(width: cardSize.width, height: cardSize.height)
                .border(Color.gray.opacity(0.3), width: 1)
                .gesture(
                    DragGesture()
                        .onEnded { value in
                            // Handle drag interactions
                        }
                )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    private var propertyInspector: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Properties")
                .font(.headline)
                .padding()
            
            if let selected = selectedElement {
                // Show properties for selected element
                Text("Selected: \(selected.uuidString)")
            } else {
                Text("No selection")
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
    }
    
    private func undo() {
        guard !undoStack.isEmpty else { return }
        _ = undoStack.removeLast()
        redoStack.append(card)
        // Restore previous state
    }
    
    private func redo() {
        guard !redoStack.isEmpty else { return }
        _ = redoStack.removeLast()
        undoStack.append(card)
        // Restore next state
    }
    
    
    private func addSticker() {
        // Open sticker picker
    }
    
    private func saveCard() {
        card.modifiedAt = Date()
        try? modelContext.save()
    }
}

struct TextEditorView: View {
    @Bindable var card: Card
    @Environment(\.dismiss) private var dismiss
    @State private var text: String = ""
    @State private var selectedTextIndex: Int = 0
    
    var body: some View {
        NavigationView {
            Form {
                Section("Text") {
                    TextField("Enter text", text: $text)
                }
                
                Section("Font") {
                    Picker("Font", selection: .constant("System")) {
                        Text("System").tag("System")
                        Text("Arial").tag("Arial")
                        Text("Helvetica").tag("Helvetica")
                        Text("Times New Roman").tag("Times New Roman")
                        Text("Courier").tag("Courier")
                    }
                }
                
                Section("Size") {
                    Slider(value: .constant(24), in: 12...72)
                }
                
                Section("Color") {
                    ColorPicker("Text Color", selection: .constant(Color.black))
                }
            }
            .navigationTitle("Edit Text")
            .appInlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        if selectedTextIndex < card.layout.textPositions.count {
                            card.updateTextPosition(at: selectedTextIndex, text: text)
                        }
                        dismiss()
                    }
                }
            }
        }
    }
}

extension Color {
    static var random: Color {
        Color(
            red: .random(in: 0...1),
            green: .random(in: 0...1),
            blue: .random(in: 0...1)
        )
    }
}
