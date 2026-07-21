//
//  SayingsGenerationView.swift
//  My Funny Valentine
//
//  Created by Nathan Fennel on 2/12/26.
//

import SwiftUI

struct SayingsGenerationView: View {
    @StateObject private var viewModel: AIGenerationViewModel
    @Environment(\.dismiss) private var dismiss
    
    var onSayingSelected: ((String) -> Void)?
    
    init(userId: String, onSayingSelected: ((String) -> Void)? = nil) {
        _viewModel = StateObject(wrappedValue: AIGenerationViewModel(userId: userId))
        self.onSayingSelected = onSayingSelected
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Inspiration Input Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Enter inspiration text")
                        .font(.headline)
                    
                    TextField("e.g., love, friendship, humor", text: $viewModel.inspirationText)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: viewModel.inspirationText) { _, newValue in
                            if newValue.count > 50 {
                                viewModel.inspirationText = String(newValue.prefix(50))
                            }
                        }
                    
                    HStack {
                        Spacer()
                        Text("\(viewModel.characterCount)/50")
                            .font(.caption)
                            .foregroundColor(viewModel.characterCount > 50 ? .red : .secondary)
                    }
                }
                .padding(.horizontal)
                
                // Generate Button
                Button(action: {
                    Task {
                        await viewModel.generateSayings()
                    }
                }) {
                    HStack {
                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Image(systemName: "sparkles")
                            Text("Generate Sayings")
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
                .accessibilityIdentifier("sayings.generate")
                
                // Usage Info
                HStack {
                    Image(systemName: "info.circle")
                    Text("Remaining requests: \(viewModel.remainingRequests)")
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
                
                // Generated Sayings List
                if !viewModel.generatedSayings.isEmpty {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(Array(viewModel.generatedSayings.enumerated()), id: \.offset) { index, saying in
                                SayingsRowView(
                                    saying: saying,
                                    isSelected: viewModel.selectedSaying == saying,
                                    onTap: {
                                        viewModel.selectSaying(saying)
                                    }
                                )
                            }
                        }
                        .padding()
                    }
                } else if !viewModel.isLoading {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                        Text("Enter inspiration text and tap Generate to create Valentine's sayings")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    Spacer()
                }
                
                Spacer()
            }
            .navigationTitle("Generate Sayings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        if let selectedSaying = viewModel.selectedSaying {
                            onSayingSelected?(selectedSaying)
                        }
                        dismiss()
                    }
                    .disabled(viewModel.selectedSaying == nil)
                    .accessibilityIdentifier("sayings.done")
                }
            }
        }
    }
}

struct SayingsRowView: View {
    let saying: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Text(saying)
                    .font(.body)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.accentColor)
                }
            }
            .padding()
            .background(isSelected ? Color.accentColor.opacity(0.1) : Color(.systemGray6))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    SayingsGenerationView(userId: "test-user")
}
