import Foundation

/// The thermodynamic cycle an engine runs, as far as the catalogue is concerned.
///
/// `EngineSim` models a four-stroke, 720-degree cycle. Anything in another cycle is catalogued
/// (the research has it) but cannot be played until a cycle-aware simulator exists.
public enum EngineCycle: String, Sendable, CaseIterable {
    case fourStroke
    case twoStroke
    case rotary
    case turbine
    case electric
}

/// Mechanical family, which decides what has to be modelled in 3D and how the crank is built.
public enum EngineFamily: String, Sendable, CaseIterable {
    case pistonInline
    case pistonV
    case pistonFlat
    case pistonW
    case radial
    /// Rotary piston engine: cylinders and crankcase revolve around a fixed crankpin.
    case rotaryCrankcase
    /// Wankel: no pistons, no valves, an eccentric shaft and rotors.
    case wankel
    case turbine
    case electric
}

/// A firing order and how well it is evidenced.
///
/// This is the honesty record for the catalogue: a row is never `.sourced` without a citation,
/// and `.notSourced` is never filled in with a guess. `cylinders` stays `nil` when the source
/// states the order in a notation that cannot be translated to plain 1..n numbers without
/// knowing the source's numbering convention (bank-lettered orders, or two equally valid
/// alternatives), so the verbatim `text` never loses information.
public struct FiringOrderRecord: Sendable, Equatable {
    public enum Status: String, Sendable, CaseIterable {
        /// The source states the sequence.
        case sourced
        /// The research (or this catalogue) derives the sequence from stated crank or wire timing.
        case derived
        /// No sequence was found. Never guessed.
        case notSourced
        /// The architecture has no firing order (single cylinder, rotary, turbine, electric).
        case notApplicable
    }

    public let status: Status
    /// Cylinder numbers in firing order, 1-based, when a plain numeric sequence is available.
    public let cylinders: [Int]?
    /// What the research actually says, kept close to verbatim.
    public let text: String
    /// Research source tags (for example "S2, E10, E19").
    public let source: String

    public init(status: Status, cylinders: [Int]?, text: String, source: String) {
        self.status = status
        self.cylinders = cylinders
        self.text = text
        self.source = source
    }
}

extension FiringOrderRecord {
    public static func sourced(_ cylinders: [Int]?, _ text: String, source: String) -> FiringOrderRecord {
        FiringOrderRecord(status: .sourced, cylinders: cylinders, text: text, source: source)
    }

    public static func derived(_ cylinders: [Int]?, _ text: String, source: String) -> FiringOrderRecord {
        FiringOrderRecord(status: .derived, cylinders: cylinders, text: text, source: source)
    }

    public static func notSourced(_ text: String = "Not sourced", source: String = "none") -> FiringOrderRecord {
        FiringOrderRecord(status: .notSourced, cylinders: nil, text: text, source: source)
    }

    public static func notApplicable(_ text: String) -> FiringOrderRecord {
        FiringOrderRecord(status: .notApplicable, cylinders: nil, text: text, source: "definition")
    }
}

/// What stands between a catalogue row and being playable in this build.
public enum Playability: Sendable, Equatable {
    /// Shipped today: the row maps onto an `EngineLayout` case.
    case playable(EngineLayout)
    /// A four-stroke piston design whose order is known, but no sourced bore and stroke, so a
    /// stock build would have to invent geometry. Held back deliberately.
    case blockedOnGeometry
    /// A four-stroke piston design the simulator could run once its order is sourced.
    case blockedOnFiringOrder
    /// Wrong cycle or no piston mechanism: the current model and 3D kit do not describe it.
    case unsupportedArchitecture
}

/// One row of the researched engine catalogue (`docs/research/raw/engines.md`, 83 rows).
///
/// Every field is quoted from the research or marked as absent. Nothing here is rounded into
/// a nicer-looking number: `displacement` and `redline` keep the research's own "(calc)" and
/// "(unverified)" qualifiers so a design choice can never be mistaken for a sourced figure.
public struct EngineCatalogEntry: Identifiable, Sendable, Equatable {
    /// The research row ID, 1...83.
    public let id: Int
    public let name: String
    /// `nil` where the source does not state a cylinder count.
    public let cylinders: Int?
    public let family: EngineFamily
    /// Bank angle in degrees, `nil` where the source gives a range or says nothing.
    public let bankAngle: Double?
    public let cycle: EngineCycle
    public let firingOrder: FiringOrderRecord
    /// The research's firing-interval cell.
    public let interval: String
    public let displacement: String
    public let redline: String
    public let aspiration: String
    public let valvetrain: String
    /// Real engines named in the research. Reference data only: never shown in the app.
    public let examples: [String]
    /// Research source tags.
    public let sources: [String]
    public let playability: Playability

    public init(
        id: Int,
        name: String,
        cylinders: Int?,
        family: EngineFamily,
        cycle: EngineCycle,
        bankAngle: Double? = nil,
        firingOrder: FiringOrderRecord,
        interval: String,
        displacement: String = "not sourced",
        redline: String = "not sourced",
        aspiration: String = "NA",
        valvetrain: String = "not sourced",
        examples: [String] = [],
        sources: [String],
        playability: Playability
    ) {
        self.id = id
        self.name = name
        self.cylinders = cylinders
        self.family = family
        self.cycle = cycle
        self.bankAngle = bankAngle
        self.firingOrder = firingOrder
        self.interval = interval
        self.displacement = displacement
        self.redline = redline
        self.aspiration = aspiration
        self.valvetrain = valvetrain
        self.examples = examples
        self.sources = sources
        self.playability = playability
    }
}

/// The researched catalogue, transcribed from `docs/research/raw/engines.md`.
///
/// This is a data layer beside `EngineLayout`, not a replacement for it. `EngineLayout` is the
/// set of layouts the simulation, sound and 3D code can actually run; this is everything the
/// research found, with the evidence for each row. Keeping them apart means a row can be
/// catalogued without pretending it is playable, and a playable layout cannot appear without
/// its evidence.
public enum EngineCatalog {
    public static let all: [EngineCatalogEntry] = rows

    public static func entry(id: Int) -> EngineCatalogEntry? {
        all.first { $0.id == id }
    }

    public static func entries(for layout: EngineLayout) -> [EngineCatalogEntry] {
        all.filter { $0.playability == .playable(layout) }
    }

    /// Every layout the catalogue says is playable, in catalogue order, without duplicates.
    public static var playableLayouts: [EngineLayout] {
        var seen = Set<EngineLayout>()
        var result: [EngineLayout] = []
        for entry in all {
            guard case .playable(let layout) = entry.playability, seen.insert(layout).inserted else { continue }
            result.append(layout)
        }
        return result
    }

