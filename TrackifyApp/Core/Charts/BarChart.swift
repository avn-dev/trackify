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

    var body: some View {
        Chart(data) { p in
            BarMark(
                x: .value("label", p.label),
                y: .value("value", p.value)
            )
            .foregroundStyle(p.highlighted ? t.accent : t.text.opacity(0.35))
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
