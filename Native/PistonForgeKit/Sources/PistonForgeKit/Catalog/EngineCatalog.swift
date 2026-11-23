import Foundation

/// One row of the researched engine catalogue (`docs/research/raw/engines.md`).
///
/// Provenance is first-class: the research file states a firing order only where a source
/// gives one, marks derived values, and leaves the rest unsourced. The catalogue must never
/// pretend otherwise, so `firingSource` is required and `firingOrder` is nil unless the source
/// actually stated one.
public struct EngineCatalogEntry: Sendable, Hashable {
    public enum FiringSource: String, Sendable, CaseIterable {
        /// A source states the order outright.
        case sourced
        /// Computed from a stated rule (e.g. the 720/N rule, or wire timing).
        case derived
        /// No source found. `firingOrder` must be nil.
        case unsourced
        /// Not applicable (single cylinder, rotary).
        case notApplicable
    }

    public let id: String
    public let name: String
    public let cylinders: Int
    public let layout: String
    public let crank: String
    public let firingOrder: String?
    public let firingSource: FiringSource
    public let displacementCc: Int?
    /// Source tags as written in the research file, e.g. "S2, E14".
    public let sources: String

    public init(id: String, name: String, cylinders: Int, layout: String, crank: String,
                firingOrder: String?, firingSource: FiringSource, displacementCc: Int?, sources: String) {
        self.id = id
        self.name = name
        self.cylinders = cylinders
        self.layout = layout
        self.crank = crank
        self.firingOrder = firingOrder
        self.firingSource = firingSource
        self.displacementCc = displacementCc
        self.sources = sources
    }
}

/// The whole catalogue. Deliberately empty until `EngineCatalogTests` is satisfied:
/// the tests are the specification, the data is generated from the research file.
public enum EngineCatalog {
    public static let all: [EngineCatalogEntry] = []
}
