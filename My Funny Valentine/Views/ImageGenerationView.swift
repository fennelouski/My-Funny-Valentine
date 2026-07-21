//
//  ImageGenerationView.swift
//  My Funny Valentine
//
//  Created by Nathan Fennel on 2/12/26.
//

import SwiftUI

struct ImageGenerationView: View {
    @StateObject private var viewModel: ImageGenerationViewModel
    @Environment(\.dismiss) private var dismiss
    
    var onImageGenerated: ((String) -> Void)?
    
    init(userId: String, isPremium: Bool, onImageGenerated: ((String) -> Void)? = nil) {
        _viewModel = StateObject(wrappedValue: ImageGenerationViewModel(userId: userId, isPremium: isPremium))
        self.onImageGenerated = onImageGenerated
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Premium Gate
                    if !viewModel.isPremium {
                        PremiumGateView()
                            .padding()
                    } else {
                        // Description Input Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Describe the image you want")
                                .font(.headline)
                            
                            TextField("e.g., two hearts intertwined, romantic sunset", text: $viewModel.descriptionText)
                                .textFieldStyle(.roundedBorder)
                                .onChange(of: viewModel.descriptionText) { _, newValue in
                                    if newValue.count > 100 {
                                        viewModel.descriptionText = String(newValue.prefix(100))
                                    }
                                }
                            
                            HStack {
                                Spacer()
                                Text("\(viewModel.characterCount)/100")
                                    .font(.caption)
                                    .foregroundColor(viewModel.characterCount > 100 ? .red : .secondary)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Style Selector
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Style")
                                .font(.headline)
                            
                            Picker("Style", selection: $viewModel.selectedStyle) {
                                ForEach(ImageStyle.allCases, id: \.self) { style in
                                    Text(style.displayName).tag(style)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                        .padding(.horizontal)
                        
                        // Generate Button
                        Button(action: {
                            Task {
                                await viewModel.generateImage()
                            }
                        }) {
                            HStack {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Image(systemName: "sparkles")
                                    Text("Generate Image")
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(viewModel.canGenerate ? Color.accentColor : Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .disabled(!viewModel.canGenerate)
                        .padding(.horizontal)
                        
                        // Usage Info
                        HStack {
                            Image(systemName: "info.circle")
                            Text("Remaining generations: \(viewModel.remainingGenerations)")
                            Spacer()
                            if viewModel.isCached {
                                Label("Cached", systemImage: "checkmark.circle.fill")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                        
                        // Error Message
                        if let errorMessage = viewModel.errorMessage {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.red)
                                Text(errorMessage)
                                    .font(.caption)
                                    .foregroundColor(.red)
                                Spacer()
                                Button(action: {
                                    viewModel.clearError()
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.red)
                                }
                            }
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                            .padding(.horizontal)
                        }
                        
                        // Generated Image
                        if let imageURL = viewModel.generatedImageURL, let url = URL(string: imageURL) {
                            VStack(spacing: 12) {
                                AsyncImage(url: url) { phase in
                                    switch phase {
                                    case .empty:
                                        ProgressView()
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                    case .failure:
                                        Image(systemName: "photo")
                                            .font(.system(size: 50))
                                            .foregroundColor(.secondary)
                                    @unknown default:
                                        EmptyView()
                                    }
                                }
                                .frame(maxHeight: 400)
                                .cornerRadius(10)
                                
                                Button(action: {
                                    onImageGenerated?(imageURL)
                                    dismiss()
                                }) {
                                    HStack {
                                        Image(systemName: "plus.circle.fill")
                                        Text("Add to Card")
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.accentColor)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                                }
                            }
                            .padding()
                        } else if !viewModel.isLoading {
                            VStack(spacing: 12) {
                                Image(systemName: "photo")
                                    .font(.system(size: 50))
                                    .foregroundColor(.secondary)
                                Text("Enter a description and tap Generate to create a custom image")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding()
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Generate Image")
            .appInlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct PremiumGateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "crown.fill")
                .font(.system(size: 50))
                .foregroundColor(.yellow)
            
            Text("Premium Feature")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Custom image generation is available for premium subscribers")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: {
                // TODO: Navigate to subscription screen
            }) {
                HStack {
                    Image(systemName: "star.fill")
                    Text("Upgrade to Premium")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
        }
        .padding()
        .background(Color.appFill)
        .cornerRadius(12)
    }
}

#Preview {
    ImageGenerationView(userId: "test-user", isPremium: true)
}
