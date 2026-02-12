//
//  GIFExportView.swift
//  My Funny Valentine
//
//  Created by Nathan Fennel on 2/12/26.
//

import SwiftUI

#if os(macOS)
import AppKit

struct GIFExportView: View {
    let cardImage: NSImage
    let onCancel: () -> Void
    
    @State private var selectedAnimation: AnimationType = .fadeInOut
    @State private var frameRate: Double = 12.0
    @State private var duration: Double = 4.0
    @State private var isExporting = false
    @State private var exportError: Error? = nil
    @State private var showingError = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Export as GIF")
                .font(.title)
                .padding()
            
            // Preview
            Image(nsImage: cardImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxHeight: 300)
                .cornerRadius(8)
                .padding()
            
            // Animation Type Selection
            VStack(alignment: .leading, spacing: 12) {
                Text("Animation Style")
                    .font(.headline)
                
                Picker("Animation", selection: $selectedAnimation) {
                    Text("Fade In/Out").tag(AnimationType.fadeInOut)
                    Text("Slide").tag(AnimationType.slide)
                    Text("Zoom").tag(AnimationType.zoom)
                    Text("Heart Animation").tag(AnimationType.heartAnimation)
                    Text("Text Reveal").tag(AnimationType.textReveal)
                }
                .pickerStyle(.segmented)
            }
            .padding(.horizontal)
            
            // Frame Rate
            VStack(alignment: .leading, spacing: 8) {
                Text("Frame Rate: \(Int(frameRate)) fps")
                    .font(.headline)
                Slider(value: $frameRate, in: 8...15, step: 1)
            }
            .padding(.horizontal)
            
            // Duration
            VStack(alignment: .leading, spacing: 8) {
                Text("Duration: \(String(format: "%.1f", duration)) seconds")
                    .font(.headline)
                Slider(value: $duration, in: 2...6, step: 0.5)
            }
            .padding(.horizontal)
            
            // Export Button
            HStack {
                Button("Cancel") {
                    onCancel()
                }
                .keyboardShortcut(.cancelAction)
                
                Spacer()
                
                Button("Export GIF") {
                    exportGIF()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(isExporting)
            }
            .padding()
        }
        .frame(width: 500, height: 600)
        .alert("Export Error", isPresented: $showingError, presenting: exportError) { error in
            Button("OK", role: .cancel) { }
        } message: { error in
            Text(error.localizedDescription)
        }
    }
    
    private func exportGIF() {
        isExporting = true
        
        Task {
            do {
                let options = GIFExportOptions(
                    frameRate: frameRate,
                    duration: duration,
                    maxColors: 256,
                    maxSizeMB: 10.0,
                    animationType: selectedAnimation
                )
                
                guard let gifData = GIFExporter.shared.createAnimatedGIF(from: cardImage, options: options) else {
                    throw NSError(domain: "GIFExport", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create GIF"])
                }
                
                await MainActor.run {
                    GIFExporter.shared.saveGIF(gifData, suggestedFilename: "valentine_card.gif")
                    isExporting = false
                    onCancel()
                }
            } catch {
                await MainActor.run {
                    isExporting = false
                    exportError = error
                    showingError = true
                }
            }
        }
    }
}

#endif
