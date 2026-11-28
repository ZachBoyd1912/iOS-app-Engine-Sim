import Foundation
import PistonForgeKit
import RealityKit
import simd
import UIKit

/// The parts a tap on the 3D engine can select.
enum PartGroup: String, CaseIterable, Sendable {
    case block, heads, crank, intake, exhaust, induction, fuel, sensors, nitrous, wiring

    var title: String {
        switch self {
        case .block: "Block"
        case .heads: "Heads"
        case .crank: "Crank and pistons"
        case .intake: "Intake"
        case .exhaust: "Exhaust"
        case .induction: "Turbo or blower"
        case .fuel: "Fuel system"
        case .sensors: "Sensors"
        case .nitrous: "Nitrous"
        case .wiring: "Wiring"
        }
    }

    static func from(entityName: String) -> PartGroup? {
        guard entityName.hasPrefix("part.") else { return nil }
        let rest = entityName.dropFirst(5)
        let group = rest.split(separator: ".").first.map(String.init) ?? ""
        return PartGroup(rawValue: group)
    }
}

/// Surface finishes for the engine's parts.
enum Finish: CaseIterable {
    case castIron, aluminium, polished, steel, valveCover, exhaust, rubber, fuelRail, sensor, nitrous, intercooler

    @MainActor
    var material: SimpleMaterial {
        switch self {
        case .castIron: SimpleMaterial(color: Theme.Engine.castIron, roughness: 0.75, isMetallic: true)
        case .aluminium: SimpleMaterial(color: Theme.Engine.aluminium, roughness: 0.45, isMetallic: true)
        case .polished: SimpleMaterial(color: Theme.Engine.polished, roughness: 0.2, isMetallic: true)
        case .steel: SimpleMaterial(color: Theme.Engine.steel, roughness: 0.35, isMetallic: true)
        case .valveCover: SimpleMaterial(color: Theme.Engine.valveCover, roughness: 0.4, isMetallic: false)
        case .exhaust: SimpleMaterial(color: Theme.Engine.exhaust, roughness: 0.6, isMetallic: true)
        case .rubber: SimpleMaterial(color: Theme.Engine.rubber, roughness: 0.9, isMetallic: false)
        case .fuelRail: SimpleMaterial(color: Theme.Engine.fuelRail, roughness: 0.35, isMetallic: true)
        case .sensor: SimpleMaterial(color: Theme.Engine.sensor, roughness: 0.5, isMetallic: false)
        case .nitrous: SimpleMaterial(color: Theme.Engine.nitrous, roughness: 0.3, isMetallic: true)
        case .intercooler: SimpleMaterial(color: Theme.Engine.intercooler, roughness: 0.8, isMetallic: true)
        }
    }
}

/// Builds the engine in code from its layout and parts: no downloaded or bought models.
///
/// Axes: x runs along the crank (the front pulley is at -x), y is up, z is across. Each bank
/// leans `tilt` radians about the crank axis. Static parts are merged into one mesh per part
/// group and finish; the crank, pistons and rods move, posed by `EngineAnimationSystem`.
@MainActor
enum EngineModelBuilder {
    static let rootName = "engineRoot"

    /// Engine dimensions in metres, derived once from the build.
    struct Geometry {
        let bore: Float
        let stroke: Float
        let crankRadius: Float
        let rodLength: Float
        let pitch: Float
        let deck: Float
        let headHeight: Float
        let rowLength: Float
        let tilts: [Float]
        let cylinderX: [Float]
        let cylinderBank: [Int]
        let pistonHeight: Float
        let crownOffset: Float

        init(_ b: EngineBuild) {
            let spec = b.layout.spec
            let mm: Float = 0.001
            bore = Float(b.bore) * mm
            stroke = Float(b.stroke) * mm
            crankRadius = stroke / 2
            rodLength = stroke * Float(b.rodRatio)
            pitch = bore + 0.012
            pistonHeight = bore * 0.55
            crownOffset = bore * 0.3
            deck = crankRadius + rodLength + crownOffset + pistonHeight / 2 + 0.004
            headHeight = 0.07 + bore * 0.25
            let banks = max(spec.banks, 1)
            let perBank = spec.cylinders / banks
            rowLength = Float(perBank) * pitch + (banks > 1 ? pitch / 2 : 0)
            let angle = Float(spec.bankAngle) * .pi / 180
            switch banks {
            case 1: tilts = [0]
            case 2: tilts = [-angle / 2, angle / 2]
            default:
                let narrow: Float = 15 * .pi / 180
                let wide = angle / 2
                tilts = [-wide - narrow, -wide + narrow, wide - narrow, wide + narrow]
            }
            var counts = Array(repeating: 0, count: banks)
            var xs: [Float] = []
            var owners: [Int] = []
            for cylinder in 0..<spec.cylinders {
                let bank = min(spec.bankOf[cylinder], banks - 1)
                let shift: Float = bank % 2 == 1 ? pitch / 2 : 0
                let k = Float(counts[bank])
                xs.append(-rowLength / 2 + pitch / 2 + k * pitch + shift)
                owners.append(bank)
                counts[bank] += 1
            }
            cylinderX = xs
            cylinderBank = owners
        }

        func axis(_ bank: Int) -> SIMD3<Float> { [0, cos(tilts[bank]), sin(tilts[bank])] }

