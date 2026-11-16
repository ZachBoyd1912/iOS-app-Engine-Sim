import Foundation

/// What the mass airflow sensor reports for `airflowGps` of real air. Past its maximum the
/// reading sticks at the maximum (`clipped`). With no MAF fitted it reads nothing.
public func mafReading(_ b: EngineBuild, airflowGps: Double) -> (gps: Double, clipped: Bool) {
    guard let size = b.sensors.maf else { return (0, false) }
    let air = bounded(airflowGps, 0...5000)
    return (min(air, size.maxGps), air > size.maxGps)
}
