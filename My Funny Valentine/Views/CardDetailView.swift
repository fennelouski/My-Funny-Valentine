import SwiftUI
import SwiftData
import PhotosUI
import UniformTypeIdentifiers

struct CardDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

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
    @State private var showingShareError = false
    @State private var shareURL: URL?
    @State private var insideURL: URL?
    @State private var animatedURL: URL?
    @State private var showingShare = false
    @State private var exportSession = CardExportSession()
    @State private var opening = 0.0
    @State private var pdfURL: URL?
    @State private var stickerURL: URL?
    @State private var htmlURL: URL?
    @State private var printData: Data?
    @State private var showingPrint = false
    @State private var exportSnapshot: CardRenderSnapshot?
    @State private var exportTask: Task<Void, Never>?
    private var exporting: Bool { exportSession.isExporting }

    init(card: Card?, starter: Card? = nil) {
        self.card = card
        let initial = CardDraft.copy(of: card ?? starter ?? Card())
        if card == nil {
            initial.id = UUID()
            if starter == nil {
                var layout = initial.getLayoutData() ?? CardLayoutData()
                layout.composition = CardComposition()
                initial.setLayoutData(layout)
            }
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
        .accessibilityIdentifier("cardDetail.scroll")
        .scrollDismissesKeyboard(.interactively)
        .background(Color.appGroupedBackground)
        .navigationTitle("Your card")
        .appInlineNavigationTitle()
        #if os(iOS)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .tabBar)
        #endif
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
            if !MFVRuntime.isPrivate {
                SayingsGenerationView(userId: UserPreferencesService.deviceUserId()) { message.wrappedValue = $0 }
            }
        }
        .sheet(isPresented: $showingFaces) {
            FaceSelectionView(faces: detectedFaces) { addFace($0) }
        }
        .sheet(isPresented: $showingShare, onDismiss: shareDismissed) { sharePreview }
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
        .onDisappear { importTask?.cancel(); shareDismissed() }
    }

    private var preview: some View {
        CardStageView(snapshot: CardRenderer.shared.snapshot(of: draft), opening: $opening,
                      motionEnabled: draft.getLayoutData()?.composition?.motionEnabled ?? false)
    }

    private var composition: CardComposition? { draft.getLayoutData()?.composition }
    private var artworkSource: Image? {
        guard let data = draft.images?.first?.imageData, let image = PlatformImageUtils.image(from: data) else { return nil }
        return PlatformImageUtils.swiftUIImage(from: image)
    }

    private var stylePicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Set the scene").font(.title2.bold())
            LazyVGrid(columns: dynamicTypeSize.isAccessibilitySize
                      ? [GridItem(.flexible())]
                      : [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(CardVisualFamily.allCases) { family in
                    Button {
                        var layout = draft.getLayoutData() ?? CardLayoutData()
                        layout.composition = CardComposition(family: family, variant: composition?.variant ?? 0,
                                                             motionEnabled: composition?.motionEnabled ?? true)
                        draft.setLayoutData(layout)
                        opening = 0
                        changed()
                    } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: family.symbol).font(.title2.bold())
                                Spacer(minLength: 4)
                                if composition?.family == family { Image(systemName: "checkmark.circle.fill") }
                            }
                            Text(family.title).font(.subheadline.bold()).fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(12).frame(maxWidth: .infinity, minHeight: 88, alignment: .leading)
                        .foregroundStyle(Color(PlatformColor.fromHex(family.inkHex) ?? .black))
                        .background(Color(PlatformColor.fromHex(family.backgroundHex) ?? .white), in: RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("cardDetail.style." + family.rawValue)
                    .accessibilityAddTraits(composition?.family == family ? .isSelected : [])
                }
            }
            if let composition {
                Picker("Composition", selection: Binding(get: { composition.variant }, set: { value in
                    var layout = draft.getLayoutData() ?? CardLayoutData()
                    layout.composition?.variant = value
                    draft.setLayoutData(layout); opening = 0; changed()
                })) {
                    ForEach(0..<5, id: \.self) { index in Text("Layout \(index + 1)").tag(index) }
                }
                .accessibilityIdentifier("cardDetail.variant")
                Toggle(isOn: Binding(get: { draft.getLayoutData()?.composition?.motionEnabled ?? true }, set: { value in
                    var layout = draft.getLayoutData() ?? CardLayoutData()
                    layout.composition?.motionEnabled = value
                    draft.setLayoutData(layout); changed()
                })) { Label("Bring it to life", systemImage: "play.circle.fill") }
                    .accessibilityIdentifier("cardDetail.motion")
            }
        }
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
            .disabled(MFVRuntime.isPrivate)

            Divider()
            Text("Make it personal").font(.title2.bold())
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 12) { photoButton; faceButton }
                VStack(alignment: .leading, spacing: 8) { photoButton; faceButton }
            }
            .disabled(MFVRuntime.isPrivate)
            ImagePlaygroundButton(generatedImageURL: $playgroundURL, concept: draft.saying ?? "", sourceImage: artworkSource) { image in
                guard let data = PlatformImageUtils.pngData(from: image) else {
                    fail("That artwork couldn't be read. Please try again.")
                    return
                }
                addArtwork(data, source: .imagePlayground)
            }
            .buttonStyle(.bordered)

            if importing { ProgressView("Adding photo…").accessibilityIdentifier("cardDetail.importing") }
            if !(draft.faces ?? []).isEmpty {
                HStack {
                    Label("Face added", systemImage: "person.crop.circle.badge.checkmark")
                    Spacer()
                    Button("Remove", role: .destructive) { draft.faces = []; changed() }
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
            Divider().padding(.vertical, 4)
            stylePicker
        }
        .padding(.vertical, 8)
        .buttonStyle(.bordered)
        .tint(colorScheme == .dark
            ? Color(red: 0.98, green: 0.55, blue: 0.68)
            : Color(red: 0.69, green: 0.10, blue: 0.28))
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
                    if let exportSnapshot {
                        CardStageView(snapshot: exportSnapshot, opening: $opening,
                                      motionEnabled: exportSnapshot.composition?.motionEnabled ?? false)
                    }
                    if let shareURL {
                        ShareLink(item: shareURL, preview: SharePreview("My Funny Valentine")) {
                            Label("Share card front", systemImage: "square.and.arrow.up")
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
                    } else {
                        Button { makeExport(.animation) } label: {
                            Label("Animate the card", systemImage: "play.rectangle.fill").frame(minHeight: 44)
                        }
                        .buttonStyle(.bordered).disabled(exporting)
                        .accessibilityIdentifier("cardDetail.animateCard")
                    }
                    if let exportSnapshot, !exportSnapshot.note.isEmpty {
                        exportRow(title: "Inside message PNG", symbol: "envelope.open", url: insideURL, kind: .inside)
                    }
                    exportRow(title: "Printable PDF", symbol: "doc.richtext", url: pdfURL, kind: .pdf)
                    exportRow(title: "Chat sticker PNG", symbol: "face.smiling", url: stickerURL, kind: .sticker)
                    exportRow(title: "Interactive browser card", symbol: "globe", url: htmlURL, kind: .html)
                    if let printData {
                        Button { self.printData = printData; showingPrint = true } label: {
                            Label("Print card", systemImage: "printer.fill").frame(minHeight: 44)
                        }
                        .buttonStyle(.bordered).accessibilityIdentifier("cardDetail.print")
                        .disabled(MFVRuntime.isPrivate)
                    }
                    Text("Mail and chat apps appear in your device's share menu.")
                        .font(.footnote).foregroundStyle(.secondary).multilineTextAlignment(.center)
                    if exporting { ProgressView("Making your file…").accessibilityIdentifier("cardDetail.exporting") }
                }
                .padding(20)
            }
            .accessibilityIdentifier("cardShare.scroll")
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Ready to send")
            .appInlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { shareDismissed(); showingShare = false }
                }
            }
            .sheet(isPresented: $showingPrint) {
                if let printData {
                    CardPrintView(data: printData) { showingPrint = false }
                        .frame(minWidth: 280, minHeight: 240)
                }
            }
            .alert("Couldn't export", isPresented: $showingShareError) {
                Button("OK", role: .cancel) { }
            } message: { Text(errorMessage ?? "Your draft is still here. Try again.") }
        }
    }

    private func changed() {
        draft.updateModifiedDate()
        resetExportContent()
    }

    private func resetExportContent() {
        cancelExport()
        exportSession.invalidate()
        shareURL = nil
        insideURL = nil
        animatedURL = nil
        pdfURL = nil; stickerURL = nil; htmlURL = nil; printData = nil
        exportSnapshot = nil
    }

    private func cancelExport() {
        exportTask?.cancel()
        exportTask = nil
        exportSession.cancelJob()
    }

    private func shareDismissed() {
        cancelExport()
        exportSession.invalidate()
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
        resetExportContent()
        opening = 0
        let snapshot = CardRenderer.shared.snapshot(of: draft)
        do {
            shareURL = try export(CardExportService.png(snapshot), extension: "png")
            exportSnapshot = snapshot
            exportSession.replaceSnapshot()
            showingShare = true
        } catch { fail(error.localizedDescription) }
    }

    private enum ExportKind: String {
        case animation, inside, pdf, sticker, html
        var fileExtension: String {
            switch self {
            case .animation: "gif"
            case .inside, .sticker: "png"
            case .pdf: "pdf"
            case .html: "html"
            }
        }
    }

    @ViewBuilder private func exportRow(title: String, symbol: String, url: URL?, kind: ExportKind) -> some View {
        if let url {
            ShareLink(item: url) { Label("Share " + title, systemImage: "square.and.arrow.up").frame(minHeight: 44) }
                .buttonStyle(.bordered).accessibilityIdentifier("cardDetail.share." + kind.rawValue)
        } else {
            Button { makeExport(kind) } label: { Label(title, systemImage: symbol).frame(minHeight: 44) }
                .buttonStyle(.bordered).disabled(exporting).accessibilityIdentifier("cardDetail.export." + kind.rawValue)
        }
    }

    private func makeExport(_ kind: ExportKind) {
        guard showingShare, let snapshot = exportSnapshot, let job = exportSession.begin() else { return }
        exportTask = Task { @MainActor in
            defer { if exportSession.finish(job) { exportTask = nil } }
            do {
                let data: Data
                switch kind {
                case .animation:
                    guard let animation = try await GIFExporter.shared.createCardAnimationCancellable(from: snapshot) else {
                        throw CardExportService.ExportError.render
                    }
                    data = animation
                case .inside: data = try await CardExportService.pngCancellable(snapshot, inside: true)
                case .pdf: data = try await CardExportService.pdfCancellable(snapshot)
                case .sticker: data = try await CardExportService.stickerPNGCancellable(snapshot)
                case .html: data = try await CardExportService.interactiveHTMLCancellable(snapshot)
                }
                try Task.checkCancellation()
                guard showingShare, exportSnapshot != nil, exportSession.canCommit(job) else { return }
                // No suspension between the ownership check, file write and URL
                // commit: an edit/dismiss cannot publish an obsolete snapshot.
                let url = try export(data, extension: kind.fileExtension)
                switch kind {
                case .animation: animatedURL = url
                case .inside: insideURL = url
                case .pdf: pdfURL = url; printData = data
                case .sticker: stickerURL = url
                case .html: htmlURL = url
                }
            } catch is CancellationError {
                // Dismissal/editing is an expected cancellation, not an alert.
            } catch {
                if !Task.isCancelled, showingShare, exportSession.canCommit(job) { fail(error.localizedDescription) }
            }
        }
    }

    private func export(_ data: Data, extension fileExtension: String) throws -> URL {
        let url = try MFVRuntime.mediaDirectory()
            .appendingPathComponent("Valentine-\(UUID().uuidString).\(fileExtension)")
        try data.write(to: url, options: .atomic)
        return url
    }

    private func fail(_ message: String) {
        errorMessage = message
        if showingShare { showingShareError = true }
        else { showingError = true }
    }
}

/// A snapshot and its current export own the result together. Cancellation,
/// reopening Share or editing a draft invalidates old completion callbacks.
nonisolated struct CardExportSession {
    struct Job: Equatable {
        let snapshotID: UUID
        let id: UUID
    }
    private var snapshotID: UUID?
    private var activeJob: Job?
    var isExporting: Bool { activeJob != nil }

    mutating func replaceSnapshot() {
        snapshotID = UUID()
        activeJob = nil
    }
    mutating func begin() -> Job? {
        guard let snapshotID, activeJob == nil else { return nil }
        let job = Job(snapshotID: snapshotID, id: UUID())
        activeJob = job
        return job
    }
    func canCommit(_ job: Job) -> Bool { snapshotID == job.snapshotID && activeJob == job }
    @discardableResult mutating func finish(_ job: Job) -> Bool {
        guard canCommit(job) else { return false }
        activeJob = nil
        return true
    }
    mutating func cancelJob() { activeJob = nil }
    mutating func invalidate() { snapshotID = nil; activeJob = nil }
}
