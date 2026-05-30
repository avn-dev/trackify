// LineChart.swift
// Thin Swift-Charts wrapper that matches the prototype's visual language:
// 1.75pt line, faint grid, mono tabular tick labels, optional accent + baseline.

import SwiftUI
import Charts

struct LinePoint: Identifiable {
    let id = UUID()
    var x: Double
    var y: Double
    var label: String?
    var highlighted: Bool = false
}

struct TrackifyLineChart: View {
    @Environment(\.theme) private var t
    var data: [LinePoint]
    var accent: Bool = false
    var baseline: Double? = nil
    var showAxis: Bool = true

    private var stroke: Color { accent ? t.accent : t.text }
    private var fill: Color { accent ? t.accent.opacity(0.12) : t.text.opacity(0.06) }

    var body: some View {
        Chart {
            // Area fill (subtle)
            ForEach(data) { p in
                AreaMark(x: .value("x", p.x), y: .value("y", p.y))
            }
            .foregroundStyle(fill)
            .interpolationMethod(.monotone)

            // Line
            ForEach(data) { p in
                LineMark(x: .value("x", p.x), y: .value("y", p.y))
            }
            .foregroundStyle(stroke)
            .lineStyle(StrokeStyle(lineWidth: 1.75, lineCap: .round, lineJoin: .round))
            .interpolationMethod(.monotone)

            // Highlighted dot(s)
            ForEach(data.filter { $0.highlighted }) { p in
                PointMark(x: .value("x", p.x), y: .value("y", p.y))
                    .foregroundStyle(t.bg)
                    .symbolSize(36)
                PointMark(x: .value("x", p.x), y: .value("y", p.y))
                    .foregroundStyle(stroke)
                    .symbolSize(12)
            }

            // Baseline (goal)
            if let b = baseline {
                RuleMark(y: .value("baseline", b))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
                    .foregroundStyle(t.accent.opacity(0.7))
            }
        }
        .chartXAxis {
            if showAxis {
                AxisMarks(values: data.compactMap { $0.label != nil ? $0.x : nil }) { v in
                    AxisValueLabel {
                        if let i = data.firstIndex(where: { $0.x == v.as(Double.self) }),
                           let l = data[i].label {
                            Text(l)
                                .font(.custom(Typography.geistMono, size: 9))
                                .foregroundStyle(t.textMuted)
                        }
                    }
                }
            } else {
                AxisMarks(values: []) { _ in EmptyAxisContent() }
            }
        }
        .chartYAxis {
            if showAxis {
                AxisMarks(position: .leading, values: .automatic(desiredCount: 3)) { v in
                    AxisGridLine().foregroundStyle(t.grid)
                    AxisValueLabel {
                        if let n = v.as(Double.self) {
                            Text(Int(n).formatted(.number.locale(Locale(identifier: "de_DE"))))
                                .font(.custom(Typography.geistMono, size: 9))
                                .foregroundStyle(t.textMuted)
                                .monospacedDigit()
                        }
                    }
                }
            } else {
                AxisMarks(values: []) { _ in EmptyAxisContent() }
            }
        }
    }
}

// Empty axis content used to suppress axis rendering when showAxis = false.
private struct EmptyAxisContent: AxisMarkComposite { var body: some AxisMark { AxisGridLine().foregroundStyle(.clear) } }
