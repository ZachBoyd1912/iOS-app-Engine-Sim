import Foundation
import RealityKit
import simd

/// On the engine's root entity: the crank angle to pose the moving parts at, degrees 0..<720.
struct EngineMotionComponent: Component {
    var crankAngle: Double = 0
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

/// Poses the crank, pistons and rods every frame from the root's `EngineMotionComponent`.
struct EngineAnimationSystem: System {
    static let movers = EntityQuery(where: .has(ReciprocatingComponent.self))
    static let cranks = EntityQuery(where: .has(CrankComponent.self))

    init(scene: RealityKit.Scene) {}

    @MainActor
    mutating func update(context: SceneUpdateContext) {
        for crank in context.entities(matching: Self.cranks, updatingSystemWhen: .rendering) {
            guard let motion = crank.parent?.components[EngineMotionComponent.self] else { continue }
            crank.orientation = simd_quatf(angle: Float(motion.crankAngle * .pi / 180), axis: [1, 0, 0])
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
        ReciprocatingComponent.registerComponent()
        EngineAnimationSystem.registerSystem()
    }
}
