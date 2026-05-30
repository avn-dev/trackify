// HomeView.swift
// Example port of HomeScreen (from screens-home.jsx) → SwiftUI.
// Use this as a pattern for porting the other screens.

import SwiftUI

struct HomeView: View {
    @Environment(\.theme) private var t

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                topBar
                content
            }
        }
        .background(t.bg.ignoresSafeArea())
        .overlay(alignment: .bottom) {
            // TabBar would live here in MainTabView — shown for preview only.
            // TabBarView(active: .home)
        }
    }

    // MARK: - Top bar

    @ViewBuilder private var topBar: some View {
        HStack(alignment: .center, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Eyebrow(text: "Mittwoch · 14. Mai")
                Text("Hey, Lena.")
                    .font(Typography.title(26))
                    .kerning(-0.8)
                    .foregroundStyle(t.text)
            }
            Spacer()
            CircleBtn(systemIcon: "bell") {}
            Avatar(initials: "LB")
        }
        .padding(.top, 54)
        .padding(.horizontal, Spacing.xl)
    }

    // MARK: - Content

    @ViewBuilder private var content: some View {
        VStack(spacing: 14) {
            todayCard
            statsRow
            quickTrack
            weightCard
        }
        .padding(.horizontal, Spacing.xl)
        .padding(.top, 20)
        .padding(.bottom, Spacing.screenSafeBottom)
    }

    // MARK: - Hero today card

    @ViewBuilder private var todayCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("HEUTE · TAG A")
                    .font(Typography.eyebrow).kerning(1.0)
                    .foregroundStyle(t.bg.opacity(0.6))
                Spacer()
                Text("PUSH")
                    .font(.custom(Typography.geistMono, size: 10).weight(.semibold))
                    .kerning(0.6)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(Capsule().fill(t.accent))
                    .foregroundStyle(t.accentText)
            }

            Text("Brust · Schulter · Trizeps")
                .font(Typography.title(26))
                .kerning(-0.6)
                .foregroundStyle(t.bg)

            HStack(spacing: 18) {
                Text("6 Übungen"); Text("·"); Text("~58 Min"); Text("·"); Text("22 Sätze")
            }
            .font(.custom(Typography.geistMono, size: 12))
            .foregroundStyle(t.bg.opacity(0.7))

            PrimaryButton(title: "Workout starten", systemIcon: "play.fill") {}
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: Radii.card, style: .continuous).fill(t.text))
        .foregroundStyle(t.bg)
    }

    // MARK: - Stats row

    @ViewBuilder private var statsRow: some View {
        HStack(spacing: 10) {
            Card(pad: Spacing.l) {
                HStack {
                    Eyebrow(text: "Diese Woche")
                    Spacer()
                    Image(systemName: "dumbbell").font(.system(size: 14))
                        .foregroundStyle(t.textMuted)
                }
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("3").font(Typography.number(28)).kerning(-1)
                    Text("/ 4").font(.custom(Typography.geistMono, size: 14))
                        .foregroundStyle(t.textMuted)
                }
                .padding(.top, 8)
                Text("Workouts")
                    .font(.custom(Typography.geist, size: 11))
                    .foregroundStyle(t.textMid)
                weekGrid
                    .padding(.top, 12)
            }
            Card(pad: Spacing.l) {
                HStack {
                    Eyebrow(text: "Volumen")
                    Spacer()
                    Image(systemName: "arrow.up.right").font(.system(size: 12))
                        .foregroundStyle(t.accent)
                }
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("18.420").font(Typography.number(28)).kerning(-1)
                    Text("kg").font(.custom(Typography.geistMono, size: 14))
                        .foregroundStyle(t.textMuted)
                }
                .padding(.top, 8)
                Text("↑ 14% vs. Vorw.")
                    .font(.custom(Typography.geistMono, size: 11))
                    .foregroundStyle(t.accent)
                    .padding(.top, 4)
                TrackifyLineChart(
                    data: [12, 14, 13, 17, 16, 19, 21].enumerated().map { i, v in
                        LinePoint(x: Double(i), y: v)
                    },
                    accent: true,
                    showAxis: false
                )
                .frame(height: 36)
                .padding(.top, 8)
            }
        }
    }

    @ViewBuilder private var weekGrid: some View {
        HStack(spacing: 4) {
            let days = ["M","D","M","D","F","S","S"]
            let active: Set<Int> = [0, 2, 3]
            let today = 4
            ForEach(0..<7, id: \.self) { i in
                VStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(active.contains(i) ? t.accent : (i == today ? Color.clear : t.surface2))
                        .frame(height: 24)
                        .overlay(
                            i == today
                            ? RoundedRectangle(cornerRadius: 4)
                                .stroke(t.borderStrong, style: StrokeStyle(lineWidth: 1, dash: [3, 2]))
                            : nil
                        )
                    Text(days[i])
                        .font(.custom(Typography.geistMono, size: 9))
                        .foregroundStyle(t.textMuted)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Quick track row

    @ViewBuilder private var quickTrack: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHead(label: "Schnell tracken", action: "Alle")
                .padding(.horizontal, 0)
            HStack(spacing: 10) {
                QuickTile(icon: "figure.run", label: "Lauf", sub: "Live")
                QuickTile(icon: "scalemass", label: "Gewicht", sub: "eintragen")
                QuickTile(icon: "ruler", label: "Maße", sub: "+ Wert")
            }
        }
    }

    // MARK: - Weight card

    @ViewBuilder private var weightCard: some View {
        Card(pad: Spacing.l) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Eyebrow(text: "Körpergewicht · 30T")
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text("72,4")
                            .font(Typography.number(30))
                            .kerning(-1)
                        Text("kg")
                            .font(.custom(Typography.geistMono, size: 13))
                            .foregroundStyle(t.textMuted)
                        Text("↓ 1,2")
                            .font(.custom(Typography.geistMono, size: 12))
                            .foregroundStyle(t.danger)
                    }
                }
                Spacer()
                Button("+ Eintragen") {}
                    .font(.custom(Typography.geist, size: 12))
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(Capsule().fill(t.surface2))
                    .foregroundStyle(t.text)
                    .buttonStyle(.plain)
            }
            .padding(.bottom, 8)

            TrackifyLineChart(
                data: [73.6, 73.4, 73.5, 73.1, 72.9, 72.7, 73.0, 72.6, 72.5, 72.4]
                    .enumerated().map { i, v in LinePoint(x: Double(i), y: v) },
                accent: false,
                showAxis: false
            )
            .frame(height: 88)
        }
    }
}

