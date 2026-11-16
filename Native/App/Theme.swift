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

    /// Layered surfaces on the dark-grey base.
    static let surface = Color(white: 0.18)
    static let surfaceRaised = Color(white: 0.22)
    static let separator = Color(white: 0.32)
    /// Text and icons on the accent fill.
    static let onAccent = Color(white: 0.08)

    /// Status marks (icons, dots, chart lines) and inks (words): vivid in the dark theme.
    static let goodMark = Color(red: 0.13, green: 0.77, blue: 0.37)
    static let goodInk = Color(red: 0.29, green: 0.87, blue: 0.50)
    static let warnMark = Color(red: 0.98, green: 0.75, blue: 0.14)
    static let warnInk = Color(red: 0.98, green: 0.75, blue: 0.14)
    static let badMark = Color(red: 1.0, green: 0.42, blue: 0.38)
    static let badInk = Color(red: 1.0, green: 0.42, blue: 0.38)
    /// Chart series.
    static let power = accent
    static let torque = Color(red: 0.36, green: 0.66, blue: 1.0)
    static let lastPull = Color(white: 0.6)

    /// 4-point spacing scale.
    enum Space {
        static let xs: CGFloat = 4
        static let s: CGFloat = 8
        static let m: CGFloat = 12
        static let l: CGFloat = 16
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 40
    }

    enum Radius {
        static let s: CGFloat = 8
        static let m: CGFloat = 12
        static let l: CGFloat = 16
    }

    /// Smallest touch target, points.
    static let hitTarget: CGFloat = 44

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
