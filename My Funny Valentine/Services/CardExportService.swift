import Foundation
import CoreGraphics
import CoreText
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Local export only. Every format consumes the same immutable card snapshot.
enum CardExportService {
    enum ExportError: LocalizedError {
        case render, tooLarge, stickerTooLarge
        var errorDescription: String? {
            switch self {
            case .render: "The card couldn't be exported. Your draft is still here."
            case .tooLarge: "This file would be too large. Try a shorter note or a smaller photo."
            case .stickerTooLarge: "This sticker is too detailed for a small chat image. Try a shorter message or remove the photo."
            }
        }
    }

    static func png(_ card: CardRenderSnapshot, inside: Bool = false) throws -> Data {
        guard let image = CardRenderer.shared.render(card, opening: inside ? 1 : 0),
              let data = PlatformImageUtils.pngData(from: image) else { throw ExportError.render }
        return data
    }

    /// Transparent PNG for sharing as a chat image. This does not claim to
    /// register a Messages/WhatsApp sticker pack or extension.
    static func stickerPNG(_ card: CardRenderSnapshot) throws -> Data {
        for edge: CGFloat in [618, 408, 300] {
            guard let image = CardRenderer.shared.render(card, size: CGSize(width: edge, height: edge), sticker: true),
                  let data = PlatformImageUtils.pngData(from: image) else { throw ExportError.render }
            if data.count < 500_000 { return data }
        }
        throw ExportError.stickerTooLarge
    }

    /// A 4 × 6 inch front plus readable inside pages. Long saved notes continue
    /// onto additional pages rather than being clipped or reduced to tiny type.
    static func pdf(_ card: CardRenderSnapshot) throws -> Data {
        let document = try PDFWriter(card)
        defer { document.close() }
        while document.hasRemainingText { try document.appendInsidePage() }
        document.close()
        return document.data as Data
    }

    // UIKit/AppKit image and font access stays on the renderer's actor. Yield
    // between bounded pieces of work so the user can dismiss and cancel.
    static func pngCancellable(_ card: CardRenderSnapshot, inside: Bool = false) async throws -> Data {
        try await checkpoint()
        let data = try png(card, inside: inside)
        try await checkpoint()
        return data
    }

    static func stickerPNGCancellable(_ card: CardRenderSnapshot) async throws -> Data {
        for edge: CGFloat in [618, 408, 300] {
            try await checkpoint()
            guard let image = CardRenderer.shared.render(card, size: CGSize(width: edge, height: edge), sticker: true),
                  let data = PlatformImageUtils.pngData(from: image) else { throw ExportError.render }
            try await checkpoint()
            if data.count < 500_000 { return data }
        }
        throw ExportError.stickerTooLarge
    }

    static func pdfCancellable(_ card: CardRenderSnapshot) async throws -> Data {
        try await checkpoint()
        let document = try PDFWriter(card)
        defer { document.close() }
        try await checkpoint()
        while document.hasRemainingText {
            try document.appendInsidePage()
            try await checkpoint()
        }
        document.close()
        try Task.checkCancellation()
        return document.data as Data
    }

    private static func checkpoint() async throws {
        try Task.checkCancellation()
        await Task.yield()
        try Task.checkCancellation()
    }

    private final class PDFWriter {
        let data: NSMutableData
        private let context: CGContext
        private let box = CGRect(x: 0, y: 0, width: 288, height: 432)
        private let textLength: Int
        private let setter: CTFramesetter
        private var location = 0
        private var closed = false
        var hasRemainingText: Bool { location < textLength }

        init(_ card: CardRenderSnapshot) throws {
            let output = NSMutableData()
            let pageBox = CGRect(x: 0, y: 0, width: 288, height: 432)
            let content = [card.saying, card.note].filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
                .joined(separator: "\n\n")
            let paragraph = NSMutableParagraphStyle()
            paragraph.alignment = .center
            paragraph.lineBreakMode = .byWordWrapping
            let text = NSAttributedString(string: content.isEmpty ? "Made with love." : content, attributes: [
                .font: PlatformFont(name: "Georgia", size: 18) ?? PlatformFont.systemFont(ofSize: 18),
                .foregroundColor: PlatformColor.fromHex("#4E2036") ?? .black,
                .paragraphStyle: paragraph
            ])
            guard text.length <= 100_000 else { throw ExportError.tooLarge }
            textLength = text.length
            setter = CTFramesetterCreateWithAttributedString(text as CFAttributedString)
            guard let consumer = CGDataConsumer(data: output as CFMutableData) else { throw ExportError.render }
            var mediaBox = pageBox
            guard let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else { throw ExportError.render }
            data = output
            self.context = context
            context.beginPDFPage(nil)
            context.saveGState()
            context.translateBy(x: 0, y: box.height); context.scaleBy(x: 0.72, y: -0.72)
            CardRenderer.shared.draw(card, context: context)
            context.restoreGState(); context.endPDFPage()
        }

        func appendInsidePage() throws {
            try Task.checkCancellation()
            context.beginPDFPage(nil)
            context.setFillColor((PlatformColor.fromHex("#FFF7FA") ?? .white).cgColor)
            context.fill(box)
            let path = CGPath(rect: CGRect(x: 28, y: 36, width: 232, height: 360), transform: nil)
            let frame = CTFramesetterCreateFrame(setter, CFRange(location: location, length: 0), path, nil)
            let visible = CTFrameGetVisibleStringRange(frame)
            guard visible.length > 0 else { context.endPDFPage(); throw ExportError.render }
            CTFrameDraw(frame, context)
            context.endPDFPage()
            location += visible.length
        }