        /// Across the bank, pointing into the valley (intake side); for an inline, toward +z.
        func inner(_ bank: Int) -> SIMD3<Float> {
            let tilt = tilts[bank]
            let w = SIMD3<Float>(0, -sin(tilt), cos(tilt))
            return tilt <= 0 ? w : -w
        }

        func outer(_ bank: Int) -> SIMD3<Float> { -inner(bank) }
        func rotation(_ bank: Int) -> simd_quatf { simd_quatf(angle: tilts[bank], axis: [1, 0, 0]) }

        func bankCylinders(_ bank: Int) -> [Int] { cylinderBank.indices.filter { cylinderBank[$0] == bank } }

        func bankCentreX(_ bank: Int) -> Float {
            let xs = bankCylinders(bank).map { cylinderX[$0] }
            return xs.isEmpty ? 0 : xs.reduce(0, +) / Float(xs.count)
        }

        func bankLength(_ bank: Int) -> Float { Float(bankCylinders(bank).count) * pitch }

        /// Top of the cylinder head above cylinder `index`.
        func headTop(_ index: Int) -> SIMD3<Float> {
            SIMD3<Float>(cylinderX[index], 0, 0) + axis(cylinderBank[index]) * (deck + headHeight * 0.5)
        }

        var width: Float {
            let reach = deck + headHeight
            let spread = tilts.map { abs(sin($0)) * reach }.max() ?? 0
            return max(bore * 1.6, spread * 2 + bore * 1.6)
        }
    }

    /// Centre and size of the finished model, for framing the camera.
    static func focus(for b: EngineBuild) -> (center: SIMD3<Float>, radius: Float) {
        let g = Geometry(b)
        let height = g.deck + g.headHeight
        let radius = max(g.rowLength + 0.4, g.width + 0.2, height + 0.3) * 0.75
        return ([0, height * 0.35, 0], radius)
    }

    /// A string that changes whenever anything visible about the engine changes.
    static func signature(_ b: EngineBuild) -> String {
        "\(b.layout.rawValue)|\(b.induction)|\(b.bore)|\(b.stroke)|\(b.rodRatio)|\(b.parts.intercooler)|\(String(describing: b.nitrous?.kind))|\(b.sensors)"
    }

    private struct Key: Hashable {
        let group: PartGroup
        let finish: Finish
    }

    /// Collects static geometry per part group and finish.
    private struct Assembly {
        var meshes: [Key: MeshBuilder] = [:]

        mutating func box(_ group: PartGroup, _ finish: Finish, center: SIMD3<Float>, size: SIMD3<Float>, rotation: simd_quatf = simd_quatf(angle: 0, axis: [1, 0, 0])) {
            meshes[Key(group: group, finish: finish), default: MeshBuilder()].addBox(center: center, size: size, rotation: rotation)
        }

        mutating func cylinder(_ group: PartGroup, _ finish: Finish, from a: SIMD3<Float>, to b: SIMD3<Float>, radius: Float, segments: Int = 16) {
            meshes[Key(group: group, finish: finish), default: MeshBuilder()].addCylinder(from: a, to: b, radius: radius, segments: segments)
        }

        mutating func tube(_ group: PartGroup, _ finish: Finish, through points: [SIMD3<Float>], radius: Float) {
            meshes[Key(group: group, finish: finish), default: MeshBuilder()].addTube(through: points, radius: radius)
        }
    }

    // MARK: - Build

    static func build(_ b: EngineBuild) throws -> Entity {
        let g = Geometry(b)
        let root = Entity()
        root.name = rootName
        root.components.set(EngineMotionComponent(crankAngle: 0))

        var parts = Assembly()
        addBlock(&parts, g)
        addHeads(&parts, g)
        let plenum = addIntake(&parts, g, b)
        let collectors = addExhaust(&parts, g, b)
        addInduction(&parts, g, b, plenum: plenum, collectors: collectors)
        addFuel(&parts, g)
        addSensors(&parts, g, b, plenum: plenum, collectors: collectors)
        addWiring(&parts, g)
        if let kit = b.nitrous { addNitrous(&parts, g, kit: kit, plenum: plenum) }

        for (key, mesh) in parts.meshes where !mesh.isEmpty {
            let entity = ModelEntity(mesh: try mesh.meshResource(named: "\(key.group.rawValue).\(key.finish)"), materials: [key.finish.material])
            entity.name = "part.\(key.group.rawValue).\(key.finish)"
            if key.finish == .exhaust { entity.components.set(HeatGlowComponent()) }
            makeTappable(entity)
            root.addChild(entity)
        }

        let crank = ModelEntity(mesh: try crankMesh(g, b).meshResource(named: "crank"), materials: [Finish.steel.material])
        crank.name = "part.crank.shaft"
        crank.components.set(CrankComponent())
        makeTappable(crank)
        root.addChild(crank)

        var pistonMesh = MeshBuilder()
        pistonMesh.addCylinder(from: [0, -g.pistonHeight / 2, 0], to: [0, g.pistonHeight / 2, 0], radius: g.bore * 0.48, segments: 20)
        let pistonResource = try pistonMesh.meshResource(named: "piston")
        var rodMesh = MeshBuilder()
        rodMesh.addBox(center: .zero, size: [g.bore * 0.1, g.rodLength, g.bore * 0.07])
        let rodResource = try rodMesh.meshResource(named: "rod")
        let pistonMaterial = Finish.polished.material
        let rodMaterial = Finish.steel.material
        let spec = b.layout.spec
        for index in 0..<spec.cylinders {
            let geometry = ReciprocatingComponent(
                kind: .piston, x: g.cylinderX[index], bankTilt: g.tilts[g.cylinderBank[index]],
                tdcDegrees: spec.crankPins[index], crankRadius: g.crankRadius, rodLength: g.rodLength,
                crownOffset: g.crownOffset
            )
            let piston = ModelEntity(mesh: pistonResource, materials: [pistonMaterial])
            piston.name = "piston.\(index + 1)"
            piston.components.set(geometry)
            root.addChild(piston)
            var rodGeometry = geometry
            rodGeometry.kind = .rod
            let rod = ModelEntity(mesh: rodResource, materials: [rodMaterial])
            rod.name = "rod.\(index + 1)"
            rod.components.set(rodGeometry)
            root.addChild(rod)
        }
        try addValveTrain(root, g, spec)
        return root
    }

