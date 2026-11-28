import UIKit
import XCTest

/// Screenshots of the screens, exported from the test results in CI (the only way to see the
/// app without a Mac).
/// Every launch passes -noEngineSound: screenshots need no sound, and engine-sim's sim and audio
/// threads starved the 3-core CI runner, giving "Failed to terminate" and "Audit failed to
/// complete in time" (run 46088889270). LiveAppUITests.testSoundLoads still checks the sound loads.
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
            app.launchArguments = ["-noEngineSound", "-screen", "engine", "-layout", layout, "-induction", induction]
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
                app.launchArguments = ["-noEngineSound", "-screen", screen, "-preview"]
                app.launch()
                XCTAssertTrue(app.descendants(matching: .any)["screen.\(screen)"].waitForExistence(timeout: 30), "\(screen) did not open")
                Thread.sleep(forTimeInterval: screen == "engine" ? 3 : 1)
                let name = orientation == .portrait ? "portrait" : "landscape"
                let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
                shot.name = "\(screen)-\(device)-\(name)"
                shot.lifetime = .keepAlways
                add(shot)
                if orientation == .portrait {
                    // Collect every issue so one run shows them all.
                    var issues: [String] = []
                    var advisories: [String] = []
                    do {
                        // Contrast is checked from the theme tokens by ci/check_contrast.py instead:
                        // this audit flagged headers and footers on the gradient background that
                        // measure 6.55:1 or better in the screenshots (run 45920342777).
                        // Dynamic Type is judged from testLargeTextScreens' screenshots instead:
                        // the audit said text "will not change size" when every flagged text
                        // visibly scaled at AccessibilityXXXL, and it flagged 17 plain Dyno
                        // labels in one run and none in the run before (run 45931568847).
                        try app.performAccessibilityAudit(for: XCUIAccessibilityAuditType.all.subtracting([.contrast, .dynamicType])) { issue in
                            // Name the element so the fix can be found without a Mac.
                            var element = "-"
                            if let found = issue.element {
                                element = "\(found.elementType.rawValue) id='\(found.identifier)' label='\(found.label.prefix(60))' frame=\(found.frame.integral)"
                            }
                            let line = "\(issue.compactDescription) (type \(issue.auditType.rawValue): \(issue.detailedDescription)) [\(element)]"
                            // Logged, not failed (Zach's call, 28/11/2026). These two never name an
                            // element, every visible text was in the element tree on the flagged
                            // screens (runs 46077391124, 46082041421), and two fixes based on them
                            // were wrong. The tree attachment below still shows what VoiceOver can
                            // read, and testLargeTextScreens' screenshots cover clipping.
                            if issue.auditType == .elementDetection || issue.auditType == .textClipped {
                                advisories.append(line)
                            } else {
                                issues.append(line)
                            }
                            return true
                        }
                    } catch {
                        issues.append("audit error: \(error)")
                    }
                    if !issues.isEmpty || !advisories.isEmpty {
                        // Keep the whole element tree to match flags against what the
                        // accessibility API actually exposes.
                        let header = advisories.isEmpty ? "" : "advisory:\n" + advisories.joined(separator: "\n") + "\n\n"
                        let tree = XCTAttachment(string: header + app.debugDescription)
                        tree.name = "tree-\(screen)-\(device).txt"
                        tree.lifetime = .keepAlways
                        add(tree)
                    }
                    if !advisories.isEmpty {
                        print("AUDIT ADVISORY \(screen)-\(device) (\(advisories.count)): " + advisories.joined(separator: " | "))
                    }
                    if !issues.isEmpty {
                        XCTFail("\(screen) accessibility (\(issues.count)): " + issues.joined(separator: " | "))
                    }
                }
                app.terminate()
            }
        }
        XCUIDevice.shared.orientation = .portrait
    }

    /// Every screen at the largest accessibility text size, screenshot only. This is the evidence
    /// for the audit's "Dynamic Type partially unsupported" findings: what actually truncates.
    func testLargeTextScreens() throws {
        XCUIDevice.shared.orientation = .portrait
        for screen in ["engine", "parts", "tune", "dyno", "car", "settings", "garage"] {
            let app = XCUIApplication()
            app.launchArguments = [
                "-noEngineSound", "-screen", screen, "-preview",
                "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL",
            ]
            app.launch()
            XCTAssertTrue(app.descendants(matching: .any)["screen.\(screen)"].waitForExistence(timeout: 30), "\(screen) did not open")
            Thread.sleep(forTimeInterval: 1)
            let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
            shot.name = "largetext-\(screen)-\(device)"
            shot.lifetime = .keepAlways
            add(shot)
            app.terminate()
        }
    }
}
