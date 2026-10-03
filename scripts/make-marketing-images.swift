#!/usr/bin/env swift
// Explicit native-capture manifest → 30 composed App Store JPEGs.
// Usage: swift scripts/make-marketing-images.swift [--validate] MANIFEST.json
//        swift scripts/make-marketing-images.swift --self-test
// Relative paths resolve beside the manifest. No screenshot discovery or UI redrawing.

import AppKit
import CoreText
import CryptoKit
import ImageIO

struct MarketingError: LocalizedError {
    let message: String
    var errorDescription: String? { message }
}
func require(_ condition: @autoclosure () -> Bool, _ message: String) throws {
    if !condition() { throw MarketingError(message: message) }
}

// Preserve arbitrary native-capture fields, including arrays and numeric values.
enum JSONValue: Codable, Equatable {
    case string(String), bool(Bool), integer(Int64), unsigned(UInt64), number(Double)
    case array([JSONValue]), object([String: JSONValue]), null
    init(from decoder: Decoder) throws {
        let value = try decoder.singleValueContainer()
        if value.decodeNil() { self = .null }
        else if let v = try? value.decode(Bool.self) { self = .bool(v) }
        else if let v = try? value.decode(String.self) { self = .string(v) }
        else if let v = try? value.decode(Int64.self) { self = .integer(v) }
        else if let v = try? value.decode(UInt64.self) { self = .unsigned(v) }
        else if let v = try? value.decode(Double.self) { self = .number(v) }
        else if let v = try? value.decode([JSONValue].self) { self = .array(v) }
        else { self = .object(try value.decode([String: JSONValue].self)) }
    }
    func encode(to encoder: Encoder) throws {
        var value = encoder.singleValueContainer()
        switch self {
        case .string(let v): try value.encode(v)
        case .bool(let v): try value.encode(v)
        case .integer(let v): try value.encode(v)
        case .unsigned(let v): try value.encode(v)
        case .number(let v): try value.encode(v)
        case .array(let v): try value.encode(v)
        case .object(let v): try value.encode(v)
        case .null: try value.encodeNil()
        }
    }
    var string: String? {
        if case .string(let value) = self { return value }
        return nil
    }
}

enum Platform: String, Codable, CaseIterable {
    case phone = "iphone-6.9", pad = "ipad-13", mac = "mac"
    var size: CGSize {
        switch self {
        case .phone: return CGSize(width: 1320, height: 2868)
        case .pad: return CGSize(width: 2752, height: 2064)
        case .mac: return CGSize(width: 2560, height: 1600)
        }
    }
}
struct Capture: Codable {
    var id: String
    var path: String
    var platform: Platform
    var sha256: String
    var nativeCapture: [String: JSONValue]
}
struct MarketingImage: Codable {
    var id: String
    var headline: String
    var hero: String
    var left: String?
    var right: String?
    var captureIDs: [String] { [left, right, hero].compactMap { $0 } }
}
struct Gallery: Codable {
    var platform: Platform
    var images: [MarketingImage]
}
struct Manifest: Codable {
    var schemaVersion: Int
    var revision: String
    var sourceBuildRef: String
    var outputDirectory: String
    var captures: [Capture]
    var galleries: [Gallery]
}
struct LoadedCapture {
    let metadata: Capture
    let url: URL
    let image: CGImage
    let encodedPixelWidth: Int
    let encodedPixelHeight: Int
    let sourceOrientation: Int
}

enum Palette: String, Codable, CaseIterable {
    case coralBurgundy, midnightStars, pinkPlum, tealMint
    var colors: (top: NSColor, bottom: NSColor, accent: NSColor) {
        switch self {
        case .coralBurgundy: return (color(0.35, 0.035, 0.13), color(0.94, 0.22, 0.27), color(1, 0.48, 0.38))
        case .midnightStars: return (color(0.035, 0.055, 0.16), color(0.11, 0.17, 0.40), color(0.57, 0.77, 1))
        case .pinkPlum: return (color(0.25, 0.055, 0.30), color(0.80, 0.20, 0.56), color(1, 0.48, 0.77))
        case .tealMint: return (color(0.015, 0.23, 0.26), color(0.055, 0.52, 0.49), color(0.44, 0.94, 0.76))
        }
    }
}
func color(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat, _ alpha: CGFloat = 1) -> NSColor {
    NSColor(srgbRed: red, green: green, blue: blue, alpha: alpha)
}
func digest(_ data: Data) -> String { SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined() }
func isHex(_ text: String, length: Int) -> Bool {
    text.count == length && text.unicodeScalars.allSatisfy { CharacterSet(charactersIn: "0123456789abcdef").contains($0) }
}
func resolve(_ path: String, beside base: URL) -> URL {
    (path.hasPrefix("/") ? URL(fileURLWithPath: path) : base.appendingPathComponent(path)).standardizedFileURL
}
func safeID(_ id: String) -> Bool {
    !id.isEmpty && id.count <= 80 && !id.hasPrefix(".") && !id.contains("..") && id.unicodeScalars.allSatisfy {
        CharacterSet.alphanumerics.contains($0) || $0 == "-" || $0 == "_" || $0 == "."
    }
}
func validDate(_ string: String) -> Bool {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    if formatter.date(from: string) != nil { return true }
    formatter.formatOptions = [.withInternetDateTime]
    return formatter.date(from: string) != nil
}

