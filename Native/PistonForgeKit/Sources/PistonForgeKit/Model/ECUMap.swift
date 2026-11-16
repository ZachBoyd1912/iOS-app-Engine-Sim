import Foundation

/// The engine's tune: fuel and ignition tables over rpm and load, boost target, limits and the
/// nitrous settings.
///
/// Tables are indexed `[loadIndex][rpmIndex]`: 12 load rows by 16 rpm columns.
public struct ECUMap: Codable, Equatable, Sendable {
    public static let rpmCount = 16
    public static let loadCount = 12
    public static let defaultLoadAxis: [Double] = [20, 40, 60, 80, 100, 120, 140, 170, 200, 230, 260, 300]

    public var rpmAxis: [Double]
    /// Load in kPa (see `loadKpa`).
    public var loadAxis: [Double]
    /// Target air-fuel ratio per cell.
    public var afrTable: [[Double]]
    /// Spark advance per cell, degrees before TDC.
    public var ignitionTable: [[Double]]
    public var boostTargetPsi: Double
    public var revLimit: Double
    public var launchRpm: Double
    public var strategy: FuelStrategy
    /// Throttle positions (0...1) at which an armed nitrous kit may spray.
    public var nitrousWindow: ClosedRange<Double>
    /// Share of a dry kit's fuel the ECU adds through the injectors while it sprays, 0...1.5.
    public var nitrousEnrichment: Double
    /// Timing taken out while nitrous sprays, degrees.
    public var nitrousRetardDeg: Double

    public init(
        rpmAxis: [Double], loadAxis: [Double], afrTable: [[Double]], ignitionTable: [[Double]],
        boostTargetPsi: Double, revLimit: Double, launchRpm: Double, strategy: FuelStrategy,
        nitrousWindow: ClosedRange<Double>, nitrousEnrichment: Double, nitrousRetardDeg: Double
    ) {
        self.rpmAxis = rpmAxis
        self.loadAxis = loadAxis
        self.afrTable = afrTable
        self.ignitionTable = ignitionTable
        self.boostTargetPsi = boostTargetPsi
        self.revLimit = revLimit
        self.launchRpm = launchRpm
        self.strategy = strategy
        self.nitrousWindow = nitrousWindow
        self.nitrousEnrichment = nitrousEnrichment
        self.nitrousRetardDeg = nitrousRetardDeg
    }

    /// A neutral, well-formed map used only while a build is first assembled.
    static let placeholder = ECUMap(
        rpmAxis: (0..<rpmCount).map { 800 + Double($0) * 400 },
        loadAxis: defaultLoadAxis,
        afrTable: Array(repeating: Array(repeating: 12.5, count: rpmCount), count: loadCount),
        ignitionTable: Array(repeating: Array(repeating: 10, count: rpmCount), count: loadCount),
        boostTargetPsi: 0, revLimit: 6000, launchRpm: 4000, strategy: .speedDensity,
        nitrousWindow: 0.9...1, nitrousEnrichment: 0, nitrousRetardDeg: 0
    )

    /// True when the tables have the right shape, every number is finite and the axes rise.
    public var isWellFormed: Bool {
        func rising(_ axis: [Double]) -> Bool {
            axis.allSatisfy(\.isFinite) && zip(axis, axis.dropFirst()).allSatisfy { $0 < $1 }
        }
        func shaped(_ table: [[Double]]) -> Bool {
            table.count == Self.loadCount && table.allSatisfy { $0.count == Self.rpmCount && $0.allSatisfy(\.isFinite) }
        }
        return rpmAxis.count == Self.rpmCount && loadAxis.count == Self.loadCount
            && rising(rpmAxis) && rising(loadAxis) && shaped(afrTable) && shaped(ignitionTable)
            && [boostTargetPsi, revLimit, launchRpm, nitrousEnrichment, nitrousRetardDeg].allSatisfy(\.isFinite)
            && nitrousWindow.lowerBound.isFinite && nitrousWindow.upperBound.isFinite
    }

