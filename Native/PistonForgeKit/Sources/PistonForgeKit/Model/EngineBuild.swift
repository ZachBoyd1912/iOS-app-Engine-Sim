import Foundation

/// One complete engine: layout, geometry, induction, fuel, parts, sensors, nitrous and tune.
public struct EngineBuild: Codable, Equatable, Identifiable, Sendable {
    public static let boreRange: ClosedRange<Double> = 60...110
    public static let strokeRange: ClosedRange<Double> = 50...110
    public static let compressionRange: ClosedRange<Double> = 7.5...14
    public static let rodRatioRange: ClosedRange<Double> = 1.4...2.1

    public var id: UUID
    public var name: String
    public var layout: EngineLayout
    /// Bore in mm.
    public var bore: Double
    /// Stroke in mm.
    public var stroke: Double
    public var compression: Double
    /// Connecting rod length divided by stroke.
    public var rodRatio: Double
    public var induction: Induction
    public var fuel: Fuel
    public var parts: PartChoices
    public var sensors: SensorSet
    public var nitrous: NitrousKit?
    public var ecu: ECUMap

    public init(
        id: UUID = UUID(), name: String, layout: EngineLayout, bore: Double, stroke: Double,
        compression: Double, rodRatio: Double, induction: Induction, fuel: Fuel, parts: PartChoices,
        sensors: SensorSet, nitrous: NitrousKit?, ecu: ECUMap
    ) {
        self.id = id
        self.name = name
        self.layout = layout
        self.bore = bore
        self.stroke = stroke
        self.compression = compression
        self.rodRatio = rodRatio
        self.induction = induction
        self.fuel = fuel
        self.parts = parts
        self.sensors = sensors
        self.nitrous = nitrous
        self.ecu = ecu
    }

    // RED stubs below: replaced by the implementation in the next commit.
    public static func starter(_ layout: EngineLayout) -> EngineBuild {
        EngineBuild(
            name: "", layout: layout, bore: 0, stroke: 0, compression: 0, rodRatio: 0, induction: .natural,
            fuel: .pump95, parts: PartChoices(injectorCcMin: 0, pumpLph: 0),
            sensors: SensorSet(maf: nil, map: false, iat: false, wideband: false, knock: false, egt: false, oil: false),
            nitrous: nil, ecu: ECUMap()
        )
    }

    public func sanitized() -> EngineBuild { self }
    public var displacementCc: Double { 0 }
    public var meanPistonSpeedAtRedline: Double { 0 }
    public var mechanicalRedline: Double { 0 }
    public var envelopeMm: (length: Double, width: Double, height: Double) { (0, 0, 0) }
}
