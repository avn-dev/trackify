import SwiftUI

/// Horizontal bar showing low (amber) / normal (lime) / high (danger) zones with a value marker.
struct RangeScale: View {
    @Environment(\.theme) private var t
    var value: Double
    var refLow: Double
    var refHigh: Double
    var absMin: Double
    var absMax: Double

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let range = absMax - absMin
            let lowFrac  = (refLow  - absMin) / range
            let highFrac = (refHigh - absMin) / range
            let valueFrac = min(max((value - absMin) / range, 0), 1)

            ZStack(alignment: .leading) {
                // Background track
                RoundedRectangle(cornerRadius: 4)
                    .fill(t.surface2)
                    .frame(height: 8)

                // Low zone (amber)
                RoundedRectangle(cornerRadius: 4)
                    .fill(t.amber.opacity(0.5))
                    .frame(width: max(lowFrac * w, 0), height: 8)

                // Normal zone (lime)
                RoundedRectangle(cornerRadius: 2)
                    .fill(t.accent.opacity(0.6))
                    .frame(width: max((highFrac - lowFrac) * w, 0), height: 8)
                    .offset(x: lowFrac * w)

                // High zone (danger)
                RoundedRectangle(cornerRadius: 4)
                    .fill(t.danger.opacity(0.5))
                    .frame(width: max((1 - highFrac) * w, 0), height: 8)
                    .offset(x: highFrac * w)

                // Value marker
                VStack(spacing: 2) {
                    RoundedRectangle(cornerRadius: 1)
                        .fill(t.text)
                        .frame(width: 2, height: 14)
                }
                .offset(x: valueFrac * w - 1)
            }

            // Tick labels
            HStack {
                Text(Formatters.compact(absMin))
                Spacer()
                Text(Formatters.compact(refLow))
                Spacer()
                Text(Formatters.compact(refHigh))
                Spacer()
                Text(Formatters.compact(absMax))
            }
            .font(.custom(Typography.geistMono, size: 9))
            .foregroundStyle(t.textMuted)
            .offset(y: 16)
        }
        .frame(height: 32)
    }
}