func validate(_ manifest: Manifest, beside base: URL, testOnly: Bool = false) throws -> [String: LoadedCapture] {
    try require(manifest.schemaVersion == 1, "Unknown manifest schemaVersion.")
    try require(isHex(manifest.revision.lowercased(), length: 40), "revision must be the full 40-character Git SHA.")
    try require(!manifest.sourceBuildRef.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, "Missing sourceBuildRef.")
    try require(!manifest.outputDirectory.isEmpty, "Missing outputDirectory.")
    let output = resolve(manifest.outputDirectory, beside: base)
    try require(testOnly || output.pathComponents.contains("app-store-audit"), "Outputs must be inside app-store-audit.")
    try require(manifest.galleries.count == 3 && Set(manifest.galleries.map(\.platform)) == Set(Platform.allCases),
                "Include exactly one gallery each for iphone-6.9, ipad-13 and mac.")
    try require(Set(manifest.captures.map(\.id)).count == manifest.captures.count, "Duplicate capture IDs.")
    var loaded: [String: LoadedCapture] = [:]
    for capture in manifest.captures {
        try require(safeID(capture.id), "Unsafe capture ID: \(capture.id).")
        try require(isHex(capture.sha256.lowercased(), length: 64), "\(capture.id): missing or invalid SHA-256.")
        let provenance = capture.nativeCapture
        let kind = provenance["kind"]?.string
        try require(kind == "native-screenshot" || (testOnly && kind == "test-only-solid-fixture"),
                    "\(capture.id): native capture provenance is required.")
        try require(provenance["platform"]?.string == capture.platform.rawValue, "\(capture.id): provenance platform mismatch.")
        try require(provenance["revision"]?.string == manifest.revision, "\(capture.id): provenance revision mismatch.")
        try require(provenance["sourceBuildRef"]?.string == manifest.sourceBuildRef, "\(capture.id): source build mismatch.")
        for field in ["device", "captureMethod", "capturedAtUTC"] {
            try require(!(provenance[field]?.string?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true),
                        "\(capture.id): missing nativeCapture.\(field).")
        }
        try require(validDate(provenance["capturedAtUTC"]!.string!), "\(capture.id): invalid capture timestamp.")
        let url = resolve(capture.path, beside: base)
        let fileExtension = url.pathExtension.lowercased()
        try require(["png", "jpg", "jpeg"].contains(fileExtension), "\(capture.id): original captures must be PNG or JPEG files.")
        let data = try Data(contentsOf: url)
        try require(digest(data) == capture.sha256.lowercased(), "\(capture.id): source capture hash changed.")
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let sourceType = CGImageSourceGetType(source) as String?,
              (fileExtension == "png" ? sourceType == "public.png" : sourceType == "public.jpeg"),
              CGImageSourceGetCount(source) == 1,
              let encodedImage = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            throw MarketingError(message: "\(capture.id): unsupported or unreadable native capture.")
        }
        let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any]
        let orientation = (properties?[kCGImagePropertyOrientation as String] as? NSNumber)?.intValue ?? 1
        try require((1...8).contains(orientation), "\(capture.id): unsupported source orientation metadata.")
        let image: CGImage
        if orientation == 1 {
            image = encodedImage
        } else {
            // Honor native screenshot metadata without rewriting, cropping or retouching the original.
            guard let orientedImage = CGImageSourceCreateThumbnailAtIndex(source, 0, [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceThumbnailMaxPixelSize: max(encodedImage.width, encodedImage.height)
            ] as CFDictionary) else {
                throw MarketingError(message: "\(capture.id): cannot apply standard source orientation.")
            }
            let swapsAxes = (5...8).contains(orientation)
            try require(orientedImage.width == (swapsAxes ? encodedImage.height : encodedImage.width)
                        && orientedImage.height == (swapsAxes ? encodedImage.width : encodedImage.height),
                        "\(capture.id): orientation normalization must retain full native pixel dimensions.")
            image = orientedImage
        }
        let aspect = CGFloat(image.width) / CGFloat(image.height)
        let appropriateShape: Bool
        switch capture.platform {
        case .phone: appropriateShape = (0.38...0.59).contains(aspect)
        case .pad: appropriateShape = (1.20...1.50).contains(aspect)
        // Native Mac export sheets can be portrait even when the app window is wide.
        case .mac: appropriateShape = (0.60...2.6).contains(aspect)
        }
        try require(appropriateShape, "\(capture.id): source orientation/aspect does not match \(capture.platform.rawValue).")
        loaded[capture.id] = LoadedCapture(metadata: capture, url: url, image: image,
                                          encodedPixelWidth: encodedImage.width, encodedPixelHeight: encodedImage.height,
                                          sourceOrientation: orientation)
    }
    for gallery in manifest.galleries {
        try require(gallery.images.count == 10, "\(gallery.platform.rawValue): exactly 10 marketing images are required.")
        try require(Set(gallery.images.map(\.id)).count == 10, "\(gallery.platform.rawValue): duplicate output IDs.")
        for image in gallery.images {
            try require(safeID(image.id), "Unsafe output ID: \(image.id).")
            let words = image.headline.split(whereSeparator: { $0.isWhitespace })
            try require(!words.isEmpty && words.count <= 8 && image.headline.count <= 60,
                        "\(image.id): use a short headline (at most 8 words / 60 characters).")
            try require(Set(image.captureIDs).count == image.captureIDs.count, "\(image.id): each layer must use a distinct capture.")
            guard let hero = loaded[image.hero] else {
                throw MarketingError(message: "\(image.id): unknown hero capture \(image.hero).")
            }
            for id in image.captureIDs {
                guard let capture = loaded[id] else { throw MarketingError(message: "\(image.id): unknown capture \(id).") }
                try require(capture.metadata.platform == gallery.platform, "\(image.id): capture \(id) belongs to another platform.")
                try require(capture.metadata.nativeCapture["device"] == hero.metadata.nativeCapture["device"],
                            "\(image.id): supporting captures must come from the hero's device.")
                if let deviceID = hero.metadata.nativeCapture["deviceIdentifier"] {
                    try require(capture.metadata.nativeCapture["deviceIdentifier"] == deviceID,
                                "\(image.id): supporting capture deviceIdentifier mismatch.")
                }
            }
        }
    }
    return loaded
}

