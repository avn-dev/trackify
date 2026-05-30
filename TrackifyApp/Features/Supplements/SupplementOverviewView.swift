import SwiftUI

struct SupplementOverviewView: View {
    @Environment(\.theme) private var t
    @Environment(AppDependencies.self) private var deps
    @Environment(\.dismiss) private var dismiss
    @State private var showAdd = false
    @State private var supplements: [Supplement] = []
    @State private var intakes: [SupplementIntake] = []
    @State private var streak: Int = 0

    private var schedule: [TimeBlock] {
        var order: [String] = []
        var dict: [String: [SupItem]] = [:]
        for sup in supplements {
            for time in sup.times.sorted() {
                if !order.contains(time) { order.append(time) }
                let isTaken = intakes.contains { $0.supplementID == sup.id && $0.takenAt != nil }
                let item = SupItem(supplementID: sup.id, name: sup.name, dose: sup.dose,
                                   kind: sup.kind, taken: isTaken, withFood: sup.withFood)
                dict[time, default: []].append(item)
            }
        }
        return order.map { time in
            TimeBlock(name: blockName(time), time: time, supplements: dict[time] ?? [])
        }
    }

    @ViewBuilder private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "pills")
                .font(.system(size: 36))
                .foregroundStyle(t.textMuted)
            Text("Noch keine Supplements")
                .font(.custom(Typography.geist, size: 17).weight(.semibold))
                .foregroundStyle(t.text)
            Text("Tippe auf + um dein erstes\nSupplement einzutragen.")
                .font(.custom(Typography.geist, size: 14))
                .foregroundStyle(t.textMuted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
        .padding(.horizontal, Spacing.xl)
    }

    private func blockName(_ time: String) -> String {
        let hour = Int(time.prefix(2)) ?? 0
        switch hour {
        case 0..<12:  return "Morgens"
        case 12..<14: return "Mittags"
        case 14..<20: return "Abends"
        default:      return "Vor Schlaf"
        }
    }

    private var totalCount: Int { schedule.flatMap(\.supplements).count }
    private var takenCount: Int { schedule.flatMap(\.supplements).filter(\.taken).count }

    private var lowStockSupplements: [Supplement] {
        supplements.filter { $0.trackStock && $0.stockUnits > 0 && $0.stockUnits <= 7 }
    }

    private var adherenceStates: [AdherenceState] {
        let filled = min(streak, 13)
        var states: [AdherenceState] = Array(repeating: .missed, count: 13 - filled)
        states += Array(repeating: .taken, count: filled)
        states.append(.today)
        return states
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ScreenHeader(title: "Supplements", eyebrow: todayEyebrow,
                             back: "Körper", onBack: { dismiss() }) {
                    CircleBtn(systemIcon: "plus") { showAdd = true }
                }

                adherenceCard.padding(.horizontal, Spacing.xl)

                if supplements.isEmpty {
                    emptyState
                } else {
                    ForEach(schedule) { block in
                        timeBlockSection(block)
                    }
                    if !lowStockSupplements.isEmpty {
                        stockAlertCard.padding(.horizontal, Spacing.xl).padding(.top, 12)
                    }
                }

                Spacer().frame(height: Spacing.screenSafeBottom)
            }
        }
        .background(t.bg.ignoresSafeArea())
        .navigationBarHidden(true)
        .navigationDestination(for: SupItem.self) { item in
            SupplementDetailView(supplement: item)
        }
        .sheet(isPresented: $showAdd) {
            ThemedRoot { SupplementAddView() }
                .environment(deps)
        }
        .task { await loadData() }
        .onChange(of: showAdd) { _, isShowing in
            if !isShowing { Task { await loadData() } }
        }
    }

    private var todayEyebrow: String {
        let df = DateFormatter()
        df.locale = Locale(identifier: "de_DE")
        df.dateFormat = "d. MMM"
        return "\(df.string(from: .now)) · heute"
    }

    private func loadData() async {
        supplements = (try? await deps.supplements.fetchSupplements()) ?? []
        intakes     = (try? await deps.supplements.todayIntakes()) ?? []
        streak      = (try? await deps.supplements.streakDays()) ?? 0
    }

    private func toggleIntake(_ item: SupItem) async {
        if item.taken {
            try? await deps.supplements.clearIntake(supplementID: item.supplementID)
        } else {
            try? await deps.supplements.recordIntake(supplementID: item.supplementID, takenAt: Date())
        }
        intakes = (try? await deps.supplements.todayIntakes()) ?? []
        streak  = (try? await deps.supplements.streakDays()) ?? 0
    }

    @ViewBuilder private var adherenceCard: some View {
        Card(pad: Spacing.l) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Eyebrow(text: "Heute eingenommen")
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(takenCount)")
                            .font(Typography.number(40))
                            .kerning(-1.4)
                            .foregroundStyle(t.text)
                        Text("/ \(totalCount)")
                            .font(.custom(Typography.geistMono, size: 18))
                            .foregroundStyle(t.textMuted)
                    }
                    if streak > 0 {
                        Text("↑ \(streak)T Streak")
                            .font(.custom(Typography.geistMono, size: 12))
                            .foregroundStyle(t.accent)
                    }
                }
                Spacer()
                DonutMini(value: Double(takenCount), total: Double(totalCount))
                    .frame(width: 72, height: 72)
            }

            adherenceStrip.padding(.top, 14)
        }
    }

    @ViewBuilder private var adherenceStrip: some View {
        HStack(spacing: 3) {
            ForEach(adherenceStates.indices, id: \.self) { i in
                RoundedRectangle(cornerRadius: 3)
                    .fill(adherenceStates[i] == .taken ? t.accent :
                          adherenceStates[i] == .partial ? t.amber :
                          adherenceStates[i] == .missed ? t.danger :
                          Color.clear)
                    .frame(height: 24)
                    .overlay(
                        adherenceStates[i] == .today
                        ? RoundedRectangle(cornerRadius: 3)
                            .stroke(t.borderStrong, style: StrokeStyle(lineWidth: 1, dash: [3, 2]))
                        : nil
                    )
            }
        }
    }

    @ViewBuilder private var stockAlertCard: some View {
        Card(pad: Spacing.l) {
            HStack(spacing: 10) {
                Circle().fill(t.amber).frame(width: 8, height: 8)
                Text("Bestand wird knapp")
                    .font(.custom(Typography.geist, size: 14).weight(.semibold))
                    .foregroundStyle(t.text)
                Spacer()
            }
            VStack(spacing: 6) {
                ForEach(lowStockSupplements, id: \.id) { sup in
                    HStack {
                        Text(sup.name)
                            .font(.custom(Typography.geist, size: 13))
                            .foregroundStyle(t.textMid)
                        Spacer()
                        Text("\(sup.stockUnits) verbleibend")
                            .font(.custom(Typography.geistMono, size: 12))
                            .foregroundStyle(t.amber)
                    }
                }
            }
            .padding(.top, 8)
        }
    }

    @ViewBuilder private func timeBlockSection(_ block: TimeBlock) -> some View {
        let taken = block.supplements.filter(\.taken).count
        let total = block.supplements.count
        VStack(spacing: 0) {
            HStack {
                Text(block.name.uppercased())
                    .font(.custom(Typography.geistMono, size: 11).weight(.semibold))
                    .kerning(0.8)
                    .foregroundStyle(t.text)
                Text(block.time)
                    .font(.custom(Typography.geistMono, size: 11))
                    .foregroundStyle(t.textMuted)
                Spacer()
                Text("\(taken)/\(total)")
                    .font(.custom(Typography.geistMono, size: 11))
                    .foregroundStyle(t.textMuted)
            }
            .padding(.horizontal, Spacing.xl).padding(.top, 16).padding(.bottom, 8)

            Card(pad: 0) {
                VStack(spacing: 0) {
                    ForEach(block.supplements) { sup in
                        NavigationLink(value: sup) {
                            SupRow(item: sup) { await toggleIntake(sup) }
                        }
                        .buttonStyle(.plain)
                        if sup.id != block.supplements.last?.id {
                            Divider().background(t.border).padding(.horizontal, Spacing.l)
                        }
                    }
                }
            }
            .padding(.horizontal, Spacing.xl)
        }
    }
}