    private static func makeTappable(_ entity: ModelEntity) {
        let bounds = entity.visualBounds(relativeTo: entity)
        let size = simd_max(bounds.extents, SIMD3<Float>(repeating: 0.01))
        entity.components.set(CollisionComponent(shapes: [ShapeResource.generateBox(size: size).offsetBy(translation: bounds.center)]))
        entity.components.set(InputTargetComponent())
    }

    // MARK: - Parts

    private static func addBlock(_ parts: inout Assembly, _ g: Geometry) {
        let r = g.crankRadius
        let width = g.width
        parts.box(.block, .castIron, center: [0, -r * 0.2, 0], size: [g.rowLength + 0.05, r * 2.6 + 0.05, min(width * 0.7, g.bore * 1.6 + 2 * r)])
        parts.box(.block, .castIron, center: [0, -r * 1.4 - 0.06, 0], size: [g.rowLength * 0.9, 0.1, min(width * 0.6, g.bore * 1.5 + 2 * r)])
        for bank in g.tilts.indices {
            let axis = g.axis(bank)
            let x = g.bankCentreX(bank)
            let length = g.bankLength(bank) + 0.01
            let rotation = g.rotation(bank)
            // The skirt below the bores; above it the block is cut away to show the pistons.
            let skirtTop = r + g.rodLength * 0.5
            let skirtBottom = r * 0.6
            let skirtCenter = (skirtTop + skirtBottom) / 2
            parts.box(.block, .castIron, center: SIMD3<Float>(x, 0, 0) + axis * skirtCenter, size: [length, skirtTop - skirtBottom, g.bore * 1.3], rotation: rotation)
            // End walls and the deck plate frame the open bores.
            let wallSpan = g.deck - skirtTop
            let wallCenter = SIMD3<Float>(0, 0, 0) + axis * (skirtTop + wallSpan / 2)
            for end in [Float(-1), 1] {
                let wallX = x + end * (length / 2 - 0.006)
                parts.box(.block, .castIron, center: wallCenter + SIMD3<Float>(wallX, 0, 0), size: [0.012, wallSpan, g.bore * 1.3], rotation: rotation)
            }
            parts.box(.block, .castIron, center: SIMD3<Float>(x, 0, 0) + axis * (g.deck - 0.006), size: [length, 0.012, g.bore * 1.3], rotation: rotation)
        }
    }

    private static func addHeads(_ parts: inout Assembly, _ g: Geometry) {
        let top = g.deck + g.headHeight
        for bank in g.tilts.indices {
            let axis = g.axis(bank)
            let inner = g.inner(bank)
            let x = g.bankCentreX(bank)
            let length = g.bankLength(bank) + 0.02
            let rotation = g.rotation(bank)
            let base = SIMD3<Float>(x, 0, 0)
            parts.box(.heads, .aluminium, center: base + axis * (g.deck + g.headHeight / 2), size: [length, g.headHeight, g.bore * 1.55], rotation: rotation)
            // The cam cover is a lid-less frame, two rails and two end caps, so the cams, springs
            // and rockers sitting on the head stay visible from above.
            for side in [Float(-1), 1] {
                parts.box(.heads, .valveCover, center: base + axis * (top + 0.028) + inner * (side * g.bore * 0.74), size: [length * 0.96, 0.056, 0.014], rotation: rotation)
                // A pedestal under each row of rockers, which turn about a shaft on top of it.
                parts.box(.heads, .aluminium, center: base + axis * (top + 0.014) + inner * (side * g.bore * 0.60), size: [length * 0.9, 0.030, g.bore * 0.18], rotation: rotation)
            }
            // A tower at each end carries each camshaft: one per valve row.
            for side in [Float(-1), 1] {
                for end in [Float(-1), 1] {
                    parts.box(.heads, .aluminium, center: base + axis * (top + 0.024) + inner * (side * g.bore * 0.42) + SIMD3<Float>(end * (length / 2 - 0.008), 0, 0), size: [0.014, 0.052, g.bore * 0.34], rotation: rotation)
                }
            }
        }
    }