    /// Bilinear lookup in `table`, clamped at the edges. Returns NaN for a map whose shape is
    /// wrong (never traps); callers' bounds then fall back to safe values.
    public func value(_ table: KeyPath<ECUMap, [[Double]]>, rpm: Double, loadKpa: Double) -> Double {
        let cells = self[keyPath: table]
        guard rpmAxis.count >= 2, loadAxis.count >= 2, cells.count == loadAxis.count,
              cells.allSatisfy({ $0.count == rpmAxis.count }) else { return .nan }
        let (i, fx) = Self.locate(rpmAxis, rpm)
        let (j, fy) = Self.locate(loadAxis, loadKpa)
        let low = cells[j][i] + (cells[j][i + 1] - cells[j][i]) * fx
        let high = cells[j + 1][i] + (cells[j + 1][i + 1] - cells[j + 1][i]) * fx
        return low + (high - low) * fy
    }

    /// Index of the cell below `x` and the fraction across it.
    private static func locate(_ axis: [Double], _ x: Double) -> (Int, Double) {
        let value = x.isFinite ? min(max(x, axis[0]), axis[axis.count - 1]) : axis[0]
        var index = 0
        while index < axis.count - 2, axis[index + 1] < value { index += 1 }
        let span = axis[index + 1] - axis[index]
        let fraction = span > 0 ? (value - axis[index]) / span : 0
        return (index, min(max(fraction, 0), 1))
    }

    /// The same map with every number in a safe range; a malformed map is replaced by the
    /// auto-base tune for `build`.
    func sanitized(for build: EngineBuild) -> ECUMap {
        guard isWellFormed else { return ECUMap.autoBase(for: build) }
        var clean = self
        clean.afrTable = afrTable.map { $0.map { min(max($0, 6), 20) } }
        clean.ignitionTable = ignitionTable.map { $0.map { min(max($0, -10), 50) } }
        clean.boostTargetPsi = min(max(boostTargetPsi, 0), 45)
        clean.revLimit = min(max(revLimit, 3000), 11_000)
        clean.launchRpm = min(max(launchRpm, 1500), clean.revLimit)
        let low = min(max(nitrousWindow.lowerBound, 0), 1)
        let high = min(max(nitrousWindow.upperBound, low), 1)
        clean.nitrousWindow = low...high
        clean.nitrousEnrichment = min(max(nitrousEnrichment, 0), 1.5)
        clean.nitrousRetardDeg = min(max(nitrousRetardDeg, 0), 30)
        return clean
    }
}

extension ECUMap {
    /// Lambda (AFR over stoichiometric) the auto-base tune targets at this load: stoichiometric
    /// cruising, 0.86 at wide-open throttle, richening to 0.78 under 100 kPa of boost.
    static func baseLambda(loadKpa: Double) -> Double {
        if loadKpa <= 60 { return 1 }
        if loadKpa <= 100 { return 1 + (loadKpa - 60) / 40 * (0.86 - 1) }
        return 0.86 - 0.08 * min(1, (loadKpa - 100) / 100)
    }

    /// Most turbo boost (0.5 psi steps) that keeps at least 8° of knock-limited timing at low,
    /// middle and top rpm, and stays 2 psi under the head gasket's limit.
    static func knockLimitedBoost(for b: EngineBuild) -> Double {
        guard case .turbo(let size) = b.induction else { return 0 }
        let gasket = PartChoices.gasketBoostLimitPsi[min(max(b.parts.gasket, 0), PartChoices.gasketBoostLimitPsi.count - 1)]
        var best = 0.0
        var psi = 0.0
        while psi <= min(size.maxPsi, gasket - 2) {
            let safe = [0.3, 0.6, 1.0].allSatisfy { fraction in
                let rpm = b.mechanicalRedline * fraction
                let heat = chargeTempC(b, boostPsi: psi)
                let air = airflowGps(b, rpm: rpm, throttle: 1, boostPsi: psi, chargeTempC: heat)
                let load = loadKpa(b, rpm: rpm, airflowGps: air)
                return knockLimitDegrees(b, rpm: rpm, loadKpa: load, iatC: heat, nitrousHpPerCylinder: 0) >= 8
            }
            if !safe { break }
            best = psi
            psi += 0.5
        }
        return best
    }