// MARK: - Reusable bits used only on Home

struct Avatar: View {
    @Environment(\.theme) private var t
    var initials: String
    var body: some View {
        Text(initials)
            .font(.custom(Typography.geist, size: 14).weight(.semibold))
            .foregroundStyle(t.text)
            .frame(width: 40, height: 40)
            .background(Circle().fill(t.surface2))
            .overlay(Circle().stroke(t.border, lineWidth: 1))
    }
}

struct QuickTile: View {
    @Environment(\.theme) private var t
    var icon: String
    var label: String
    var sub: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .regular))
                .foregroundStyle(t.text)
                .frame(width: 32, height: 32)
                .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(t.surface2))
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.custom(Typography.geist, size: 14).weight(.semibold))
                    .foregroundStyle(t.text)
                Text(sub)
                    .font(.custom(Typography.geistMono, size: 11))
                    .foregroundStyle(t.textMuted)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12).padding(.vertical, 14)
        .background(RoundedRectangle(cornerRadius: Radii.cardSmall, style: .continuous).fill(t.surface))
        .overlay(RoundedRectangle(cornerRadius: Radii.cardSmall, style: .continuous).stroke(t.border, lineWidth: 1))
    }
}

#Preview {
    ThemedRoot {
        HomeView()
    }
}