    /// Adds the intake and returns the throttle body's mouth, where induction plumbing joins.
    private static func addIntake(_ parts: inout Assembly, _ g: Geometry, _ b: EngineBuild) -> SIMD3<Float> {
        let top = g.deck + g.headHeight
        let plenumCenter: SIMD3<Float>
        let plenumSize: SIMD3<Float>
        if g.tilts.count == 1 {
            plenumCenter = [0, top * 0.75, g.bore * 0.8 + 0.12]
            plenumSize = [g.rowLength * 0.9, 0.1, 0.09]
        } else {
            let heights = g.tilts.indices.map { (g.axis($0) * top).y }
            plenumCenter = [0, (heights.max() ?? top) + 0.05, 0]
            plenumSize = [g.rowLength * 0.85, 0.09, max(0.12, g.width * 0.22)]
        }
        parts.box(.intake, .aluminium, center: plenumCenter, size: plenumSize)
        for index in g.cylinderX.indices {
            let bank = g.cylinderBank[index]
            let port = g.headTop(index) + g.inner(bank) * (g.bore * 0.8)
            let mouth = SIMD3<Float>(g.cylinderX[index], plenumCenter.y - plenumSize.y * 0.3, plenumCenter.z * 0.85)
            let bend = port + g.inner(bank) * 0.04 + SIMD3<Float>(0, 0.03, 0)
            parts.tube(.intake, .aluminium, through: [port, bend, mouth], radius: g.bore * 0.17)
        }
        let throttleStart = plenumCenter - SIMD3<Float>(plenumSize.x / 2, 0, 0)
        let mouth = throttleStart - SIMD3<Float>(0.07, 0, 0)
        parts.cylinder(.intake, .polished, from: throttleStart, to: mouth, radius: 0.035)
        if !b.induction.isForced {
            let filter = mouth + SIMD3<Float>(-0.16, -0.04, 0.05)
            parts.tube(.intake, .rubber, through: [mouth, mouth + SIMD3<Float>(-0.07, 0, 0), filter], radius: 0.034)
            parts.cylinder(.intake, .castIron, from: filter, to: filter + SIMD3<Float>(-0.12, -0.02, 0.03), radius: 0.06)
        }
        return mouth
    }

    /// Adds headers and collectors and returns each bank's collector.
    private static func addExhaust(_ parts: inout Assembly, _ g: Geometry, _ b: EngineBuild) -> [SIMD3<Float>] {
        var collectors: [SIMD3<Float>] = []
        for bank in g.tilts.indices {
            let outer = g.outer(bank)
            let axis = g.axis(bank)
            let lastX = g.bankCylinders(bank).map { g.cylinderX[$0] }.max() ?? 0
            let collector = SIMD3<Float>(lastX + g.pitch * 0.9, 0, 0) + axis * (g.deck * 0.55) + outer * (g.bore * 0.9 + 0.1)
            collectors.append(collector)
            for index in g.bankCylinders(bank) {
                let port = g.headTop(index) + outer * (g.bore * 0.8)
                let out = port + outer * 0.07
                let drop = out + outer * 0.03 - axis * (g.deck * 0.25)
                parts.tube(.exhaust, .exhaust, through: [port, out, drop, collector], radius: g.bore * 0.16)
            }
            if !b.induction.isTurbo {
                let tail = collector + SIMD3<Float>(0.12, -0.08, 0)
                parts.tube(.exhaust, .exhaust, through: [collector, collector + SIMD3<Float>(0.08, -0.03, 0), tail], radius: g.bore * 0.24)
            }
        }
        return collectors
    }

