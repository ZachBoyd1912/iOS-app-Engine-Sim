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

    /// RED stub.
    public static func defaults() -> SaveFile {
        SaveFile(
            version: 0, builds: [], selectedBuild: nil,
            car: CarSetup(body: .hatch, gearbox: .m5, finalDrive: 0, tyre: Tyre(compound: .street, widthMm: 0)),
            settings: Settings(units: .metric, steering: .touch, gears: .automatic, sound: true, haptics: true, quality: .medium)
        )
    }
}

public enum LoadStatus: String, Sendable {
    case fresh, loaded, recoveredFromBackup, newerVersionKept, corruptReset
}

/// Reads and writes the save file. RED stub.
public final class SaveStore {
    public init(directory: URL) {}
    public func load() -> (SaveFile, LoadStatus) { (SaveFile.defaults(), .corruptReset) }
    public func save(_ file: SaveFile) throws {}
}
