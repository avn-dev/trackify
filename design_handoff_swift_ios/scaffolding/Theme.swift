// Theme.swift
// A Theme is a snapshot of resolved colors for the current scheme. Use the
// `\.theme` Environment value inside views — it switches automatically with
// system appearance and any in-app override.

import SwiftUI

struct Theme {
    var name: String

    var bg: Color
    var bgElev: Color
    var surface: Color
    var surface2: Color
    var border: Color
    var borderStrong: Color
    var text: Color
    var textMid: Color
    var textMuted: Color
    var grid: Color

    // Brand
    var accent: Color
    var accentText: Color
    var danger: Color
    var amber: Color

    static let dark = Theme(
        name: "dark",
        bg: Palette.darkBg, bgElev: Palette.darkBgElev,
        surface: Palette.darkSurface, surface2: Palette.darkSurface2,
        border: Palette.darkBorder, borderStrong: Palette.darkBorderStrong,
        text: Palette.darkText, textMid: Palette.darkTextMid, textMuted: Palette.darkTextMuted,
        grid: Palette.darkGrid,
        accent: Palette.accent, accentText: Palette.accentText,
        danger: Palette.danger, amber: Palette.amber
    )

    static let light = Theme(
        name: "light",
        bg: Palette.lightBg, bgElev: Palette.lightBgElev,
        surface: Palette.lightSurface, surface2: Palette.lightSurface2,
        border: Palette.lightBorder, borderStrong: Palette.lightBorderStrong,
        text: Palette.lightText, textMid: Palette.lightTextMid, textMuted: Palette.lightTextMuted,
        grid: Palette.lightGrid,
        accent: Palette.accent, accentText: Palette.accentText,
        danger: Palette.dangerLight, amber: Palette.amber
    )
}

// MARK: - Environment key

private struct ThemeKey: EnvironmentKey {
    static let defaultValue: Theme = .dark
}

extension EnvironmentValues {
    var theme: Theme {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}

// MARK: - Root provider

struct ThemedRoot<Content: View>: View {
    @Environment(\.colorScheme) private var scheme
    @ViewBuilder var content: () -> Content

    var body: some View {
        let theme: Theme = scheme == .dark ? .dark : .light
        content()
            .environment(\.theme, theme)
            .background(theme.bg.ignoresSafeArea())
            .preferredColorScheme(scheme)
    }
}