    private static func addInduction(_ parts: inout Assembly, _ g: Geometry, _ b: EngineBuild, plenum mouth: SIMD3<Float>, collectors: [SIMD3<Float>]) {
        let front = -g.rowLength / 2
        let intercooler = SIMD3<Float>(front - 0.26, -0.02, 0)
        let hasIntercooler = b.parts.intercooler > 0
        switch b.induction {
        case .natural:
            return
        case .turbo(let size):
            let radius: Float = switch size {
            case .small: 0.05
            case .medium: 0.06
            case .large: 0.075
            case .twin: 0.05
            }
            let banks = size == .twin ? Array(collectors.indices) : [0]
            var outlets: [SIMD3<Float>] = []
            for (number, bank) in banks.enumerated() {
                var collector = collectors[bank]
                if size == .twin && collectors.count == 1 && number == 1 { collector.x -= g.rowLength * 0.5 }
                let outer = g.outer(bank)
                let turbine = collector + SIMD3<Float>(0.1, 0.02, 0) + outer * 0.05
                parts.tube(.exhaust, .exhaust, through: [collector, collector + SIMD3<Float>(0.05, 0.01, 0), turbine], radius: g.bore * 0.22)
                parts.cylinder(.induction, .castIron, from: turbine - SIMD3<Float>(0, 0, 0.035), to: turbine + SIMD3<Float>(0, 0, 0.035), radius: radius)
                let compressor = turbine - outer * 0.09
                parts.cylinder(.induction, .aluminium, from: compressor - SIMD3<Float>(0, 0, 0.03), to: compressor + SIMD3<Float>(0, 0, 0.03), radius: radius * 1.12)
                parts.cylinder(.induction, .steel, from: turbine, to: compressor, radius: radius * 0.35)
                let downpipe = turbine + SIMD3<Float>(0.12, -0.1, 0)
                parts.tube(.exhaust, .exhaust, through: [turbine, turbine + SIMD3<Float>(0.05, -0.03, 0), downpipe], radius: g.bore * 0.26)
                parts.cylinder(.induction, .steel, from: turbine + SIMD3<Float>(0, radius, 0), to: turbine + SIMD3<Float>(0, radius + 0.04, 0), radius: 0.016)
                outlets.append(compressor + SIMD3<Float>(0, radius * 1.1, 0))
            }
            for outlet in outlets {
                let target = hasIntercooler ? intercooler + SIMD3<Float>(0, 0.1, outlet.z > 0 ? 0.15 : -0.15) : mouth
                parts.tube(.induction, .polished, through: [outlet, outlet + SIMD3<Float>(0, 0.08, 0), SIMD3<Float>(front - 0.1, outlet.y + 0.05, outlet.z), target], radius: 0.028)
            }
            if hasIntercooler {
                parts.box(.induction, .intercooler, center: intercooler, size: [0.06, 0.26, max(0.45, g.width * 0.9)])
                parts.tube(.induction, .polished, through: [intercooler + SIMD3<Float>(0, 0.12, 0), intercooler + SIMD3<Float>(0.08, 0.2, 0), mouth + SIMD3<Float>(-0.05, 0, 0), mouth], radius: 0.03)
            }
            parts.cylinder(.induction, .polished, from: mouth + SIMD3<Float>(-0.04, 0.03, 0), to: mouth + SIMD3<Float>(-0.04, 0.07, 0), radius: 0.018)
        case .supercharger(let kind, _):
            let crankPulley = SIMD3<Float>(front - 0.045, 0, 0)
            if kind == .centrifugal {
                let snail = SIMD3<Float>(front - 0.1, 0.08, g.width * 0.35 + 0.08)
                parts.cylinder(.induction, .polished, from: snail - SIMD3<Float>(0.035, 0, 0), to: snail + SIMD3<Float>(0.035, 0, 0), radius: 0.09)
                parts.cylinder(.induction, .steel, from: snail + SIMD3<Float>(0.035, 0, 0), to: snail + SIMD3<Float>(0.075, 0, 0), radius: 0.04)
                parts.tube(.induction, .rubber, through: [snail + SIMD3<Float>(0.06, 0.04, 0), crankPulley + SIMD3<Float>(0, 0.06, 0)], radius: 0.008)
                let target = hasIntercooler ? intercooler + SIMD3<Float>(0, 0.1, 0.15) : mouth
                parts.tube(.induction, .polished, through: [snail + SIMD3<Float>(0, 0.09, 0), snail + SIMD3<Float>(-0.05, 0.14, -0.05), target], radius: 0.03)
                if hasIntercooler {
                    parts.box(.induction, .intercooler, center: intercooler, size: [0.06, 0.26, max(0.45, g.width * 0.9)])
                    parts.tube(.induction, .polished, through: [intercooler + SIMD3<Float>(0, 0.12, 0), mouth + SIMD3<Float>(-0.05, 0, 0), mouth], radius: 0.03)
                }
            } else {
                // Roots and twin-screw blowers sit on top of the intake, driven from the front.
                let top = mouth + SIMD3<Float>(0.07 + g.rowLength * 0.3, 0.1, 0)
                let body: SIMD3<Float> = [g.rowLength * 0.6, 0.12, 0.17]
                parts.box(.induction, .polished, center: top, size: body)
                for rib in stride(from: -body.x / 2 + 0.03, through: body.x / 2 - 0.03, by: 0.05) {
                    parts.box(.induction, .aluminium, center: top + SIMD3<Float>(rib, body.y / 2 + 0.006, 0), size: [0.01, 0.012, body.z * 0.9])
                }
                let snoutEnd = SIMD3<Float>(front - 0.05, top.y, top.z)
                parts.cylinder(.induction, .aluminium, from: top - SIMD3<Float>(body.x / 2, 0, 0), to: snoutEnd, radius: 0.035)
                parts.cylinder(.induction, .steel, from: snoutEnd, to: snoutEnd - SIMD3<Float>(0.025, 0, 0), radius: kind == .roots ? 0.055 : 0.05)
                parts.tube(.induction, .rubber, through: [snoutEnd + SIMD3<Float>(-0.012, 0.05, 0), crankPulley + SIMD3<Float>(0, 0.07, 0)], radius: 0.007)
                parts.tube(.induction, .rubber, through: [snoutEnd + SIMD3<Float>(-0.012, -0.05, 0), crankPulley + SIMD3<Float>(0, -0.07, 0)], radius: 0.007)
                parts.cylinder(.induction, .polished, from: top + SIMD3<Float>(0, body.y / 2, 0), to: top + SIMD3<Float>(0, body.y / 2 + 0.06, 0), radius: 0.045)
            }
        }
    }

    private static func addFuel(_ parts: inout Assembly, _ g: Geometry) {
        for bank in g.tilts.indices {
            let axis = g.axis(bank)
            let inner = g.inner(bank)
            let cylinders = g.bankCylinders(bank)
            guard let first = cylinders.first, let last = cylinders.last else { continue }
            func railPoint(_ x: Float) -> SIMD3<Float> { SIMD3<Float>(x, 0, 0) + axis * (g.deck + g.headHeight * 0.85) + inner * (g.bore * 0.75) }
            let start = railPoint(g.cylinderX[first] - g.pitch * 0.4)
            let end = railPoint(g.cylinderX[last] + g.pitch * 0.4)
            parts.cylinder(.fuel, .fuelRail, from: start, to: end, radius: 0.009, segments: 10)
            for index in cylinders {
                let top = railPoint(g.cylinderX[index])
                parts.cylinder(.fuel, .rubber, from: top, to: top + inner * 0.03 - axis * 0.02, radius: 0.007, segments: 8)
            }
            parts.tube(.fuel, .rubber, through: [start, start + SIMD3<Float>(-0.06, -0.02, 0), start + SIMD3<Float>(-0.1, -0.2, 0)], radius: 0.006)
        }
    }

