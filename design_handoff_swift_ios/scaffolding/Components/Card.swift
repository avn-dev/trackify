// Card.swift
// Surface primitive — every grouped content panel uses this.

import SwiftUI

struct Card<Content: View>: View {
    @Environment(\.theme) private var t
    var pad: CGFloat = Spacing.l
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) { content() }
            .padding(pad)
            .background(
                RoundedRectangle(cornerRadius: Radii.card, style: .continuous)
                    .fill(t.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Radii.card, style: .continuous)
                    .stroke(t.border, lineWidth: 1)
            )
    }
}

/// Inline "section head": uppercase mono label, optional trailing action link.
struct SectionHead: View {
    @Environment(\.theme) private var t
    var label: String
    var action: String? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label.uppercased())
                .font(Typography.eyebrow)
                .kerning(Tracking.eyebrow)
                .foregroundStyle(t.textMuted)
            Spacer()
            if let action {
                Text(action)
                    .font(Typography.bodySmall)
                    .foregroundStyle(t.textMid)
            }
        }
        .padding(.horizontal, Spacing.xl)
        .padding(.bottom, Spacing.m)
    }
}

/// "Eyebrow" — small mono uppercase line above titles.
struct Eyebrow: View {
    @Environment(\.theme) private var t
    var text: String

    var body: some View {
        Text(text.uppercased())
            .font(Typography.eyebrow)
            .kerning(Tracking.eyebrow)
            .foregroundStyle(t.textMuted)
    }
}
