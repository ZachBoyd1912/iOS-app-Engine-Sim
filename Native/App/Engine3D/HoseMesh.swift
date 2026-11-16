import RealityKit
import simd

/// Collects triangles from boxes, cylinders and swept tubes into one mesh, so every static
/// part that shares a material becomes a single draw. Front faces wind counter-clockwise.
struct MeshBuilder {
    private(set) var positions: [SIMD3<Float>] = []
    private(set) var normals: [SIMD3<Float>] = []
    private(set) var indices: [UInt32] = []

    var isEmpty: Bool { indices.isEmpty }

    /// A box of `size` centred on `center`, turned by `rotation`.
    mutating func addBox(center: SIMD3<Float>, size: SIMD3<Float>, rotation: simd_quatf = simd_quatf(angle: 0, axis: [1, 0, 0])) {
        let half = size / 2
        let faces: [(SIMD3<Float>, SIMD3<Float>, SIMD3<Float>)] = [
            ([1, 0, 0], [0, 1, 0], [0, 0, 1]),
            ([-1, 0, 0], [0, 0, 1], [0, 1, 0]),
            ([0, 1, 0], [0, 0, 1], [1, 0, 0]),
            ([0, -1, 0], [1, 0, 0], [0, 0, 1]),
            ([0, 0, 1], [1, 0, 0], [0, 1, 0]),
            ([0, 0, -1], [0, 1, 0], [1, 0, 0]),
        ]
        for (normal, u, v) in faces {
            let base = UInt32(positions.count)
            for (su, sv) in [(Float(-1), Float(-1)), (1, -1), (1, 1), (-1, 1)] {
                let alongU: SIMD3<Float> = u * half * su
                let alongV: SIMD3<Float> = v * half * sv
                let local: SIMD3<Float> = normal * half + alongU + alongV
                positions.append(center + rotation.act(local))
                normals.append(rotation.act(normal))
            }
            indices += [base, base + 1, base + 2, base, base + 2, base + 3]
        }
    }

    /// A solid cylinder from `a` to `b`.
    mutating func addCylinder(from a: SIMD3<Float>, to b: SIMD3<Float>, radius: Float, segments: Int = 16, caps: Bool = true) {
        let axis = b - a
        guard simd_length(axis) > 1e-6 else { return }
        let d = simd_normalize(axis)
        let (e1, e2) = Self.frame(for: d)
        addRingStrip(rings: [(a, e1, e2), (b, e1, e2)], radius: radius, segments: segments)
        if caps {
            addCap(center: b, normal: d, e1: e1, e2: e2, radius: radius, segments: segments, flip: false)
            addCap(center: a, normal: -d, e1: e1, e2: e2, radius: radius, segments: segments, flip: true)
        }
    }

    /// A hose or pipe of `radius` swept along a Catmull-Rom curve through `points`.
    mutating func addTube(through points: [SIMD3<Float>], radius: Float, segments: Int = 10, samplesPerSpan: Int = 8) {
        let path = Self.catmullRom(points, samplesPerSpan: samplesPerSpan)
        guard path.count >= 2 else { return }
        var rings: [(SIMD3<Float>, SIMD3<Float>, SIMD3<Float>)] = []
        var e1 = SIMD3<Float>(0, 0, 0)
        for index in path.indices {
            let next = path[min(index + 1, path.count - 1)]
            let previous = path[max(index - 1, 0)]
            let along = next - previous
            guard simd_length(along) > 1e-6 else { continue }
            let tangent = simd_normalize(along)
            if rings.isEmpty {
                e1 = Self.frame(for: tangent).0
            } else {
                // Parallel transport: keep the ring from twisting along the hose.
                let projected = e1 - tangent * simd_dot(e1, tangent)
                e1 = simd_length(projected) > 1e-6 ? simd_normalize(projected) : Self.frame(for: tangent).0
            }
            rings.append((path[index], e1, simd_cross(tangent, e1)))
        }
        guard rings.count >= 2, let first = rings.first, let last = rings.last else { return }
        addRingStrip(rings: rings, radius: radius, segments: segments)
        let startTangent = simd_normalize(rings[1].0 - first.0)
        let endTangent = simd_normalize(last.0 - rings[rings.count - 2].0)
        addCap(center: last.0, normal: endTangent, e1: last.1, e2: last.2, radius: radius, segments: segments, flip: false)
        addCap(center: first.0, normal: -startTangent, e1: first.1, e2: first.2, radius: radius, segments: segments, flip: true)
    }