    private static func addSensors(_ parts: inout Assembly, _ g: Geometry, _ b: EngineBuild, plenum mouth: SIMD3<Float>, collectors: [SIMD3<Float>]) {
        let sensors = b.sensors
        if sensors.maf != nil {
            let maf = mouth + SIMD3<Float>(-0.1, -0.02, 0.03)
            parts.cylinder(.sensors, .rubber, from: maf, to: maf + SIMD3<Float>(-0.06, 0, 0), radius: 0.042)
            parts.box(.sensors, .sensor, center: maf + SIMD3<Float>(-0.03, 0.05, 0), size: [0.03, 0.02, 0.025])
        }
        if sensors.map {
            parts.box(.sensors, .sensor, center: mouth + SIMD3<Float>(0.1, 0.06, 0), size: [0.025, 0.02, 0.02])
        }
        if sensors.iat {
            parts.cylinder(.sensors, .sensor, from: mouth + SIMD3<Float>(0.03, 0.03, 0), to: mouth + SIMD3<Float>(0.03, 0.06, 0), radius: 0.008)
        }
        // Every engine has an oxygen sensor; a wideband is the bigger, yellow-capped one.
        let oxygenFinish: Finish = sensors.wideband ? .sensor : .steel
        let oxygenRadius: Float = sensors.wideband ? 0.011 : 0.008
        for collector in collectors {
            parts.cylinder(.sensors, oxygenFinish, from: collector, to: collector + SIMD3<Float>(0, -0.05, 0), radius: oxygenRadius)
        }
        if sensors.knock {
            parts.cylinder(.sensors, .sensor, from: [0, 0, g.bore * 0.75], to: [0, 0, g.bore * 0.75 + 0.03], radius: 0.012)
        }
        if sensors.egt {
            for collector in collectors {
                parts.cylinder(.sensors, .sensor, from: collector + SIMD3<Float>(-0.05, 0, 0), to: collector + SIMD3<Float>(-0.05, 0.06, 0), radius: 0.004)
            }
        }
        if sensors.oil {
            let r = g.crankRadius
            parts.cylinder(.sensors, .sensor, from: [-g.rowLength / 2 + 0.03, -r, -g.bore * 0.7], to: [-g.rowLength / 2 + 0.03, -r, -g.bore * 0.7 - 0.035], radius: 0.01)
        }
    }

    private static func addWiring(_ parts: inout Assembly, _ g: Geometry) {
        for bank in g.tilts.indices {
            let axis = g.axis(bank)
            let inner = g.inner(bank)
            let x = g.bankCentreX(bank)
            let half = g.bankLength(bank) / 2
            // Lifted clear of the cam cover, outboard of it, so the valve train underneath and
            // the intake ports it crosses both stay readable.
            let base = axis * (g.deck + g.headHeight + 0.052) + inner * (g.bore * 0.88)
            parts.tube(.wiring, .rubber, through: [
                base + SIMD3<Float>(x - half - 0.12, -0.08, 0),
                base + SIMD3<Float>(x - half, 0, 0),
                base + SIMD3<Float>(x, 0.008, 0),
                base + SIMD3<Float>(x + half, 0, 0),
            ], radius: 0.007)
        }
    }

    private static func addNitrous(_ parts: inout Assembly, _ g: Geometry, kit: NitrousKit, plenum mouth: SIMD3<Float>) {
        let z = -(g.width / 2 + 0.18)
        let bottleStart = SIMD3<Float>(-0.2, -0.12, z)
        let bottleEnd = SIMD3<Float>(0.25, -0.12, z)
        parts.cylinder(.nitrous, .nitrous, from: bottleStart, to: bottleEnd, radius: 0.055)
        parts.cylinder(.nitrous, .polished, from: bottleEnd, to: bottleEnd + SIMD3<Float>(0.04, 0, 0), radius: 0.02)
        let solenoid = mouth + SIMD3<Float>(0.05, -0.05, -0.05)
        parts.box(.nitrous, .steel, center: solenoid, size: [0.04, 0.03, 0.03])
        if kit.kind == .wet {
            parts.box(.nitrous, .fuelRail, center: solenoid + SIMD3<Float>(0, 0, -0.04), size: [0.04, 0.03, 0.03])
        }
        parts.tube(.nitrous, .steel, through: [bottleEnd + SIMD3<Float>(0.04, 0, 0), bottleEnd + SIMD3<Float>(0.08, 0.1, 0), SIMD3<Float>(0, solenoid.y, z * 0.6), solenoid], radius: 0.005)
    }

    // MARK: - Valve train

    /// Valve events in crank degrees after each cylinder's firing top dead centre, and half the
    /// duration each valve is off its seat. Roughly a fast road cam: exhaust opens early for
    /// blowdown and shuts after TDC, intake opens before TDC and shuts well after bottom dead
    /// centre, leaving a little overlap.
    private static let intakeTiming = (centre: 460.0, halfDuration: 116.0)
    private static let exhaustTiming = (centre: 258.0, halfDuration: 118.0)

