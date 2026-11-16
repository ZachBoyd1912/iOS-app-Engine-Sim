import UIKit
import XCTest

/// Proves the app launches on a simulator and leaves a screenshot of the first screen.
@MainActor
final class SmokeUITests: XCTestCase {
    func testLaunches() throws {
        let app = XCUIApplication()
        app.launch()

        let title = app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "Piston Forge")).firstMatch
        XCTAssertTrue(title.waitForExistence(timeout: 20), "No text containing \"Piston Forge\" within 20 s")

        let device = UIDevice.current.userInterfaceIdiom == .pad ? "ipad" : "iphone"
        let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        shot.name = "smoke-\(device)"
        shot.lifetime = .keepAlways
        add(shot)
    }
}
