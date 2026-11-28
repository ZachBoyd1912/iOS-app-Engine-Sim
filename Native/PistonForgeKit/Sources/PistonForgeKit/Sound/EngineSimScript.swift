import Foundation

// Writes engine-sim engine scripts (.mr text) and exhaust impulse responses from our own engine
// descriptions, so every engine's firing order, bank angles and exhaust come from OUR catalogue.
// Nothing here is copied from engine-sim's bundled engines: the script grammar (the language
// library under es/) is engine-sim's MIT code; the engine, the numbers and the sounds are ours.

/// How the rev limiter behaves. The value is how long (seconds) the spark is cut at the limit.
public enum LimiterStyle: String, CaseIterable, Codable, Sendable {
    case soft, normal, hard

    public var displayName: String {
        switch self {
        case .soft: "Soft cut"
        case .normal: "Hard cut"
        case .hard: "Bouncing limiter"
        }
    }

    var cutSeconds: Double {
        switch self {
        case .soft: 0.03
        case .normal: 0.10
        case .hard: 0.25
        }
    }
}

/// An exhaust set: header, pipe and silencer. In this stage it changes the sound; the power effect
/// (back pressure) arrives with the dyno depth stage.
public enum ExhaustPreset: String, CaseIterable, Codable, Sendable {
    case stock, sport, catback, straight, race, muffled, reference

    public var displayName: String {
        switch self {
        case .stock: "Stock (cast manifold, quiet)"
        case .sport: "Sport (tubular headers, chambered)"
        case .catback: "Cat-back (stock headers, free-flow pipe)"
        case .straight: "Straight pipe (loud, raw)"
        case .race: "Race (long-tube headers, no silencer)"
        case .muffled: "Muffled (deep and soft)"
        case .reference: "Reference recording (personal test only)"
        }
    }

    /// False for the one preset that uses engine-sim's own recording, which has no stated licence.
    public var isShippable: Bool { self != .reference }

    /// Primary (header) length in inches and main pipe length in inches.
    var headerInches: Double {
        switch self {
        case .stock: 12
        case .sport: 24
        case .catback: 14
        case .straight: 18
        case .race: 34
        case .muffled: 10
        case .reference: 29
        }
    }

    var pipeInches: Double {
        switch self {
        case .stock: 120
        case .sport: 100
        case .catback: 90
        case .straight: 70
        case .race: 60
        case .muffled: 140
        case .reference: 100
        }
    }

    /// Output loudness multiplier.
    var loudness: Double {
        switch self {
        case .stock: 0.75
        case .sport: 1.0
        case .catback: 1.0
        case .straight: 1.35
        case .race: 1.5
        case .muffled: 0.6
        case .reference: 1.0
        }
    }

    /// Settings for the generated impulse response.
    var impulse: ImpulseSettings {
        switch self {
        case .stock: ImpulseSettings(lowpassHz: 1500, decayMs: 70, tail: 0.30, echoes: [(5.5, 0.30), (11, 0.22), (17, 0.15)])
        case .sport: ImpulseSettings(lowpassHz: 2800, decayMs: 55, tail: 0.30, echoes: [(4.2, 0.35), (9, 0.25), (15, 0.12)])
        case .catback: ImpulseSettings(lowpassHz: 3200, decayMs: 50, tail: 0.28, echoes: [(3.6, 0.30), (8, 0.18)])
        case .straight: ImpulseSettings(lowpassHz: 7000, decayMs: 28, tail: 0.18, echoes: [(2.4, 0.40), (5, 0.25), (9, 0.12)])
        case .race: ImpulseSettings(lowpassHz: 6000, decayMs: 22, tail: 0.15, echoes: [(1.8, 0.35), (4, 0.2)])
        case .muffled: ImpulseSettings(lowpassHz: 900, decayMs: 90, tail: 0.35, echoes: [(7, 0.35), (14, 0.28), (22, 0.2)])
        case .reference: ImpulseSettings(lowpassHz: 3000, decayMs: 50, tail: 0.3, echoes: [])
        }
    }
}