        func close() {
            guard !closed else { return }
            context.closePDF()
            closed = true
        }
    }

    /// No scripts from user input, remote fonts, trackers or CDN dependencies.
    /// The baked frame sequence is generated by the native renderer; CSS adds
    /// a small perspective interaction around those identical pixels.
    static func interactiveHTML(_ card: CardRenderSnapshot) throws -> Data {
        var frames: [String] = []
        for index in 0..<16 {
            try Task.checkCancellation()
            frames.append(try htmlFrame(card, index: index))
        }
        return try htmlDocument(card, frames: frames)
    }

    static func interactiveHTMLCancellable(_ card: CardRenderSnapshot) async throws -> Data {
        var frames: [String] = []
        for index in 0..<16 {
            try await checkpoint()
            frames.append(try htmlFrame(card, index: index))
        }
        try await checkpoint()
        let data = try htmlDocument(card, frames: frames)
        try Task.checkCancellation()
        return data
    }

    private static func htmlFrame(_ card: CardRenderSnapshot, index: Int) throws -> String {
        // The 16 frames are the opening half of the same 30-frame/3-second
        // clock used by the full GIF, including its eased paper fold.
        let phase = Double(index) / 30
        let opening = CardMotion.opening(phase: phase)
        return try autoreleasepool {
            guard let image = CardRenderer.shared.render(card, size: CGSize(width: 400, height: 600),
                                                         phase: phase, opening: opening),
                  let data = PlatformImageUtils.pngData(from: image) else { throw ExportError.render }
            return "data:image/png;base64," + data.base64EncodedString()
        }
    }

    private static func htmlDocument(_ card: CardRenderSnapshot, frames: [String]) throws -> Data {
        let json = try JSONSerialization.data(withJSONObject: frames, options: [.fragmentsAllowed])
        guard let frameJSON = String(data: json, encoding: .utf8) else { throw ExportError.render }
        let words = htmlEscape(card.saying)
        let alt = words.replacingOccurrences(of: "<br>", with: " ")
        let note = htmlEscape(card.note)
        let html = """
        <!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
        <meta http-equiv="Content-Security-Policy" content="default-src 'none'; img-src data:; style-src 'unsafe-inline'; script-src 'unsafe-inline'; base-uri 'none'; form-action 'none'">
        <meta name="color-scheme" content="light dark"><title>My Funny Valentine</title>
        <style>
        *{box-sizing:border-box}body{margin:0;min-height:100svh;background:#39192d;color:#fff1f7;font:18px/1.5 Georgia,serif;display:grid;justify-items:center;align-content:center;gap:20px;padding:24px}
        main{width:min(100%,440px);text-align:center}button{font:600 17px/1.4 system-ui;color:#39192d;background:#f4b5d0;border:0;border-radius:14px;min-height:48px;padding:12px 24px;cursor:pointer}button:focus-visible{outline:3px solid white;outline-offset:5px}
        #card{display:block;width:100%;aspect-ratio:2/3;object-fit:contain;touch-action:pan-y;user-select:none;filter:drop-shadow(0 16px 20px #13000b88);transform:perspective(1000px) rotateY(var(--tilt,0deg));transform-origin:center}
        p{overflow-wrap:anywhere}summary{cursor:pointer;padding:12px}::selection{background:#f4b5d0;color:#39192d}@media(prefers-reduced-motion:reduce){#card{transform:none}}
        </style></head><body><main><img id="card" alt="\(alt)" src="\(frames[0])" draggable="false"><p><button id="open" type="button">Open card</button></p>
        <details><summary>Read the message</summary><p>\(words)</p><p>\(note)</p></details></main>
        <script>
        const frames=\(frameJSON),image=document.getElementById('card'),button=document.getElementById('open');
        let value=0,startX=null,startValue=0,animation=null;const calm=matchMedia('(prefers-reduced-motion:reduce)').matches||\(card.composition?.motionEnabled == false ? "true" : "false");
        function show(v){value=Math.max(0,Math.min(1,v));image.src=frames[Math.round(value*(frames.length-1))];image.style.setProperty('--tilt',calm?'0deg':(-4*(1-value))+'deg');button.textContent=value>.5?'Close card':'Open card';button.setAttribute('aria-expanded',String(value>.5))}
        function toggle(){cancelAnimationFrame(animation);const from=value,to=value>.5?0:1;if(calm){show(to);return}const started=performance.now();function tick(now){const p=Math.min(1,(now-started)/600);show(from+(to-from)*(1-Math.pow(1-p,3)));if(p<1)animation=requestAnimationFrame(tick)}animation=requestAnimationFrame(tick)}
        button.addEventListener('click',toggle);image.addEventListener('pointerdown',e=>{cancelAnimationFrame(animation);startX=e.clientX;startValue=value;image.setPointerCapture(e.pointerId)});image.addEventListener('pointermove',e=>{if(startX!==null)show(startValue+(startX-e.clientX)/Math.max(1,image.clientWidth))});image.addEventListener('pointerup',e=>{const small=Math.abs(e.clientX-startX)<8;startX=null;if(small)toggle()});image.addEventListener('pointercancel',()=>startX=null);show(0);
        </script></body></html>
        """
        guard let data = html.data(using: .utf8), data.count <= 12 * 1024 * 1024 else { throw ExportError.tooLarge }
        return data
    }

    static func htmlEscape(_ text: String) -> String {
        text.replacingOccurrences(of: "&", with: "&amp;").replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;").replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#39;").replacingOccurrences(of: "\n", with: "<br>")
    }
}