struct LayerTransform: Codable {
    let captureID: String
    let role: String
    let centerX: CGFloat
    let centerY: CGFloat
    let width: CGFloat
    let height: CGFloat
    // CSS/screen convention: negative = counterclockwise, positive = clockwise.
    let rotationDegreesClockwise: CGFloat
    let uniformScale: CGFloat
    let framePadding: CGFloat
}
func layers(for image: MarketingImage, platform: Platform, index: Int, captures: [String: LoadedCapture]) -> [LayerTransform] {
    let size = platform.size, width = size.width, height = size.height
    let portrait = platform == .phone
    let variation = CGFloat(index % 3), padding = width * 0.007
    var result: [LayerTransform] = []
    func layer(_ id: String, role: String, center: CGPoint, maxWidth: CGFloat, maxHeight: CGFloat, angle: CGFloat) -> LayerTransform {
        let source = captures[id]!.image
        let scale = min(maxWidth / CGFloat(source.width), maxHeight / CGFloat(source.height))
        return LayerTransform(captureID: id, role: role, centerX: center.x, centerY: center.y,
                              width: CGFloat(source.width) * scale, height: CGFloat(source.height) * scale,
                              rotationDegreesClockwise: angle, uniformScale: scale, framePadding: padding)
    }
    let fanAngle = 9 + variation * 2
    if let left = image.left {
        result.append(layer(left, role: "left", center: CGPoint(x: width * 0.24, y: height * 0.40),
                            maxWidth: width * 0.64, maxHeight: portrait ? height * 0.72 : height * 0.61,
                            angle: -fanAngle))
    }
    if let right = image.right {
        result.append(layer(right, role: "right", center: CGPoint(x: width * 0.76, y: height * 0.40),
                            maxWidth: width * 0.64, maxHeight: portrait ? height * 0.72 : height * 0.61,
                            angle: fanAngle))
    }
    let source = captures[image.hero]!.image
    let hasFans = image.left != nil || image.right != nil
    let heroWidth = width * (portrait ? (hasFans ? 0.76 + variation * 0.02 : 0.84) : 0.90)
    let heroScale = min(heroWidth / CGFloat(source.width), portrait ? .greatestFiniteMagnitude : height * (0.69 - variation * 0.01) / CGFloat(source.height))
    let heroHeight = CGFloat(source.height) * heroScale
    result.append(LayerTransform(captureID: image.hero, role: "hero", centerX: width / 2,
                                 centerY: height * (portrait ? 0.79 : 0.76) - heroHeight / 2,
                                 width: CGFloat(source.width) * heroScale, height: heroHeight,
                                 rotationDegreesClockwise: 0, uniformScale: heroScale, framePadding: padding))
    return result
}