struct ImpulseSettings {
    let lowpassHz: Double
    let decayMs: Double
    let tail: Double
    let echoes: [(ms: Double, gain: Double)]
}

public enum ExhaustImpulse {
    public static let sampleRate = 44100
    /// engine-sim only uses the first 10,000 samples of an impulse response.
    public static let length = 10_000

    /// A 16-bit mono WAV file holding a synthetic exhaust response: a direct pulse, a few echoes off
    /// the silencer chambers, and a decaying noise tail, all low-passed to give the pipe its tone.
    public static func wav(_ preset: ExhaustPreset) -> [UInt8] {
        let s = preset.impulse
        var h = [Double](repeating: 0, count: length)
        h[0] = 1.0
        for echo in s.echoes {
            let index = Int(echo.ms * Double(sampleRate) / 1000)
            if index > 0 && index < length { h[index] += echo.gain }
        }
        var state: UInt32 = 0x1234_5678
        let decaySamples = max(s.decayMs, 1) * Double(sampleRate) / 1000
        for index in 24..<length {
            state = state &* 1_664_525 &+ 1_013_904_223
            let unit = Double(state) / 4_294_967_296.0 * 2 - 1
            let envelope = exp(-Double(index) / decaySamples)
            h[index] += unit * s.tail * envelope
        }
        // Two one-pole low-pass passes give a -12 dB/octave roll-off at the chosen frequency.
        let a = 1 - exp(-2 * Double.pi * s.lowpassHz / Double(sampleRate))
        for _ in 0..<2 {
            var y = 0.0
            for index in 0..<length {
                y += a * (h[index] - y)
                h[index] = y
            }
        }
        // Remove DC so the pipe does not thump.
        var low = 0.0
        let dcA = 1 - exp(-2 * Double.pi * 25 / Double(sampleRate))
        for index in 0..<length {
            low += dcA * (h[index] - low)
            h[index] -= low
        }
        var peak = 0.0001
        for value in h { peak = max(peak, abs(value)) }
        let scale = 0.92 / peak
        var pcm = [Int16](repeating: 0, count: length)
        for index in 0..<length {
            let value = (h[index] * scale * 32767).rounded()
            pcm[index] = Int16(max(-32767, min(32767, value)))
        }
        return wavBytes(pcm)
    }

    static func wavBytes(_ pcm: [Int16]) -> [UInt8] {
        var out: [UInt8] = []
        func u32(_ v: UInt32) { out.append(contentsOf: [UInt8(v & 255), UInt8((v >> 8) & 255), UInt8((v >> 16) & 255), UInt8((v >> 24) & 255)]) }
        func u16(_ v: UInt16) { out.append(contentsOf: [UInt8(v & 255), UInt8((v >> 8) & 255)]) }
        let dataBytes = UInt32(pcm.count * 2)
        out.append(contentsOf: Array("RIFF".utf8))
        u32(36 + dataBytes)
        out.append(contentsOf: Array("WAVEfmt ".utf8))
        u32(16)
        u16(1)
        u16(1)
        u32(UInt32(sampleRate))
        u32(UInt32(sampleRate * 2))
        u16(2)
        u16(16)
        out.append(contentsOf: Array("data".utf8))
        u32(dataBytes)
        for sample in pcm { u16(UInt16(bitPattern: sample)) }
        return out
    }
}

/// Everything the app writes into a work folder so engine-sim can load one engine.
public struct EngineSimPackage: Sendable {
    /// File name of the main script to compile (inside the work folder).
    public let mainScript: String
    /// Relative path to bytes, e.g. "ir_sport.wav".
    public let files: [String: [UInt8]]
    /// The engine script text itself, also stored in `files` under `engineScript`.
    public let engineScript: String
}

public enum EngineSimScript {
    /// The sign used to turn a bank's angle offset into a crank-pin offset. Verified in CI by
    /// running every layout and requiring it to rev freely; if a layout does not, flip it.
    public static let defaultBankPhaseSign: Double = 1

    static func num(_ x: Double) -> String { String(format: "%.4f", x) }

