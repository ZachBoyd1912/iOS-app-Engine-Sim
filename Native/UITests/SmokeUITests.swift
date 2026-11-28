import UIKit
import XCTest

/// Proves the app launches on a simulator and leaves a screenshot of the first screen.
@MainActor
final class SmokeUITests: XCTestCase {
    func testLaunches() throws {
        let app = XCUIApplication()
        app.launch()

        // A plain launch opens RootView, which has no "Piston Forge" title (only the explicit
        // test route does). Not the tab bar either: iPadOS 26 draws tabs outside `tabBars`, so
        // that query passed on iPhone and failed on iPad (run 45915804981). The Start button is
        // on the first screen of both.
        let start = app.buttons["button.start"]
        XCTAssertTrue(start.waitForExistence(timeout: 20), "Start button not shown within 20 s")

        let device = UIDevice.current.userInterfaceIdiom == .pad ? "ipad" : "iphone"
        let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        shot.name = "smoke-\(device)"
        shot.lifetime = .keepAlways
        add(shot)
    }
}