    public static var playableCount: Int {
        all.reduce(0) { total, entry in
            if case .playable = entry.playability { return total + 1 }
            return total
        }
    }

    public static var blockedOnGeometryCount: Int { count { $0.playability == .blockedOnGeometry } }
    public static var blockedOnFiringOrderCount: Int { count { $0.playability == .blockedOnFiringOrder } }
    public static var unsupportedArchitectureCount: Int { count { $0.playability == .unsupportedArchitecture } }

    public static var sourcedOrderCount: Int { count { $0.firingOrder.status == .sourced } }
    public static var derivedOrderCount: Int { count { $0.firingOrder.status == .derived } }
    public static var notApplicableOrderCount: Int { count { $0.firingOrder.status == .notApplicable } }
    public static var unsourcedOrderCount: Int { count { $0.firingOrder.status == .notSourced } }

    private static func count(_ include: (EngineCatalogEntry) -> Bool) -> Int {
        all.reduce(0) { total, entry in total + (include(entry) ? 1 : 0) }
    }
}

// MARK: - The 83 rows

extension EngineCatalog {
    private static let rows: [EngineCatalogEntry] = [
        EngineCatalogEntry(
            id: 1, name: "Single (I1)", cylinders: 1, family: .pistonInline, cycle: .fourStroke,
            firingOrder: .notApplicable("one cylinder: no firing order exists"),
            interval: "720 deg",
            displacement: "518 cc (calc, E11); 0.1-1.0 L (unverified)",
            redline: "5000 rpm (E11)",
            valvetrain: "one intake and one exhaust cam (E11); OHV or OHC not stated",
            examples: ["Honda TRX520 ATV"],
            sources: ["E11"],
            playability: .blockedOnGeometry
        ),
        EngineCatalogEntry(
            id: 2, name: "Parallel twin 180", cylinders: 2, family: .pistonInline, cycle: .fourStroke,
            firingOrder: .derived([1, 2], "second cylinder fires 180 deg after the first, then a 540 deg gap", source: "S9"),
            interval: "180 / 540",
            displacement: "0.4-1.0 L (unverified)",
            examples: ["Honda CB450"],
            sources: ["S9"],
            playability: .blockedOnGeometry
        ),
        EngineCatalogEntry(
            id: 3, name: "Parallel twin 270", cylinders: 2, family: .pistonInline, cycle: .fourStroke,
            firingOrder: .derived([1, 2], "second cylinder fires 270 deg after the first, then a 450 deg gap", source: "S9"),
            interval: "270 / 450",
            examples: ["Yamaha TRX850", "Norton Commando 961", "Triumph Thruxton 1200"],
            sources: ["S9"],
            playability: .blockedOnGeometry
        ),
        EngineCatalogEntry(
            id: 4, name: "Parallel twin 360", cylinders: 2, family: .pistonInline, cycle: .fourStroke,
            firingOrder: .derived([1, 2], "even: one firing per crank revolution, 360 deg apart", source: "S9"),
            interval: "360 deg",
            examples: ["Honda CB92 (1965)", "Yamaha XS650"],
            sources: ["S9"],
            playability: .playable(.i2)
        ),
        EngineCatalogEntry(
            id: 5, name: "Inline-3 (120 crank)", cylinders: 3, family: .pistonInline, cycle: .fourStroke,
            firingOrder: .sourced([1, 3, 2], "1-3-2 (diagram caption)", source: "S8"),
            interval: "240 deg (derived)",
            displacement: "0.7-1.2 L (unverified)",
            examples: ["Triumph 765 Moto2 triple", "Suzuki Fronte 360 (two-stroke, 256 cc)"],
            sources: ["S8"],
            playability: .playable(.i3)
        ),
        EngineCatalogEntry(
            id: 6, name: "Inline-3 (180 crank)", cylinders: 3, family: .pistonInline, cycle: .fourStroke,
            firingOrder: .notSourced("crank stated (180 deg, outer pistons together); no sequence found"),
            interval: "Not sourced",
            examples: ["Laverda Jota (1976-81)"],
            sources: ["S8"],
            playability: .blockedOnFiringOrder
        ),
        EngineCatalogEntry(
            id: 7, name: "Inline-3 T-plane", cylinders: 3, family: .pistonInline, cycle: .fourStroke,
            firingOrder: .notSourced("crank stated (T-plane, throws at 90 deg, 1 and 3 at 180); no sequence found"),
            interval: "Not sourced",
            examples: ["Triumph Tiger 900 (2020)"],
            sources: ["S8"],
            playability: .blockedOnFiringOrder
        ),
        EngineCatalogEntry(
            id: 8, name: "Inline-4 (180 crank)", cylinders: 4, family: .pistonInline, cycle: .fourStroke,
            firingOrder: .sourced(
                [1, 3, 4, 2],
                "1-3-4-2 (typical); engine-sim labels the same sequence as 1-2-4-3",
                source: "S2, E14, E15"
            ),
            interval: "180 deg",
            displacement: "1.3-2.5 L (unverified); 1797 cc (calc, E15); 1340 cc (calc, E14)",
            redline: "8400 rpm (E15); 11000 rpm (E14)",
            valvetrain: "DOHC; E15 has VTEC with standard and VTEC cam sets; E14 has separate intake and exhaust cams",
            examples: ["Honda B18C5 VTEC", "Suzuki Hayabusa I4"],
            sources: ["S2", "E14", "E15"],
            playability: .playable(.i4)
        ),
        EngineCatalogEntry(
            id: 9, name: "Inline-4 crossplane (R1 style)", cylinders: 4, family: .pistonInline, cycle: .fourStroke,
            firingOrder: .notSourced("page title states an uneven order only; no sequence found"),
            interval: "Not sourced",
            displacement: "998 cc (S17)",
            redline: "13750 rpm rev limiter (S17)",
            valvetrain: "DOHC, 16 valves (S17)",
            examples: ["Yamaha YZF-R1 (2009 onward)"],
            sources: ["S17"],
            playability: .blockedOnFiringOrder
        ),
        EngineCatalogEntry(
            id: 10, name: "Inline-5", cylinders: 5, family: .pistonInline, cycle: .fourStroke,
            firingOrder: .derived([1, 2, 4, 5, 3], "derived from 72 deg rod journals", source: "E18"),
            interval: "144 deg",
            displacement: "2.2 L (calc, E18)",
            redline: "7500 rpm (E18)",
            valvetrain: "standard cam, 110 deg lobe separation (E18)",
            examples: ["Audi 2.2 inline-5"],
            sources: ["E18"],
            playability: .playable(.i5)
        ),
        EngineCatalogEntry(
            id: 11, name: "Inline-6", cylinders: 6, family: .pistonInline, cycle: .fourStroke,
            firingOrder: .sourced([1, 5, 3, 6, 2, 4], "1-5-3-6-2-4", source: "S2, E10, E19"),
            interval: "120 deg",
            displacement: "2.8 L (calc, E19); 3.0 L (calc, E10)",
            redline: "6000 rpm (E10); 7000 rpm (E19)",
            valvetrain: "DOHC; E10 intake and exhaust cams with 116 deg lobe centres",
            examples: ["Toyota 2JZ", "BMW M52B28"],
            sources: ["S2", "E10", "E19"],
            playability: .playable(.i6)
        ),
        EngineCatalogEntry(
            id: 12, name: "Inline-8", cylinders: 8, family: .pistonInline, cycle: .fourStroke,
            firingOrder: .sourced([1, 4, 7, 3, 8, 5, 2, 6], "1-4-7-3-8-5-2-6 (diagram caption)", source: "S22"),
            interval: "90 deg (derived)",
            examples: ["Bugatti Type 35 (2 L)", "Alfa Romeo 158 (1.5 L supercharged)", "Duesenberg 3 L"],
            sources: ["S22"],
            playability: .playable(.i8)
        ),
        EngineCatalogEntry(
            id: 13, name: "V-twin 45", cylinders: 2, family: .pistonV, cycle: .fourStroke, bankAngle: 45,
            firingOrder: .derived([1, 2], "wire offsets 0 and 315 deg give firings 315 then 405 deg", source: "E13"),
            interval: "315 / 405",
            displacement: "1340 cc (calc, E13)",
            redline: "5000 rpm, rev limit 5500 (E13)",
            valvetrain: "cam lobe 210 deg, 400 thou lift (E13); OHV pushrod in real life (unverified)",
            examples: ["Harley-Davidson Shovelhead", "Honda VT1100"],
            sources: ["E13", "S10"],
            playability: .blockedOnGeometry
        ),
        EngineCatalogEntry(
            id: 14, name: "V-twin 60", cylinders: 2, family: .pistonV, cycle: .fourStroke, bankAngle: 60,
            firingOrder: .notSourced("single shared crankpin stated; no sequence found"),
            interval: "Not sourced",
            examples: ["Harley-Davidson VRSC", "Indian Scout"],
            sources: ["S10"],
            playability: .blockedOnFiringOrder
        ),
        EngineCatalogEntry(
            id: 15, name: "V-twin 75", cylinders: 2, family: .pistonV, cycle: .fourStroke, bankAngle: 75,
            firingOrder: .notSourced("crank stated (75 deg pin offset; 45 deg in the US on the VX800); no sequence found"),
            interval: "Not sourced",
            examples: ["KTM 1190 RC8", "Yamaha Virago"],
            sources: ["S10"],
            playability: .blockedOnFiringOrder
        ),
        EngineCatalogEntry(
            id: 16, name: "V-twin 90", cylinders: 2, family: .pistonV, cycle: .fourStroke, bankAngle: 90,
            firingOrder: .derived([1, 2], "270 then 450 deg, uneven", source: "S10"),
            interval: "270 / 450",
            displacement: "747 cc (calc, E12)",
            redline: "3600 rpm, rev limit 5000 (E12)",
            valvetrain: "generic small-engine head, 160 deg duration at 50 thou (E12)",
            examples: ["Kohler CH750", "Ducati", "Moto Guzzi", "Honda RC51"],
            sources: ["S10", "E12"],
            playability: .playable(.v2)
        ),
        EngineCatalogEntry(
            id: 17, name: "V-twin 120 (offset cranks)", cylinders: 2, family: .pistonV, cycle: .fourStroke, bankAngle: 120,
            firingOrder: .derived([1, 2], "firing at 180 deg, on a 180 deg crankpin offset", source: "S10"),
            interval: "180 deg",
            displacement: "500 cc (S10, racer)",
            examples: ["Moto Guzzi 1935 racer"],
            sources: ["S10"],
            playability: .blockedOnGeometry
        ),
        EngineCatalogEntry(
            id: 18, name: "V4 60 (split crankpins)", cylinders: 4, family: .pistonV, cycle: .fourStroke, bankAngle: 60,
            firingOrder: .notSourced("even firing states, but no specific order given"),
            interval: "180 deg (derived)",
            examples: ["Ford Taunus", "Ford Essex"],
            sources: ["S26"],
            playability: .blockedOnFiringOrder
        ),
        EngineCatalogEntry(
            id: 19, name: "V4 90 (shared crankpins)", cylinders: 4, family: .pistonV, cycle: .fourStroke, bankAngle: 90,
            firingOrder: .notSourced("fires unevenly; no specific order given"),
            interval: "Not sourced",
            displacement: "2.0 L turbo (Porsche 919 Hybrid)",
            aspiration: "turbo (Porsche 919)",
            examples: ["Porsche 919 Hybrid", "Honda and Aprilia motorcycles"],
            sources: ["S26"],
            playability: .blockedOnFiringOrder
        ),
        EngineCatalogEntry(
            id: 20, name: "V4 narrow (16-20 deg)", cylinders: 4, family: .pistonV, cycle: .fourStroke,
            firingOrder: .notSourced("no sequence found"),
            interval: "Not sourced",
            examples: ["Lancia (20 deg)", "Matchless Silver Hawk (16 deg)"],
            sources: ["S26"],
            playability: .blockedOnFiringOrder
        ),
        EngineCatalogEntry(
            id: 21, name: "V4 wide (170 deg)", cylinders: 4, family: .pistonV, cycle: .fourStroke, bankAngle: 170,
            firingOrder: .notSourced("no sequence found"),
            interval: "Not sourced",
            examples: ["Puch P800"],
            sources: ["S26"],
            playability: .blockedOnFiringOrder
        ),
        EngineCatalogEntry(
            id: 22, name: "V6 60", cylinders: 6, family: .pistonV, cycle: .fourStroke, bankAngle: 60,
            firingOrder: .sourced(
                [1, 2, 3, 4, 5, 6],
                "alternating banks R1-L1-R2-L2-R3-L3; engine-sim wires at 120 deg",
                source: "S2, E1"
            ),
            interval: "120 deg",
            displacement: "3.3 L (calc, E1)",
            redline: "5500 rpm, rev limit 5600 (E1)",
            valvetrain: "two cams per bank, intake and exhaust (E1)",
            examples: ["GMC V6 305", "Toyota 1GR-FE 4.0 L"],
            sources: ["S27", "E1", "S2"],
            playability: .playable(.v6_60)
        ),
        EngineCatalogEntry(
            id: 23, name: "V6 65 (Ferrari Dino)", cylinders: 6, family: .pistonV, cycle: .fourStroke, bankAngle: 65,
            firingOrder: .notSourced("crankpins offset 55 deg within pairs; no sequence found"),
            interval: "120 deg (even firing)",
            examples: ["Ferrari Dino"],
            sources: ["S27"],
            playability: .blockedOnFiringOrder
        ),
        EngineCatalogEntry(
            id: 24, name: "V6 72 (OM642)", cylinders: 6, family: .pistonV, cycle: .fourStroke, bankAngle: 72,
            firingOrder: .notSourced("crankpins offset 48 deg; no sequence found"),
            interval: "Even",
            examples: ["Mercedes-Benz OM642"],
            sources: ["S27"],
            playability: .blockedOnFiringOrder
        ),
        EngineCatalogEntry(
            id: 25, name: "V6 75", cylinders: 6, family: .pistonV, cycle: .fourStroke, bankAngle: 75,
            firingOrder: .notSourced("no sequence found"),
            interval: "Not sourced",
            examples: ["Isuzu V engine", "Honda NSX"],
            sources: ["S27"],
            playability: .blockedOnFiringOrder
        ),
        EngineCatalogEntry(
            id: 26, name: "V6 90 (even fire)", cylinders: 6, family: .pistonV, cycle: .fourStroke, bankAngle: 90,
            firingOrder: .sourced(
                [1, 6, 5, 4, 3, 2],
                "1-6-5-4-3-2; split rod journals rj1/rj3/rj5 at -30 deg",
                source: "E3, S11"
            ),
            interval: "120 deg",
            displacement: "3.3 L (calc, E3)",
            redline: "5500 rpm (E3)",
            valvetrain: "two cams per bank (E3)",
            examples: ["Audi 2.8 V6 (90 deg)", "Renault-Gordini CH1", "Rover KV6"],
            sources: ["E3", "S27"],
            playability: .blockedOnGeometry
        ),
        EngineCatalogEntry(
            id: 27, name: "V6 90 (odd fire)", cylinders: 6, family: .pistonV, cycle: .fourStroke, bankAngle: 90,
            firingOrder: .notSourced(
                "wires at 0/150/240/390/480/630 deg, so firings alternate 150/90; cylinder-to-angle mapping not stated"
            ),
            interval: "150 / 90",
            displacement: "3.3 L (calc, E2)",
            redline: "5500 rpm (E2)",
            valvetrain: "two cams per bank (E2)",
            examples: ["Generic odd-fire V6"],
            sources: ["E2", "S27"],
            playability: .playable(.v6_90)
        ),
        EngineCatalogEntry(
            id: 28, name: "VR6", cylinders: 6, family: .pistonV, cycle: .fourStroke, bankAngle: 15,
            firingOrder: .sourced([1, 5, 3, 6, 2, 4], "1-5-3-6-2-4", source: "S11"),
            interval: "120 deg",
            displacement: "2.8 L (128 kW 12-valve; 150 kW 24-valve)",
            valvetrain: "12-valve (2 per cylinder) and 24-valve (4 per cylinder) versions",
            examples: ["Volkswagen VR6 (2.8, 2.9, 3.2, 3.6)"],
            sources: ["S11"],
            playability: .blockedOnGeometry
        ),
        EngineCatalogEntry(
            id: 29, name: "VR5", cylinders: 5, family: .pistonV, cycle: .fourStroke,
            firingOrder: .notSourced("no sequence found"),
            interval: "Not sourced",
            examples: ["VW VR5"],
            sources: ["S11"],
            playability: .blockedOnFiringOrder
        ),
        EngineCatalogEntry(
            id: 30, name: "V8 cross-plane 90", cylinders: 8, family: .pistonV, cycle: .fourStroke, bankAngle: 90,
            firingOrder: .sourced(
                [1, 8, 7, 2, 6, 5, 4, 3],
                "1-8-7-2-6-5-4-3; usual cross-plane bank pattern L-R-L-L-R-L-R-R",
                source: "E4, S28"
            ),
            interval: "90 deg; exhaust pulses uneven",
            displacement: "5.3 L (calc, E4); 7.4 L (calc, E20)",
            redline: "6500 rpm, limiter 6800 (E4); 5500 rpm, limiter 7000 (E20)",
            valvetrain: "separate intake and exhaust cams per bank (E4, E20); type not stated in E20",
            examples: ["GM LS", "Chevrolet 454 V8", "Alfa Romeo Montreal (2.6 L cross-plane)"],
            sources: ["S28", "E4", "E20"],
            playability: .playable(.v8Cross)
        ),
        EngineCatalogEntry(
            id: 31, name: "V8 flat-plane 90", cylinders: 8, family: .pistonV, cycle: .fourStroke, bankAngle: 90,
            firingOrder: .sourced([1, 5, 3, 7, 4, 8, 2, 6], "1-5-3-7-4-8-2-6", source: "E5"),
            interval: "90 deg",
            displacement: "4.5 L (calc, E5)",
            redline: "9000 rpm, limiter 9300 (E5)",
            valvetrain: "per-bank intake and exhaust cams, 551 thou lift (E5)",
            examples: ["Ferrari F136", "Ferrari 208 GT4 (2.0 L)"],
            sources: ["S3", "S28", "E5"],
            playability: .playable(.v8Flat)
        ),
        EngineCatalogEntry(
            id: 32, name: "V8 flat-plane 75", cylinders: 8, family: .pistonV, cycle: .fourStroke, bankAngle: 75,
            firingOrder: .notSourced("flat-plane crank stated; no sequence found"),
            interval: "Not sourced",
            examples: ["TVR Speed Eight (1996-2003)"],
            sources: ["S28"],
            playability: .blockedOnFiringOrder
        ),
        EngineCatalogEntry(
            id: 33, name: "V8 60", cylinders: 8, family: .pistonV, cycle: .fourStroke, bankAngle: 60,
            firingOrder: .notSourced("no crank or sequence stated"),
            interval: "Not sourced",
            examples: ["Ford Taurus SHO", "Volvo XC90"],
            sources: ["S28"],
            playability: .blockedOnFiringOrder
        ),
        EngineCatalogEntry(
            id: 34, name: "V8 45", cylinders: 8, family: .pistonV, cycle: .fourStroke, bankAngle: 45,
            firingOrder: .notSourced("no crank or sequence stated"),
            interval: "Not sourced",
            examples: ["EMD 567 locomotive engine", "1932 Miller racers"],
            sources: ["S28"],
            playability: .blockedOnFiringOrder
        ),
        EngineCatalogEntry(
            id: 35, name: "V10 72", cylinders: 10, family: .pistonV, cycle: .fourStroke, bankAngle: 72,
            firingOrder: .derived([1, 6, 2, 7, 4, 9, 5, 10, 3, 8], "derived from wire timing; five shared journals at 0/72/144/216/288", source: "E7"),
            interval: "72 deg",
            displacement: "4.8 L (calc, E7)",
            redline: "9000 rpm, limiter 9500 (E7)",
            valvetrain: "DOHC, intake and exhaust cams per bank (E7)",
            examples: ["Lexus 1LR-GUE", "Renault F1 V10 (72 deg, later)"],
            sources: ["S20", "E7"],
            playability: .playable(.v10)
        ),
        EngineCatalogEntry(
            id: 36, name: "V10 90", cylinders: 10, family: .pistonV, cycle: .fourStroke, bankAngle: 90,
            firingOrder: .notSourced("odd firing order used to avoid a balance shaft; no sequence given"),
            interval: "Not sourced",
            displacement: "8.4 L, 477 kW (640 hp) (Dodge Viper)",
            examples: ["Dodge Viper"],
            sources: ["S20"],
            playability: .blockedOnFiringOrder
        ),
        EngineCatalogEntry(
            id: 37, name: "V10 110", cylinders: 10, family: .pistonV, cycle: .fourStroke, bankAngle: 110,
            firingOrder: .notSourced("no sequence found"),
            interval: "Not sourced",
            displacement: "3.5 L F1, later 3.0 L",
            examples: ["Renault F1 2002-03"],
            sources: ["S20"],
            playability: .blockedOnFiringOrder
        ),
        EngineCatalogEntry(
            id: 38, name: "V10 diesel", cylinders: 10, family: .pistonV, cycle: .fourStroke,
            firingOrder: .notSourced("no sequence found"),
            interval: "Not sourced",
            displacement: "15.8 L (Tatra 815); 37.4 L (MTU MB 838 CaM 500)",
            aspiration: "diesel",
            examples: ["Tatra 815", "MTU MB 838 tank engine"],
            sources: ["S20"],
            playability: .blockedOnFiringOrder
        ),
        EngineCatalogEntry(
            id: 39, name: "V12 60", cylinders: 12, family: .pistonV, cycle: .fourStroke, bankAngle: 60,
            firingOrder: .sourced(
                nil,
                "1a-6b-4a-3b-2a-5b-6a-1b-3a-4b-5a-2b (bank-lettered; not translatable to 1-12 without the source convention); journals at 0/120/240",
                source: "E8"
            ),
            interval: "60 deg",
            displacement: "27 L (calc, E8)",
            redline: "3000 rpm, limiter 3500 (E8)",
            valvetrain: "two cams per bank; cam_1 offset 60 deg (E8)",
            examples: ["Rolls-Royce Merlin V-1650-9", "Sunbeam Toodles V (9.0 L)"],
            sources: ["S21", "E8"],
            playability: .playable(.v12)
        ),
        EngineCatalogEntry(
            id: 40, name: "V12 75", cylinders: 12, family: .pistonV, cycle: .fourStroke, bankAngle: 75,
            firingOrder: .sourced([1, 12, 5, 8, 3, 10, 6, 7, 2, 11, 4, 9], "1-12-5-8-3-10-6-7-2-11-4-9", source: "E9"),
            interval: "60 deg, alternating 75/45",
            displacement: "3.0 L (calc, E9)",
            redline: "18000 rpm, limiter 18500 (E9)",
            valvetrain: "per-bank cam sets, b1 offset 75 deg (E9)",
            examples: ["Ferrari 412 T2"],
            sources: ["E9"],
            playability: .blockedOnGeometry
        ),
        EngineCatalogEntry(
            id: 41, name: "V12 65", cylinders: 12, family: .pistonV, cycle: .fourStroke, bankAngle: 65,
            firingOrder: .notSourced("no source found for this row"),
            interval: "Not sourced",
            sources: ["none"],
            playability: .blockedOnFiringOrder
        ),
        EngineCatalogEntry(
            id: 42, name: "V12 90", cylinders: 12, family: .pistonV, cycle: .fourStroke, bankAngle: 90,
            firingOrder: .notSourced("no sequence found"),
            interval: "Not sourced",
            examples: ["1904 Craig-Dorwald racing-boat engine"],
            sources: ["S21"],
            playability: .blockedOnFiringOrder
        ),
        EngineCatalogEntry(
            id: 43, name: "V12 diesel", cylinders: 12, family: .pistonV, cycle: .fourStroke, bankAngle: 60,
            firingOrder: .notSourced("no sequence found; 60 deg angle itself unverified"),
            interval: "Not sourced",
            displacement: "5.5 L, 476 kW (Audi R10 TDI)",
            aspiration: "turbo diesel (R10)",
            examples: ["Audi R10 TDI"],
            sources: ["S24"],
            playability: .blockedOnFiringOrder
        ),
        EngineCatalogEntry(
            id: 44, name: "V16 45 (OHV)", cylinders: 16, family: .pistonV, cycle: .fourStroke, bankAngle: 45,
            firingOrder: .notSourced("two inline-8 on one crank; no sequence found"),
            interval: "Not sourced",
            displacement: "452 cu in (7.4 L)",
            valvetrain: "overhead valves; five main bearings",
            examples: ["Cadillac Series 452 (1930-37)"],
            sources: ["S15"],
            playability: .blockedOnFiringOrder
        ),
        EngineCatalogEntry(
            id: 45, name: "V16 135 (sidevalve)", cylinders: 16, family: .pistonV, cycle: .fourStroke, bankAngle: 135,
            firingOrder: .notSourced("no sequence found"),
            interval: "Not sourced",
            displacement: "431 cu in (7.1 L)",
            valvetrain: "sidevalve; nine main bearings",
            examples: ["Cadillac Series 90 (1938-40)"],
            sources: ["S15"],
            playability: .blockedOnFiringOrder
        ),
        EngineCatalogEntry(
            id: 46, name: "Flat-2 (boxer twin)", cylinders: 2, family: .pistonFlat, cycle: .fourStroke, bankAngle: 180,
            firingOrder: .derived([1, 2], "one pin per cylinder pair (boxer), 360 deg spacing (derived)", source: "S7"),
            interval: "360 deg (derived)",
            examples: ["BMW motorcycles from 1923", "Tatra 11 (1923-27)"],
            sources: ["S7"],
            playability: .blockedOnGeometry
        ),
        EngineCatalogEntry(
            id: 47, name: "Flat-4 (boxer)", cylinders: 4, family: .pistonFlat, cycle: .fourStroke, bankAngle: 180,
            firingOrder: .sourced(
                [1, 3, 4, 2],
                "1-3-4-2 (R1-R2-L1-L2 typical); engine-sim runs bank0, bank0, bank1, bank1",
                source: "S2, E16"
            ),
            interval: "180 deg",
            displacement: "2.46 L (calc, E16); 99.5 mm bore x 79 mm stroke",
            redline: "6500 rpm (E16)",
            valvetrain: "two cams per bank, intake and exhaust (E16)",
            examples: ["Subaru EJ25", "VW air-cooled", "Porsche 356"],
            sources: ["S2", "S7", "E16"],
            playability: .playable(.flat4)
        ),
        EngineCatalogEntry(
            id: 48, name: "Flat-6 (boxer)", cylinders: 6, family: .pistonFlat, cycle: .fourStroke, bankAngle: 180,
            firingOrder: .sourced(
                nil,
                "R1-L2-R3-L1-R2-L3 or R1-L3-R2-L1-R3-L2 (two valid options given); pins at 0/120/240 paired",
                source: "S2, S7"
            ),
            interval: "120 deg",
            examples: ["Porsche 911 (boxer-six since 1964)", "Chevrolet Corvair", "Subaru boxer-six"],
            sources: ["S2", "S7"],
            playability: .playable(.flat6)
        ),
        EngineCatalogEntry(
            id: 49, name: "Flat-8 (boxer)", cylinders: 8, family: .pistonFlat, cycle: .fourStroke, bankAngle: 180,
            firingOrder: .notSourced("no sequence found"),
            interval: "90 deg (derived)",
            examples: ["Porsche 804 (1962 F1)", "Porsche 908 (1968-71)"],
            sources: ["S7"],
            playability: .blockedOnFiringOrder
        ),
        EngineCatalogEntry(
            id: 50, name: "Flat-10 (boxer prototype)", cylinders: 10, family: .pistonFlat, cycle: .fourStroke, bankAngle: 180,
            firingOrder: .notSourced("no sequence found"),
            interval: "Not sourced",
            examples: ["Chevrolet 1960s prototype, never produced"],
            sources: ["S7"],
            playability: .blockedOnFiringOrder
        ),
        EngineCatalogEntry(
            id: 51, name: "Flat-12 (180 V12)", cylinders: 12, family: .pistonFlat, cycle: .fourStroke, bankAngle: 180,
            firingOrder: .notSourced("shared crankpins stated; no sequence found"),
            interval: "60 deg (derived)",
            examples: ["Porsche 917 (1969-73)", "Ferrari flat-12 (1973-96)", "Hino DS140 diesel boxer-12"],
            sources: ["S7", "S21"],
            playability: .blockedOnFiringOrder
        ),
        EngineCatalogEntry(
            id: 52, name: "Flat-16 (boxer prototype)", cylinders: 16, family: .pistonFlat, cycle: .fourStroke, bankAngle: 180,
            firingOrder: .notSourced("no sequence found"),
            interval: "Not sourced",
            examples: ["Coventry Climax prototype", "Porsche prototype"],
            sources: ["S7"],
            playability: .blockedOnFiringOrder
        ),
        EngineCatalogEntry(
            id: 53, name: "W8", cylinders: 8, family: .pistonW, cycle: .fourStroke,
            firingOrder: .notSourced("no sequence found; the 2-bank and 4-bank descriptions conflict"),
            interval: "Not sourced",
            displacement: "4.0 L experimental (sources conflict on bank count)",
            examples: ["VW Group W8 (2001-04)"],
            sources: ["S12"],
            playability: .blockedOnFiringOrder
        ),
        EngineCatalogEntry(
            id: 54, name: "W12", cylinders: 12, family: .pistonW, cycle: .fourStroke,
            firingOrder: .notSourced("no sequence found"),
            interval: "Not sourced",
            displacement: "6.0 L (Bentley), 6.3 L NA (Audi A8 D4)",
            aspiration: "NA and turbo",
            examples: ["VW Group W12 (two VR6 on one crank)", "Bentley 6.0", "1990 Life F1 three-bank"],
            sources: ["S12"],
            playability: .blockedOnFiringOrder
        ),
        EngineCatalogEntry(
            id: 55, name: "W16 (90 deg)", cylinders: 16, family: .pistonW, cycle: .fourStroke, bankAngle: 90,
            firingOrder: .derived(
                [1, 9, 5, 13, 3, 11, 7, 15, 4, 12, 8, 16, 2, 10, 6, 14],
                "even 45 deg spacing across four banks; no source states a sequence",
                source: "none (derived)"
            ),
            interval: "45 deg (derived)",
            displacement: "8.0 L (7993 cc)",
            redline: "peak power at 7000 rpm (Bolide); no limiter stated",
            aspiration: "quad-turbo",
            valvetrain: "64-valve DOHC, four valves per cylinder",
            examples: ["Bugatti 8.0 W16 (Veyron, Chiron)", "VW 8.0 WR16"],
            sources: ["S6", "S12"],
            playability: .playable(.w16)
        ),
        EngineCatalogEntry(
            id: 56, name: "W18", cylinders: 18, family: .pistonW, cycle: .fourStroke,
            firingOrder: .notSourced("no sequence found"),
            interval: "Not sourced",
            aspiration: "turbo (Porsche 2025 patent: three turbochargers)",
            examples: ["Aircraft W18 (1920s-30s)", "CRM Motori marine"],
            sources: ["S12"],
            playability: .blockedOnFiringOrder
        ),
        EngineCatalogEntry(
            id: 57, name: "Wankel 1-rotor", cylinders: 1, family: .wankel, cycle: .rotary,
            firingOrder: .notApplicable("rotary: no firing order; one power impulse per eccentric-shaft revolution"),
            interval: "one impulse per 360 deg of eccentric shaft (derived)",
            displacement: "125 cc to 996 cc per rotor (KKM 125, KKM 502, Mazda MX-30 R-EV 830 cc)",
            redline: "10000 rpm (auto racing)",
            aspiration: "NA or turbo",
            valvetrain: "no valves; ports open as apex seals pass",
            examples: ["NSU Spider (KKM 502)", "Mazda MX-30 R-EV"],
            sources: ["S4"],
            playability: .unsupportedArchitecture
        ),
        EngineCatalogEntry(
            id: 58, name: "Wankel 2-rotor", cylinders: 2, family: .wankel, cycle: .rotary,
            firingOrder: .notApplicable("rotary: no firing order"),
            interval: "derived",
            displacement: "1992 cc (NSU Ro 80); 2616 cc (Mazda 13B-REW); 2.6 L Renesis, 177 kW",
            aspiration: "NA or turbo",
            valvetrain: "no valves",
            examples: ["Mazda RX-7", "Mazda RX-8", "NSU Ro 80", "Audi-NSU KKM 871"],
            sources: ["S4", "S1"],
            playability: .unsupportedArchitecture
        ),
        EngineCatalogEntry(
            id: 59, name: "Wankel 3-rotor", cylinders: 3, family: .wankel, cycle: .rotary,
            firingOrder: .notApplicable("rotary: no firing order"),
            interval: "derived",
            aspiration: "twin-turbo (Mazda Eunos Cosmo, 1990)",
            valvetrain: "no valves",
            examples: ["Mazda Eunos Cosmo (1990)", "Mercedes C 111 (1969)"],
            sources: ["S4"],
            playability: .unsupportedArchitecture
        ),
        EngineCatalogEntry(
            id: 60, name: "Wankel 4-rotor", cylinders: 4, family: .wankel, cycle: .rotary,
            firingOrder: .notApplicable("rotary: no firing order"),
            interval: "derived",
            displacement: "4.8 L total (Mercedes C 111-II, 1970)",
            aspiration: "NA",
            valvetrain: "no valves",
            examples: ["Mercedes-Benz C 111-II"],
            sources: ["S4"],
            playability: .unsupportedArchitecture
        ),
        EngineCatalogEntry(
            id: 61, name: "Rotary (rotating crankcase, 7)", cylinders: 7, family: .rotaryCrankcase, cycle: .fourStroke,
            firingOrder: .notSourced("odd count gives an every-other-piston order; no specific sequence given"),
            interval: "derived",
            valvetrain: "poppet valves, rotating (unverified)",
            examples: ["Gnome Omega 50 hp", "Gnome Lambda 80 hp"],
            sources: ["S25"],
            playability: .unsupportedArchitecture
        ),
        EngineCatalogEntry(
            id: 62, name: "Rotary (rotating crankcase, 9)", cylinders: 9, family: .rotaryCrankcase, cycle: .fourStroke,
            firingOrder: .notSourced("every-other-piston order; no specific sequence given"),
            interval: "derived",
            examples: ["Monosoupape 100 hp", "Gnome 9N 160 hp", "Le Rhone 9C 80 hp"],
            sources: ["S25"],
            playability: .unsupportedArchitecture
        ),
        EngineCatalogEntry(
            id: 63, name: "Rotary (rotating crankcase, 14)", cylinders: 14, family: .rotaryCrankcase, cycle: .fourStroke,
            firingOrder: .notSourced("two rows of seven; no sequence found"),
            interval: "Not sourced",
            examples: ["Double Lambda 14-cylinder 160 hp"],
            sources: ["S25"],
            playability: .unsupportedArchitecture
        ),
        EngineCatalogEntry(
            id: 64, name: "Radial-5", cylinders: 5, family: .radial, cycle: .fourStroke,
            firingOrder: .sourced(
                [1, 3, 5, 2, 4],
                "article gives 1-3-5-2-4; engine-sim wire timing b0, b3, b1, b4, b2",
                source: "S5, E17"
            ),
            interval: "144 deg",
            displacement: "8.85 L (calc, E17)",
            redline: "3000 rpm, limiter 3500 (E17)",
            valvetrain: "single lobe profile, offsets per head (E17)",
            examples: ["Shvetsov M-11 (5-cylinder, 8.6 L)"],
            sources: ["S5", "E17"],
            playability: .blockedOnGeometry
        ),
        EngineCatalogEntry(
            id: 65, name: "Radial-7", cylinders: 7, family: .radial, cycle: .fourStroke,
            firingOrder: .derived([1, 3, 5, 7, 2, 4, 6], "every-other-piston rule applied to 7 cylinders", source: "S5"),
            interval: "102.9 deg (720/7, derived)",
            examples: ["Continental R-670 (1931)"],
            sources: ["S5"],
            playability: .blockedOnGeometry
        ),
        EngineCatalogEntry(
            id: 66, name: "Radial-9", cylinders: 9, family: .radial, cycle: .fourStroke,
            firingOrder: .derived(
                [1, 8, 6, 4, 2, 9, 7, 5, 3],
                "distributor wiring b0, b7, b5, b3, b1, b8, b6, b4, b2 (b-index translated to cylinders 1-9)",
                source: "E6"
            ),
            interval: "80 deg",
            displacement: "15.9 L (calc, E6); Packard DR-980 16.06 L",
            redline: "3000 rpm, limiter 3500 (E6)",
            valvetrain: "one shared cam profile, offsets per head (E6)",
            examples: ["Packard DR-980", "Radial 9 (E6)"],
            sources: ["S5", "E6"],
            playability: .blockedOnGeometry
        ),
        EngineCatalogEntry(
            id: 67, name: "Radial-14 (twin row)", cylinders: 14, family: .radial, cycle: .fourStroke,
            firingOrder: .notSourced("twin-row radials are not described with a firing order in the source"),
            interval: "Not sourced",
            displacement: "30 L (R-1830), 41 L (ASh-82), 42 L (BMW 801), 43 L (R-2600)",
            examples: ["Pratt & Whitney R-1830 Twin Wasp", "BMW 801", "Shvetsov ASh-82", "Wright R-2600"],
            sources: ["S5"],
            playability: .blockedOnFiringOrder
        ),
        EngineCatalogEntry(
            id: 68, name: "Radial-18 (twin row)", cylinders: 18, family: .radial, cycle: .fourStroke,
            firingOrder: .notSourced("twin-row radials are not described with a firing order in the source"),
            interval: "Not sourced",
            displacement: "46 L (R-2800), 55 L (R-3350), 58 L (ASh-73)",
            examples: ["Pratt & Whitney R-2800 Double Wasp", "Wright R-3350"],
            sources: ["S5"],
            playability: .blockedOnFiringOrder
        ),
        EngineCatalogEntry(
            id: 69, name: "Two-stroke parallel twin 180", cylinders: 2, family: .pistonInline, cycle: .twoStroke,
            firingOrder: .derived([1, 2], "180 deg crank, even power strokes", source: "S9"),
            interval: "180 deg",
            valvetrain: "ports, no poppet valves",
            examples: ["Yamaha RD350 (1973-75)"],
            sources: ["S9"],
            playability: .unsupportedArchitecture
        ),
        EngineCatalogEntry(
            id: 70, name: "Two-stroke inline-3", cylinders: 3, family: .pistonInline, cycle: .twoStroke,
            firingOrder: .notSourced("no sequence found"),
            interval: "Not sourced",
            displacement: "750 and 850 cc (Saab); 256 cc (Suzuki Fronte 360)",
            valvetrain: "ports",
            examples: ["Saab 750 and 850 three-cylinder", "Suzuki Fronte 360"],
            sources: ["S13", "S8"],
            playability: .unsupportedArchitecture
        ),
        EngineCatalogEntry(
            id: 71, name: "Two-stroke uniflow diesel", cylinders: nil, family: .pistonInline, cycle: .twoStroke,
            firingOrder: .notSourced("no sequence found; cylinder count not stated"),
            interval: "Not sourced",
            aspiration: "blower-scavenged (uniflow)",
            valvetrain: "ports, no poppet valves",
            examples: ["Detroit Diesel Series 71"],
            sources: ["S13"],
            playability: .unsupportedArchitecture
        ),
        EngineCatalogEntry(
            id: 72, name: "Two-stroke opposed-piston I6 diesel", cylinders: 6, family: .pistonInline, cycle: .twoStroke,
            firingOrder: .notSourced("two crankshafts geared together, lower 11 deg behind upper; no sequence found"),
            interval: "Not sourced",
            displacement: "16.62 L (Jumo 205E)",
            aspiration: "diesel, two-stroke",
            valvetrain: "ports, no poppet valves",
            examples: ["Junkers Jumo 205E (700 PS at 2500 rpm)"],
            sources: ["S16"],
            playability: .unsupportedArchitecture
        ),
        EngineCatalogEntry(
            id: 73, name: "Diesel I4", cylinders: 4, family: .pistonInline, cycle: .fourStroke,
            firingOrder: .notSourced("no sequence found"),
            interval: "Not sourced",
            displacement: "1.8 L (Mitsubishi 4N13 DOHC); 2.0 L (BMW 320d racing, 180 kW)",
            aspiration: "turbo diesel (BMW 320d racing)",
            valvetrain: "DOHC (Mitsubishi 4N13)",
            examples: ["Mitsubishi 4N13", "BMW 320d racing engine"],
            sources: ["S24"],
            playability: .blockedOnFiringOrder
        ),
        EngineCatalogEntry(
            id: 74, name: "Diesel I5", cylinders: 5, family: .pistonInline, cycle: .fourStroke,
            firingOrder: .notSourced("no sequence found"),
            interval: "Not sourced",
            aspiration: "diesel",
            examples: ["MAN B&W 5S50MC (marine two-stroke)"],
            sources: ["S24"],
            playability: .blockedOnFiringOrder
        ),
        EngineCatalogEntry(
            id: 75, name: "Diesel I6", cylinders: 6, family: .pistonInline, cycle: .fourStroke,
            firingOrder: .notSourced("no sequence found"),
            interval: "Not sourced",
            displacement: "4.6 L (Mercedes-Benz OM 312 A, 115 PS)",
            aspiration: "diesel",
            examples: ["Mercedes-Benz OM 312 A (industrial)"],
            sources: ["S24"],
            playability: .blockedOnFiringOrder
        ),
        EngineCatalogEntry(
            id: 76, name: "Diesel V8", cylinders: 8, family: .pistonV, cycle: .fourStroke,
            firingOrder: .notSourced("no sequence found"),
            interval: "Not sourced",
            displacement: "Wartsila 8V31 marine (4400-4880 kW)",
            aspiration: "diesel",
            examples: ["Wartsila 8V31"],
            sources: ["S28"],
            playability: .blockedOnFiringOrder
        ),
        EngineCatalogEntry(
            id: 77, name: "Diesel V12", cylinders: 12, family: .pistonV, cycle: .fourStroke, bankAngle: 60,
            firingOrder: .notSourced("no sequence found; 60 deg angle unverified"),
            interval: "Not sourced",
            displacement: "5.5 L, 476 kW (Audi R10 TDI); 1157 L (Wartsila 46F V12 marine)",
            aspiration: "diesel, turbo (R10)",
            examples: ["Audi R10 TDI"],
            sources: ["S24", "S21"],
            playability: .blockedOnFiringOrder
        ),
        EngineCatalogEntry(
            id: 78, name: "Atkinson-cycle inline-4 (hybrid)", cylinders: 4, family: .pistonInline, cycle: .fourStroke,
            firingOrder: .notSourced("no sequence found; inline layout unverified"),
            interval: "Not sourced",
            aspiration: "Atkinson cycle, intake valve held open longer",
            examples: ["Toyota 1NZ-FXE (early Prius, 1997)"],
            sources: ["S14"],
            playability: .blockedOnFiringOrder
        ),
        EngineCatalogEntry(
            id: 79, name: "Electric motor (BLDC)", cylinders: nil, family: .electric, cycle: .electric,
            firingOrder: .notApplicable("no combustion, no firing order"),
            interval: "n/a",
            redline: "up to 16000 rpm (unverified)",
            aspiration: "n/a",
            valvetrain: "n/a",
            examples: ["EV traction motors"],
            sources: ["S23"],
            playability: .unsupportedArchitecture
        ),
        EngineCatalogEntry(
            id: 80, name: "Turboshaft (helicopter)", cylinders: nil, family: .turbine, cycle: .turbine,
            firingOrder: .notApplicable("gas turbine: continuous combustion, no firing order"),
            interval: "n/a",
            displacement: "n/a (100 shp Turbomeca 782, 1948; 280 shp Artouste)",
            examples: ["Lotarev D-136", "GE T64"],
            sources: ["S18"],
            playability: .unsupportedArchitecture
        ),
        EngineCatalogEntry(
            id: 81, name: "Low-bypass turbofan", cylinders: nil, family: .turbine, cycle: .turbine,
            firingOrder: .notApplicable("gas turbine: continuous combustion, no firing order"),
            interval: "n/a",
            displacement: "n/a (Conway BPR 0.3; CF700 BPR 2.0, 19000 N thrust)",
            examples: ["Rolls-Royce Conway", "GE CF700"],
            sources: ["S19"],
            playability: .unsupportedArchitecture
        ),
        EngineCatalogEntry(
            id: 82, name: "High-bypass turbofan (airliner)", cylinders: nil, family: .turbine, cycle: .turbine,
            firingOrder: .notApplicable("gas turbine: continuous combustion, no firing order"),
            interval: "n/a",
            displacement: "n/a (PLF1A-2 BPR 6:1, 4320 lb thrust; PW1000G BPR 12.5:1; LEAP BPR 11:1)",
            examples: ["GE90", "CFM LEAP", "Pratt & Whitney PW1000G"],
            sources: ["S19"],
            playability: .unsupportedArchitecture
        ),
        EngineCatalogEntry(
            id: 83, name: "Afterburning fighter turbofan", cylinders: nil, family: .turbine, cycle: .turbine,
            firingOrder: .notApplicable("gas turbine: continuous combustion, no firing order"),
            interval: "n/a",
            displacement: "n/a (low/medium bypass, military)",
            aspiration: "afterburner",
            examples: ["Pratt & Whitney F119"],
            sources: ["S19"],
            playability: .unsupportedArchitecture
        ),
    ]
}
