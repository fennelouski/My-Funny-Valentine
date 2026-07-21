#!/usr/bin/env swift
//
//  make-marketing-images.swift
//  Composes raw App Store screenshots onto branded gradient backgrounds with
//  a headline, producing marketing images at the exact required dimensions.
//
//  Usage:  swift scripts/make-marketing-images.swift
//
//  Reads  app-store/screenshots/{iphone-6.9,ipad-13,mac}/NN-Name.png
//  Writes app-store/screenshots/marketing/{iphone-6.9,ipad-13,mac}/NN-Name.png
//
//  Outputs live under app-store/screenshots/ so they stay gitignored build
//  output, regenerable any time.
//

import AppKit
import CoreText

// MARK: - Config

struct Shot {
    let file: String
    let headline: String
    let subline: String
}

// Ordered as they should appear in App Store Connect.
let captions: [String: Shot] = [
    "03-AISayings": Shot(file: "03-AISayings", headline: "Type a word.", subline: "Get ten sayings worth sending."),
    "02-CardEditor": Shot(file: "02-CardEditor", headline: "Make it yours.", subline: "Your words, your photos, your card."),
    "01-Home": Shot(file: "01-Home", headline: "Start in seconds.", subline: "One tap from idea to card."),
    "04-MyCards": Shot(file: "04-MyCards", headline: "Little love notes.", subline: "Every card saved, synced with iCloud."),
    "05-Settings": Shot(file: "05-Settings", headline: "Private by design.", subline: "Generated on your device. Nothing collected."),
    "00-Welcome": Shot(file: "00-Welcome", headline: "Free. No account.", subline: "No ads, no tracking, no catch."),
    // macOS uses its own numbering.
    "02-MyCards": Shot(file: "02-MyCards", headline: "Little love notes.", subline: "Every card saved, synced with iCloud."),
    "03-Settings": Shot(file: "03-Settings", headline: "Private by design.", subline: "Generated on your device. Nothing collected."),
]

let devices = ["iphone-6.9", "ipad-13", "mac"]

// Brand gradient (deep valentine red -> warm pink)
let gradientTop = NSColor(calibratedRed: 0.55, green: 0.06, blue: 0.20, alpha: 1)
let gradientBottom = NSColor(calibratedRed: 0.95, green: 0.35, blue: 0.47, alpha: 1)

// MARK: - Drawing

