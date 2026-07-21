//
//  OnDeviceSayingsGenerator.swift
//  My Funny Valentine
//
//  Generates sayings with Apple's on-device foundation model. Runs entirely on
//  device: no network, no per-request cost, and nothing the user types leaves
//  the phone.
//

import Foundation

#if canImport(FoundationModels)
import FoundationModels
#endif

#if canImport(FoundationModels)
@available(iOS 26.0, macOS 26.0, visionOS 26.0, *)
@Generable
nonisolated struct GeneratedValentineSayings {
    @Guide(description: "Ten distinct Valentine's card messages, each under 120 characters")
    var sayings: [String]
}
#endif

enum OnDeviceGenerationError: LocalizedError {
    case unavailable
    case emptyResult

    var errorDescription: String? {
        switch self {
        case .unavailable:
            return "On-device generation isn't available on this device."
        case .emptyResult:
            return "The on-device model didn't return anything usable."
        }
    }
}

nonisolated struct OnDeviceSayingsGenerator {
    static let shared = OnDeviceSayingsGenerator()

    private init() {}

    /// True when Apple Intelligence is enabled and the model is ready.
    static var isAvailable: Bool {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, macOS 26.0, visionOS 26.0, *) {
            return SystemLanguageModel.default.isAvailable
        }
        #endif
        return false
    }

    /// A short explanation when generation isn't available, for surfacing in UI.
    static var unavailableReason: String? {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, macOS 26.0, visionOS 26.0, *) {
            switch SystemLanguageModel.default.availability {
            case .available:
                return nil
            case .unavailable(.deviceNotEligible):
                return "This device doesn't support Apple Intelligence."
            case .unavailable(.appleIntelligenceNotEnabled):
                return "Turn on Apple Intelligence in Settings to generate sayings on device."
            case .unavailable(.modelNotReady):
                return "Apple Intelligence is still downloading. Try again shortly."
            case .unavailable:
                return "On-device generation isn't available right now."
            }
        }
        #endif
        return "On-device generation needs a newer version of this OS."
    }

    func sayings(for inspiration: String) async throws -> [String] {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, macOS 26.0, visionOS 26.0, *) {
            guard SystemLanguageModel.default.isAvailable else {
                throw OnDeviceGenerationError.unavailable
            }

            let session = LanguageModelSession(instructions: """
                You write short Valentine's Day card messages.

                Style: warm, playful, and a little funny. Affectionate rather \
                than crude. Suitable for a partner, a friend, or a family \
                member, and safe for all audiences.

                Keep every message under 120 characters. Vary the structure so \
                the ten messages don't all sound alike. Return the messages \
                only, with no numbering or quotation marks.
                """)

            let response = try await session.respond(
                to: "Write 10 Valentine's card messages inspired by: \(inspiration)",
                generating: GeneratedValentineSayings.self
            )

            let cleaned = response.content.sayings
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }

            guard !cleaned.isEmpty else {
                throw OnDeviceGenerationError.emptyResult
            }
            return cleaned
        }
        #endif
        throw OnDeviceGenerationError.unavailable
    }
}
