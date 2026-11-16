import Foundation

/// Player settings.
public struct Settings: Codable, Equatable, Sendable {
    public enum Units: String, Codable, CaseIterable, Sendable { case metric, imperial }
    public enum Steering: String, Codable, CaseIterable, Sendable { case tilt, touch }
    public enum Gears: String, Codable, CaseIterable, Sendable { case automatic, paddles }
    public enum Quality: String, Codable, CaseIterable, Sendable { case low, medium, high }

    public var units: Units
    public var steering: Steering
    public var gears: Gears
    public var sound: Bool
    public var haptics: Bool
    public var quality: Quality

    public init(units: Units, steering: Steering, gears: Gears, sound: Bool, haptics: Bool, quality: Quality) {
        self.units = units
        self.steering = steering
        self.gears = gears
        self.sound = sound
        self.haptics = haptics
        self.quality = quality
    }
}

/// Everything the game keeps between launches.
public struct SaveFile: Codable, Equatable, Sendable {
    public static let currentVersion = 1

    public var version: Int
    public var builds: [EngineBuild]
    public var selectedBuild: UUID?
    public var car: CarSetup
    public var settings: Settings

    public init(version: Int, builds: [EngineBuild], selectedBuild: UUID?, car: CarSetup, settings: Settings) {
        self.version = version
        self.builds = builds
        self.selectedBuild = selectedBuild
        self.car = car
        self.settings = settings
    }

    /// A first launch: one stock engine of every layout, opening on the cross-plane V8 in the
    /// muscle car.
    public static func defaults() -> SaveFile {
        let builds = EngineLayout.allCases.map { EngineBuild.starter($0) }
        return SaveFile(
            version: currentVersion,
            builds: builds,
            selectedBuild: builds.first { $0.layout == .v8Cross }?.id,
            car: CarSetup(body: .muscle, gearbox: .m6, finalDrive: 3.55, tyre: Tyre(compound: .sport, widthMm: 255)),
            settings: Settings(units: .metric, steering: .touch, gears: .automatic, sound: true, haptics: true, quality: .high)
        )
    }

    /// The same save with every build sanitised, a garage that is never empty, and a selected
    /// build that exists.
    func sanitized() -> SaveFile {
        var clean = self
        clean.builds = builds.map { $0.sanitized() }
        if clean.builds.isEmpty { clean.builds = SaveFile.defaults().builds }
        if !clean.builds.contains(where: { $0.id == clean.selectedBuild }) { clean.selectedBuild = clean.builds.first?.id }
        clean.car.finalDrive = EngineBuild.clamp(car.finalDrive, 2...5.5, fallback: 3.55)
        clean.car.tyre.widthMm = EngineBuild.clamp(car.tyre.widthMm, 155...355, fallback: 225)
        return clean
    }
}

public enum LoadStatus: String, Sendable {
    case fresh, loaded, recoveredFromBackup, newerVersionKept, corruptReset
}

/// Reads and writes the save file.
///
/// - `save.json` is the save; every write first copies a good previous save to `save.bak.json`,
///   and writes atomically, so a crash mid-write never leaves half a file.
/// - A corrupt or empty save falls back to the backup, then to a fresh save. A corrupt file is
///   moved to `save.corrupt.json` on the next write rather than silently deleted.
/// - A save from a newer version of the game is never overwritten: it loads as fresh defaults,
///   and the first write moves it to `save.newer.json`.
public final class SaveStore {
    public let directory: URL
    private var mainURL: URL { directory.appendingPathComponent("save.json") }
    private var backupURL: URL { directory.appendingPathComponent("save.bak.json") }
    private var newerURL: URL { directory.appendingPathComponent("save.newer.json") }
    private var corruptURL: URL { directory.appendingPathComponent("save.corrupt.json") }

    private enum Contents {
        case missing, corrupt, newer, valid(SaveFile)
    }

    public init(directory: URL) {
        self.directory = directory
    }

    public func load() -> (SaveFile, LoadStatus) {
        switch read(mainURL) {
        case .valid(let file):
            return (file, .loaded)
        case .newer:
            return (SaveFile.defaults(), .newerVersionKept)
        case .missing:
            if case .valid(let file) = read(backupURL) { return (file, .recoveredFromBackup) }
            return (SaveFile.defaults(), .fresh)
        case .corrupt:
            if case .valid(let file) = read(backupURL) { return (file, .recoveredFromBackup) }
            return (SaveFile.defaults(), .corruptReset)
        }
    }

    public func save(_ file: SaveFile) throws {
        let manager = FileManager.default
        try manager.createDirectory(at: directory, withIntermediateDirectories: true)
        switch read(mainURL) {
        case .newer:
            try replace(newerURL, with: mainURL)
        case .corrupt:
            try replace(corruptURL, with: mainURL)
        case .valid:
            try Data(contentsOf: mainURL).write(to: backupURL, options: .atomic)
        case .missing:
            break
        }
        var current = file
        current.version = SaveFile.currentVersion
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        try encoder.encode(current).write(to: mainURL, options: .atomic)
    }

    /// Moves `source` to `destination`, replacing whatever was there.
    private func replace(_ destination: URL, with source: URL) throws {
        let manager = FileManager.default
        if manager.fileExists(atPath: destination.path) { try manager.removeItem(at: destination) }
        try manager.moveItem(at: source, to: destination)
    }

    private struct VersionPeek: Decodable {
        let version: Int
    }

    private func read(_ url: URL) -> Contents {
        guard FileManager.default.fileExists(atPath: url.path) else { return .missing }
        guard let data = try? Data(contentsOf: url), !data.isEmpty,
              let peek = try? JSONDecoder().decode(VersionPeek.self, from: data) else { return .corrupt }
        if peek.version > SaveFile.currentVersion { return .newer }
        // Older versions would be migrated here, one step at a time; version 1 is the first.
        guard let file = try? JSONDecoder().decode(SaveFile.self, from: data) else { return .corrupt }
        return .valid(file.sanitized())
    }
}