    /// Most turbo boost (0.5 psi steps) the installed injectors and pump can fuel at redline.
    static func fuelLimitedBoost(for b: EngineBuild, upTo limit: Double) -> Double {
        var best = 0.0
        var psi = 0.0
        while psi <= limit {
            let needs = fuelSystemNeeds(b, boostPsi: psi)
            if needs.injectorCcMin > b.parts.injectorCcMin + 0.5 || needs.pumpLph > b.parts.pumpLph + 0.5 { break }
            best = psi
            psi += 0.5
        }
        return best
    }

    /// A safe starting tune for `b`, as a tuner would load before the first pull.
    ///
    /// - Fuel: λ from `baseLambda` for the fuel in use.
    /// - Ignition: MBT, or 2° under the knock limit where that is lower, at the charge
    ///   temperature each load implies.
    /// - Boost: turbo target capped by knock, the head gasket and the installed fuel system.
    /// - Strategy: MAF when its sensor reads the engine's peak airflow; otherwise speed-density
    ///   if a MAP sensor is fitted.
    /// - Nitrous: a dry kit gets full enrichment; any kit gets timing taken out for its shot.
    public static func autoBase(for b: EngineBuild) -> ECUMap {
        let redline = b.mechanicalRedline
        let rpmAxis = (0..<rpmCount).map { 800 + (redline + 300 - 800) * Double($0) / Double(rpmCount - 1) }
        let loadAxis = defaultLoadAxis
        let stoich = b.fuel.spec.stoichAfr

        let afr = loadAxis.map { load in Array(repeating: baseLambda(loadKpa: load) * stoich, count: rpmCount) }
        let ignition = loadAxis.map { load in
            rpmAxis.map { rpm in
                // The boost that produces this load, and the charge heat that comes with it.
                let psi = max(0, (load / 101.3 - 1) * 14.7)
                let heat = chargeTempC(b, boostPsi: psi)
                let limit = knockLimitDegrees(b, rpm: rpm, loadKpa: load, iatC: heat, nitrousHpPerCylinder: 0)
                return min(max(min(mbtDegrees(b, rpm: rpm, loadKpa: load), limit - 2), 0), 45)
            }
        }

        let knockBoost = knockLimitedBoost(for: b)
        let target = fuelLimitedBoost(for: b, upTo: knockBoost)

        let peakBoost = steadyBoostPsi(b, rpm: redline, throttle: 1, target: target)
        let peakAir = airflowGps(b, rpm: redline, throttle: 1, boostPsi: peakBoost, chargeTempC: chargeTempC(b, boostPsi: peakBoost))
        let strategy: FuelStrategy
        if let maf = b.sensors.maf, peakAir <= maf.maxGps || !b.sensors.map {
            strategy = .maf
        } else {
            strategy = .speedDensity
        }

        var enrichment = 0.0
        var retard = 0.0
        if let kit = b.nitrous {
            enrichment = kit.kind == .dry ? 1 : 0
            retard = bounded(kit.shotHp, NitrousKit.shotRange, or: 100) / Double(b.layout.spec.cylinders) * 0.4 + 1
        }
        return ECUMap(
            rpmAxis: rpmAxis, loadAxis: loadAxis, afrTable: afr, ignitionTable: ignition,
            boostTargetPsi: target, revLimit: redline, launchRpm: min(4000, redline - 500),
            strategy: strategy, nitrousWindow: 0.9...1, nitrousEnrichment: enrichment, nitrousRetardDeg: retard
        )
    }
}
