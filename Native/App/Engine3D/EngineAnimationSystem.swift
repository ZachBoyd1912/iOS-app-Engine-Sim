import Foundation
import PistonForgeKit
import RealityKit
import simd
import UIKit

/// On the engine's root entity: the crank angle to pose the moving parts at, degrees 0..<720.
struct EngineMotionComponent: Component {
    var crankAngle: Double = 0
    /// How hot the exhaust is, 0 (cold) ... 1 (glowing).
    var heat: Float = 0
}

/// On meshes that glow when the exhaust is hot. `lastHeat` avoids rebuilding the material every frame.
struct HeatGlowComponent: Component {
    var lastHeat: Float = -1
}

/// Marks the crankshaft entity, which turns about the x axis.
struct CrankComponent: Component {}

/// A piston or connecting rod and the geometry that places it for a crank angle.
struct ReciprocatingComponent: Component {
    enum Kind {
        case piston, rod
    }

    var kind: Kind
    /// Position of the cylinder along the crank, metres.
    var x: Float
    /// Tilt of the cylinder's bank about the crank axis, radians (0 = straight up).
    var bankTilt: Float
    /// Crank angle at which this cylinder reaches top dead centre, degrees.
    var tdcDegrees: Double
    var crankRadius: Float
    var rodLength: Float
    /// Height of the piston's middle above its gudgeon pin, metres.
    var crownOffset: Float
}

/// Marks a camshaft: the shafts and lobes of one valve row, turning about their own axis.
struct CamshaftComponent: Component {
    /// Tilt of the bank, radians. The cam's frame starts from here and turns on from it.
    var tilt: Float = 0
}

/// A valve, its spring or its rocker, and where its own cam puts it at a crank angle.
struct ValveTrainComponent: Component {
    enum Motion {
        /// A valve: slides along `axis` by the lift as it opens.
        case slide(axis: SIMD3<Float>)
        /// A spring: shortens along its local y, which points up the bank, by the lift.
        case compress(free: Float)
        /// A rocker: turns about the crank axis from `angle`, by `swing` as the valve opens.
        case rock(angle: Float, swing: Float)
    }

    var motion: Motion
    /// Where the part sits with the valve shut.
    var rest: SIMD3<Float>
    /// Crank degrees at full lift, 0..<720.
    var centre: Double
    /// Half the valve's open duration, in crank degrees.
    var halfDuration: Double
    /// Full lift at the peak of the lobe, metres.
    var lift: Float
}

/// The cam's lift curve, delegated to `PistonForgeKit.ValveTrainKinematics` so the timing is
/// the version covered by tests rather than a second copy that can drift from it.
enum CamLift {
    /// 0 with the valve shut, 1 at full lift.
    /// `centre` and `halfDuration` stay in crank degrees at this call site, because that is what
    /// the model builder computes from the firing order; the kinematics work in cam degrees.
    static func fraction(centre: Double, halfDuration: Double, crankAngle: Double) -> Float {
        Float(ValveTrainKinematics.normalisedLift(camAngle: crankAngle / 2,
                                                  eventCentre: centre / 2,
                                                  duration: halfDuration))
    }
}

/// Slider-crank geometry shared by the system and the model builder.
enum EngineKinematics {
    /// Where the crank pin, the gudgeon pin and the bank axis are for `part` at `crankAngle`.
    static func pins(_ part: ReciprocatingComponent, crankAngle: Double) -> (crankPin: SIMD3<Float>, gudgeon: SIMD3<Float>, axis: SIMD3<Float>) {
        let theta = Float((crankAngle - part.tdcDegrees) * .pi / 180)
        let throwAngle = theta + part.bankTilt
        let r = part.crankRadius
        let axis = SIMD3<Float>(0, cos(part.bankTilt), sin(part.bankTilt))
        let crankPin = SIMD3<Float>(part.x, r * cos(throwAngle), r * sin(throwAngle))
        let side = r * sin(theta)
        let reach = r * cos(theta) + (max(part.rodLength * part.rodLength - side * side, 0)).squareRoot()
        let gudgeon = SIMD3<Float>(part.x, 0, 0) + axis * reach
        return (crankPin, gudgeon, axis)
    }
}

/// Poses the crank, pistons, rods and valve train every frame from the root's
/// `EngineMotionComponent`.
struct EngineAnimationSystem: System {
    static let movers = EntityQuery(where: .has(ReciprocatingComponent.self))
    static let cranks = EntityQuery(where: .has(CrankComponent.self))
    static let shafts = EntityQuery(where: .has(CamshaftComponent.self))
    static let valveTrain = EntityQuery(where: .has(ValveTrainComponent.self))
    static let glowers = EntityQuery(where: .has(HeatGlowComponent.self))

