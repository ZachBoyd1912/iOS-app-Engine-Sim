import Foundation

/// `value` limited to `range`; a non-number becomes `fallback`.
@inline(__always)
func bounded(_ value: Double, _ range: ClosedRange<Double>, or fallback: Double = 0) -> Double {
    guard value.isFinite else { return fallback }
    return min(max(value, range.lowerBound), range.upperBound)
}

/// Hermite step from 0 at `edge0` to 1 at `edge1`.
@inline(__always)
func smoothstep(_ edge0: Double, _ edge1: Double, _ x: Double) -> Double {
    let t = bounded((x - edge0) / (edge1 - edge0), 0...1)
    return t * t * (3 - 2 * t)
}

/// Real air mass the engine takes in, g/s. RED stub.
public func airflowGps(_ b: EngineBuild, rpm: Double, throttle: Double, boostPsi: Double, chargeTempC: Double) -> Double {
    0
}

/// Volumetric efficiency at wide-open throttle: how well the cylinders fill, 0.35...1.15.
///
/// Rises from a low-rpm value to one peak, then falls to about 84% of the peak at redline.
/// Head, intake and exhaust raise the peak; cams raise and move it up the rev range but cost
/// low-rpm filling. A flat-plane V8 scavenges a little better than a cross-plane one, and a
/// turbine in the exhaust costs a little filling through back-pressure.
public func volumetricEfficiency(_ b: EngineBuild, rpm: Double) -> Double {
    let parts = b.parts
    let redline = b.mechanicalRedline
    let speed = bounded(rpm, 0...30_000)

    var peak = 0.88 + 0.03 * Double(parts.head) + 0.02 * Double(parts.cams)
        + 0.015 * Double(parts.intake) + 0.015 * Double(parts.exhaust)
    switch b.layout {
    case .v8Flat: peak += 0.02
    case .v8Cross: peak -= 0.02
    default: break
    }
    if case .turbo = b.induction { peak *= 0.97 }
    peak = min(peak, 1.12)

    let low = peak * (0.78 - 0.05 * Double(parts.cams))
    let peakRpm = redline * min(0.62 + 0.06 * Double(parts.cams) + 0.02 * Double(parts.head) + 0.015 * Double(parts.intake), 0.9)

    let ve: Double
    if speed <= peakRpm {
        let t = speed / peakRpm
        ve = low + (peak - low) * (1 - (1 - t) * (1 - t))
    } else {
        let u = (speed - peakRpm) / max(redline - peakRpm, 1)
        ve = peak - peak * 0.16 * pow(u, 1.5)
    }
    return bounded(ve, 0.35...1.15, or: 0.35)
}
