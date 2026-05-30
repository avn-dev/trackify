import SwiftUI

// MARK: - Color palette

enum Palette {
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

    static let accentLime   = Color(hex: 0xc8ff3d)
    static let accentRose   = Color(hex: 0xff6bce)
    static let accentSky    = Color(hex: 0x38d9f5)
    static let accentViolet = Color(hex: 0xc084fc)
    static let accentText   = Color(hex: 0x0b0b0c)
    static let danger       = Color(hex: 0xff6b4a)
    static let dangerLight  = Color(hex: 0xe0432a)
    static let amber        = Color(hex: 0xf5b13a)
}

// MARK: - Accent color options

enum AccentOption: String, CaseIterable {
    case lime   = "lime"
    case rose   = "rose"
    case sky    = "sky"
    case violet = "violet"

    static let storageKey = "accentOption"

    var label: String {
        switch self {
        case .lime:   return "Lime"
        case .rose:   return "Rosa"
        case .sky:    return "Sky"
        case .violet: return "Violett"
        }
    }

    var color: Color {
        switch self {
        case .lime:   return Palette.accentLime
        case .rose:   return Palette.accentRose
        case .sky:    return Palette.accentSky
        case .violet: return Palette.accentViolet
        }
    }

    var textColor: Color { Palette.accentText }
}

// MARK: - Typography

enum Typography {
    static let geist     = "Geist"
    static let geistMono = "Geist Mono"

    static func display(_ size: CGFloat = 88, weight: Font.Weight = .medium) -> Font {
        .custom(geistMono, size: size).weight(weight).monospacedDigit()
    }

    static func title(_ size: CGFloat = 32, weight: Font.Weight = .semibold) -> Font {
        .custom(geist, size: size).weight(weight)
    }

    static let eyebrow   = Font.custom(geistMono, size: 11).weight(.medium)
    static let body      = Font.custom(geist, size: 15)
    static let bodySmall = Font.custom(geist, size: 13)

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
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 28
    static let tabBarHeight: CGFloat = 76
    static let screenSafeBottom: CGFloat = 100
}

enum Radii {
    static let card: CGFloat = 22
    static let cardSmall: CGFloat = 18
    static let row: CGFloat = 14
    static let chip: CGFloat = 10
    static let pill: CGFloat = 999
}

enum Tracking {
    static let titleTight: CGFloat = -1.0
    static let titleVeryTight: CGFloat = -2.0
    static let eyebrow: CGFloat = 0.6
}

// MARK: - Hex color init

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

extension View {
    func tabularNumbers() -> some View { self.monospacedDigit() }
}
