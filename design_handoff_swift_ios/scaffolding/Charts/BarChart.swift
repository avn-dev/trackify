// BarChart.swift
// Rounded-end bars over a faint track. Pass `highlightedLabel` to make one bar
// pop in lime — used for "today" or current week.

import SwiftUI
import Charts

struct BarPoint: Identifiable {
    let id = UUID()
    var label: String
    var value: Double
    var highlighted: Bool = false
}

struct TrackifyBarChart: View {
    @Environment(\.theme) private var t
    var data: [BarPoint]
    var accent: Bool = false

    var body: some View {
        Chart(data) { p in
            // Background track per-bar (Swift Charts doesn't have this natively —
            // overlay a separate Chart layer, or use a RectangleMark from 0 to max).
            BarMark(
                x: .value("week", p.label),
                y: .value("value", p.value)
            )
            .foregroundStyle(p.highlighted ? t.accent : (accent ? t.accent : t.text))
            .cornerRadius(20)
        }
        .chartYAxis(.hidden)
        .chartXAxis {
            AxisMarks { v in
                AxisValueLabel {
                    if let s = v.as(String.self) {
                        Text(s)
                            .font(.custom(Typography.geistMono, size: 9))
                            .foregroundStyle(t.textMuted)
                    }
                }
            }
        }
    }
}
