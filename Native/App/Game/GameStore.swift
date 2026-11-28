import Foundation
import PistonForgeKit
import SwiftUI

/// The live game: the saved garage, the engine being run, the dyno pull in progress and the sound.
/// Our model (`EngineSim`) owns every number; `SoundEngine` is told the rpm, throttle and rev-limiter
/// cut each frame and plays what engine-sim makes of it.
@Observable
@MainActor
final class GameStore {
    var save: SaveFile {
        didSet { persist() }
    }
    private(set) var loadStatus: LoadStatus = .fresh
    let sound = SoundEngine()

    var exhaust: ExhaustPreset = .sport { didSet { reloadSound() } }
    var limiter: LimiterStyle = .normal { didSet { reloadSound() } }
    var throttle = 0.0

    private(set) var state = EngineState()
    private(set) var sim: EngineSim
    private(set) var displayCrank = 0.0

    // Dyno
    private(set) var pullRun: DynoRun?
    private(set) var currentPull: DynoResult?
    private(set) var lastPull: DynoResult?

    // Drive (drag strip)
    var driveMode: DriveMode = .comfort
    var driveAutomatic = true
    var dragLengthM = DragRun.quarterMileM
    var launchControl = false
    var gasPedal = false
    var brakePedal = false
    var shiftUpRequest = false
    var shiftDownRequest = false
    private(set) var dragRun: DragRun?
    private(set) var driveState: DriveState?
    private(set) var dragFinished = false
    private var pedal = 0.0

    var pops: PopsLevel = .mild
    private var crankTimer = 0.0
    private var throttlePeak = 0.0
    private var noiseSeed: UInt32 = 0x9E37_79B9

    private let store: SaveStore
    private var loopTask: Task<Void, Never>?
    private var soundTask: Task<Void, Never>?

    init() {
        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("PistonForge", isDirectory: true)
        store = SaveStore(directory: directory)
        let (file, status) = store.load()
        save = file
        loadStatus = status
        let selected = file.builds.first { $0.id == file.selectedBuild } ?? file.builds[0]
        sim = EngineSim(build: selected)
        state = sim.state
    }

    var build: EngineBuild {
        get { save.builds.first { $0.id == save.selectedBuild } ?? save.builds[0] }
        set {
            guard let index = save.builds.firstIndex(where: { $0.id == newValue.id }) else { return }
            save.builds[index] = newValue
            sim.setBuild(newValue)
            state.warnings = sim.warnings
            reloadSound()
        }
    }

    var isRunning: Bool { state.isRunning }

    func select(_ id: UUID) {
        guard save.builds.contains(where: { $0.id == id }) else { return }
        stop()
        save.selectedBuild = id
        sim = EngineSim(build: build)
        state = sim.state
        currentPull = nil
        reloadSound()
    }

    func duplicate(_ id: UUID) {
        guard var copy = save.builds.first(where: { $0.id == id }) else { return }
        copy.id = UUID()
        copy.name += " copy"
        save.builds.append(copy)
    }

    func delete(_ id: UUID) {
        guard save.builds.count > 1 else { return }
        save.builds.removeAll { $0.id == id }
        if save.selectedBuild == id { select(save.builds[0].id) }
    }

    /// Adds a fresh stock engine of this layout to the garage and selects it.
    func addEngine(_ layout: EngineLayout) {
        let engine = EngineBuild.starter(layout)
        save.builds.append(engine)
        select(engine.id)
    }

    func start() {
        guard !isRunning, crankTimer <= 0 else { return }
        crankTimer = 1.2
    }

    func stop() {
        crankTimer = 0
        sim.stop()
        state = sim.state
        sound.drive(rpm: 0, throttle: 0, ignition: false)
        sound.setAux(kind: 0, boost01: 0, rpm: 0)
    }

    func toggleEngine() {
        if isRunning || crankTimer > 0 { stop() } else { start() }
    }

    func repair() {
        sim.repair()
        state = sim.state
    }

    func autoTune() {
        var tuned = build
        tuned.ecu = ECUMap.autoBase(for: tuned)
        build = tuned
    }

    func startPull() {
        guard pullRun == nil || pullRun?.isFinished == true else { return }
        if let previous = currentPull, !previous.samples.isEmpty { lastPull = previous }
        let pullSim = EngineSim(build: build)
        pullRun = DynoRun(sim: pullSim)
        currentPull = pullRun?.result
    }

    var isPulling: Bool {
        if let run = pullRun { return !run.isFinished }
        return false
    }

    // MARK: Driving

    var isDriving: Bool { dragRun != nil && !dragFinished }

    func startDrag() {
        stop()
        pedal = 0
        dragFinished = false
        let car = DriveSim(build: build, car: save.car, mode: driveMode, automatic: driveAutomatic)
        dragRun = DragRun(sim: car, lengthM: dragLengthM)
        driveState = car.state
    }

    func endDrag() {
        dragRun = nil
        driveState = nil
        dragFinished = false
        gasPedal = false
        brakePedal = false
        sound.drive(rpm: 0, throttle: 0, ignition: false)
    }

    var timeslip: DragTimeslip? { dragRun?.timeslip }

    // MARK: Sound loading

    func loadSoundIfNeeded() {
        reloadSound()
    }

    /// UI tests on CI pass `-noEngineSound`. The CI simulator runs engine-sim at 235-280% of a
    /// frame, and with the live UI on top the test runner times out (runs 45719432044 to
    /// 45915804981). Sound loading has its own short test, and the `sound-check` job renders it.
    private static let soundDisabled = ProcessInfo.processInfo.arguments.contains("-noEngineSound")

