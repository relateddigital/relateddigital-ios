//
//  Theme.swift
//  RelatedDigitalExample
//
//  Design tokens for the sample app. Everything visual in the app is derived
//  from here so the look stays consistent across screens.
//

import SwiftUI

enum Theme {

    // MARK: - Palette

    /// Brand accent. Used for primary actions and selected states.
    static let accent = Color(light: 0x4C43D9, dark: 0x8C86FF)
    static let accentSoft = Color(light: 0xEDECFF, dark: 0x231F4D)

    static let success = Color(light: 0x0E8A55, dark: 0x3DD68C)
    static let warning = Color(light: 0xB25E00, dark: 0xF5A623)
    static let danger = Color(light: 0xC0392B, dark: 0xFF6B5B)
    static let info = Color(light: 0x0B6FBF, dark: 0x5AB8FF)

    // MARK: - Surfaces

    /// Screen background, one step behind cards.
    static let background = Color(light: 0xF4F4F8, dark: 0x0E0E12)
    /// Card / grouped-row background.
    static let surface = Color(light: 0xFFFFFF, dark: 0x1A1A21)
    /// Nested surface inside a card (code blocks, payload previews).
    static let surfaceRaised = Color(light: 0xF6F6FA, dark: 0x24242D)
    static let separator = Color(light: 0xE2E2EA, dark: 0x2E2E38)

    // MARK: - Text

    static let textPrimary = Color(light: 0x14141A, dark: 0xF2F2F7)
    static let textSecondary = Color(light: 0x5E5E6B, dark: 0x9E9EAD)
    static let textTertiary = Color(light: 0x8E8E9B, dark: 0x6E6E7C)

    // MARK: - Metrics

    enum Radius {
        static let card: CGFloat = 16
        static let control: CGFloat = 12
        static let pill: CGFloat = 999
    }

    enum Spacing {
        static let xs: CGFloat = 4
        static let s: CGFloat = 8
        static let m: CGFloat = 12
        static let l: CGFloat = 16
        static let xl: CGFloat = 24
    }

    /// Monospaced font used for identifiers, payloads and console output.
    static func mono(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
}

// MARK: - Color helpers

extension Color {

    /// Builds a dynamic color from two hex literals so every token is
    /// declared once and adapts to the active appearance.
    init(light: UInt32, dark: UInt32) {
        self.init(UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(hex: dark)
                : UIColor(hex: light)
        })
    }

    init(hex: UInt32) {
        self.init(UIColor(hex: hex))
    }
}

extension UIColor {

    convenience init(hex: UInt32) {
        self.init(
            red: CGFloat((hex & 0xFF0000) >> 16) / 255,
            green: CGFloat((hex & 0x00FF00) >> 8) / 255,
            blue: CGFloat(hex & 0x0000FF) / 255,
            alpha: 1
        )
    }
}