func background(_ context: CGContext, size: CGSize, palette: Palette) {
    let width = size.width, height = size.height, colors = palette.colors
    let gradient = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB),
                              colors: [colors.bottom.cgColor, colors.top.cgColor] as CFArray, locations: [0, 1])!
    context.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: 0, y: height), options: [])
    context.saveGState()
    context.setFillColor(colors.accent.withAlphaComponent(0.23).cgColor)
    context.setStrokeColor(colors.accent.withAlphaComponent(0.40).cgColor)
    context.setLineWidth(width * 0.002)
    switch palette {
    case .coralBurgundy:
        context.fillEllipse(in: CGRect(x: -width * 0.32, y: -height * 0.13, width: width * 0.92, height: width * 0.92))
        context.strokeEllipse(in: CGRect(x: width * 0.65, y: height * 0.40, width: width * 0.53, height: width * 0.53))
    case .midnightStars:
        context.setFillColor(colors.accent.withAlphaComponent(0.55).cgColor)
        for i in 0..<42 {
            let x = width * CGFloat((i * 37 + 11) % 101) / 100
            let y = height * CGFloat((i * 23 + 7) % 76) / 100
            let diameter = width * (i % 5 == 0 ? 0.005 : 0.002)
            context.fillEllipse(in: CGRect(x: x, y: y, width: diameter, height: diameter))
            if i % 9 == 0 {
                context.move(to: CGPoint(x: x - diameter, y: y + diameter / 2))
                context.addLine(to: CGPoint(x: x + diameter * 2, y: y + diameter / 2))
                context.move(to: CGPoint(x: x + diameter / 2, y: y - diameter))
                context.addLine(to: CGPoint(x: x + diameter / 2, y: y + diameter * 2))
                context.strokePath()
            }
        }
    case .pinkPlum:
        context.saveGState()
        context.translateBy(x: width * 0.52, y: height * 0.29)
        context.rotate(by: .pi / 5)
        for x in [CGFloat(-0.58), -0.13, 0.32] {
            context.fill(CGRect(x: width * x, y: -height, width: width * 0.22, height: height * 2))
        }
        context.restoreGState()
    case .tealMint:
        context.fillEllipse(in: CGRect(x: width * 0.55, y: -width * 0.24, width: width * 0.85, height: width * 0.85))
        for i in 0..<3 {
            let diameter = width * (0.30 + CGFloat(i) * 0.15)
            context.strokeEllipse(in: CGRect(x: -diameter * 0.55, y: height * 0.54 - diameter / 2,
                                             width: diameter, height: diameter))
        }
    }
    context.restoreGState()
}

func headline(_ text: String, context: CGContext, size: CGSize) throws {
    let portrait = size.height > size.width
    let area = CGRect(x: size.width * 0.055, y: size.height * 0.825,
                      width: size.width * 0.89, height: size.height * 0.135)
    var fontSize = portrait ? size.width * 0.087 : size.height * 0.077
    let minimum = portrait ? size.width * 0.050 : size.height * 0.050
    while fontSize >= minimum {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        paragraph.lineBreakMode = .byWordWrapping
        let attributed = NSAttributedString(string: text, attributes: [
            .font: NSFont.systemFont(ofSize: fontSize, weight: .bold),
            .foregroundColor: NSColor.white, .paragraphStyle: paragraph
        ])
        let setter = CTFramesetterCreateWithAttributedString(attributed)
        let measured = CTFramesetterSuggestFrameSizeWithConstraints(setter, CFRange(location: 0, length: attributed.length),
                                                                   nil, CGSize(width: area.width, height: .greatestFiniteMagnitude), nil)
        if measured.height <= area.height && measured.height <= fontSize * 2.7 {
            let path = CGPath(rect: CGRect(x: area.minX, y: area.midY - measured.height / 2 - 2,
                                          width: area.width, height: measured.height + 4), transform: nil)
            let frame = CTFramesetterCreateFrame(setter, CFRange(location: 0, length: attributed.length), path, nil)
            if CTFrameGetVisibleStringRange(frame).length == attributed.length {
                CTFrameDraw(frame, context)
                return
            }
        }
        fontSize -= 2
    }
    throw MarketingError(message: "Headline cannot fit without clipping: \(text)")
}

