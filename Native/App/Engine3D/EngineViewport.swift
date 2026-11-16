import PistonForgeKit
import RealityKit
import SwiftUI

/// The 3D engine. One finger orbits, two fingers pinch to zoom, a tap selects a part.
struct EngineViewport: View {
    let build: EngineBuild
    let state: EngineState
    var onSelect: (PartGroup) -> Void = { _ in }

    @State private var yaw: Float = 0.75
    @State private var pitch: Float = 0.42
    @State private var zoom: Float = 1
    @State private var dragStart: SIMD2<Float>?
    @State private var zoomStart: Float?

    private static let pitchRange: ClosedRange<Float> = (5 * .pi / 180)...(80 * .pi / 180)

    var body: some View {
        let model = build
        let focus = EngineModelBuilder.focus(for: build)
        RealityView { content in
            content.camera = .virtual
            do {
                content.add(try EngineModelBuilder.build(model))
            } catch {
                // A mesh that fails to build leaves the stage empty rather than crashing.
            }
            let camera = PerspectiveCamera()
            camera.name = "camera"
            content.add(camera)
            let key = DirectionalLight()
            key.light.intensity = 3500
            key.look(at: .zero, from: [-0.8, 1.4, 1.0], relativeTo: nil)
            content.add(key)
            let fill = DirectionalLight()
            fill.light.intensity = 1200
            fill.look(at: .zero, from: [1.0, 0.5, -1.2], relativeTo: nil)
            content.add(fill)
        } update: { content in
            if let root = content.entities.first(where: { $0.name == EngineModelBuilder.rootName }) {
                root.components.set(EngineMotionComponent(crankAngle: state.crankAngle))
            }
            if let camera = content.entities.first(where: { $0.name == "camera" }) {
                let distance = focus.radius * 2.4 * zoom
                let eye = focus.center + SIMD3<Float>(
                    distance * cos(pitch) * sin(yaw),
                    distance * sin(pitch),
                    distance * cos(pitch) * cos(yaw)
                )
                camera.look(at: focus.center, from: eye, relativeTo: nil)
            }
        }
        .id(EngineModelBuilder.signature(build))
        .gesture(
            DragGesture(minimumDistance: 4)
                .onChanged { value in
                    let start = dragStart ?? SIMD2<Float>(yaw, pitch)
                    if dragStart == nil { dragStart = start }
                    yaw = start.x - Float(value.translation.width) * 0.01
                    let raised = start.y + Float(value.translation.height) * 0.01
                    pitch = min(max(raised, Self.pitchRange.lowerBound), Self.pitchRange.upperBound)
                }
                .onEnded { _ in dragStart = nil }
        )
        .simultaneousGesture(
            MagnifyGesture()
                .onChanged { value in
                    let start = zoomStart ?? zoom
                    if zoomStart == nil { zoomStart = start }
                    zoom = min(max(start / Float(value.magnification), 0.45), 2.2)
                }
                .onEnded { _ in zoomStart = nil }
        )
        .simultaneousGesture(
            SpatialTapGesture()
                .targetedToAnyEntity()
                .onEnded { value in
                    if let group = PartGroup.from(entityName: value.entity.name) { onSelect(group) }
                }
        )
        .accessibilityElement()
        .accessibilityLabel("\(build.name) in 3D")
        .accessibilityHint("Drag to turn the engine, pinch to zoom, tap a part to choose it")
    }
}
