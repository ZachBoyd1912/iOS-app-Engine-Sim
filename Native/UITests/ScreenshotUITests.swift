import UIKit
import XCTest

/// Screenshots of the screens, exported from the test results in CI (the only way to see the
/// app without a Mac).
@MainActor
final class ScreenshotUITests: XCTestCase {
    private var device: String { UIDevice.current.userInterfaceIdiom == .pad ? "ipad" : "iphone" }

    /// Every layout in 3D, with a twin turbo on the cross-plane V8 and the W16 and a Roots
    /// blower on the flat-plane V8, so the induction plumbing is visible too.
    func testEngineLayouts() throws {
        let cases = [
            ("i3", "na"), ("i4", "na"), ("i6", "na"), ("v6_60", "na"), ("v6_90", "na"),
            ("v8Cross", "turbo-twin"), ("v8Flat", "roots"), ("v10", "na"), ("v12", "na"), ("w16", "turbo-twin"),
        ]
        for (layout, induction) in cases {
            let app = XCUIApplication()
            app.launchArguments = ["-screen", "engine", "-layout", layout, "-induction", induction]
            app.launch()
            XCTAssertTrue(app.staticTexts["label.engineName"].waitForExistence(timeout: 20), "\(layout) did not open")
            // Give RealityKit time to draw and the crank time to turn.
            Thread.sleep(forTimeInterval: 3)
            let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
            shot.name = "engine-\(layout)-\(induction)-\(device)"
            shot.lifetime = .keepAlways
            add(shot)
            app.terminate()
        }
    }

    /// Every screen with sample data and its PREVIEW tag: portrait, plus landscape on iPhone,
    /// each checked by Xcode's accessibility audit.
    func testEveryScreen() throws {
        let screens = ["engine", "parts", "tune", "dyno", "car", "settings", "garage"]
        var orientations: [UIDeviceOrientation] = [.portrait]
        if UIDevice.current.userInterfaceIdiom == .phone { orientations.append(.landscapeLeft) }
        for screen in screens {
            for orientation in orientations {
                XCUIDevice.shared.orientation = orientation
                let app = XCUIApplication()
                app.launchArguments = ["-screen", screen, "-preview"]
                app.launch()
                XCTAssertTrue(app.descendants(matching: .any)["screen.\(screen)"].waitForExistence(timeout: 30), "\(screen) did not open")
                Thread.sleep(forTimeInterval: screen == "engine" ? 3 : 1)
                let name = orientation == .portrait ? "portrait" : "landscape"
                let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
                shot.name = "\(screen)-\(device)-\(name)"
                shot.lifetime = .keepAlways
                add(shot)
                if orientation == .portrait {
                    do {
                        try app.performAccessibilityAudit()
                    } catch {
                        XCTFail("\(screen) accessibility audit: \(error)")
                    }
                }
                app.terminate()
            }
        }
        XCUIDevice.shared.orientation = .portrait
    }
}
