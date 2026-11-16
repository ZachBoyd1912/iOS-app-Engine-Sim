import PistonForgeKit

/// Sample data for the screen previews: real model output, not invented numbers.
@MainActor
enum SampleData {
    /// A twin-turbo cross-plane V8 with street parts, its fuel system sized and auto-tuned.
    static let build: EngineBuild = {
        var build = EngineBuild.starter(.v8Cross)
        build.name = "Garage V8 twin turbo"
        build.induction = .turbo(.twin)
        build.parts.head = 1
        build.parts.cams = 1
        build.parts.intercooler = 2
        build.parts.gasket = 1
        build.sensors.wideband = true
        build.sensors.egt = true
        build = build.withFuelSystemSized()
        build.ecu = ECUMap.autoBase(for: build)
        return build
    }()

    /// The engine idling at the moment of the preview.
    static let state: EngineState = {
        let sim = EngineSim(build: build)
        sim.start()
        var state = sim.state
        for _ in 0..<120 { state = sim.step(dt: 1.0 / 60, throttle: 0, load: 0) }
        return state
    }()

    static let warnings: [Warning] = [.mapOutOfDate]

    /// This build's pull and the stock engine's, for the overlay.
    static let pull: DynoResult = runDynoToEnd(build)
    static let lastPull: DynoResult = runDynoToEnd(EngineBuild.starter(.v8Cross))

    static let builds: [EngineBuild] = [build, EngineBuild.starter(.i4), EngineBuild.starter(.v12), EngineBuild.starter(.w16)]

    static let car = SaveFile.defaults().car
    static let settings = SaveFile.defaults().settings
}
