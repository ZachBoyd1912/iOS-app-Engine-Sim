import SwiftUI

@main
struct PistonForgeApp: App {
    var body: some Scene {
        WindowGroup {
            LoopTestView()
                .preferredColorScheme(.dark)
        }
    }
}
