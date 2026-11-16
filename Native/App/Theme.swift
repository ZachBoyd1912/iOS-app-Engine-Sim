import SwiftUI
import UIKit

/// Every colour in the app. Dark only, dark grey (never black), with low-opacity warm and cool
/// hues behind the content and one accent (orange). Nothing else hard-codes a colour.
@MainActor
enum Theme {
    static let baseUI = UIColor(red: 0.13, green: 0.14, blue: 0.15, alpha: 1)
    static let accentUI = UIColor(red: 1.0, green: 0.55, blue: 0.18, alpha: 1)
    static let hueWarmUI = UIColor(red: 0.9, green: 0.38, blue: 0.12, alpha: 1)
    static let hueCoolUI = UIColor(red: 0.16, green: 0.45, blue: 0.75, alpha: 1)

    static let base = Color(uiColor: baseUI)
    static let accent = Color(uiColor: accentUI)
    static let hueWarm = Color(uiColor: hueWarmUI)
    static let hueCool = Color(uiColor: hueCoolUI)
    static let textPrimary = Color(white: 0.95)
    static let textSecondary = Color(white: 0.7)

    static var background: some View {
        ZStack {
            base
            RadialGradient(colors: [hueWarm.opacity(0.22), .clear], center: .topTrailing, startRadius: 0, endRadius: 520)
            RadialGradient(colors: [hueCool.opacity(0.18), .clear], center: .bottomLeading, startRadius: 0, endRadius: 560)
        }
    }

    /// Finishes for the 3D engine's parts.
    @MainActor
    enum Engine {
        static let castIron = UIColor(white: 0.30, alpha: 1)
        static let aluminium = UIColor(white: 0.72, alpha: 1)
        static let polished = UIColor(white: 0.86, alpha: 1)
        static let steel = UIColor(white: 0.55, alpha: 1)
        static let valveCover = UIColor(red: 0.78, green: 0.30, blue: 0.10, alpha: 1)
        static let exhaust = UIColor(red: 0.46, green: 0.36, blue: 0.30, alpha: 1)
        static let rubber = UIColor(white: 0.12, alpha: 1)
        static let fuelRail = UIColor(red: 0.20, green: 0.42, blue: 0.80, alpha: 1)
        static let sensor = UIColor(red: 0.95, green: 0.78, blue: 0.20, alpha: 1)
        static let nitrous = UIColor(red: 0.15, green: 0.35, blue: 0.85, alpha: 1)
        static let intercooler = UIColor(white: 0.18, alpha: 1)
    }
}
