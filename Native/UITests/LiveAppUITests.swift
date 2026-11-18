import UIKit
import XCTest

/// Opens the real app (no launch arguments), starts the engine, runs a dyno pull and a drag run,
/// and keeps a screenshot of each step. This is how the live tabs and engine-sim's sound loading
/// are checked without a Mac or a phone in the loop.
@MainActor
final class LiveAppUITests: XCTestCase {
    private func shot(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testLiveApp() throws {
        try XCTSkipIf(UIDevice.current.userInterfaceIdiom == .pad, "phone only")
        continueAfterFailure = true
        let app = XCUIApplication()
        app.launch()

        let start = app.buttons["button.start"]
        XCTAssertTrue(start.waitForExistence(timeout: 30), "Engine screen did not open")
        // engine-sim compiles the engine script and loads its impulse response.
        let soundReady = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'Sound load'")).firstMatch
        let loaded = soundReady.waitForExistence(timeout: 45)
        shot("live-1-engine-idle")
        XCTAssertTrue(loaded, "engine-sim sound did not report loaded within 45 s")

        start.tap()
        Thread.sleep(forTimeInterval: 3)
        shot("live-2-engine-running")
        let slider = app.sliders["slider.throttle"]
        if slider.waitForExistence(timeout: 5) {
            slider.adjust(toNormalizedSliderPosition: 0.85)
            Thread.sleep(forTimeInterval: 3)
            shot("live-3-engine-revving")
        }

        app.tabBars.buttons["Tune"].tap()
        Thread.sleep(forTimeInterval: 1)
        shot("live-4-tune")

        app.tabBars.buttons["Dyno"].tap()
        let pull = app.buttons["button.pull"]
        XCTAssertTrue(pull.waitForExistence(timeout: 10), "Dyno screen did not open")
        pull.tap()
        Thread.sleep(forTimeInterval: 10)
        shot("live-5-dyno-pulling")
        Thread.sleep(forTimeInterval: 8)
        shot("live-6-dyno-after")

        app.tabBars.buttons["Garage"].tap()
        Thread.sleep(forTimeInterval: 1)
        shot("live-7-garage-parts")
        let engines = app.buttons["Engines"]
        if engines.exists {
            engines.tap()
            Thread.sleep(forTimeInterval: 1)
            shot("live-8-garage-engines")
        }
        let car = app.buttons["Car"]
        if car.exists {
            car.tap()
            Thread.sleep(forTimeInterval: 1)
            shot("live-9-garage-car")
        }

        app.tabBars.buttons["Drive"].tap()
        let go = app.buttons["button.drive"]
        XCTAssertTrue(go.waitForExistence(timeout: 10), "Drive screen did not open")
        shot("live-10-drive-setup")
        go.tap()
        Thread.sleep(forTimeInterval: 2)
        let gas = app.descendants(matching: .any)["Gas pedal"]
        if gas.waitForExistence(timeout: 10) {
            gas.press(forDuration: 9)
            shot("live-11-drive-after-9s")
        } else {
            shot("live-11-drive-no-pedal")
            XCTFail("Gas pedal not found")
        }
    }
}