    private func reloadSound() {
        if Self.soundDisabled { return }
        soundTask?.cancel()
        let engine = build
        let chosenExhaust = exhaust
        let chosenLimiter = limiter
        soundTask = Task { [sound] in
            // A short pause so a slider or picker change does not reload on every tick.
            try? await Task.sleep(for: .milliseconds(300))
            if Task.isCancelled { return }
            await sound.load(build: engine, exhaust: chosenExhaust, limiter: chosenLimiter)
        }
    }

    /// Random spark cuts on the overrun (throttle lifted at high rpm): the burble.
    private func popCut(throttle: Double, rpm: Double) -> Bool {
        guard pops != .off, throttle < 0.06, rpm > 2200 else { return false }
        noiseSeed = noiseSeed &* 1_664_525 &+ 1_013_904_223
        let unit = Double(noiseSeed >> 8) / 16_777_216.0
        // The crackle fades as the revs fall.
        let fade = min(1, (rpm - 2200) / 2500)
        return unit < pops.cutProbability * fade
    }

    /// Turbo whistle, blower whine and the blow-off valve, from the model's boost.
    private func updateAux(rpm: Double, throttle: Double, boostPsi: Double) {
        let kind: Int
        switch build.induction {
        case .natural: kind = 0
        case .turbo: kind = 1
        case .supercharger: kind = 2
        }
        sound.setAux(kind: kind, boost01: min(max(boostPsi / 25, 0), 1), rpm: rpm)
        throttlePeak = max(throttle, throttlePeak - 0.8 * (1.0 / 60))
        if kind == 1, throttle < 0.2, throttlePeak > 0.65, boostPsi > 4 {
            sound.blowOff()
            throttlePeak = 0
        }
    }

    // MARK: The frame loop

    /// Runs about 60 times a second while the app is on screen.
    func run() async {
        let clock = ContinuousClock()
        var last = clock.now
        while !Task.isCancelled {
            try? await Task.sleep(for: .milliseconds(16))
            let now = clock.now
            let elapsed = last.duration(to: now).components
            last = now
            let dt = min(Double(elapsed.seconds) + Double(elapsed.attoseconds) / 1e18, 0.1)
            frame(dt: dt)
        }
    }

    private func frame(dt: Double) {
        // Starter motor: a short crank with the spark off, then the spark and the engine catch.
        if crankTimer > 0 {
            crankTimer -= dt
            let progress = max(0, 1 - crankTimer / 1.2)
            sound.drive(rpm: 110 + 140 * progress, throttle: 0.15, ignition: progress > 0.6)
            sound.setAux(kind: 0, boost01: 0, rpm: 0)
            if crankTimer <= 0 {
                sim.start()
                state = sim.state
            }
            return
        }
        if var run = dragRun, !dragFinished {
            // Pedal ramps so a tap is gentle and a hold is full throttle.
            let target = gasPedal ? 1.0 : 0.0
            pedal += (target - pedal) * min(1, dt * 6)
            let input = DriveInput(
                throttle: pedal, brake: brakePedal ? 1 : 0,
                manualShiftUp: shiftUpRequest, manualShiftDown: shiftDownRequest, launchControl: launchControl
            )
            shiftUpRequest = false
            shiftDownRequest = false
            let snap = run.step(dt: dt, input: input)
            dragRun = run
            driveState = snap.state
            displayCrank = (displayCrank + snap.state.rpm * 6 * dt).truncatingRemainder(dividingBy: 720)
            let spark = !snap.state.limiterActive && !popCut(throttle: pedal, rpm: snap.state.rpm)
            sound.drive(rpm: snap.state.rpm, throttle: pedal, ignition: spark)
            updateAux(rpm: snap.state.rpm, throttle: pedal, boostPsi: driveBoost(rpm: snap.state.rpm, throttle: pedal))
            if snap.finished {
                dragFinished = true
                sound.drive(rpm: 0, throttle: 0, ignition: false)
                sound.setAux(kind: 0, boost01: 0, rpm: 0)
            }
            return
        }
        if let run = pullRun, !run.isFinished {
            run.step(dt: dt)
            currentPull = run.result
            let live = run.sim.state
            displayCrank = live.crankAngle
            sound.drive(rpm: live.rpm, throttle: 1, ignition: live.isRunning && !live.limiterActive)
            updateAux(rpm: live.rpm, throttle: 1, boostPsi: live.boostPsi)
            if run.isFinished {
                currentPull = run.result
                sound.drive(rpm: 0, throttle: 0, ignition: false)
                sound.setAux(kind: 0, boost01: 0, rpm: 0)
            }
            return
        }
        state = sim.step(dt: dt, throttle: throttle, load: 0)
        displayCrank = state.crankAngle
        let spark = state.isRunning && !state.limiterActive && !popCut(throttle: throttle, rpm: state.rpm)
        sound.drive(rpm: state.rpm, throttle: throttle, ignition: spark)
        updateAux(rpm: state.rpm, throttle: throttle, boostPsi: state.isRunning ? state.boostPsi : 0)
    }

    /// Boost while driving: the model's steady boost at this rpm and pedal.
    private func driveBoost(rpm: Double, throttle: Double) -> Double {
        steadyBoostPsi(build, rpm: rpm, throttle: throttle, target: build.ecu.boostTargetPsi)
    }

    // MARK: Saving

    private func persist() {
        try? store.save(save)
    }
}