func render(input: URL, output: URL, shot: Shot) throws {
    guard let source = NSImage(contentsOf: input) else {
        throw NSError(domain: "marketing", code: 1, userInfo: [NSLocalizedDescriptionKey: "Cannot read \(input.path)"])
    }
    var proposed = CGRect(origin: .zero, size: source.size)
    guard let sourceCG = source.cgImage(forProposedRect: &proposed, context: nil, hints: nil) else {
        throw NSError(domain: "marketing", code: 2, userInfo: [NSLocalizedDescriptionKey: "No CGImage for \(input.path)"])
    }

    let width = sourceCG.width
    let height = sourceCG.height
    let isLandscape = width > height

    guard let ctx = CGContext(
        data: nil, width: width, height: height,
        bitsPerComponent: 8, bytesPerRow: 0,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else {
        throw NSError(domain: "marketing", code: 3, userInfo: [NSLocalizedDescriptionKey: "No context"])
    }

    let w = CGFloat(width), h = CGFloat(height)

    // Background gradient (context origin is bottom-left).
    let colors = [gradientBottom.cgColor, gradientTop.cgColor] as CFArray
    let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1])!
    ctx.drawLinearGradient(gradient, start: CGPoint(x: 0, y: 0), end: CGPoint(x: 0, y: h), options: [])

    // Layout: headline block at the top, screenshot below it.
    let headlineBlock = isLandscape ? h * 0.20 : h * 0.16
    let margin = w * (isLandscape ? 0.10 : 0.075)

    // Headline
    let headlineSize = isLandscape ? h * 0.070 : w * 0.062
    let sublineSize = isLandscape ? h * 0.036 : w * 0.032

    func draw(text: String, font: NSFont, color: NSColor, centerY: CGFloat) {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        let attr = NSAttributedString(string: text, attributes: [
            .font: font, .foregroundColor: color, .paragraphStyle: paragraph,
        ])
        let framesetter = CTFramesetterCreateWithAttributedString(attr)
        let size = CTFramesetterSuggestFrameSizeWithConstraints(
            framesetter, CFRange(location: 0, length: attr.length), nil,
            CGSize(width: w - margin * 2, height: .greatestFiniteMagnitude), nil)
        let path = CGPath(rect: CGRect(x: margin, y: centerY - size.height / 2, width: w - margin * 2, height: size.height + 4), transform: nil)
        let frame = CTFramesetterCreateFrame(framesetter, CFRange(location: 0, length: attr.length), path, nil)
        CTFrameDraw(frame, ctx)
    }

    let headlineY = h - headlineBlock * 0.42
    let sublineY = h - headlineBlock * 0.74
    draw(text: shot.headline, font: NSFont.systemFont(ofSize: headlineSize, weight: .bold), color: .white, centerY: headlineY)
    draw(text: shot.subline, font: NSFont.systemFont(ofSize: sublineSize, weight: .medium), color: NSColor(calibratedWhite: 1, alpha: 0.85), centerY: sublineY)

    // Screenshot: scaled to fit under the headline, rounded corners, bottom-anchored
    // with a slight bleed off the bottom edge for the classic App Store look.
    let availableH = h - headlineBlock
    let scale = min((w - margin * 2) / w, (availableH * 1.06) / h)
    let shotW = w * scale
    let shotH = h * scale
    let shotX = (w - shotW) / 2
    let shotY = h - headlineBlock - shotH  // may be slightly negative: bleeds off bottom

    let corner = w * 0.045
    let rect = CGRect(x: shotX, y: shotY, width: shotW, height: shotH)

    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -h * 0.008), blur: w * 0.03,
                  color: NSColor.black.withAlphaComponent(0.45).cgColor)
    // Shadow needs a fill pass; draw a rounded rect base then clip-draw the image.
    let path = CGPath(roundedRect: rect, cornerWidth: corner, cornerHeight: corner, transform: nil)
    ctx.addPath(path)
    ctx.setFillColor(NSColor.black.cgColor)
    ctx.fillPath()
    ctx.restoreGState()

    ctx.saveGState()
    ctx.addPath(path)
    ctx.clip()
    ctx.draw(sourceCG, in: rect)
    ctx.restoreGState()

    guard let outCG = ctx.makeImage() else {
        throw NSError(domain: "marketing", code: 4, userInfo: [NSLocalizedDescriptionKey: "No output image"])
    }
    let rep = NSBitmapImageRep(cgImage: outCG)
    guard let png = rep.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "marketing", code: 5, userInfo: [NSLocalizedDescriptionKey: "No PNG data"])
    }
    try FileManager.default.createDirectory(at: output.deletingLastPathComponent(), withIntermediateDirectories: true)
    try png.write(to: output)
}

// MARK: - Main

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let shotsRoot = root.appendingPathComponent("app-store/screenshots")
var made = 0, skipped = 0

for device in devices {
    let inDir = shotsRoot.appendingPathComponent(device)
    let outDir = shotsRoot.appendingPathComponent("marketing").appendingPathComponent(device)
    guard let files = try? FileManager.default.contentsOfDirectory(at: inDir, includingPropertiesForKeys: nil) else {
        print("skip \(device): no input dir")
        continue
    }
    for file in files where file.pathExtension == "png" {
        let base = file.deletingPathExtension().lastPathComponent
        guard let shot = captions[base] else { skipped += 1; continue }
        do {
            try render(input: file, output: outDir.appendingPathComponent("\(base).png"), shot: shot)
            made += 1
            print("made marketing/\(device)/\(base).png")
        } catch {
            print("FAILED \(device)/\(base): \(error.localizedDescription)")
        }
    }
}
print("done: \(made) made, \(skipped) uncaptioned inputs skipped")
