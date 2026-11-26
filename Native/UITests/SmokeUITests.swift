import UIKit
import XCTest

/// Proves the app launches on a simulator and leaves a screenshot of the first screen.
@MainActor
final class SmokeUITests: XCTestCase {
    func testLaunches() throws {
        let app = XCUIApplication()
        app.launch()

        // A plain launch opens RootView, which has no "Piston Forge" title (only the explicit
        // test route does), so the Engine tab is the sign the real first screen is up.
        let engineTab = app.tabBars.buttons["Engine"]
        XCTAssertTrue(engineTab.waitForExistence(timeout: 20), "Engine tab not shown within 20 s")

        let device = UIDevice.current.userInterfaceIdiom == .pad ? "ipad" : "iphone"
        let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        shot.name = "smoke-\(device)"
        shot.lifetime = .keepAlways
        add(shot)
    }
}
