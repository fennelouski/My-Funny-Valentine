import SwiftUI

struct ImageGenerationView: View {
    @StateObject private var viewModel: ImageGenerationViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedImage: PlatformImage?
    @State private var playgroundImageURL: URL?
    @State private var confirmingOnlineGeneration = false
    @State private var importError: String?

    var onImageGenerated: ((Data) -> Void)?

    init(userId: String, onImageGenerated: ((Data) -> Void)? = nil) {
        _viewModel = StateObject(wrappedValue: ImageGenerationViewModel(userId: userId))
        self.onImageGenerated = onImageGenerated
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    PhotoPickerView(selectedImage: $selectedImage) { image in
                        importImage(image)
                    }
                    .frame(minHeight: 44)

                    ImagePlaygroundButton(generatedImageURL: $playgroundImageURL) { image in
                        importImage(image)
                    }
                }

                if viewModel.isBackendConfigured {
                    Section("Online artwork") {
                        TextField("Two hearts, a dancing cat…", text: $viewModel.descriptionText, axis: .vertical)
                            .lineLimit(2...4)
                        Picker("Style", selection: $viewModel.selectedStyle) {
                            ForEach(ImageStyle.allCases, id: \.self) { style in
                                Text(style.displayName).tag(style)
                            }
                        }

                        Button {
                            confirmingOnlineGeneration = true
                        } label: {
                            Label("Create artwork", systemImage: "sparkles")
                                .frame(minHeight: 44)
                        }
                        .disabled(!viewModel.canGenerate)

                        if viewModel.isLoading {
                            ProgressView("Making artwork…")
                        }

                        if let imageURL = viewModel.generatedImageURL,
                           let url = URL(string: imageURL) {
                            AsyncImage(url: url) { image in
                                image.resizable().scaledToFit()
                            } placeholder: {
                                ProgressView()
                            }
                            .frame(maxHeight: 320)

                            Button {
                                Task { await importOnlineImage(from: url) }
                            } label: {
                                Label("Use artwork", systemImage: "checkmark")
                                    .frame(minHeight: 44)
                            }
                        }
                    }
                }

                if let error = importError ?? viewModel.errorMessage {
                    Section {
                        Label(error, systemImage: "exclamationmark.triangle")
                            .foregroundStyle(.red)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .tint(.pink)
            .navigationTitle("Add artwork")
            .appInlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .frame(minHeight: 44)
                }
            }
            .task { await viewModel.loadAvailability() }
            .confirmationDialog("Send this description to OpenAI?", isPresented: $confirmingOnlineGeneration, titleVisibility: .visible) {
                Button("Send and create") {
                    Task { await viewModel.generateImage() }
                }
            } message: {
                Text("Your description goes through our artwork service to OpenAI. Your photos stay out of this request.")
            }
        }
    }

    private func importImage(_ image: PlatformImage) {
        guard let data = PlatformImageUtils.pngData(from: image) else {
            importError = "Couldn't open that image. Choose another photo."
            return
        }
        onImageGenerated?(data)
        dismiss()
    }

    private func importOnlineImage(from url: URL) async {
        guard url.scheme == "https" else {
            importError = "Artwork couldn't be loaded. Try again."
            return
        }
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let response = response as? HTTPURLResponse,
                  response.statusCode == 200,
                  let image = PlatformImage(data: data) else {
                importError = "Artwork couldn't be loaded. Try again."
                return
            }
            importImage(image)
        } catch {
            importError = "Artwork couldn't be loaded. Check your connection and try again."
        }
    }
}

#Preview {
    ImageGenerationView(userId: "preview")
}
