import SwiftUI
import SwiftData
import PhotosUI
import UniformTypeIdentifiers

struct CardDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let card: Card?
    @State private var draft: Card
    @State private var showingSayings = false
    @State private var artworkItem: PhotosPickerItem?
    @State private var faceItem: PhotosPickerItem?
    @State private var showingFileImporter = false
    @State private var importingFileAsFace = false
    @State private var playgroundURL: URL?
    @State private var detectedFaces: [DetectedFace] = []
    @State private var showingFaces = false
    @State private var importing = false
    @State private var importID = UUID()
    @State private var importTask: Task<Void, Never>?
    @State private var errorMessage: String?
    @State private var showingError = false
    @State private var shareURL: URL?
    @State private var animatedURL: URL?
    @State private var showingShare = false
    @State private var exporting = false
    @State private var playing = false

    init(card: Card?, starter: Card? = nil) {
        self.card = card
        let initial = CardDraft.copy(of: card ?? starter ?? Card())
        if card == nil {
            initial.id = UUID()
            for face in initial.faces ?? [] { face.id = UUID(); face.cardId = initial.id }
            for image in initial.images ?? [] { image.id = UUID(); image.cardId = initial.id }
            for sticker in initial.stickers ?? [] { sticker.id = UUID(); sticker.cardId = initial.id }
        }
        _draft = State(initialValue: initial)
    }

    private var message: Binding<String> {
        Binding {
            draft.saying ?? ""
        } set: {
            draft.saying = $0
            if !(draft.getLayoutData()?.textPositions ?? []).isEmpty {
                draft.updateTextPosition(at: 0, text: $0)
            }
            changed()
        }
    }
    private var note: Binding<String> {
        Binding {
            draft.customText ?? ""
        } set: {
            draft.customText = $0
            changed()
        }
    }
    private var hasContent: Bool {
        !(draft.saying ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        || !(draft.customText ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        || draft.templateId != nil || !(draft.images ?? []).isEmpty || !(draft.faces ?? []).isEmpty
        || !(draft.stickers ?? []).isEmpty
        || !(draft.getLayoutData()?.textPositions ?? []).isEmpty
    }

    var body: some View {
        ScrollView {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top, spacing: 32) {
                    preview
                    editor.frame(width: 340)
                }
                VStack(spacing: 24) {
                    preview
                    editor.frame(maxWidth: 480)
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity)
        }
        .background(Color.appGroupedBackground)
        .navigationTitle(card == nil ? "Make it yours" : "Edit card")
        .appInlineNavigationTitle()
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
                    .accessibilityIdentifier("cardDetail.cancel")
            }
            ToolbarItem(placement: .primaryAction) {
                Button { prepareShare() } label: { Label("Share", systemImage: "square.and.arrow.up") }
                    .labelStyle(.iconOnly)
                    .disabled(!hasContent || importing)
                    .accessibilityIdentifier("cardDetail.share")
                    .keyboardShortcut("e", modifiers: [.command, .shift])
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { save() }
                    .fontWeight(.semibold)
                    .disabled(!hasContent || importing)
                    .accessibilityIdentifier("cardDetail.save")
                    .keyboardShortcut("s", modifiers: .command)
            }
        }
        .sheet(isPresented: $showingSayings) {
            SayingsGenerationView(userId: UserPreferencesService.deviceUserId()) { message.wrappedValue = $0 }
        }
        .sheet(isPresented: $showingFaces) {
            FaceSelectionView(faces: detectedFaces) { addFace($0) }
        }
        .sheet(isPresented: $showingShare) { sharePreview }
        .alert("Couldn't finish", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: { Text(errorMessage ?? "Please try again.") }
        .fileImporter(isPresented: $showingFileImporter, allowedContentTypes: [.image]) { result in
            switch result {
            case .success(let url):
                let face = importingFileAsFace
                importPhoto(face: face) {
                    let scoped = url.startAccessingSecurityScopedResource()
                    defer { if scoped { url.stopAccessingSecurityScopedResource() } }
                    if let size = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize, size > 40 * 1024 * 1024 {
                        throw CocoaError(.fileReadTooLarge)
                    }
                    return try Data(contentsOf: url)
                }
            case .failure(let error):
                fail(error.localizedDescription)
            }
        }
        .onChange(of: artworkItem) { _, item in importPhoto(item, face: false) }
        .onChange(of: faceItem) { _, item in importPhoto(item, face: true) }
        .onDisappear { importTask?.cancel() }
    }

    private var preview: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 12, paused: !playing || reduceMotion)) { timeline in
            CardTileView(
                card: draft, size: CGSize(width: 280, height: 420),
                faceAnimationPhase: playing && !reduceMotion
                    ? timeline.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 2) / 2 : nil
            )
        }
        .shadow(color: .black.opacity(0.12), radius: 12, y: 6)
        .accessibilityIdentifier("cardDetail.preview")
    }

    private var editor: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Your words").font(.title2.bold())
            if let positions = draft.getLayoutData()?.textPositions, !positions.isEmpty {
                ForEach(positions.indices, id: \.self) { index in
                    TextField("Text \(index + 1)", text: Binding(
                        get: { draft.getLayoutData()?.textPositions[index].text ?? "" },
                        set: { draft.updateTextPosition(at: index, text: $0); changed() }
                    ), axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(3...8)
                }
            } else {
                AppTextField(title: "Message", text: message, placeholder: "You're my favorite person.", characterLimit: card == nil ? 160 : nil, axis: .vertical)
                    .accessibilityIdentifier("cardDetail.message")
                AppTextField(title: "Personal note", text: note, placeholder: "Love, me", characterLimit: card == nil ? 240 : nil, axis: .vertical)
                    .accessibilityIdentifier("cardDetail.note")
            }
            Button { showingSayings = true } label: {
                Label("Find the words", systemImage: "text.bubble")
                    .frame(minHeight: 44)
            }
            .accessibilityIdentifier("cardDetail.generateWithAI")

            Divider()
            Text("Make it personal").font(.title2.bold())
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 12) { photoButton; faceButton }
                VStack(alignment: .leading, spacing: 8) { photoButton; faceButton }
            }
            ImagePlaygroundButton(generatedImageURL: $playgroundURL, concept: draft.saying ?? "") { image in
                guard let data = PlatformImageUtils.pngData(from: image) else {
                    fail("That artwork couldn't be read. Please try again.")
                    return
                }
                addArtwork(data, source: .imagePlayground)
            }
            .buttonStyle(.bordered)

            if importing { ProgressView("Adding photo…").accessibilityIdentifier("cardDetail.importing") }
            if !(draft.faces ?? []).isEmpty {
                if !reduceMotion {
                    Button { playing.toggle() } label: {
                        Label(playing ? "Pause face" : "Play face", systemImage: playing ? "pause.fill" : "play.fill")
                            .frame(minHeight: 44)
                    }
                    .accessibilityIdentifier("cardDetail.playFace")
                }
                HStack {
                    Label("Face added", systemImage: "person.crop.circle.badge.checkmark")
                    Spacer()
                    Button("Remove", role: .destructive) { draft.faces = []; playing = false; changed() }
                }
                .font(.subheadline)
            }
            if !(draft.images ?? []).isEmpty {
                HStack {
                    Label("Photo added", systemImage: "photo")
                    Spacer()
                    Button("Remove", role: .destructive) { draft.images = []; changed() }
                }
                .font(.subheadline)
            }
        }
        .padding(20)
        .background(Color.appSecondaryGroupedBackground, in: RoundedRectangle(cornerRadius: 20))
        .buttonStyle(.bordered)
        .tint(Color(red: 0.69, green: 0.10, blue: 0.28))
    }

    @ViewBuilder private var photoButton: some View {
        #if os(macOS)
        Menu {
            PhotosPicker("From Photos", selection: $artworkItem, matching: .images)
            Button("Choose file…") { importingFileAsFace = false; showingFileImporter = true }
        } label: { Label("Photo", systemImage: "photo.badge.plus").frame(minHeight: 44) }
        .accessibilityIdentifier("cardDetail.photo")
        #else
        PhotosPicker(selection: $artworkItem, matching: .images) {
            Label("Photo", systemImage: "photo.badge.plus").frame(minHeight: 44)
        }
        .accessibilityIdentifier("cardDetail.photo")
        #endif
    }
    @ViewBuilder private var faceButton: some View {
        #if os(macOS)
        Menu {
            PhotosPicker("From Photos", selection: $faceItem, matching: .images)
            Button("Choose file…") { importingFileAsFace = true; showingFileImporter = true }
        } label: { Label("Face", systemImage: "person.crop.square").frame(minHeight: 44) }
        .accessibilityIdentifier("cardDetail.face")
        #else
        PhotosPicker(selection: $faceItem, matching: .images) {
            Label("Face", systemImage: "person.crop.square").frame(minHeight: 44)
        }
        .accessibilityIdentifier("cardDetail.face")
        #endif
    }

    private var sharePreview: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    preview
                    if let shareURL {
                        ShareLink(item: shareURL, preview: SharePreview("My Funny Valentine")) {
                            Label("Share card", systemImage: "square.and.arrow.up")
                                .frame(minHeight: 44)
                        }
                        .buttonStyle(.borderedProminent)
                        .accessibilityIdentifier("cardDetail.sharePNG")
                    }
                    if let animatedURL {
                        ShareLink(item: animatedURL) {
                            Label("Share animation", systemImage: "play.rectangle")
                                .frame(minHeight: 44)
                        }
                        .buttonStyle(.bordered)
                        .accessibilityIdentifier("cardDetail.shareGIF")
                    } else if !(draft.faces ?? []).isEmpty {
                        Button {
                            exporting = true
                            Task {
                                await Task.yield()
                                defer { exporting = false }
                                guard let data = GIFExporter.shared.createAnimatedGIF(from: draft) else {
                                    fail("The animation couldn't be exported. Your card is still ready to share.")
                                    return
                                }
                                do { animatedURL = try export(data, extension: "gif") }
                                catch { fail(error.localizedDescription) }
                            }
                        } label: {
                            Label("Animate face", systemImage: "person.crop.rectangle.badge.sparkles")
                                .frame(minHeight: 44)
                        }
                        .buttonStyle(.bordered)
                        .disabled(exporting)
                        .accessibilityIdentifier("cardDetail.animateFace")
                    }
                    if exporting { ProgressView("Making animation…") }
                }
                .padding(20)
            }
            .navigationTitle("Ready to send")
            .appInlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { showingShare = false }
                }
            }
        }
    }

    private func changed() {
        draft.updateModifiedDate()
        shareURL = nil
        animatedURL = nil
    }

    private func addArtwork(_ data: Data, source: ImageSource) {
        draft.images = [CardImage(cardId: draft.id, source: source, imageData: data,
                                  position: CGPoint(x: 16, y: 16), size: CGSize(width: 368, height: 388))]
        if draft.templateId == nil {
            var layout = draft.getLayoutData() ?? CardLayoutData()
            layout.textPositionX = 32
            layout.textPositionY = 430
            draft.setLayoutData(layout)
        }
        changed()
    }

    private func addFace(_ face: DetectedFace) {
        let slot = TemplateManager.shared.getTemplate(id: draft.templateId ?? "")?.facePositions.first
        draft.faces = [FaceImage(cardId: draft.id, imageData: face.imageData, thumbnailData: face.imageData,
                                 position: slot?.position ?? CGPoint(x: 154, y: 164),
                                 size: slot?.size ?? CGSize(width: 92, height: 110))]
        changed()
    }

    private func importPhoto(_ item: PhotosPickerItem?, face: Bool) {
        guard let item else { return }
        importPhoto(face: face) { try await item.loadTransferable(type: Data.self) }
    }

    private func importPhoto(face: Bool, load: @escaping () async throws -> Data?) {
        importTask?.cancel()
        importing = true
        let token = UUID()
        importID = token
        importTask = Task {
            defer { if importID == token { importing = false } }
            do {
                guard let data = try await load(),
                      data.count <= 40 * 1024 * 1024,
                      let image = PlatformImage(data: data) else {
                    if !Task.isCancelled { fail("Choose another photo under 40 MB.") }
                    return
                }
                if face {
                    let faces = try await FaceDetectionService.shared.detectFaces(in: image)
                    guard !Task.isCancelled else { return }
                    if faces.isEmpty { fail("No face found. Try a clearer photo, or add it with Photo.") }
                    else if faces.count == 1 { addFace(faces[0]) }
                    else { detectedFaces = faces; showingFaces = true }
                } else {
                    guard !Task.isCancelled else { return }
                    let resized = PlatformImageUtils.resized(image, maxDimension: 2048)
                    guard let pixels = PlatformImageUtils.pngData(from: resized) else {
                        fail("That photo couldn't be read. Please try another.")
                        return
                    }
                    addArtwork(pixels, source: .photoImport)
                }
            } catch {
                if !Task.isCancelled { fail(error.localizedDescription) }
            }
        }
    }

    private func save() {
        draft.updateModifiedDate()
        do {
            _ = try CardDraft.save(draft, replacing: card, in: modelContext)
            dismiss()
        } catch { fail("Your changes are still here. \(error.localizedDescription)") }
    }

    private func prepareShare() {
        playing = false
        guard let image = CardRenderer.shared.renderCard(draft),
              let data = PlatformImageUtils.pngData(from: image) else {
            fail("The card couldn't be exported. Your changes are still here.")
            return
        }
        do {
            shareURL = try export(data, extension: "png")
            showingShare = true
        } catch { fail(error.localizedDescription) }
    }

    private func export(_ data: Data, extension fileExtension: String) throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("Valentine-\(UUID().uuidString).\(fileExtension)")
        try data.write(to: url, options: .atomic)
        return url
    }

    private func fail(_ message: String) {
        errorMessage = message
        showingError = true
    }
}
