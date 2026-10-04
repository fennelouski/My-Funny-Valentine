import Foundation

/// Release resolves the original app paths. DEBUG QA cannot fall back to them.
nonisolated enum MFVRuntime {
    enum Mode: String, Sendable { case normal, unit, ui, invalid }
    struct Configuration: Sendable {
        let mode: Mode
        let session: UUID?
        var isPrivate: Bool { mode != .normal }
        var usesBlankHost: Bool { mode == .unit || mode == .invalid }
    }
    enum IsolationError: LocalizedError {
        case invalidSession
        var errorDescription: String? { "Private QA needs a valid session UUID." }
    }

    static let configuration: Configuration = {
        #if DEBUG
        let process = ProcessInfo.processInfo
        let isXCTest = process.environment["XCTestConfigurationFilePath"] != nil
            || process.environment["XCTestBundlePath"] != nil || NSClassFromString("XCTestCase") != nil
        #if MFV_QA_STORE
        let forcedPrivate = true
        #else
        let forcedPrivate = false
        #endif
        return parse(arguments: process.arguments, environment: process.environment,
                     isXCTest: isXCTest, forcedPrivate: forcedPrivate)
        #else
        return Configuration(mode: .normal, session: nil)
        #endif
    }()

    static var isPrivate: Bool { configuration.isPrivate }
    static var usesBlankHost: Bool { configuration.usesBlankHost }

    @MainActor private static let privatePreferences: UserDefaults = {
        let identifier = configuration.session ?? UUID()
        guard let preferences = UserDefaults(suiteName: "MFVPrivateQA." + identifier.uuidString) else {
            // Creating a private domain may fail, but ordinary preferences are
            // never an acceptable fallback for a private process.
            fatalError("Private QA preferences could not open")
        }
        return preferences
    }()

    @MainActor static var preferences: UserDefaults {
        isPrivate ? privatePreferences : .standard
    }

    static func privateRoot() throws -> URL {
        guard isPrivate, let session = configuration.session, configuration.mode != .invalid else {
            throw IsolationError.invalidSession
        }
        return FileManager.default.temporaryDirectory
            .appendingPathComponent("MFVPrivateQA-" + session.uuidString, isDirectory: true)
    }

    static func storeDirectory() throws -> URL {
        let path = try privateRoot().appendingPathComponent("Store", isDirectory: true)
        try FileManager.default.createDirectory(at: path, withIntermediateDirectories: true)
        return path
    }

    static func mediaDirectory() throws -> URL {
        if !isPrivate { return FileManager.default.temporaryDirectory }
        let path = try privateRoot().appendingPathComponent("Media", isDirectory: true)
        try FileManager.default.createDirectory(at: path, withIntermediateDirectories: true)
        return path
    }

    /// Pure parsing is also tested without opening a preference domain or store.
    static func parse(arguments: [String], environment: [String: String], isXCTest: Bool,
                      forcedPrivate: Bool = false, generatedUnitSession: UUID = UUID()) -> Configuration {
        let unit = arguments.contains("--mfv-unit-tests")
        let ui = arguments.contains("--mfv-ui-tests") || arguments.contains("--uitesting") || forcedPrivate
        let indices = arguments.indices.filter { arguments[$0] == "--mfv-test-session" }
        let hasArgument = !indices.isEmpty
        let argumentSession = indices.first.flatMap { index in
            arguments.indices.contains(index + 1) ? arguments[index + 1] : nil
        }
        let environmentSession = environment["MFV_TEST_SESSION"]
        let legacyPrivate = arguments.contains("-qaStore") || arguments.contains("-qaStoreName")
        let requested = unit || ui || hasArgument || environmentSession != nil || legacyPrivate || isXCTest
        guard requested else { return Configuration(mode: .normal, session: nil) }
        guard !(unit && ui), indices.count <= 1 else { return Configuration(mode: .invalid, session: nil) }

        func validUUID(_ value: String?) -> UUID? {
            guard let value, value.range(of: "^[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}$", options: .regularExpression) != nil else { return nil }
            return UUID(uuidString: value)
        }
        if hasArgument && validUUID(argumentSession) == nil { return Configuration(mode: .invalid, session: nil) }
        if environmentSession != nil && validUUID(environmentSession) == nil { return Configuration(mode: .invalid, session: nil) }
        if let argument = validUUID(argumentSession), let value = validUUID(environmentSession), argument != value {
            return Configuration(mode: .invalid, session: nil)
        }
        let explicitSession = validUUID(argumentSession) ?? validUUID(environmentSession)
        if ui {
            guard let explicitSession else { return Configuration(mode: .invalid, session: nil) }
            return Configuration(mode: .ui, session: explicitSession)
        }
        if unit || isXCTest {
            // An explicitly requested unit session must supply its UUID. An
            // automatic test host may use a fresh, stable process-local UUID.
            if unit && explicitSession == nil { return Configuration(mode: .invalid, session: nil) }
            return Configuration(mode: .unit, session: explicitSession ?? generatedUnitSession)
        }
        return Configuration(mode: .invalid, session: nil)
    }
}
