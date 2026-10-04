import Foundation
import CoreGraphics

/// Optional JSON in CardLayoutData: older saved cards keep their original layout.
nonisolated struct CardComposition: Codable, Equatable {
    var version = 1
    var family: CardVisualFamily
    var variant: Int
    var motionEnabled: Bool

    init(family: CardVisualFamily = .loveLetter, variant: Int = 0, motionEnabled: Bool = true) {
        self.family = family
        self.variant = min(max(variant, 0), 4)
        self.motionEnabled = motionEnabled
    }

    static func starter(templateID: String) -> CardComposition? {
        let parts = templateID.split(separator: "_")
        guard parts.count == 3, parts[0] == "starter", let number = Int(parts[2]), (1...5).contains(number) else { return nil }
        let families: [String: CardVisualFamily] = [
            "pizza": .comic, "space": .cosmic, "birds": .loveLetter,
            "dino": .popUp, "disco": .photoBooth, "sweets": .confetti
        ]
        guard let family = families[String(parts[1])] else { return nil }
        return CardComposition(family: family, variant: number - 1)
    }

    var isSupported: Bool { version == 1 && (0...4).contains(variant) }
}

nonisolated enum CardVisualFamily: String, CaseIterable, Codable, Identifiable, Hashable {
    case comic, cosmic, loveLetter, photoBooth, confetti, popUp
    var id: String { rawValue }
    var title: String {
        switch self {
        case .comic: "Comic crush"
        case .cosmic: "Cosmic love"
        case .loveLetter: "Love letter"
        case .photoBooth: "Photo booth"
        case .confetti: "Confetti party"
        case .popUp: "Pop-up heart"
        }
    }
    var symbol: String {
        switch self {
        case .comic: "bolt.fill"
        case .cosmic: "sparkles"
        case .loveLetter: "envelope.open.fill"
        case .photoBooth: "photo.stack.fill"
        case .confetti: "party.popper.fill"
        case .popUp: "heart.fill"
        }
    }
    var backgroundHex: String {
        switch self {
        case .comic: "#FFE95C"
        case .cosmic: "#161B55"
        case .loveLetter: "#F8C9D2"
        case .photoBooth: "#242033"
        case .confetti: "#BCEEE9"
        case .popUp: "#294CD3"
        }
    }
    var inkHex: String {
        switch self {
        case .comic: "#231F20"
        case .cosmic, .photoBooth, .popUp: "#FFFFFF"
        case .loveLetter: "#741B37"
        case .confetti: "#143E4C"
        }
    }
    var accentHex: String {
        switch self {
        case .comic: "#E52E63"
        case .cosmic: "#F2B4D4"
        case .loveLetter: "#B52C50"
        case .photoBooth: "#EBA0C4"
        case .confetti: "#D33364"
        case .popUp: "#FFC4D9"
        }
    }
    var fontName: String {
        switch self {
        case .comic: "AvenirNext-Heavy"
        case .cosmic: "AvenirNext-DemiBold"
        case .loveLetter: "Georgia-Bold"
        case .photoBooth: "AvenirNextCondensed-Bold"
        case .confetti: "AvenirNext-Heavy"
        case .popUp: "Georgia-Bold"
        }
    }
}

/// Time is an explicit input, so preview, export and offline browser frames agree.
nonisolated enum CardMotion {
    static func phase(elapsed: TimeInterval, duration: TimeInterval = 3) -> Double {
        guard elapsed.isFinite, duration.isFinite, duration > 0 else { return 0 }
        return max(0, elapsed).truncatingRemainder(dividingBy: duration) / duration
    }
    static func opening(phase: Double) -> Double {
        guard phase.isFinite else { return 0 }
        let p = min(max(phase, 0), 1)
        let triangle = p < 0.5 ? p * 2 : (1 - p) * 2
        return triangle * triangle * (3 - 2 * triangle)
    }
}

/// Frozen value graph. Never reads a SwiftData model or file during an export.
nonisolated struct CardRenderSnapshot {
    struct ImageLayer {
        let data: Data
        let rect: CGRect
        let rotation: Double
    }
    let saying: String
    let note: String
    let template: CardTemplate?
    let templateArtwork: Data?
    let layout: CardLayoutData?
    let images: [ImageLayer]
    let faces: [ImageLayer]
    let stickers: [ImageLayer]
    var composition: CardComposition? { layout?.composition.flatMap { $0.isSupported ? $0 : nil } }
}
