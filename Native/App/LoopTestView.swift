import PistonForgeKit
import RealityKit
import SwiftUI
import UIKit

/// Build-loop test screen, not game UI. It proves four things in one install: the SwiftUI
/// app launches, RealityKit renders a non-AR scene, the PistonForgeKit package links, and the
/// approved theme direction (dark grey, never black, with colour hues) shows on a real phone.
struct LoopTestView: View {
    /// 78 mm bore, 82 mm stroke, cylinder count from the Swift layout table.
    private let displacement = Double.pi / 4 * 78 * 78 * 82 * Double(EngineLayout.i4.spec.cylinders) / 1000

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            RealityView { content in
                content.camera = .virtual
                content.add(Self.engineBlock())
                let camera = PerspectiveCamera()
                camera.position = [0, 0.25, 0.9]
                camera.look(at: .zero, from: camera.position, relativeTo: nil)
                content.add(camera)
                let light = DirectionalLight()
                light.light.intensity = 3000
                light.look(at: .zero, from: [0.6, 1, 0.8], relativeTo: nil)
                content.add(light)
            }

            VStack(spacing: 8) {
                Text("PREVIEW · build loop test")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.accent)
                Text("Piston Forge")
                    .font(.largeTitle.weight(.bold))
                Text("I4 78x82: \(Int(displacement.rounded())) cc, computed in Swift")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.top, 24)
            .padding(.horizontal, 16)
        }
    }

    /// Placeholder block: four cylinders on a crankcase, standing in for the engine model.
    private static func engineBlock() -> Entity {
        let root = Entity()
        let metal = SimpleMaterial(color: UIColor(white: 0.55, alpha: 1), roughness: 0.35, isMetallic: true)
        let block = ModelEntity(mesh: .generateBox(size: [0.42, 0.16, 0.2], cornerRadius: 0.02), materials: [metal])
        root.addChild(block)
        for index in 0..<4 {
            let cylinder = ModelEntity(mesh: .generateCylinder(height: 0.14, radius: 0.04), materials: [metal])
            cylinder.position = [Float(index) * 0.1 - 0.15, 0.15, 0]
            root.addChild(cylinder)
        }
        root.orientation = simd_quatf(angle: -0.5, axis: [0, 1, 0])
        return root
    }
}

/// Theme tokens: dark grey, never pure black, with low-opacity game-colour hues behind.
enum Theme {
    static let base = Color(red: 0.13, green: 0.14, blue: 0.15)
    static let accent = Color(red: 1.0, green: 0.55, blue: 0.18)
    static let hueWarm = Color(red: 0.9, green: 0.38, blue: 0.12)
    static let hueCool = Color(red: 0.16, green: 0.45, blue: 0.75)

    static var background: some View {
        ZStack {
            base
            RadialGradient(colors: [hueWarm.opacity(0.22), .clear], center: .topTrailing, startRadius: 0, endRadius: 520)
            RadialGradient(colors: [hueCool.opacity(0.18), .clear], center: .bottomLeading, startRadius: 0, endRadius: 560)
        }
    }
}