func draw(_ capture: CGImage, transform: LayerTransform, context: CGContext, canvas: CGSize) {
    context.saveGState()
    context.translateBy(x: transform.centerX, y: transform.centerY)
    // Core Graphics is bottom-left/y-up, so CSS clockwise angles change sign here.
    context.rotate(by: -transform.rotationDegreesClockwise * .pi / 180)
    let imageRect = CGRect(x: -transform.width / 2, y: -transform.height / 2,
                           width: transform.width, height: transform.height)
    let outer = imageRect.insetBy(dx: -transform.framePadding, dy: -transform.framePadding)
    let frame = CGPath(roundedRect: outer, cornerWidth: transform.framePadding,
                       cornerHeight: transform.framePadding, transform: nil)
    context.saveGState()
    context.setShadow(offset: CGSize(width: 0, height: -canvas.height * 0.006), blur: canvas.width * 0.025,
                      color: color(0, 0, 0, 0.40).cgColor)
    context.addPath(frame)
    context.setFillColor(NSColor.black.cgColor)
    context.fillPath()
    context.restoreGState()
    // No clipping, corner repainting, filters, overlays or retouching inside a capture.
    context.interpolationQuality = .high
    context.draw(capture, in: imageRect)
    context.restoreGState()
}

func jpeg(_ image: MarketingImage, platform: Platform, palette: Palette, transforms: [LayerTransform],
          captures: [String: LoadedCapture]) throws -> Data {
    let size = platform.size
    guard let space = CGColorSpace(name: CGColorSpace.sRGB),
          let context = CGContext(data: nil, width: Int(size.width), height: Int(size.height),
                                  bitsPerComponent: 8, bytesPerRow: 0, space: space,
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
        throw MarketingError(message: "Cannot allocate sRGB composition context.")
    }
    background(context, size: size, palette: palette)
    for transform in transforms { draw(captures[transform.captureID]!.image, transform: transform, context: context, canvas: size) }
    // Text is outside capture regions; drawing last keeps shadows from obscuring it.
    try headline(image.headline, context: context, size: size)
    guard let result = context.makeImage() else { throw MarketingError(message: "Cannot create composition.") }
    let data = NSMutableData()
    guard let destination = CGImageDestinationCreateWithData(data, "public.jpeg" as CFString, 1, nil) else {
        throw MarketingError(message: "Cannot create JPEG destination.")
    }
    CGImageDestinationAddImage(destination, result, [kCGImageDestinationLossyCompressionQuality: 0.95] as CFDictionary)
    try require(CGImageDestinationFinalize(destination), "Cannot encode JPEG.")
    try require(data.length < 10_000_000, "\(image.id): JPEG exceeds the 10 MB limit at quality 0.95.")
    return data as Data
}

struct SourceProof: Encodable {
    let id: String
    let path: String
    let platform: Platform
    let sha256: String
    let pixelWidth: Int
    let pixelHeight: Int
    let encodedPixelWidth: Int
    let encodedPixelHeight: Int
    let sourceOrientation: Int
    let standardOrientationApplied: Bool
    let nativeCapture: [String: JSONValue]
}
struct OutputProof: Encodable {
    let id: String
    let path: String
    let platform: Platform
    let revision: String
    let sourceBuildRef: String
    let headline: String
    let background: Palette
    let sha256: String
    let byteCount: Int
    let pixelWidth: Int
    let pixelHeight: Int
    let jpegQuality: Double
    let colorSpace: String
    let transforms: [LayerTransform]
}
struct Receipt: Encodable {
    let schemaVersion: Int
    let manifestPath: String
    let manifestSHA256: String
    let revision: String
    let sourceBuildRef: String
    let generatedAtUTC: String
    let coordinates: String
    let sources: [SourceProof]
    let outputs: [OutputProof]
}

