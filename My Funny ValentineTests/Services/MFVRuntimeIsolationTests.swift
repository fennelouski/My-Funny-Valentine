import Foundation
import Testing
@testable import My_Funny_Valentine

@MainActor
struct MFVRuntimeIsolationTests {
    @Test("A valid explicit UI UUID selects only its private session")
    func validUISession() {
        let session = UUID()
        let configuration = MFVRuntime.parse(arguments: ["app", "--mfv-ui-tests", "--mfv-test-session", session.uuidString.lowercased()],
                                             environment: [:], isXCTest: false)
        #expect(configuration.mode == .ui)
        #expect(configuration.session == session)
        #expect(configuration.isPrivate && !configuration.usesBlankHost)
    }

    @Test("Missing and malformed explicit private requests remain blank")
    func malformedPrivateRequests() {
        let requests: [[String]] = [
            ["--mfv-ui-tests"], ["--uitesting"], ["-qaStore", "YES"], ["-qaStoreName", "old-gallery"],
            ["--mfv-test-session"], ["--mfv-ui-tests", "--mfv-test-session", "../ordinary"],
            ["--mfv-unit-tests"], ["--mfv-unit-tests", "--mfv-test-session", "not-a-uuid"]
        ]
        for request in requests {
            let configuration = MFVRuntime.parse(arguments: ["app"] + request, environment: [:], isXCTest: false)
            #expect(configuration.mode == .invalid)
            #expect(configuration.isPrivate && configuration.usesBlankHost)
            #expect(configuration.session == nil)
        }
        let invalidEnvironment = MFVRuntime.parse(arguments: ["app"], environment: ["MFV_TEST_SESSION": ""], isXCTest: true)
        #expect(invalidEnvironment.mode == .invalid && invalidEnvironment.usesBlankHost)
    }

    @Test("Conflicting private modes or UUIDs cannot silently choose a store")
    func conflictingRequests() {
        let first = UUID().uuidString
        let second = UUID().uuidString
        let requests: [([String], [String: String])] = [
            (["--mfv-ui-tests", "--mfv-unit-tests", "--mfv-test-session", first], [:]),
            (["--mfv-ui-tests", "--mfv-test-session", first, "--mfv-test-session", second], [:]),
            (["--mfv-ui-tests", "--mfv-test-session", first], ["MFV_TEST_SESSION": second])
        ]
        for (arguments, environment) in requests {
            let configuration = MFVRuntime.parse(arguments: ["app"] + arguments, environment: environment, isXCTest: true)
            #expect(configuration.mode == .invalid && configuration.usesBlankHost && configuration.isPrivate)
        }
    }

    @Test("Automatic and explicitly valid unit hosts are blank before model creation")
    func unitHostsAreBlank() {
        let generated = UUID()
        let automatic = MFVRuntime.parse(arguments: ["app"], environment: [:], isXCTest: true, generatedUnitSession: generated)
        #expect(automatic.mode == .unit && automatic.session == generated && automatic.usesBlankHost)
        let explicit = UUID()
        let requested = MFVRuntime.parse(arguments: ["app", "--mfv-unit-tests", "--mfv-test-session", explicit.uuidString],
                                         environment: [:], isXCTest: true, generatedUnitSession: generated)
        #expect(requested.mode == .unit && requested.session == explicit && requested.usesBlankHost)
        let rejected = MFVRuntime.parse(arguments: ["app", "--mfv-test-session", "bad"], environment: [:], isXCTest: true,
                                        generatedUnitSession: generated)
        #expect(rejected.mode == .invalid && rejected.session == nil)
    }

    @Test("Ordinary launch remains ordinary, while a forced QA build still needs a UUID")
    func ordinaryAndForcedModes() {
        let normal = MFVRuntime.parse(arguments: ["app"], environment: [:], isXCTest: false)
        #expect(normal.mode == .normal && normal.session == nil && !normal.isPrivate)
        let forced = MFVRuntime.parse(arguments: ["app"], environment: [:], isXCTest: false, forcedPrivate: true)
        #expect(forced.mode == .invalid && forced.isPrivate && forced.usesBlankHost)
    }

    @Test("The actual unit process writes preferences and media only inside its private session")
    func actualPrivateUnitPaths() throws {
        try #require(MFVRuntime.configuration.mode == .unit)
        let session = try #require(MFVRuntime.configuration.session)
        let root = try MFVRuntime.privateRoot()
        #expect(root.lastPathComponent == "MFVPrivateQA-" + session.uuidString)
        let media = try MFVRuntime.mediaDirectory()
        #expect(media.deletingLastPathComponent().standardizedFileURL == root.standardizedFileURL)
        let store = try MFVRuntime.storeDirectory()
        #expect(store.deletingLastPathComponent().standardizedFileURL == root.standardizedFileURL)
        let file = media.appendingPathComponent("isolation-" + UUID().uuidString + ".txt")
        defer { try? FileManager.default.removeItem(at: file) }
        let payload = Data("Private unit media".utf8)
        try payload.write(to: file, options: .atomic)
        #expect(try Data(contentsOf: file) == payload)
        let key = "isolation-" + UUID().uuidString
        let preferences = MFVRuntime.preferences
        defer { preferences.removeObject(forKey: key) }
        preferences.set(session.uuidString, forKey: key)
        #expect(preferences.string(forKey: key) == session.uuidString)
    }
}
