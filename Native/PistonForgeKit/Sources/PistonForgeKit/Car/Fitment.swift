import Foundation

/// Whether an engine goes in a car's bay.
public enum Fitment: Equatable, Sendable {
    case fits
    /// The dimension ("length", "width" or "height") that is most over, and by how much.
    case blocked(dimension: String, overMm: Int)
}

/// Whether `e`, with its induction, fits `body`'s engine bay. When it does not, names the
/// dimension that is furthest over and by how many millimetres (rounded up).
public func fitment(_ e: EngineBuild, in body: CarBody) -> Fitment {
    let engine = e.envelopeMm
    let bay = body.spec.bayMm
    let overs: [(String, Double)] = [
        ("length", engine.length - bay.length),
        ("width", engine.width - bay.width),
        ("height", engine.height - bay.height),
    ]
    guard let worst = overs.max(by: { $0.1 < $1.1 }), worst.1 > 0 else { return .fits }
    return .blocked(dimension: worst.0, overMm: Int(worst.1.rounded(.up)))
}
