//
//  LocalSayingsGenerator.swift
//  My Funny Valentine
//
//  On-device saying generation. Keeps the core experience working when the
//  hosted AI backend isn't configured or the device is offline.
//

import Foundation

nonisolated struct LocalSayingsGenerator {
    static let shared = LocalSayingsGenerator()

    private init() {}

    /// `{x}` is replaced with the user's inspiration.
    private static let templates: [String] = [
        "You're the {x} to my heart.",
        "I love you more than {x}, and that's saying something.",
        "Life without you would be like {x} without the magic.",
        "You had me at {x}.",
        "Roses are red, violets are blue, I really love {x}, but not as much as you.",
        "If loving {x} is wrong, loving you is very, very right.",
        "You're my favorite thing, right after {x}. Kidding. You're first.",
        "Some people dream about {x}. I dream about you.",
        "Together we're better than {x}, and that is a high bar.",
        "I would give up {x} for you. Probably. Let's not test it.",
        "You make {x} look boring.",
        "My heart does a little dance whenever I think about {x} and you.",
        "Fair warning: I may start talking about {x} and you interchangeably.",
        "Be mine, and I'll share my {x}.",
        "You're sweeter than {x}, and that is scientifically impressive.",
        "{x} is wonderful. You're better.",
        "I'm absolutely nuts about you, and mildly obsessed with {x}.",
        "Of all the {x} in all the world, I'm glad I found you.",
        "You plus me plus {x} equals happily ever after.",
        "I never believed in love at first sight until {x} brought us together.",
        "They say the way to the heart is {x}. They were right about you.",
        "Every love story is beautiful, but ours has {x} in it.",
        "I'd choose you over {x} every single time. Don't tell {x}.",
        "You're the reason I smile, and {x} is a distant second."
    ]

    /// Returns a freshly shuffled batch of sayings built around `inspiration`.
    func sayings(for inspiration: String, count: Int = 10) -> [String] {
        let subject = normalized(inspiration)

        return Self.templates
            .shuffled()
            .prefix(count)
            .map { template in
                capitalizingFirstLetter(
                    template.replacingOccurrences(of: "{x}", with: subject)
                )
            }
    }

    private func normalized(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "love" : trimmed.lowercased()
    }

    private func capitalizingFirstLetter(_ text: String) -> String {
        guard let first = text.first else { return text }
        return first.uppercased() + text.dropFirst()
    }
}
