import Foundation

/// Times and trap speeds for a run. Times are seconds from the start of the run, not counting
/// the reaction time. A split is nil until the car passes it.
public struct DragTimeslip: Sendable {
    /// Set by the caller, for example from a launch-timing input. Default 0.
    public var reactionTimeS: Double = 0.0
    public var sixtyFootS: Double?
    public var threeThirtyFootS: Double?
    public var eighthMileS: Double?
    public var eighthTrapMph: Double?
    public var quarterMileS: Double?
    public var quarterTrapMph: Double?
    public var halfMileS: Double?
    public var halfTrapMph: Double?
    public var mileS: Double?
    public var mileTrapMph: Double?
    /// Highest speed reached so far, mph. 0 before the car moves.
    public var topSpeedMph: Double = 0
    /// True once the car has reached the run's length.
    public var finished: Bool = false

    public init() {}
}

/// A drag run: the car from a standing start to `lengthM`, with the timeslip recorded on the way.
/// Each split time is found by linear interpolation between the two steps either side of it.
public struct DragRun: Sendable {
    public struct Snapshot: Sendable {
        public let state: DriveState
        /// True once the run is over: the length was reached, or the time limit passed.
        public let finished: Bool
    }

    public static let sixtyFootM = 18.288
    public static let threeThirtyFootM = 100.584
    public static let eighthMileM = 201.168
    public static let quarterMileM = 402.336
    public static let halfMileM = 804.672
    public static let mileM = 1609.344
    /// A run that has not reached its length by this car time is over, with no quarter time.
    public static let timeLimitS = 120.0

    public let lengthM: Double
    private var sim: DriveSim
    private var previous: DriveState

    public private(set) var timeslip = DragTimeslip()
    /// True once the run is over, whether or not the length was reached.
    public private(set) var isOver = false

    public init(sim: DriveSim, lengthM: Double) {
        self.sim = sim
        self.lengthM = bounded(lengthM, 1...5000, or: DragRun.quarterMileM)
        self.previous = sim.state
    }

    /// Sets the reaction time shown on the slip. Clamped to 0...5 s.
    public mutating func setReactionTime(_ seconds: Double) {
        timeslip.reactionTimeS = bounded(seconds, 0...5, or: 0)
    }

    /// Advances the run by `dt` seconds. Does nothing once the run is over.
    public mutating func step(dt: Double, input: DriveInput) -> Snapshot {
        if isOver {
            return Snapshot(state: previous, finished: true)
        }
        let before = previous
        let after = sim.step(dt: dt, input: input)
        previous = after

        recordSplits(from: before, to: after)
        if after.speedMph > timeslip.topSpeedMph {
            timeslip.topSpeedMph = after.speedMph
        }
        if after.distanceM >= lengthM {
            timeslip.finished = true
            isOver = true
        } else if after.time >= DragRun.timeLimitS {
            isOver = true
        }
        return Snapshot(state: after, finished: isOver)
    }

    private mutating func recordSplits(from before: DriveState, to after: DriveState) {
        if timeslip.sixtyFootS == nil, let hit = DragRun.crossing(before, after, DragRun.sixtyFootM) {
            timeslip.sixtyFootS = hit.time
        }
        if timeslip.threeThirtyFootS == nil, let hit = DragRun.crossing(before, after, DragRun.threeThirtyFootM) {
            timeslip.threeThirtyFootS = hit.time
        }
        if timeslip.eighthMileS == nil, let hit = DragRun.crossing(before, after, DragRun.eighthMileM) {
            timeslip.eighthMileS = hit.time
            timeslip.eighthTrapMph = hit.mph
        }
        if timeslip.quarterMileS == nil, let hit = DragRun.crossing(before, after, DragRun.quarterMileM) {
            timeslip.quarterMileS = hit.time
            timeslip.quarterTrapMph = hit.mph
        }
        if timeslip.halfMileS == nil, let hit = DragRun.crossing(before, after, DragRun.halfMileM) {
            timeslip.halfMileS = hit.time
            timeslip.halfTrapMph = hit.mph
        }
        if timeslip.mileS == nil, let hit = DragRun.crossing(before, after, DragRun.mileM) {
            timeslip.mileS = hit.time
            timeslip.mileTrapMph = hit.mph
        }
    }

    /// Time and speed (mph) at the moment the car passes `distance`, interpolated between two
    /// steps. Nil unless the car passed it during this step.
    private static func crossing(_ before: DriveState, _ after: DriveState, _ distance: Double) -> (time: Double, mph: Double)? {
        guard before.distanceM < distance && after.distanceM >= distance else {
            return nil
        }
        let span = after.distanceM - before.distanceM
        let fraction = (distance - before.distanceM) / span
        let time = before.time + fraction * (after.time - before.time)
        let speedMps = before.speedMps + fraction * (after.speedMps - before.speedMps)
        return (time: time, mph: speedMps * DriveState.mphPerMps)
    }
}