    init(scene: RealityKit.Scene) {}

    /// Exhaust metal from cold grey-brown to dull red, orange, then yellow-white.
    @MainActor
    static func hotMaterial(_ heat: Float) -> PhysicallyBasedMaterial {
        let h = min(max(heat, 0), 1)
        var material = PhysicallyBasedMaterial()
        material.baseColor = .init(tint: Theme.Engine.exhaust)
        material.roughness = 0.6
        material.metallic = 0.7
        let red: CGFloat = 1.0
        let green = CGFloat(0.12 + 0.6 * h * h)
        let blue = CGFloat(0.02 + 0.35 * h * h * h)
        material.emissiveColor = .init(color: UIColor(red: red, green: green, blue: blue, alpha: 1))
        material.emissiveIntensity = h * h * 5
        return material
    }

    @MainActor
    mutating func update(context: SceneUpdateContext) {
        for entity in context.entities(matching: Self.glowers, updatingSystemWhen: .rendering) {
            guard var glow = entity.components[HeatGlowComponent.self],
                  let motion = entity.parent?.components[EngineMotionComponent.self],
                  let model = entity as? ModelEntity else { continue }
            if abs(motion.heat - glow.lastHeat) < 0.02 { continue }
            glow.lastHeat = motion.heat
            entity.components.set(glow)
            model.model?.materials = [Self.hotMaterial(motion.heat)]
        }
        for crank in context.entities(matching: Self.cranks, updatingSystemWhen: .rendering) {
            guard let motion = crank.parent?.components[EngineMotionComponent.self] else { continue }
            crank.orientation = simd_quatf(angle: Float(motion.crankAngle * .pi / 180), axis: [1, 0, 0])
        }
        for shaft in context.entities(matching: Self.shafts, updatingSystemWhen: .rendering) {
            guard let cam = shaft.components[CamshaftComponent.self],
                  let motion = shaft.parent?.components[EngineMotionComponent.self] else { continue }
            // The cam turns once for every two turns of the crank.
            shaft.orientation = simd_quatf(angle: cam.tilt + Float(motion.crankAngle * 0.5 * .pi / 180), axis: [1, 0, 0])
        }
        for entity in context.entities(matching: Self.valveTrain, updatingSystemWhen: .rendering) {
            guard let part = entity.components[ValveTrainComponent.self],
                  let motion = entity.parent?.components[EngineMotionComponent.self] else { continue }
            let open = CamLift.fraction(centre: part.centre, halfDuration: part.halfDuration, crankAngle: motion.crankAngle)
            switch part.motion {
            case .slide(let axis):
                entity.position = part.rest - axis * (part.lift * open)
            case .compress(let free):
                // A coil spring cannot close to nothing, so stop it at a quarter of its length.
                let length = max(free - part.lift * open, free * 0.25)
                entity.scale = [1, length / free, 1]
            case .rock(let angle, let swing):
                entity.orientation = simd_quatf(angle: angle + swing * open, axis: [1, 0, 0])
            }
        }
        for entity in context.entities(matching: Self.movers, updatingSystemWhen: .rendering) {
            guard let part = entity.components[ReciprocatingComponent.self],
                  let motion = entity.parent?.components[EngineMotionComponent.self] else { continue }
            let pins = EngineKinematics.pins(part, crankAngle: motion.crankAngle)
            switch part.kind {
            case .piston:
                entity.position = pins.gudgeon + pins.axis * part.crownOffset
                entity.orientation = simd_quatf(angle: part.bankTilt, axis: [1, 0, 0])
            case .rod:
                let span = pins.gudgeon - pins.crankPin
                entity.position = (pins.gudgeon + pins.crankPin) / 2
                if simd_length(span) > 1e-6 {
                    entity.orientation = simd_quatf(from: [0, 1, 0], to: simd_normalize(span))
                }
            }
        }
    }
}

/// Registers the 3D engine's components and system. Call once at launch.
enum Engine3D {
    @MainActor
    static func register() {
        EngineMotionComponent.registerComponent()
        CrankComponent.registerComponent()
        HeatGlowComponent.registerComponent()
        ReciprocatingComponent.registerComponent()
        CamshaftComponent.registerComponent()
        ValveTrainComponent.registerComponent()
        EngineAnimationSystem.registerSystem()
    }
}