    /// Adds a cam, two valves, their springs and their rockers per cylinder, above each bank's
    /// head. Nothing here moves: `EngineAnimationSystem` poses it all from the crank angle.
    private static func addValveTrain(_ root: Entity, _ g: Geometry, _ spec: LayoutSpec) throws {
        // The crank angle of each cylinder's firing top dead centre, indexed by cylinder - 1.
        var firingTDC = [Double](repeating: 0, count: spec.cylinders)
        for (index, cylinder) in spec.firingOrder.enumerated() where cylinder >= 1 && cylinder <= spec.cylinders {
            firingTDC[cylinder - 1] = spec.firingAngles[index]
        }

        let b = g.bore
        let top = g.deck + g.headHeight
        let valveRow = b * 0.26
        let camRow = b * 0.42
        let pivotRow = b * 0.60
        let lift = b * 0.11
        // The valve tip, the retainer's underside, and where the rocker pad rests on top of it.
        let tip = top + 0.028
        let retainer = tip - 0.005
        let toe = top + 0.032
        let pivot = top + 0.030
        let seat = top + 0.002
        let spring = retainer - seat
        let camRadius = b * 0.14
        let rollerRadius = b * 0.045
        // Where along the rocker, as a fraction of its length out from the pivot, the cam presses.
        let roller: Float = 0.53
        // The rocker doubles the cam's lift at the valve, so the lobe only has to be half as tall.
        let camRise = lift * roller
        let rollerU = pivot + (toe - pivot) * roller
        // The base circle rests on the roller, so the shaft sits one base circle above it.
        let camU = rollerU + rollerRadius + camRadius
        let reach = ((pivotRow - valveRow) * (pivotRow - valveRow) + (pivot - toe) * (pivot - toe)).squareRoot()

        // Intake valves face the valley, exhaust valves face the outside of the bank.
        let rows: [(v: Float, timing: (centre: Double, halfDuration: Double))] = [
            (valveRow, Self.intakeTiming),
            (-valveRow, Self.exhaustTiming),
        ]

        var valveShape = MeshBuilder()
        // The stem hangs down into the head; its tip and retainer are what you see moving.
        valveShape.addCylinder(from: [0, -0.024, 0], to: [0, 0, 0], radius: b * 0.028, segments: 8)
        valveShape.addCylinder(from: [0, -0.005, 0], to: [0, 0.001, 0], radius: b * 0.085, segments: 10)
        let valveMesh = try valveShape.meshResource(named: "valve")

        var springShape = MeshBuilder()
        springShape.addCylinder(from: [0, 0, 0], to: [0, spring, 0], radius: b * 0.075, segments: 8)
        for coil in 0..<4 {
            let y = spring * (Float(coil) + 0.5) / 4
            springShape.addCylinder(from: [0, y - spring * 0.03, 0], to: [0, y + spring * 0.03, 0], radius: b * 0.10, segments: 10)
        }
        let springMesh = try springShape.meshResource(named: "spring")

        // A rocker from its pivot at the origin out to the valve: blade, pad, cam roller, hub.
        var rockerShape = MeshBuilder()
        rockerShape.addBox(center: [0, reach / 2, 0], size: [b * 0.07, reach, b * 0.045])
        rockerShape.addBox(center: [0, reach * 0.97, 0], size: [b * 0.09, reach * 0.12, b * 0.055])
        rockerShape.addCylinder(from: [-b * 0.045, reach * roller, 0], to: [b * 0.045, reach * roller, 0], radius: rollerRadius, segments: 10)
        rockerShape.addCylinder(from: [-b * 0.05, 0, 0], to: [b * 0.05, 0, 0], radius: b * 0.03, segments: 8)
        let rockerMesh = try rockerShape.meshResource(named: "rocker")

        let valveMaterial = Finish.polished.material
        let springMaterial = Finish.steel.material
        let rockerMaterial = Finish.aluminium.material
        let camMaterial = Finish.polished.material

        for bank in g.tilts.indices {
            let tilt = g.tilts[bank]
            let axis = g.axis(bank)
            let inner = g.inner(bank)
            let rotation = g.rotation(bank)
            let front = g.bankCentreX(bank) - g.bankLength(bank) / 2
            let back = g.bankCentreX(bank) + g.bankLength(bank) / 2

            func place(_ x: Float, _ u: Float, _ v: Float) -> SIMD3<Float> {
                SIMD3<Float>(x, 0, 0) + axis * u + inner * v
            }

            for (v, timing) in rows {
                // A cam turns about its own shaft, not about the crank, so each one is its own
                // entity sitting on the shaft's centre line with the lobes built around it.
                var camShape = MeshBuilder()
                camShape.addCylinder(from: [front, 0, 0], to: [back, 0, 0], radius: camRadius, segments: 12)

                for index in g.bankCylinders(bank) {
                    let x = g.cylinderX[index]
                    // Normalised into the 720-degree cycle so the lift curve only has to
                    // unwrap one turn when an event crosses the wrap.
                    let centre = (firingTDC[index] + timing.centre).truncatingRemainder(dividingBy: 720)
                    let halfDuration = timing.halfDuration

                    let valve = ModelEntity(mesh: valveMesh, materials: [valveMaterial])
                    valve.name = "part.heads.valve"
                    valve.orientation = rotation
                    valve.position = place(x, tip, v)
                    valve.components.set(ValveTrainComponent(
                        motion: .slide(axis: axis), rest: valve.position,
                        centre: centre, halfDuration: halfDuration, lift: lift
                    ))
                    makeTappable(valve)
                    root.addChild(valve)

                    let coil = ModelEntity(mesh: springMesh, materials: [springMaterial])
                    coil.name = "part.heads.spring"
                    coil.orientation = rotation
                    coil.position = place(x, seat, v)
                    coil.components.set(ValveTrainComponent(
                        motion: .compress(free: spring), rest: coil.position,
                        centre: centre, halfDuration: halfDuration, lift: lift
                    ))
                    root.addChild(coil)

                    let arm = ModelEntity(mesh: rockerMesh, materials: [rockerMaterial])
                    arm.name = "part.heads.rocker"
                    // The pivot sits outboard of the valve, with the cam between the two.
                    let hub = place(x, pivot, v > 0 ? pivotRow : -pivotRow)
                    let contact = place(x, toe, v) - hub
                    // The arm carries a rotation about x and nothing else, and its mesh runs along
                    // local +y, so the angle has to be the contact direction's *world* angle from
                    // +y. Measured in the bank's own frame instead it would come up short by the
                    // bank angle: the pad would miss the valve by 23 mm on a 45° bank and 43 mm
                    // on a boxer, which is the bug this comment exists to stop coming back.
                    let angle = atan2(contact.z, contact.y)
                    arm.position = hub
                    arm.orientation = simd_quatf(angle: angle, axis: [1, 0, 0])
                    // The toe's height along the bank is reach·cos(angle − tilt), so it descends
                    // as the arm turns in the direction sign(sin(angle − tilt)); using the world
                    // angle alone would open a boxer's valves backwards.
                    arm.components.set(ValveTrainComponent(
                        motion: .rock(angle: angle, swing: (sin(angle - tilt) >= 0 ? 1 : -1) * lift / reach),
                        rest: hub, centre: centre, halfDuration: halfDuration, lift: lift
                    ))
                    root.addChild(arm)

                    // The lobe is an offset disc that points straight down the bank, onto the
                    // rocker, at the crank angle where this valve reaches full lift.
                    let psi = Float.pi - Float(centre * 0.5 * .pi / 180)
                    let offset = camRadius * 0.22 + camRise
                    let lobeU = offset * cos(psi)
                    let lobeZ = offset * sin(psi)
                    camShape.addCylinder(
                        from: [x - g.pitch * 0.17, lobeU, lobeZ], to: [x + g.pitch * 0.17, lobeU, lobeZ],
                        radius: camRadius * 0.78, segments: 12
                    )
                }

                let row = v > 0 ? "in" : "ex"
                let cam = ModelEntity(mesh: try camShape.meshResource(named: "cam.\(bank).\(row)"), materials: [camMaterial])
                cam.name = "part.heads.cam"
                cam.position = place(0, camU, v > 0 ? camRow : -camRow)
                cam.components.set(CamshaftComponent(tilt: tilt))
                makeTappable(cam)
                root.addChild(cam)
            }
        }
    }