func makeImages(manifestURL: URL, validateOnly: Bool) throws {
    let manifestData = try Data(contentsOf: manifestURL)
    let manifest = try JSONDecoder().decode(Manifest.self, from: manifestData)
    let base = manifestURL.deletingLastPathComponent()
    let captures = try validate(manifest, beside: base)
    let directory = resolve(manifest.outputDirectory, beside: base)
    let receiptURL = directory.appendingPathComponent("marketing-provenance.json")
    for gallery in manifest.galleries {
        for image in gallery.images {
            let path = directory.appendingPathComponent(gallery.platform.rawValue).appendingPathComponent(image.id + ".jpg")
            try require(!FileManager.default.fileExists(atPath: path.path), "Refusing to overwrite \(path.path). Use a new outputDirectory.")
        }
    }
    try require(!FileManager.default.fileExists(atPath: receiptURL.path), "Provenance already exists. Use a new outputDirectory.")
    if validateOnly {
        print("Validated \(captures.count) native captures and 30 images; no outputs written.")
        return
    }
    var outputs: [OutputProof] = []
    for gallery in manifest.galleries {
        let galleryDirectory = directory.appendingPathComponent(gallery.platform.rawValue)
        try FileManager.default.createDirectory(at: galleryDirectory, withIntermediateDirectories: true)
        for (index, image) in gallery.images.enumerated() {
            let proof = try autoreleasepool { () throws -> OutputProof in
                let palette = Palette.allCases[index % Palette.allCases.count]
                let transforms = layers(for: image, platform: gallery.platform, index: index, captures: captures)
                let data = try jpeg(image, platform: gallery.platform, palette: palette, transforms: transforms, captures: captures)
                let path = galleryDirectory.appendingPathComponent(image.id + ".jpg")
                try data.write(to: path, options: .atomic)
                return OutputProof(id: image.id, path: path.path, platform: gallery.platform, revision: manifest.revision,
                                   sourceBuildRef: manifest.sourceBuildRef, headline: image.headline, background: palette,
                                   sha256: digest(data), byteCount: data.count, pixelWidth: Int(gallery.platform.size.width),
                                   pixelHeight: Int(gallery.platform.size.height), jpegQuality: 0.95, colorSpace: "sRGB",
                                   transforms: transforms)
            }
            outputs.append(proof)
            print("Composed \(gallery.platform.rawValue)/\(image.id).jpg")
        }
    }
    for capture in captures.values {
        let current = try Data(contentsOf: capture.url)
        try require(digest(current) == capture.metadata.sha256.lowercased(),
                    "\(capture.metadata.id): source changed during composition; provenance was not finalized.")
    }
    let sources = captures.values.sorted { $0.metadata.id < $1.metadata.id }.map {
        SourceProof(id: $0.metadata.id, path: $0.url.path, platform: $0.metadata.platform, sha256: $0.metadata.sha256,
                    pixelWidth: $0.image.width, pixelHeight: $0.image.height,
                    encodedPixelWidth: $0.encodedPixelWidth, encodedPixelHeight: $0.encodedPixelHeight,
                    sourceOrientation: $0.sourceOrientation, standardOrientationApplied: $0.sourceOrientation != 1,
                    nativeCapture: $0.metadata.nativeCapture)
    }
    let receipt = Receipt(schemaVersion: 1, manifestPath: manifestURL.path, manifestSHA256: digest(manifestData),
                          revision: manifest.revision, sourceBuildRef: manifest.sourceBuildRef,
                          generatedAtUTC: ISO8601DateFormatter().string(from: Date()),
                          coordinates: "Pixels; origin bottom-left; rotations recorded clockwise (CSS/screen convention). Layers are back-to-front.",
                          sources: sources, outputs: outputs)
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
    try encoder.encode(receipt).write(to: receiptURL, options: .atomic)
    print("Recorded source hashes, preserved capture provenance and transforms in \(receiptURL.path).")
}

