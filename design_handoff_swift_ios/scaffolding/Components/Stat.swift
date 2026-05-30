// Stat.swift
// Number + unit + optional delta. The atomic unit of every metric in the app.

import SwiftUI

struct Stat: View {
    @Environment(\.theme) private var t
    var label: String
    var value: String
    var unit: String? = nil
    var delta: String? = nil
    var deltaDir: DeltaDirection = .up

    enum DeltaDirection { case up, down, flat }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label.uppercased())
                .font(Typography.eyebrow)
                .kerning(Tracking.eyebrow)
                .foregroundStyle(t.textMuted)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(Typography.number(28))
                    .kerning(Tracking.titleTight)
                    .foregroundStyle(t.text)
                if let unit {
                    Text(unit).font(.custom(Typography.geistMono, size: 12))
                        .foregroundStyle(t.textMuted)
                }
            }

            if let delta {
                HStack(spacing: 3) {
                    Text(arrow).foregroundStyle(deltaColor)
                    Text(delta).foregroundStyle(deltaDir == .down ? t.danger : t.text)
                }
                .font(.custom(Typography.geistMono, size: 11))
            }
        }
    }

    private var arrow: String {
        switch deltaDir { case .up: "↑"; case .down: "↓"; case .flat: "–" }
    }
    private var deltaColor: Color {
        switch deltaDir { case .up: t.accent; case .down: t.danger; case .flat: t.textMuted }
    }
}
