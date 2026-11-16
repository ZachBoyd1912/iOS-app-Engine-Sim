import Foundation

/// What the sound needs to know about the engine right now.
public struct VoiceParams: Equatable, Sendable {
    public var rpm: Double
    /// Engine load: 1 is wide open without boost, more on boost.
    public var load: Double
    public var boostPsi: Double
    public var throttle: Double
    public var nitrous: Bool
    public var induction: Induction
    public var layout: EngineLayout
    /// Exhaust upgrade level, 0...3: louder and lower with each step.
    public var exhaustLevel: Int

    public init(rpm: Double, load: Double, boostPsi: Double, throttle: Double, nitrous: Bool, induction: Induction, layout: EngineLayout, exhaustLevel: Int) {
        self.rpm = rpm
        self.load = load
        self.boostPsi = boostPsi
        self.throttle = throttle
        self.nitrous = nitrous
        self.induction = induction
        self.layout = layout
        self.exhaustLevel = exhaustLevel
    }

    /// RED stub.
    public init(state: EngineState, build: EngineBuild) {
        self.init(rpm: 0, load: 0, boostPsi: 0, throttle: 0, nitrous: false, induction: .natural, layout: build.layout, exhaustLevel: 0)
    }
}

/// Real-time engine sound synthesis. RED stub.
public final class EngineVoice {
    public init(sampleRate: Double) {}

    public func render(_ params: VoiceParams, frames: Int, into buffer: UnsafeMutablePointer<Float>) {
        for index in 0..<frames { buffer[index] = 0 }
    }

    func firingTimes(layout: EngineLayout, rpm: Double, duration: Double, bank: Int) -> [Double] { [] }
}
