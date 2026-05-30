// DesignTokens.swift
// Trackify — design tokens translated from the HTML/React prototype.
// One source of truth for colors, type, spacing, radii. Don't hardcode hex
// anywhere else. Mutate ONLY through Theme.swift.

import SwiftUI

// MARK: - Color palette

enum Palette {
    // Dark theme
    static let darkBg            = Color(hex: 0x0b0b0c)
    static let darkBgElev        = Color(hex: 0x101012)
    static let darkSurface       = Color(hex: 0x161618)
    static let darkSurface2      = Color(hex: 0x1c1c1f)
    static let darkBorder        = Color.white.opacity(0.08)
    static let darkBorderStrong  = Color.white.opacity(0.14)
    static let darkText          = Color(hex: 0xf6f6f7)
    static let darkTextMid       = Color(hex: 0xb8b8bd)
    static let darkTextMuted     = Color(hex: 0x76767c)
    static let darkGrid          = Color.white.opacity(0.06)

    // Light theme
    static let lightBg           = Color(hex: 0xf6f5f1)
    static let lightBgElev       = Color(hex: 0xfafaf8)
    static let lightSurface      = Color.white
    static let lightSurface2     = Color(hex: 0xefeeea)
    static let lightBorder       = Color.black.opacity(0.08)
    static let lightBorderStrong = Color.black.opacity(0.14)
    static let lightText         = Color(hex: 0x0b0b0c)
    static let lightTextMid      = Color(hex: 0x3a3a3d)
    static let lightTextMuted    = Color(hex: 0x86858a)
    static let lightGrid         = Color.black.opacity(0.05)

    // Shared
    static let accent       = Color(hex: 0xc8ff3d)
    static let accentText   = Color(hex: 0x0b0b0c)
    static let danger       = Color(hex: 0xff6b4a)   // dark theme
    static let dangerLight  = Color(hex: 0xe0432a)   // light theme
    static let amber        = Color(hex: 0xf5b13a)   // lab "zu niedrig" ONLY — do not reuse
}

// MARK: - Typography

enum Typography {
    static let geist     = "Geist"
    static let geistMono = "Geist Mono"

    // Large display (cover / hero numbers)
    static func display(_ size: CGFloat = 88, weight: Font.Weight = .medium) -> Font {
        .custom(geistMono, size: size).weight(weight).monospacedDigit()
    }

    // Page title
    static func title(_ size: CGFloat = 32, weight: Font.Weight = .semibold) -> Font {
        .custom(geist, size: size).weight(weight)
    }

    // Section heading (uppercase mono)
    static let eyebrow = Font.custom(geistMono, size: 11).weight(.medium)

    // Body
    static let body = Font.custom(geist, size: 15)
    static let bodySmall = Font.custom(geist, size: 13)

    // Numbers — always mono, always tabular
    static func number(_ size: CGFloat, weight: Font.Weight = .medium) -> Font {
        .custom(geistMono, size: size).weight(weight).monospacedDigit()
    }
}

// MARK: - Spacing & radii

enum Spacing {
    static let xs: CGFloat = 4
    static let s:  CGFloat = 8
    static let m:  CGFloat = 12
    static let l:  CGFloat = 16
    static let xl: CGFloat = 20            // standard screen horizontal padding
    static let xxl: CGFloat = 28
    static let tabBarHeight: CGFloat = 76
    static let screenSafeBottom: CGFloat = 100   // reserve under TabBar
}

enum Radii {
    static let card: CGFloat = 22
    static let cardSmall: CGFloat = 18
    static let row: CGFloat = 14
    static let chip: CGFloat = 10
    static let pill: CGFloat = 999
}

enum Tracking {
    // letterSpacing in points equivalent
    static let titleTight: CGFloat = -1.0
    static let titleVeryTight: CGFloat = -2.0
    static let eyebrow: CGFloat = 0.6
}

// MARK: - Color hex init helper

extension Color {
    init(hex: UInt32, alpha: Double = 1) {
        self.init(
            .sRGB,
            red:   Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8)  & 0xFF) / 255,
            blue:  Double( hex        & 0xFF) / 255,
            opacity: alpha
        )
    }
}

// MARK: - View modifiers

extension View {
    /// Apply tabular figures (every numeric label should use this)
    func tabularNumbers() -> some View {
        self.monospacedDigit()
    }
}
