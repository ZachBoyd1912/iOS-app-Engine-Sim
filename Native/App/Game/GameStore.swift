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
        sim.start()
        state = sim.state
    }

    func stop() {
        sim.stop()
        state = sim.state
        sound.drive(rpm: 0, throttle: 0, ignition: false)
    }

    func toggleEngine() {
        if isRunning { stop() } else { start() }
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

    private func reloadSound() {
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
            sound.drive(rpm: snap.state.rpm, throttle: pedal, ignition: !snap.state.limiterActive)
            if snap.finished {
                dragFinished = true
                sound.drive(rpm: 0, throttle: 0, ignition: false)
            }
            return
        }
        if let run = pullRun, !run.isFinished {
            run.step(dt: dt)
            currentPull = run.result
            let live = run.sim.state
            displayCrank = live.crankAngle
            sound.drive(rpm: live.rpm, throttle: 1, ignition: live.isRunning && !live.limiterActive)
            if run.isFinished {
                currentPull = run.result
                sound.drive(rpm: 0, throttle: 0, ignition: false)
            }
            return
        }
        state = sim.step(dt: dt, throttle: throttle, load: 0)
        displayCrank = state.crankAngle
        sound.drive(rpm: state.rpm, throttle: throttle, ignition: state.isRunning && !state.limiterActive)
    }

    // MARK: Saving

    private func persist() {
        try? store.save(save)
    }
}