    @MainActor
    func meshResource(named name: String) throws -> MeshResource {
        var descriptor = MeshDescriptor(name: name)
        descriptor.positions = MeshBuffers.Positions(positions)
        descriptor.normals = MeshBuffers.Normals(normals)
        descriptor.primitives = .triangles(indices)
        return try MeshResource.generate(from: [descriptor])
    }

    // MARK: - Pieces

    /// Two vectors perpendicular to `d` forming a right-handed basis (e1, e2, d).
    private static func frame(for d: SIMD3<Float>) -> (SIMD3<Float>, SIMD3<Float>) {
        let reference: SIMD3<Float> = abs(d.y) < 0.9 ? [0, 1, 0] : [1, 0, 0]
        let e1 = simd_normalize(simd_cross(d, reference))
        return (e1, simd_cross(d, e1))
    }

    private mutating func addRingStrip(rings: [(SIMD3<Float>, SIMD3<Float>, SIMD3<Float>)], radius: Float, segments: Int) {
        let count = max(segments, 3)
        let base = UInt32(positions.count)
        for (center, e1, e2) in rings {
            for step in 0...count {
                let angle = Float(step) / Float(count) * 2 * .pi
                let direction: SIMD3<Float> = e1 * cos(angle) + e2 * sin(angle)
                positions.append(center + direction * radius)
                normals.append(direction)
            }
        }
        let stride = UInt32(count + 1)
        for ring in 0..<(rings.count - 1) {
            for step in 0..<count {
                let a0 = base + UInt32(ring) * stride + UInt32(step)
                let a1 = a0 + 1
                let b0 = a0 + stride
                let b1 = b0 + 1
                indices += [a0, a1, b1, a0, b1, b0]
            }
        }
    }

    private mutating func addCap(center: SIMD3<Float>, normal: SIMD3<Float>, e1: SIMD3<Float>, e2: SIMD3<Float>, radius: Float, segments: Int, flip: Bool) {
        let count = max(segments, 3)
        let middle = UInt32(positions.count)
        positions.append(center)
        normals.append(normal)
        for step in 0...count {
            let angle = Float(step) / Float(count) * 2 * .pi
            let direction: SIMD3<Float> = e1 * cos(angle) + e2 * sin(angle)
            positions.append(center + direction * radius)
            normals.append(normal)
        }
        for step in 0..<count {
            let a = middle + 1 + UInt32(step)
            indices += flip ? [middle, a + 1, a] : [middle, a, a + 1]
        }
    }

    /// Points along a Catmull-Rom spline through `controls` (ends clamped).
    static func catmullRom(_ controls: [SIMD3<Float>], samplesPerSpan: Int) -> [SIMD3<Float>] {
        guard controls.count >= 2 else { return controls }
        var out: [SIMD3<Float>] = []
        for span in 0..<(controls.count - 1) {
            let p0 = controls[max(span - 1, 0)]
            let p1 = controls[span]
            let p2 = controls[span + 1]
            let p3 = controls[min(span + 2, controls.count - 1)]
            for sample in 0..<samplesPerSpan {
                let t = Float(sample) / Float(samplesPerSpan)
                let t2 = t * t
                let t3 = t2 * t
                let a: SIMD3<Float> = p1 * 2
                let b: SIMD3<Float> = (p2 - p0) * t
                let c1: SIMD3<Float> = p0 * 2 - p1 * 5
                let c2: SIMD3<Float> = p2 * 4 - p3
                let c: SIMD3<Float> = (c1 + c2) * t2
                let d1: SIMD3<Float> = p1 * 3 - p0
                let d2: SIMD3<Float> = p3 - p2 * 3
                let d: SIMD3<Float> = (d1 + d2) * t3
                let sum: SIMD3<Float> = a + b + c + d
                out.append(sum * 0.5)
            }
        }
        out.append(controls[controls.count - 1])
        return out
    }
}
