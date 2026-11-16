import Foundation
import Testing
@testable import PistonForgeKit

private func temporaryDirectory() throws -> URL {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("pf-save-\(UUID().uuidString)")
    try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    return url
}

@Test func w16DoesNotFitHatch() {
    guard case .blocked(let dimension, let overMm) = fitment(EngineBuild.starter(.w16), in: .hatch) else {
        Issue.record("a W16 must not fit the hatch")
        return
    }
    #expect(!dimension.isEmpty)
    #expect(overMm > 0)
}

@Test func v8FitsMuscle() {
    #expect(fitment(EngineBuild.starter(.v8Cross), in: .muscle) == .fits)
    #expect(fitment(EngineBuild.starter(.v8Flat), in: .muscle) == .fits)
}

@Test(arguments: EngineLayout.allCases)
func everyStarterFitsSomeCar(layout: EngineLayout) {
    let build = EngineBuild.starter(layout)
    #expect(CarBody.allCases.contains { fitment(build, in: $0) == .fits }, "\(layout) fits nowhere")
}

@Test func blockedReportsTheWorstDimension() {
    var build = EngineBuild.starter(.i6)
    build.induction = .turbo(.twin)
    guard case .blocked(let dimension, let overMm) = fitment(build, in: .hatch) else {
        Issue.record("a twin-turbo straight six must not fit the hatch")
        return
    }
    let bay = CarBody.hatch.spec.bayMm
    let envelope = build.envelopeMm
    let overs = [("length", envelope.length - bay.length), ("width", envelope.width - bay.width), ("height", envelope.height - bay.height)]
    let worst = overs.max { $0.1 < $1.1 }!
    #expect(dimension == worst.0)
    #expect(overMm == Int(worst.1.rounded(.up)))
}

@Test func carsAreSane() {
    for body in CarBody.allCases {
        let spec = body.spec
        #expect(!spec.name.isEmpty)
        #expect(spec.massKg > 700 && spec.massKg < 2500)
        #expect(spec.frontWeight > 0.3 && spec.frontWeight < 0.7)
        #expect(spec.wheelbaseM > 2 && spec.wheelbaseM < 3.6)
    }
    #expect(CarBody.hatch.spec.drivetrain == .fwd)
    #expect(CarBody.super_.spec.drivetrain == .awd)
}

@Test func saveRoundTrip() throws {
    let store = SaveStore(directory: try temporaryDirectory())
    var (file, status) = store.load()
    #expect(status == .fresh)
    file.settings.units = .imperial
    file.car.gearbox = .seq6
    var tuned = EngineBuild.starter(.v10)
    tuned.induction = .supercharger(.twinScrew, pulley: 1.1)
    file.builds.append(tuned)
    file.selectedBuild = tuned.id
    try store.save(file)
    let (back, again) = store.load()
    #expect(again == .loaded)
    #expect(back == file)
}

@Test func corruptMainUsesBackup() throws {
    let directory = try temporaryDirectory()
    let store = SaveStore(directory: directory)
    var (file, _) = store.load()
    file.settings.sound = false
    try store.save(file)
    var second = file
    second.settings.haptics = false
    try store.save(second)
    try Data("{ not json".utf8).write(to: directory.appendingPathComponent("save.json"))
    let (back, status) = SaveStore(directory: directory).load()
    #expect(status == .recoveredFromBackup)
    #expect(back == file, "the backup is the save before the last one")
}

@Test func corruptBothResets() throws {
    let directory = try temporaryDirectory()
    try Data("garbage".utf8).write(to: directory.appendingPathComponent("save.json"))
    try Data([0xFF, 0x00, 0x13]).write(to: directory.appendingPathComponent("save.bak.json"))
    let (file, status) = SaveStore(directory: directory).load()
    #expect(status == .corruptReset)
    #expect(file.version == SaveFile.currentVersion)
    #expect(!file.builds.isEmpty)
}

@Test func newerVersionIsNotOverwritten() throws {
    let directory = try temporaryDirectory()
    let main = directory.appendingPathComponent("save.json")
    let future = Data(#"{"version": 99, "somethingNew": [1, 2, 3]}"#.utf8)
    try future.write(to: main)
    let store = SaveStore(directory: directory)
    let (file, status) = store.load()
    #expect(status == .newerVersionKept)
    #expect(file.version == SaveFile.currentVersion)
    #expect(try Data(contentsOf: main) == future, "loading never touches the newer file")
    try store.save(file)
    #expect(try Data(contentsOf: directory.appendingPathComponent("save.newer.json")) == future)
    let (reloaded, again) = SaveStore(directory: directory).load()
    #expect(again == .loaded)
    #expect(reloaded == file)
}

@Test func emptyFileIsCorrupt() throws {
    let directory = try temporaryDirectory()
    try Data().write(to: directory.appendingPathComponent("save.json"))
    let (_, status) = SaveStore(directory: directory).load()
    #expect(status == .corruptReset)
}

@Test func loadedBuildsAreSanitised() throws {
    let directory = try temporaryDirectory()
    let store = SaveStore(directory: directory)
    var (file, _) = store.load()
    var wild = EngineBuild.starter(.i3)
    wild.bore = 500
    wild.ecu.afrTable = [[1]]
    file.builds = [wild]
    try store.save(file)
    let (back, _) = SaveStore(directory: directory).load()
    #expect(back.builds.first?.bore == EngineBuild.boreRange.upperBound)
    #expect(back.builds.first?.ecu.isWellFormed == true)
}

@Test func defaultsOpenOnAnAssembledEngine() {
    let file = SaveFile.defaults()
    #expect(file.builds.count == EngineLayout.allCases.count)
    let selected = file.builds.first { $0.id == file.selectedBuild }
    #expect(selected != nil)
    if let selected { #expect(fitment(selected, in: file.car.body) == .fits) }
}
