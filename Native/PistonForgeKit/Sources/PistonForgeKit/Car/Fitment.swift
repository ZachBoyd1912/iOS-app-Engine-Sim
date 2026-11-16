import Foundation

/// Whether an engine goes in a car's bay.
public enum Fitment: Equatable, Sendable {
    case fits
    /// The dimension ("length", "width" or "height") that is most over, and by how much.
    case blocked(dimension: String, overMm: Int)
}

/// RED stub.
public func fitment(_ e: EngineBuild, in body: CarBody) -> Fitment {
    .blocked(dimension: "", overMm: 0)
}
