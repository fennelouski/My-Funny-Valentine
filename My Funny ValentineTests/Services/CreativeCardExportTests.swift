import Foundation
import CoreGraphics
import ImageIO
import Testing
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif
@testable import My_Funny_Valentine

@MainActor
struct CreativeCardExportTests {
    @Test("Old layout JSON remains classic and all thirty starters receive six distinct new families")
    func backwardCompatibleLayoutsAndStarters() throws {
        let old = Data(##"{"backgroundColor":"#FFFFFF","textPositions":[],"imagePositions":[],"stickerPositions":[]}"##.utf8)
        let decoded = try JSONDecoder().decode(CardLayoutData.self, from: old)
        #expect(decoded.composition == nil)
        let future = Data(##"{"backgroundColor":"#123456","textPositions":[],"imagePositions":[],"stickerPositions":[],"composition":{"version":2,"family":"futureFamily","variant":0,"motionEnabled":true}}"##.utf8)
        let futureLayout = try JSONDecoder().decode(CardLayoutData.self, from: future)
        #expect(futureLayout.backgroundColor == "#123456")
        #expect(futureLayout.composition == nil)
        var families: Set<CardVisualFamily> = []
        var designs: Set<String> = []
        for template in TemplateManager.shared.getStarterTemplates() {
            let draft = TemplateManager.shared.makeDraft(from: template)
            let design = try #require(draft.getLayoutData()?.composition)
            families.insert(design.family)
            designs.insert(design.family.rawValue + String(design.variant))
            #expect(design.motionEnabled)
            let image = CardRenderer.shared.renderCard(draft, size: CGSize(width: 200, height: 300))
            #expect(image != nil)
        }
        #expect(families == Set(CardVisualFamily.allCases))
        #expect(designs.count == 30)
        var unsupported = CardLayoutData(composition: CardComposition())
        unsupported.composition?.version = 99
        let card = Card(saying: "Keep my saved words", layoutData: unsupported)
        #expect(CardRenderer.shared.snapshot(of: card).composition == nil)
        #expect(CardRenderer.shared.renderCard(card) != nil)
    }

    @Test("Frozen export pixels survive later text, artwork and layout edits")
    func snapshotDoesNotReadLiveDraft() throws {
        let template = try #require(TemplateManager.shared.getTemplate(id: "starter_space_1"))
        let card = TemplateManager.shared.makeDraft(from: template)
        card.customText = "A message just for you."
        let image = try #require(PlatformGraphics.image(size: CGSize(width: 20, height: 20), scale: 1) { context in
            context.setFillColor(PlatformColor.red.cgColor)
            context.fill(CGRect(x: 0, y: 0, width: 20, height: 20))
        })
        let bytes = try #require(PlatformImageUtils.pngData(from: image))
        let layer = CardImage(cardId: card.id, source: .photoImport, imageData: bytes)
        let snapshot = CardRenderer.shared.snapshot(of: card)
        let frozenArtwork = try #require(snapshot.templateArtwork)
        #expect(!frozenArtwork.isEmpty)
        #expect(snapshot.template?.id == "starter_space_1")
        let original = try CardExportService.png(snapshot)
        // Change only the live template first. The frozen bytes must retain the
        // original cosmic artwork, while a fresh snapshot uses the pizza art.
        card.templateId = "starter_pizza_1"
        let changedTemplate = CardRenderer.shared.snapshot(of: card)
        #expect(changedTemplate.template?.id == "starter_pizza_1")
        #expect(changedTemplate.templateArtwork != frozenArtwork)
        #expect(snapshot.templateArtwork == frozenArtwork)
        #expect(try CardExportService.png(snapshot) == original)
        #expect(try CardExportService.png(changedTemplate) != original)
        card.templateId = "starter_space_1"
        card.images = [layer]
        let importedSnapshot = CardRenderer.shared.snapshot(of: card)
        let importedOriginal = try CardExportService.png(importedSnapshot)
        card.saying = "Replaced after sharing"
        card.customText = "Different note"
        card.setLayoutData(CardLayoutData(composition: CardComposition(family: .comic)))
        layer.imageData = Data([0])
        card.images = []
        #expect(try CardExportService.png(snapshot) == original)
        #expect(try CardExportService.png(importedSnapshot) == importedOriginal)
        #expect(try CardExportService.png(CardRenderer.shared.snapshot(of: card)) != original)
    }