    // MARK: - Crank

    /// The crankshaft in its own frame: main journal, a throw per cylinder pointing so the
    /// cylinder is at top dead centre at its crank phase, counterweights, pulley and flywheel.
    private static func crankMesh(_ g: Geometry, _ b: EngineBuild) -> MeshBuilder {
        var mesh = MeshBuilder()
        let r = g.crankRadius
        let front = -g.rowLength / 2 - 0.03
        let back = g.rowLength / 2 + 0.03
        mesh.addCylinder(from: [front, 0, 0], to: [back, 0, 0], radius: g.bore * 0.2)
        let spec = b.layout.spec
        for index in 0..<spec.cylinders {
            let tilt = g.tilts[g.cylinderBank[index]]
            let phi = tilt - Float(spec.crankPins[index] * .pi / 180)
            let direction = SIMD3<Float>(0, cos(phi), sin(phi))
            let x = g.cylinderX[index]
            let pin = SIMD3<Float>(x, 0, 0) + direction * r
            mesh.addCylinder(from: pin - SIMD3<Float>(g.pitch * 0.22, 0, 0), to: pin + SIMD3<Float>(g.pitch * 0.22, 0, 0), radius: g.bore * 0.17, segments: 12)
            let web = simd_quatf(angle: phi, axis: [1, 0, 0])
            for side in [Float(-1), 1] {
                let wx = x + side * g.pitch * 0.27
                mesh.addBox(center: SIMD3<Float>(wx, 0, 0) + direction * (r * 0.5), size: [0.012, r + g.bore * 0.3, g.bore * 0.42], rotation: web)
                mesh.addBox(center: SIMD3<Float>(wx, 0, 0) - direction * (r * 0.55), size: [0.012, r * 0.9, g.bore * 0.7], rotation: web)
            }
        }
        mesh.addCylinder(from: [front, 0, 0], to: [front - 0.03, 0, 0], radius: g.bore * 0.75)
        mesh.addCylinder(from: [back, 0, 0], to: [back + 0.02, 0, 0], radius: g.deck * 0.45)
        return mesh
    }
}

extension Induction {
    var isTurbo: Bool {
        if case .turbo = self { return true }
        return false
    }
}