// Solid fixtures exercise geometry/encoding only; never accepted as native captures by normal execution.
func selfTest() throws {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent("valentine-marketing-test-\(UUID().uuidString)")
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directory) }
    let revision = String(repeating: "f", count: 40)
    var captures: [Capture] = []
    for platform in Platform.allCases {
        for (role, fill) in [("hero", color(1, 0, 0)), ("left", color(0, 1, 0)), ("right", color(0, 0, 1))] {
            let size = CGSize(width: (platform.size.width / 10).rounded(), height: (platform.size.height / 10).rounded())
            let context = CGContext(data: nil, width: Int(size.width), height: Int(size.height), bitsPerComponent: 8,
                                    bytesPerRow: 0, space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
            context.setFillColor(fill.cgColor)
            context.fill(CGRect(origin: .zero, size: size))
            let data = NSMutableData()
            let destination = CGImageDestinationCreateWithData(data, "public.png" as CFString, 1, nil)!
            CGImageDestinationAddImage(destination, context.makeImage()!, nil)
            try require(CGImageDestinationFinalize(destination), "Fixture PNG encoding failed.")
            let id = "\(platform.rawValue)-\(role)"
            let path = directory.appendingPathComponent(id + ".png")
            try (data as Data).write(to: path)
            captures.append(Capture(id: id, path: path.path, platform: platform, sha256: digest(data as Data),
                                    nativeCapture: ["kind": .string("test-only-solid-fixture"), "platform": .string(platform.rawValue),
                                                    "revision": .string(revision), "sourceBuildRef": .string("TEST-ONLY"),
                                                    "capturedAtUTC": .string("2026-10-03T00:00:00Z"),
                                                    "device": .string("TEST ONLY — solid color, no app UI"),
                                                    "captureMethod": .string("CGContext solid fixture"),
                                                    "extraPreservedField": .array([.bool(true), .integer(9)])]))
        }
    }
    let galleries = Platform.allCases.map { platform in
        Gallery(platform: platform, images: (0..<10).map {
            MarketingImage(id: String(format: "%02d-test-only", $0 + 1), headline: "TEST ONLY — geometry",
                           hero: "\(platform.rawValue)-hero", left: "\(platform.rawValue)-left", right: "\(platform.rawValue)-right")
        })
    }
    let manifest = Manifest(schemaVersion: 1, revision: revision, sourceBuildRef: "TEST-ONLY",
                            outputDirectory: directory.appendingPathComponent("test-only-output").path,
                            captures: captures, galleries: galleries)
    let loaded = try validate(manifest, beside: directory, testOnly: true)
    let roundTrip = try JSONDecoder().decode(Manifest.self, from: JSONEncoder().encode(manifest))
    try require(roundTrip.captures.map(\.nativeCapture) == manifest.captures.map(\.nativeCapture),
                "Unknown native provenance fields must survive encoding.")
    func rejected(_ change: (inout Manifest) -> Void, _ label: String, allowFixtures: Bool = true) throws {
        var invalid = manifest
        change(&invalid)
        var didReject = false
        do { _ = try validate(invalid, beside: directory, testOnly: allowFixtures) } catch { didReject = true }
        try require(didReject, "Validator did not reject \(label).")
    }
    try rejected({ $0.outputDirectory = directory.appendingPathComponent("app-store-audit/test").path }, "test-only provenance in production", allowFixtures: false)
    try rejected({ $0.revision = "" }, "missing revision")
    try rejected({ $0.captures[0].nativeCapture = [:] }, "missing native provenance")
    try rejected({ $0.captures[0].path = "missing.png" }, "missing source")
    try rejected({ $0.captures[0].path = "wrong-format.jpg" }, "unknown source format")
    try rejected({ $0.captures[0].sha256 = String(repeating: "0", count: 64) }, "changed source hash")
    let rotatedData = NSMutableData()
    let rotatedDestination = CGImageDestinationCreateWithData(rotatedData, "public.png" as CFString, 1, nil)!
    let padIndex = captures.firstIndex { $0.platform == .pad }!
    let fixtureImage = loaded[captures[padIndex].id]!.image
    CGImageDestinationAddImage(rotatedDestination, fixtureImage, [kCGImagePropertyOrientation: 8] as CFDictionary)
    try require(CGImageDestinationFinalize(rotatedDestination), "Rotated fixture PNG encoding failed.")
    let rotatedSource = CGImageSourceCreateWithData(rotatedData, nil)!
    let rotatedProperties = CGImageSourceCopyPropertiesAtIndex(rotatedSource, 0, nil) as? [String: Any]
    try require((rotatedProperties?[kCGImagePropertyOrientation as String] as? NSNumber)?.intValue == 8,
                "Rotated fixture must retain orientation metadata.")
    let rotatedPath = directory.appendingPathComponent("test-only-orientation-8.png")
    try (rotatedData as Data).write(to: rotatedPath)
    try rejected({
        $0.captures[padIndex].path = rotatedPath.path
        $0.captures[padIndex].sha256 = digest(rotatedData as Data)
    }, "orientation normalization yielding the wrong platform aspect")
    let portraitContext = CGContext(data: nil, width: fixtureImage.height, height: fixtureImage.width,
                                    bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    portraitContext.setFillColor(color(1, 0, 0).cgColor)
    portraitContext.fill(CGRect(x: 0, y: 0, width: fixtureImage.height, height: fixtureImage.width))
    let validOrientedData = NSMutableData()
    let validOrientedDestination = CGImageDestinationCreateWithData(validOrientedData, "public.png" as CFString, 1, nil)!
    CGImageDestinationAddImage(validOrientedDestination, portraitContext.makeImage()!, [kCGImagePropertyOrientation: 8] as CFDictionary)
    try require(CGImageDestinationFinalize(validOrientedDestination), "Valid oriented fixture PNG encoding failed.")
    let validOrientedPath = directory.appendingPathComponent("test-only-valid-pad-orientation-8.png")
    try (validOrientedData as Data).write(to: validOrientedPath)
    var validOrientedManifest = manifest
    validOrientedManifest.captures[padIndex].path = validOrientedPath.path
    validOrientedManifest.captures[padIndex].sha256 = digest(validOrientedData as Data)
    let normalized = try validate(validOrientedManifest, beside: directory, testOnly: true)[captures[padIndex].id]!
    try require(normalized.sourceOrientation == 8 && normalized.image.width == fixtureImage.width
                && normalized.image.height == fixtureImage.height, "Standard source orientation must produce full landscape pixels.")
    let unchangedOrientedData = try Data(contentsOf: validOrientedPath)
    try require(digest(unchangedOrientedData) == digest(validOrientedData as Data),
                "Source orientation normalization must preserve original file bytes.")
    try rejected({ $0.captures[1].nativeCapture["device"] = .string("DIFFERENT TEST DEVICE") }, "cross-device fan")
    try rejected({ $0.galleries[0].images[0].hero = "mac-hero" }, "cross-platform layer")
    try rejected({ $0.galleries[0].images.removeLast() }, "incomplete gallery")
    for gallery in galleries {
        let image = gallery.images[0]
        let transforms = layers(for: image, platform: gallery.platform, index: 0, captures: loaded)
        try require(transforms.last?.role == "hero" && transforms.last?.rotationDegreesClockwise == 0, "Hero must be upright and in front.")
        let left = transforms[0], right = transforms[1]
        let leftTopX = left.centerX + left.height / 2 * sin(left.rotationDegreesClockwise * .pi / 180)
        let rightTopX = right.centerX + right.height / 2 * sin(right.rotationDegreesClockwise * .pi / 180)
        try require(leftTopX < left.centerX && rightTopX > right.centerX, "Supporting captures must fan outward.")
        let data = try jpeg(image, platform: gallery.platform, palette: .midnightStars, transforms: transforms, captures: loaded)
        let source = CGImageSourceCreateWithData(data as CFData, nil)!
        let result = CGImageSourceCreateImageAtIndex(source, 0, nil)!
        try require(result.width == Int(gallery.platform.size.width) && result.height == Int(gallery.platform.size.height), "Incorrect Apple output dimensions.")
        try require(result.colorSpace?.name as String? == CGColorSpace.sRGB as String, "JPEG must retain sRGB.")
        func pixel(_ fractionX: CGFloat) -> [UInt8] {
            let crop = result.cropping(to: CGRect(x: (CGFloat(result.width) * fractionX).rounded(),
                                                  y: (CGFloat(result.height) * 0.58).rounded(), width: 1, height: 1))!
            var bytes = [UInt8](repeating: 0, count: 4)
            bytes.withUnsafeMutableBytes { buffer in
                let context = CGContext(data: buffer.baseAddress, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4,
                                        space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
                context.draw(crop, in: CGRect(x: 0, y: 0, width: 1, height: 1))
            }
            return bytes
        }
        let hero = pixel(0.50), leftPixel = pixel(0.07), rightPixel = pixel(0.93)
        try require(hero[0] > 220 && hero[1] < 30 && hero[2] < 30, "Hero must cover both fans.")
        try require(leftPixel[1] > 220 && leftPixel[0] < 30, "Left fixture not visible outside hero.")
        try require(rightPixel[2] > 220 && rightPixel[0] < 30, "Right fixture not visible outside hero.")
        print("PASS TEST ONLY \(gallery.platform.rawValue): dimensions, sRGB, hero layering and outward fan geometry.")
    }
    for capture in captures {
        let data = try Data(contentsOf: URL(fileURLWithPath: capture.path))
        try require(digest(data) == capture.sha256, "A source fixture was altered.")
    }
    print("PASS validator rejection checks; fixture bytes unchanged. Temporary test images removed.")
}

do {
    let arguments = Array(CommandLine.arguments.dropFirst())
    if arguments == ["--self-test"] { try selfTest() }
    else if arguments.count == 2 && arguments[0] == "--validate" {
        try makeImages(manifestURL: URL(fileURLWithPath: arguments[1]).standardizedFileURL, validateOnly: true)
    } else if arguments.count == 1 && !arguments[0].hasPrefix("--") {
        try makeImages(manifestURL: URL(fileURLWithPath: arguments[0]).standardizedFileURL, validateOnly: false)
    } else {
        throw MarketingError(message: "Usage: swift scripts/make-marketing-images.swift [--validate] MANIFEST.json | --self-test")
    }
} catch {
    FileHandle.standardError.write(Data("Marketing composition stopped: \(error.localizedDescription)\n".utf8))
    exit(1)
}