    @Test("Every new family keeps two people visible and freezes their original face pixels")
    func twoFaceCompositionsStayDistinctAndFrozen() throws {
        let green = try facePixels(hex: "#00FF00")
        let purple = try facePixels(hex: "#FF00FF")
        for family in CardVisualFamily.allCases {
            for variant in 0..<5 {
                try autoreleasepool {
                    let card = Card(saying: "Together", layoutData: CardLayoutData(
                        composition: CardComposition(family: family, variant: variant)))
                    let first = FaceImage(cardId: card.id, imageData: green, thumbnailData: green)
                    let second = FaceImage(cardId: card.id, imageData: purple, thumbnailData: purple)
                    card.faces = [first, second]
                    let snapshot = CardRenderer.shared.snapshot(of: card)
                    let original = try CardExportService.png(snapshot)
                    let colors = try faceColorCounts(original)
                    // The old overlap bug completely hid the first opaque face.
                    // These colors are absent from all six family palettes.
                    #expect(colors.green > 1_000, "First person must remain visible in \(family.rawValue), layout \(variant)")
                    #expect(colors.purple > 1_000, "Second person must remain visible in \(family.rawValue), layout \(variant)")
                    first.imageData = Data([0])
                    second.imageData = Data([1])
                    card.faces = []
                    #expect(try CardExportService.png(snapshot) == original)
                    let edited = try faceColorCounts(CardExportService.png(CardRenderer.shared.snapshot(of: card)))
                    #expect(edited.green == 0 && edited.purple == 0)
                }
            }
        }

        let classic = Card(saying: "Saved classic", layoutData: CardLayoutData())
        classic.faces = [
            FaceImage(cardId: classic.id, imageData: green, thumbnailData: green,
                      position: CGPoint(x: 30, y: 30), size: CGSize(width: 50, height: 60)),
            FaceImage(cardId: classic.id, imageData: purple, thumbnailData: purple,
                      position: CGPoint(x: 250, y: 30), size: CGSize(width: 50, height: 60))
        ]
        let saved = CardRenderer.shared.snapshot(of: classic)
        #expect(saved.composition == nil)
        #expect(saved.faces.map(\.rect) == [CGRect(x: 30, y: 30, width: 50, height: 60),
                                          CGRect(x: 250, y: 30, width: 50, height: 60)])
        let colors = try faceColorCounts(CardExportService.png(saved))
        #expect(colors.green > 1_000 && colors.purple > 1_000)
    }

    @Test("Dismissed or replaced exports cannot commit or finish a newer share job")
    func obsoleteExportCannotCommitOrFinishNewJob() throws {
        var session = CardExportSession()
        let beforeSnapshot = session.begin()
        #expect(beforeSnapshot == nil)
        session.replaceSnapshot()
        let firstJob = session.begin()
        let dismissed = try #require(firstJob)
        let duplicate = session.begin()
        #expect(duplicate == nil)
        session.invalidate() // Share is dismissed, even if the task completes late.
        #expect(!session.canCommit(dismissed))
        session.replaceSnapshot()
        let nextJob = session.begin()
        let current = try #require(nextJob)
        let oldFinished = session.finish(dismissed)
        #expect(!oldFinished)
        #expect(session.isExporting && session.canCommit(current))
        session.cancelJob() // Retry on the same frozen snapshot has a new owner.
        let retryJob = session.begin()
        let retry = try #require(retryJob)
        #expect(!session.canCommit(current))
        let cancelledFinished = session.finish(current)
        #expect(!cancelledFinished)
        #expect(session.isExporting && session.canCommit(retry))
        let retryFinished = session.finish(retry)
        #expect(retryFinished)
        #expect(!session.isExporting)
        #expect(!session.canCommit(retry)) // A duplicate completion cannot commit twice.
    }

    @Test("Canceled local exports throw cancellation instead of returning a completed file")
    func cancelledAsyncExportsDoNotReturnFiles() async throws {
        let card = Card(saying: "For you", customText: "Keep this note",
                        layoutData: CardLayoutData(composition: CardComposition(family: .cosmic)))
        let snapshot = CardRenderer.shared.snapshot(of: card)
        let gif = Task { @MainActor in try await GIFExporter.shared.createCardAnimationCancellable(from: snapshot) }
        gif.cancel()
        await #expect(throws: CancellationError.self) { _ = try await gif.value }
        let operations: [@MainActor () async throws -> Data] = [
            { try await CardExportService.pngCancellable(snapshot, inside: true) },
            { try await CardExportService.pdfCancellable(snapshot) },
            { try await CardExportService.stickerPNGCancellable(snapshot) },
            { try await CardExportService.interactiveHTMLCancellable(snapshot) }
        ]
        for operation in operations {
            let task = Task { @MainActor in try await operation() }
            task.cancel()
            await #expect(throws: CancellationError.self) { _ = try await task.value }
        }
    }

    @Test("Cooperative exports retain native pixels, complete PDF pages and the shared animation clock")
    func asyncExportsKeepFormatContracts() async throws {
        let card = Card(saying: "For my favorite person", customText: "A little note inside",
                        layoutData: CardLayoutData(composition: CardComposition(family: .loveLetter)))
        let snapshot = CardRenderer.shared.snapshot(of: card)
        let inside = try await CardExportService.pngCancellable(snapshot, inside: true)
        #expect(inside == (try CardExportService.png(snapshot, inside: true)))
        let sticker = try await CardExportService.stickerPNGCancellable(snapshot)
        #expect(sticker == (try CardExportService.stickerPNG(snapshot)))
        let html = try await CardExportService.interactiveHTMLCancellable(snapshot)
        #expect(html == (try CardExportService.interactiveHTML(snapshot)))
        let pdf = try await CardExportService.pdfCancellable(snapshot)
        let provider = try #require(CGDataProvider(data: pdf as CFData))
        let document = try #require(CGPDFDocument(provider))
        #expect(document.numberOfPages == 2)
        for number in 1...document.numberOfPages {
            let page = try #require(document.page(at: number))
            #expect(page.getBoxRect(.mediaBox) == CGRect(x: 0, y: 0, width: 288, height: 432))
        }
        let animation = try await GIFExporter.shared.createCardAnimationCancellable(from: snapshot)
        let data = try #require(animation)
        let frames = try #require(CGImageSourceCreateWithData(data as CFData, nil))
        #expect(CGImageSourceGetCount(frames) == 30)
        let image = try #require(CGImageSourceCreateImageAtIndex(frames, 0, nil))
        #expect(image.width == 400 && image.height == 600)
        let properties = try #require(CGImageSourceCopyPropertiesAtIndex(frames, 0, nil) as? [String: Any])
        let timing = try #require(properties[kCGImagePropertyGIFDictionary as String] as? [String: Any])
        #expect((timing[kCGImagePropertyGIFUnclampedDelayTime as String] as? Double) == 0.1)
    }

    @Test("Full card GIF opens real inside content without a face and keeps finite frame timing")
    func fullCardAnimation() throws {
        let card = Card(saying: "Stay wonderful", customText: "A little note inside",
                        layoutData: CardLayoutData(composition: CardComposition(family: .confetti)))
        let snapshot = CardRenderer.shared.snapshot(of: card)
        let data = try #require(GIFExporter.shared.createCardAnimation(from: snapshot))
        let source = try #require(CGImageSourceCreateWithData(data as CFData, nil))
        #expect(CGImageSourceGetCount(source) == 30)
        let front = try #require(CGImageSourceCreateImageAtIndex(source, 0, nil))
        let inside = try #require(CGImageSourceCreateImageAtIndex(source, 15, nil))
        #expect(front.width == 400 && front.height == 600)
        let frontBytes = try #require(front.dataProvider?.data) as Data
        let insideBytes = try #require(inside.dataProvider?.data) as Data
        #expect(frontBytes != insideBytes)
        let properties = try #require(CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any])
        let gif = try #require(properties[kCGImagePropertyGIFDictionary as String] as? [String: Any])
        #expect((gif[kCGImagePropertyGIFUnclampedDelayTime as String] as? Double) == 0.1)
        #expect(GIFExporter.shared.createAnimatedGIF(from: card,
            options: GIFExportOptions(frameRate: 0, animationType: .cardOpening)) == nil)
        #expect(CardMotion.opening(phase: 0) == 0)
        #expect(CardMotion.opening(phase: 0.5) == 1)
        #expect(CardMotion.opening(phase: 1) == 0)
        #expect(CardMotion.phase(elapsed: .infinity) == 0)
    }

    @Test("Motion-off frames stay still and manual inside selection remains usable")
    func calmMotionAndOpening() throws {
        let card = Card(saying: "My favorite person", customText: "Keep this little note",
                        layoutData: CardLayoutData(composition: CardComposition(family: .cosmic, motionEnabled: false)))
        let snapshot = CardRenderer.shared.snapshot(of: card)
        let first = try #require(CardRenderer.shared.render(snapshot, phase: 0))
        let later = try #require(CardRenderer.shared.render(snapshot, phase: 0.4))
        #expect(PlatformImageUtils.pngData(from: first) == PlatformImageUtils.pngData(from: later))
        #expect(try CardExportService.png(snapshot, inside: true) != CardExportService.png(snapshot))
        #expect(CardRenderer.shared.render(snapshot, opening: .nan) == nil)
    }

    @Test("PDF preserves 4 by 6 inch pages and continues long Unicode notes")
    func printablePDF() throws {
        let note = String(repeating: "A long, readable note with café and love.\n", count: 100)
        let card = Card(saying: "With love", customText: note,
                        layoutData: CardLayoutData(composition: CardComposition(family: .loveLetter)))
        let data = try CardExportService.pdf(CardRenderer.shared.snapshot(of: card))
        let provider = try #require(CGDataProvider(data: data as CFData))
        let document = try #require(CGPDFDocument(provider))
        #expect(document.numberOfPages > 2)
        for number in 1...document.numberOfPages {
            let page = try #require(document.page(at: number))
            #expect(page.getBoxRect(.mediaBox) == CGRect(x: 0, y: 0, width: 288, height: 432))
        }
    }

    @Test("Sticker has real transparency, bounded bytes and a square output")
    func transparentSticker() throws {
        let card = Card(saying: "You make life sweeter", layoutData: CardLayoutData(composition: CardComposition(family: .confetti)))
        let data = try CardExportService.stickerPNG(CardRenderer.shared.snapshot(of: card))
        #expect(data.count < 500_000)
        let source = try #require(CGImageSourceCreateWithData(data as CFData, nil))
        let image = try #require(CGImageSourceCreateImageAtIndex(source, 0, nil))
        #expect(image.width == image.height)
        #expect([618, 408, 300].contains(image.width))
        let cropped = try #require(image.cropping(to: CGRect(x: 0, y: 0, width: 1, height: 1)))
        var pixel = [UInt8](repeating: 0, count: 4)
        try pixel.withUnsafeMutableBytes { buffer in
            let context = try #require(CGContext(data: buffer.baseAddress, width: 1, height: 1,
                                                 bitsPerComponent: 8, bytesPerRow: 4, space: CGColorSpaceCreateDeviceRGB(),
                                                 bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
            context.draw(cropped, in: CGRect(x: 0, y: 0, width: 1, height: 1))
        }
        #expect(pixel[3] == 0)
    }

    @Test("Browser export embeds its native frames and escapes executable user text")
    func safeOfflineBrowserCard() throws {
        let payload = #"</script><img src=x onerror="alert(1)"> & ' café"#
        let card = Card(saying: payload, customText: "A\nB",
                        layoutData: CardLayoutData(composition: CardComposition(family: .popUp)))
        let data = try CardExportService.interactiveHTML(CardRenderer.shared.snapshot(of: card))
        let html = try #require(String(data: data, encoding: .utf8))
        #expect(!html.contains(payload))
        #expect(html.contains("&lt;/script&gt;"))
        #expect(html.contains("data:image/png;base64,"))
        #expect(!html.contains("https://"))
        #expect(!html.contains("<script src="))
        #expect(html.contains("prefers-reduced-motion"))
        #expect(html.contains("Read the message"))
    }

    @Test("All thirty bundled layouts retain upper and lower subject features while imported photos keep centered cropping")
    func bundledSubjectFeaturesRemainVisible() throws {
        let fixture = try #require(PlatformGraphics.image(size: CGSize(width: 1024, height: 1536), scale: 1) { context in
            context.setFillColor(PlatformColor.white.cgColor)
            context.fill(CGRect(x: 0, y: 0, width: 1024, height: 1536))
            context.setFillColor((PlatformColor.fromHex("#00FF00") ?? .green).cgColor)
            context.fill(CGRect(x: 0, y: 64, width: 1024, height: 96))
            context.setFillColor((PlatformColor.fromHex("#FF00FF") ?? .magenta).cgColor)
            context.fill(CGRect(x: 0, y: 976, width: 1024, height: 96))
        })
        let bytes = try #require(PlatformImageUtils.pngData(from: fixture))
        for template in TemplateManager.shared.getStarterTemplates() {
            let design = try #require(CardComposition.starter(templateID: template.id))
            let layout = CardLayoutData(composition: CardComposition(
                family: design.family, variant: design.variant, motionEnabled: false))
            let bundled = CardRenderSnapshot(saying: "With love", note: "", template: template,
                templateArtwork: bytes, layout: layout, images: [], faces: [], stickers: [])
            let visible = try faceColorCounts(CardExportService.png(bundled))
            #expect(visible.green > 500, "Upper subject feature must remain visible in \(template.id)")
            #expect(visible.purple > 500, "Lower subject feature must remain visible in \(template.id)")
            // A personal photo has no verified illustration bounds. It keeps
            // the old centered crop instead of inheriting bundled-art geometry.
            let imported = CardRenderSnapshot(saying: "With love", note: "", template: template,
                templateArtwork: bytes, layout: layout,
                images: [.init(data: bytes, rect: .zero, rotation: 0)], faces: [], stickers: [])
            let cropped = try faceColorCounts(CardExportService.png(imported))
            #expect(cropped.green == 0, "Imported photo crop remains unchanged in \(template.id)")
        }
    }

    @Test("Classic card opening uses its message when the note contains only whitespace")
    func classicWhitespaceNoteRetainsMessageInside() throws {
        let card = Card(saying: "My favorite person", layoutData: CardLayoutData())
        let blankNote = try CardExportService.png(CardRenderer.shared.snapshot(of: card), inside: true)
        card.customText = " \n\t "
        #expect(try CardExportService.png(CardRenderer.shared.snapshot(of: card), inside: true) == blankNote)
        card.customText = "With love, Sam"
        #expect(try CardExportService.png(CardRenderer.shared.snapshot(of: card), inside: true) != blankNote)
    }

    private func facePixels(hex: String) throws -> Data {
        let color = try #require(PlatformColor.fromHex(hex))
        let image = try #require(PlatformGraphics.image(size: CGSize(width: 20, height: 20), scale: 1) { context in
            context.setFillColor(color.cgColor)
            context.fill(CGRect(x: 0, y: 0, width: 20, height: 20))
        })
        return try #require(PlatformImageUtils.pngData(from: image))
    }

    private func faceColorCounts(_ png: Data) throws -> (green: Int, purple: Int) {
        let source = try #require(CGImageSourceCreateWithData(png as CFData, nil))
        let image = try #require(CGImageSourceCreateImageAtIndex(source, 0, nil))
        var pixels = [UInt8](repeating: 0, count: image.width * image.height * 4)
        try pixels.withUnsafeMutableBytes { buffer in
            let context = try #require(CGContext(data: buffer.baseAddress, width: image.width, height: image.height,
                bitsPerComponent: 8, bytesPerRow: image.width * 4, space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue))
            context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
        }
        var green = 0, purple = 0
        for index in stride(from: 0, to: pixels.count, by: 4) where pixels[index + 3] > 239 {
            if pixels[index] < 16 && pixels[index + 1] > 239 && pixels[index + 2] < 16 { green += 1 }
            if pixels[index] > 239 && pixels[index + 1] < 16 && pixels[index + 2] > 239 { purple += 1 }
        }
        return (green, purple)
    }
}