// MARK: - Supplement row

struct SupRow: View {
    @Environment(\.theme) private var t
    var item: SupItem
    var onToggle: (() async -> Void)?

    var body: some View {
        HStack(spacing: 12) {
            pillIcon
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.custom(Typography.geist, size: 14).weight(.medium))
                    .foregroundStyle(item.taken ? t.textMuted : t.text)
                    .strikethrough(item.taken)
                HStack(spacing: 6) {
                    Text(item.dose)
                        .font(.custom(Typography.geistMono, size: 11))
                        .foregroundStyle(t.textMuted)
                    if item.withFood {
                        Text("· mit Essen")
                            .font(.custom(Typography.geistMono, size: 11))
                            .foregroundStyle(t.textMuted)
                    }
                    if item.kind == .medication {
                        Text("RX")
                            .font(.custom(Typography.geistMono, size: 9).weight(.bold))
                            .foregroundStyle(t.danger)
                            .padding(.horizontal, 5).padding(.vertical, 2)
                            .overlay(Capsule().stroke(t.danger.opacity(0.5), lineWidth: 1))
                    }
                }
            }
            Spacer()
            Button {
                Task { await onToggle?() }
            } label: {
                Image(systemName: item.taken ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(item.taken ? t.accent : t.borderStrong)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, Spacing.l).padding(.vertical, 12)
    }

    @ViewBuilder private var pillIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(t.surface2)
                .frame(width: 32, height: 32)
            Image(systemName: item.kind == .medication ? "pills.fill" : "leaf.fill")
                .font(.system(size: 14))
                .foregroundStyle(item.taken ? t.accent : t.textMuted)
        }
    }
}

// MARK: - Donut mini

struct DonutMini: View {
    @Environment(\.theme) private var t
    var value: Double
    var total: Double

    var body: some View {
        ZStack {
            Circle().stroke(t.surface2, lineWidth: 8)
            Circle()
                .trim(from: 0, to: total > 0 ? CGFloat(value / total) : 0)
                .stroke(t.accent, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text("\(Int(total > 0 ? value / total * 100 : 0))%")
                .font(Typography.number(14))
                .foregroundStyle(t.text)
        }
    }
}

// MARK: - Models

struct TimeBlock: Identifiable {
    let id = UUID()
    var name: String
    var time: String
    var supplements: [SupItem]
}

struct SupItem: Identifiable, Hashable {
    let id = UUID()
    var supplementID: UUID = UUID()
    var name: String
    var dose: String
    var kind: SupplementKind
    var taken: Bool
    var withFood: Bool
}

enum AdherenceState { case taken, partial, missed, today }

#Preview {
    ThemedRoot { SupplementOverviewView() }
        .environment(AppDependencies.mock())
}
