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

    /// Stock bore, stroke (mm) and compression for each layout.
    static func stockGeometry(_ layout: EngineLayout) -> (bore: Double, stroke: Double, compression: Double) {
        switch layout {
        case .i2: (90, 90, 10)
        case .i5: (82, 90, 10)
        case .i8: (86, 86, 10)
        case .v2: (100, 95, 9.5)
        case .flat4: (92, 75, 10)
        case .flat6: (97, 76.4, 10)
        case .i3: (75, 84, 10.5)
        case .i4: (86, 86, 10)
        case .i6: (86, 86, 10)
        case .v6_60: (89, 80, 10)
        case .v6_90: (96, 86, 9.5)
        case .v8Cross: (101.6, 92, 10)
        case .v8Flat: (94, 72, 11)
        case .v10: (92, 75, 11)
        case .v12: (89, 80, 10.5)
        case .w16: (86, 86, 9)
        }
    }

    /// Stock injector (cc/min) and pump (L/h): injectors with headroom for the stock engine,
    /// a pump that feeds them with margin.
    static func stockFuelSystem(_ layout: EngineLayout) -> (injector: Double, pump: Double) {
        let geometry = stockGeometry(layout)
        let perCylinderCc = Double.pi / 4 * geometry.bore * geometry.bore * geometry.stroke / 1000
        let injector = (perCylinderCc * 0.65 / 10).rounded() * 10
        let pump = (max(190, injector * Double(layout.spec.cylinders) * 60 / 1000 * 1.5) / 5).rounded() * 5
        return (injector, pump)
    }

    /// A sensible stock, naturally aspirated build for each layout, on its auto-base tune:
    /// the engine the app opens on.
    public static func starter(_ layout: EngineLayout) -> EngineBuild {
        let geometry = stockGeometry(layout)
        let fuelSystem = stockFuelSystem(layout)
        var build = EngineBuild(
            name: "",
            layout: layout,
            bore: geometry.bore,
            stroke: geometry.stroke,
            compression: geometry.compression,
            rodRatio: 1.65,
            induction: .natural,
            fuel: .pump95,
            parts: PartChoices(injectorCcMin: fuelSystem.injector, pumpLph: fuelSystem.pump),
            sensors: SensorSet(maf: nil, map: true, iat: true, wideband: false, knock: true, egt: false, oil: true),
            nitrous: nil,
            ecu: .placeholder
        )
        // Smallest MAF that reads the stock engine's peak airflow (about 1.2 g per litre per
        // intake stroke) with 15% to spare.
        let peakAirGps = build.displacementCc / 1000 * build.mechanicalRedline / 120 * 1.2
        build.sensors.maf = MafSize.allCases.first { $0.maxGps >= peakAirGps * 1.15 } ?? .xl
        build.name = "\(layout.spec.name) \(String(format: "%.1f", build.displacementCc / 1000))"
        build.ecu = ECUMap.autoBase(for: build)
        return build
    }

    /// The same build with every number inside its safe range. Non-numbers (NaN, infinity),
    /// from a corrupt save or a bad slider, fall back to the stock value for the layout. A
    /// malformed tune is replaced by the auto-base tune for the cleaned build.
    public func sanitized() -> EngineBuild {
        let geometry = Self.stockGeometry(layout)
        let fuelSystem = Self.stockFuelSystem(layout)
        var clean = self
        clean.bore = Self.clamp(bore, Self.boreRange, fallback: geometry.bore)
        clean.stroke = Self.clamp(stroke, Self.strokeRange, fallback: geometry.stroke)
        clean.compression = Self.clamp(compression, Self.compressionRange, fallback: geometry.compression)
        clean.rodRatio = Self.clamp(rodRatio, Self.rodRatioRange, fallback: 1.65)
        if case .supercharger(let kind, let pulley) = induction {
            clean.induction = .supercharger(kind, pulley: Self.clamp(pulley, SuperchargerKind.pulleyRange, fallback: 1))
        }
        let levels = 0...PartChoices.maxLevel
        let paths: [WritableKeyPath<PartChoices, Int>] = [\.head, \.cams, \.intake, \.exhaust, \.internals, \.valves, \.gasket, \.intercooler]
        for path in paths {
            clean.parts[keyPath: path] = min(max(parts[keyPath: path], levels.lowerBound), levels.upperBound)
        }
        clean.parts.injectorCcMin = Self.clamp(parts.injectorCcMin, PartChoices.injectorRange, fallback: fuelSystem.injector)
        clean.parts.pumpLph = Self.clamp(parts.pumpLph, PartChoices.pumpRange, fallback: fuelSystem.pump)
        if var kit = nitrous {
            kit.shotHp = Self.clamp(kit.shotHp, NitrousKit.shotRange, fallback: 100)
            kit.armRpm = Self.clamp(kit.armRpm, NitrousKit.armRpmRange, fallback: 3000)
            clean.nitrous = kit
        }
        clean.ecu = ecu.sanitized(for: clean)
        return clean
    }

    static func clamp(_ value: Double, _ range: ClosedRange<Double>, fallback: Double) -> Double {
        guard value.isFinite else { return fallback }
        return min(max(value, range.lowerBound), range.upperBound)
    }

    /// Swept volume in cc: pi/4 x bore^2 x stroke x cylinders (mm to cc).
    public var displacementCc: Double {
        Double.pi / 4 * bore * bore * stroke * Double(layout.spec.cylinders) / 1000
    }

    /// Mean piston speed at the mechanical redline, m/s.
    public var meanPistonSpeedAtRedline: Double {
        2 * stroke / 1000 * mechanicalRedline / 60
    }

    /// Safe mean piston speed: 20 m/s on stock internals, 1.5 m/s more per upgrade level.
    var safePistonSpeed: Double { 20 + 1.5 * Double(parts.internals) }

    /// Highest safe rpm, set by piston speed and rounded down to 50 rpm, within 5000-10000.
    public var mechanicalRedline: Double {
        let raw = safePistonSpeed * 60 / (2 * max(stroke, 1) / 1000)
        return min(max((raw / 50).rounded(.down) * 50, 5000), 10000)
    }

    /// Outside size of the engine with its induction, in mm, for fitting it in a car's bay.
    public var envelopeMm: (length: Double, width: Double, height: Double) {
        let spec = layout.spec
        let pitch = bore + 12
        let perBank = Double(spec.cylinders / max(spec.banks, 1))
        let length = perBank * pitch + (spec.banks > 1 ? pitch / 2 : 0) + 260
        // Crank centre to the top of the head along one bank.
        let deck = stroke * rodRatio + stroke / 2 + bore * 0.6 + 120
        var width: Double
        var height: Double
        if spec.banks == 1 {
            width = 420 + stroke * 1.2
            height = deck + stroke + 180
        } else {
            let half = spec.bankAngle / 2 * Double.pi / 180
            width = 2 * deck * sin(half) + 380 + (spec.banks > 2 ? 220 : 0)
            height = deck * cos(half) + stroke + 220
        }
        switch induction {
        case .natural: break
        case .turbo(let size): width += size == .twin ? 260 : 180
        case .supercharger(.centrifugal, _): width += 160
        case .supercharger: height += 200
        }
        return (length, width, height)
    }
}