    /// Axis angle (degrees from vertical) of each bank. Matches the 3D model's banks.
    static func bankAxes(banks: Int, bankAngle: Double) -> [Double] {
        switch banks {
        case 1: return [0]
        case 2: return [bankAngle / 2, -bankAngle / 2]
        default:
            let wide = bankAngle / 2
            return [wide + 15, wide - 15, -wide + 15, -wide - 15]
        }
    }

    static func positive(_ degrees: Double) -> Double {
        let m = degrees.truncatingRemainder(dividingBy: 360)
        return m < 0 ? m + 360 : m
    }

    public static func package(for build: EngineBuild, exhaust: ExhaustPreset, limiter: LimiterStyle, bankPhaseSign: Double = EngineSimScript.defaultBankPhaseSign) -> EngineSimPackage {
        let spec = build.layout.spec
        let cylinders = spec.cylinders
        let banks = spec.banks
        let axes = bankAxes(banks: banks, bankAngle: spec.bankAngle)
        let bore = build.bore
        let stroke = build.stroke
        let perCylinderCc: Double = Double.pi / 4 * bore * bore * stroke / 1000
        let totalLitres: Double = perCylinderCc * Double(cylinders) / 1000
        let scale: Double = perCylinderCc / 562
        let boreScale: Double = bore / 94
        let redline: Double = build.mechanicalRedline
        let chamber: Double = perCylinderCc / max(build.compression - 1, 4)
        let simulationFrequency: Int = cylinders >= 12 ? (cylinders >= 16 ? 4000 : 5000) : (cylinders >= 10 ? 6500 : min(20_000, 80_000 / cylinders))
        let exhaustCount = banks == 1 ? 1 : 2
        let loudness = exhaust.loudness
        let perExhaust: Double = Double(cylinders) / Double(exhaustCount)
        let audioVolume: Double = 0.2 * loudness * (4 / max(perExhaust, 1)).squareRoot()
        let wheelbaseFree: Double = totalLitres / 4.5

        var s = ""
        func line(_ text: String = "") { s += text + "\n" }

        line("import \"engine_sim.mr\"")
        line()
        line("units units()")
        line("constants constants()")
        line("impulse_response_library ir_lib()")
        line()
        line("private node wires {")
        for c in 1...cylinders { line("    output wire\(c): ignition_wire();") }
        line("}")
        line()
        line("private node generated_head {")
        line("    input intake_camshaft;")
        line("    input exhaust_camshaft;")
        line("    input chamber_volume: \(num(chamber)) * units.cc;")
        line("    input intake_runner_volume: \(num(149.6 * scale)) * units.cc;")
        line("    input intake_runner_cross_section_area: \(num(2.2 * 2.2 * scale)) * units.inch * units.inch;")
        line("    input exhaust_runner_volume: \(num(50 * scale)) * units.cc;")
        line("    input exhaust_runner_cross_section_area: \(num(1.75 * 1.75 * scale)) * units.inch * units.inch;")
        line("    input flow_attenuation: \(num(boreScale * boreScale));")
        line("    input lift_scale: 1.0;")
        line("    input flip_display: false;")
        line("    alias output __out: head;")
        line()
        line("    function intake_flow(50 * units.thou)")
        line("    intake_flow")
        let intake = [(0, 0), (50, 58), (100, 103), (150, 156), (200, 214), (250, 249), (300, 268), (350, 280), (400, 280), (450, 281)]
        for point in intake {
            line("        .add_flow_sample(\(point.0) * lift_scale, \(point.1) * flow_attenuation)")
        }
        line()
        line("    function exhaust_flow(50 * units.thou)")
        line("    exhaust_flow")
        let exhaustFlow = [(0, 0), (50, 37), (100, 72), (150, 113), (200, 160), (250, 196), (300, 222), (350, 235), (400, 245), (450, 246)]
        for point in exhaustFlow {
            line("        .add_flow_sample(\(point.0) * lift_scale, \(point.1) * flow_attenuation)")
        }
        line()
        line("    generic_cylinder_head head(")
        line("        chamber_volume: chamber_volume,")
        line("        intake_runner_volume: intake_runner_volume,")
        line("        intake_runner_cross_section_area: intake_runner_cross_section_area,")
        line("        exhaust_runner_volume: exhaust_runner_volume,")
        line("        exhaust_runner_cross_section_area: exhaust_runner_cross_section_area,")
        line("        intake_port_flow: intake_flow,")
        line("        exhaust_port_flow: exhaust_flow,")
        line("        valvetrain: standard_valvetrain(")
        line("            intake_camshaft: intake_camshaft,")
        line("            exhaust_camshaft: exhaust_camshaft")
        line("        ),")
        line("        flip_display: flip_display")
        line("    )")
        line("}")
        line()
        line("private node turbulence_to_flame_speed_ratio {")
        line("    alias output __out:")
        line("        function(5.0)")
        for k in 0...9 {
            let x = Double(k) * 5
            let factor: Double = k == 0 ? 0 : (k == 1 ? 1.5 : (k == 2 ? 1.75 : 2.0))
            let y: Double = k == 0 ? 3.0 : factor * x
            line("            .add_sample(\(num(x)), \(num(y)))" + (k == 9 ? ";" : ""))
        }
        line("}")
        line()
        line("public node generated_engine {")
        line("    alias output __out: engine;")
        line()
        let starter: Double = max(60, 200 * wheelbaseFree)
        line("    engine engine(")
        line("        name: \"\(spec.name)\",")
        line("        starter_torque: \(num(starter)) * units.lb_ft,")
        line("        starter_speed: 200 * units.rpm,")
        line("        redline: \(Int(redline)) * units.rpm,")
        line("        throttle_gamma: 2.0,")
        line("        fuel: fuel(")
        line("            max_burning_efficiency: 1.0,")
        line("            turbulence_to_flame_speed_ratio: turbulence_to_flame_speed_ratio()")
        line("        ),")
        line("        hf_gain: 0.01,")
        line("        noise: 1.0,")
        line("        jitter: 0.15,")
        line("        simulation_frequency: \(simulationFrequency)")
        line("    )")
        line()
        line("    wires wires()")
        line()
        let crankMass: Double = max(20, 60 * Double(cylinders) / 8)
        line("    label stroke(\(num(stroke)) * units.mm)")
        line("    label bore(\(num(bore)) * units.mm)")
        line("    label rod_length(\(num(stroke * build.rodRatio)) * units.mm)")
        line("    label rod_mass(\(num(max(25, 50 * scale))) * units.g)")
        line("    label compression_height(\(num(boreScale)) * units.inch)")
        line("    label crank_mass(\(num(crankMass)) * units.lb)")
        line("    label flywheel_mass(30 * units.lb)")
        line("    label flywheel_radius(8 * units.inch)")
        line("    label crank_moment(1.5 * disk_moment_of_inertia(mass: crank_mass, radius: stroke))")
        line("    label flywheel_moment(disk_moment_of_inertia(mass: flywheel_mass, radius: flywheel_radius))")
        line("    label other_moment(disk_moment_of_inertia(mass: 1 * units.kg, radius: 1.0 * units.cm))")
        line()
        line("    crankshaft c0(")
        line("        throw: stroke / 2,")
        line("        flywheel_mass: flywheel_mass,")
        line("        mass: crank_mass,")
        line("        friction_torque: \(num(max(6, 2.5 * Double(cylinders)))) * units.lb_ft,")
        line("        moment_of_inertia: crank_moment + flywheel_moment + other_moment,")
        line("        position_x: 0.0,")
        line("        position_y: 0.0,")
        line("        tdc: \(num(90 + axes[0])) * units.deg")
        line("    )")
        line()
        for c in 1...cylinders {
            let bank = spec.bankOf[c - 1]
            let offset: Double = bankPhaseSign * (axes[0] - axes[bank])
            let pin = positive(spec.crankPins[c - 1] - offset)
            line("    rod_journal rj\(c)(angle: \(num(pin)) * units.deg)")
        }
        line("    c0")
        for c in 1...cylinders { line("        .add_rod_journal(rj\(c))") }
        line()
        line("    piston_parameters piston_params(")
        line("        mass: \(num(max(60, 100 * scale))) * units.g,")
        line("        compression_height: compression_height,")
        line("        wrist_pin_position: 0.0,")
        line("        displacement: 0.0")
        line("    )")
        line()
        line("    connecting_rod_parameters cr_params(")
        line("        mass: rod_mass,")
        line("        moment_of_inertia: rod_moment_of_inertia(mass: rod_mass, length: rod_length),")
        line("        center_of_mass: 0.0,")
        line("        length: rod_length")
        line("    )")
        line()
        line("    intake intake(")
        line("        plenum_volume: \(num(max(0.25, 1.325 * wheelbaseFree))) * units.L,")
        line("        plenum_cross_section_area: \(num(max(6, 20 * wheelbaseFree))) * units.cm2,")
        line("        intake_flow_rate: k_carb(\(num(max(150, 700 * wheelbaseFree)))),")
        line("        runner_flow_rate: k_carb(\(num(max(40, 100 * scale)))),")
        line("        runner_length: 12.0 * units.inch,")
        line("        idle_flow_rate: k_carb(0.0),")
        line("        idle_throttle_plate_position: 0.995,")
        line("        velocity_decay: 0.5")
        line("    )")
        line()
        line("    exhaust_system_parameters es_params(")
        line("        outlet_flow_rate: k_carb(\(num(max(250, 1000 * wheelbaseFree)))),")
        line("        primary_tube_length: \(num(exhaust.headerInches)) * units.inch,")
        line("        primary_flow_rate: k_carb(\(num(max(150, 600 * wheelbaseFree)))),")
        line("        velocity_decay: 0.5")
        line("    )")
        line()
        let irFile = exhaust == .reference ? "../es/sound-library/new/mild_exhaust_reverb.wav" : "ir_\(exhaust.rawValue).wav"
        line("    impulse_response exhaust_ir(filename: \"\(irFile)\", volume: 0.01)")
        for e in 0..<exhaustCount {
            line("    exhaust_system exhaust\(e)(")
            line("        es_params,")
            line("        audio_volume: \(num(audioVolume * (e == 0 ? 1.0 : 0.95))),")
            line("        length: \(num(exhaust.pipeInches)) * units.inch,")
            line("        impulse_response: exhaust_ir")
            line("    )")
        }
        line()
        line("    cylinder_bank_parameters bank_params(")
        line("        bore: bore,")
        line("        deck_height: stroke / 2 + rod_length + compression_height")
        line("    )")
        line()
        for b in 0..<banks { line("    cylinder_bank b\(b)(bank_params, angle: \(num(axes[b])) * units.deg)") }
        line()
        // Camshafts: one intake and one exhaust per bank, with a lobe per cylinder at its firing angle.
        line("    camshaft_parameters cam_params(advance: 0 * units.deg, base_radius: 1.0 * units.inch)")
        line("    harmonic_cam_lobe intake_lobe(")
        line("        duration_at_50_thou: 230 * units.deg,")
        line("        gamma: 0.9,")
        line("        lift: \(num(551 * boreScale)) * units.thou,")
        line("        steps: 256")
        line("    )")
        line("    harmonic_cam_lobe exhaust_lobe(")
        line("        duration_at_50_thou: 230 * units.deg,")
        line("        gamma: 0.9,")
        line("        lift: \(num(551 * boreScale)) * units.thou,")
        line("        steps: 256")
        line("    )")
        for b in 0..<banks {
            line("    camshaft intake_cam\(b)(cam_params, lobe_profile: intake_lobe)")
            line("    camshaft exhaust_cam\(b)(cam_params, lobe_profile: exhaust_lobe)")
        }
        var firingAngleOf = [Double](repeating: 0, count: cylinders)
        for (index, cylinder) in spec.firingOrder.enumerated() { firingAngleOf[cylinder - 1] = spec.firingAngles[index] }
        for b in 0..<banks {
            let members = (1...cylinders).filter { spec.bankOf[$0 - 1] == b }
            line("    exhaust_cam\(b)")
            for c in members { line("        .add_lobe(360 * units.deg - 116 * units.deg + \(num(firingAngleOf[c - 1])) * units.deg)") }
            line("    intake_cam\(b)")
            for c in members { line("        .add_lobe(360 * units.deg + 116 * units.deg + \(num(firingAngleOf[c - 1])) * units.deg)") }
        }
        line()
        for b in 0..<banks {
            let members = (1...cylinders).filter { spec.bankOf[$0 - 1] == b }
            let exhaustIndex = banks == 1 ? 0 : (b < banks / 2 ? 0 : 1)
            line("    b\(b)")
            for c in members {
                line("        .add_cylinder(")
                line("            piston: piston(piston_params, blowby: k_28inH2O(0.0)),")
                line("            connecting_rod: connecting_rod(cr_params),")
                line("            rod_journal: rj\(c),")
                line("            intake: intake,")
                line("            exhaust_system: exhaust\(exhaustIndex),")
                line("            ignition_wire: wires.wire\(c),")
                line("            sound_attenuation: \(num(0.8 + Double((c * 3) % 5) * 0.1)),")
                line("            primary_length: \((c * 3) % 7) * units.cm")
                line("        )")
            }
            line("        .set_cylinder_head(")
            line("            generated_head(")
            line("                intake_camshaft: intake_cam\(b),")
            line("                exhaust_camshaft: exhaust_cam\(b),")
            line("                flip_display: \(b == 0 ? "true" : "false"))")
            line("        )")
        }
        line()
        line("    engine")
        for b in 0..<banks { line("        .add_cylinder_bank(b\(b))") }
        line()
        line("    engine.add_crankshaft(c0)")
        line()
        line("    function timing_curve(1000 * units.rpm)")
        line("    timing_curve")
        let steps = Int(redline / 1000) + 1
        for k in 0...steps {
            let advance: Double = k == 0 ? 12 : (k == 1 ? 12 : (k == 2 ? 20 : (k == 3 ? 30 : 40)))
            line("        .add_sample(\(k * 1000) * units.rpm, \(num(advance)) * units.deg)")
        }
        line()
        line("    ignition_module ignition_module(")
        line("        timing_curve: timing_curve,")
        line("        rev_limit: \(Int(redline + 300)) * units.rpm,")
        line("        limiter_duration: \(num(limiter.cutSeconds)))")
        line("    ignition_module")
        for (index, cylinder) in spec.firingOrder.enumerated() {
            line("        .connect_wire(wires.wire\(cylinder), \(num(spec.firingAngles[index])) * units.deg)")
        }
        line()
        line("    engine.add_ignition_module(ignition_module)")
        line("}")
        line()
        line("private node generated_vehicle {")
        line("    alias output __out:")
        line("        vehicle(")
        line("            mass: 1500 * units.kg,")
        line("            drag_coefficient: 0.3,")
        line("            cross_sectional_area: (72 * units.inch) * (50 * units.inch),")
        line("            diff_ratio: 3.42,")
        line("            tire_radius: 10 * units.inch,")
        line("            rolling_resistance: 200 * units.N")
        line("        );")
        line("}")
        line()
        line("private node generated_transmission {")
        line("    alias output __out:")
        line("        transmission(max_clutch_torque: 600 * units.lb_ft)")
        line("        .add_gear(3.23)")
        line("        .add_gear(2.19)")
        line("        .add_gear(1.61)")
        line("        .add_gear(1.23)")
        line("        .add_gear(0.97)")
        line("        .add_gear(0.8);")
        line("}")
        line()
        line("public node main {")
        line("    set_engine(generated_engine())")
        line("    set_vehicle(generated_vehicle())")
        line("    set_transmission(generated_transmission())")
        line("}")

        var files: [String: [UInt8]] = [:]
        files["engine.mr"] = Array(s.utf8)
        // The entry file: engine-sim runs the top-level statements of the file it is given.
        let entry = "import \"engine_sim.mr\"\nimport \"engine.mr\"\n\nmain()\n"
        files["main.mr"] = Array(entry.utf8)
        if exhaust != .reference { files["ir_\(exhaust.rawValue).wav"] = ExhaustImpulse.wav(exhaust) }
        return EngineSimPackage(mainScript: "main.mr", files: files, engineScript: s)
    }
}
