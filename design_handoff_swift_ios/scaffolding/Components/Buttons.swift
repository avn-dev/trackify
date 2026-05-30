// Buttons.swift
// PrimaryButton (lime CTA) · GhostButton (transparent + strong border) · CircleBtn (40×40 icon).

import SwiftUI

/// THE primary action on a screen. Lime, height 52, pill. Use exactly one per screen.
struct PrimaryButton: View {
    @Environment(\.theme) private var t
    var title: String
    var systemIcon: String? = nil
    var fullWidth: Bool = true
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let systemIcon {
                    Image(systemName: systemIcon).font(.system(size: 16, weight: .semibold))
                }
                Text(title)
                    .font(.custom(Typography.geist, size: 16).weight(.semibold))
            }
            .foregroundStyle(t.accentText)
            .frame(maxWidth: fullWidth ? .infinity : nil, minHeight: 52)
            .padding(.horizontal, fullWidth ? 0 : 24)
            .background(Capsule().fill(t.accent))
        }
        .buttonStyle(.plain)
    }
}

/// Secondary action: transparent + strong-border. Same dimensions as PrimaryButton.
struct GhostButton: View {
    @Environment(\.theme) private var t
    var title: String
    var systemIcon: String? = nil
    var fullWidth: Bool = true
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if let systemIcon {
                    Image(systemName: systemIcon).font(.system(size: 16, weight: .medium))
                }
                Text(title)
                    .font(.custom(Typography.geist, size: 15).weight(.medium))
            }
            .foregroundStyle(t.text)
            .frame(maxWidth: fullWidth ? .infinity : nil, minHeight: 52)
            .padding(.horizontal, fullWidth ? 0 : 24)
            .overlay(
                Capsule().stroke(t.borderStrong, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

/// 40×40 icon button — header actions, etc.
struct CircleBtn: View {
    @Environment(\.theme) private var t
    var systemIcon: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemIcon)
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(t.text)
                .frame(width: 40, height: 40)
                .background(
                    Circle().fill(t.surface2)
                )
                .overlay(
                    Circle().stroke(t.border, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}
