import SwiftUI
import UserNotifications

struct ProfileView: View {
    @Environment(\.theme) private var t
    @Environment(AuthState.self) private var auth
    @Environment(AppDependencies.self) private var deps
    @AppStorage("colorSchemeOverride")    private var colorSchemeOverride    = "system"
    @AppStorage(AccentOption.storageKey)  private var accentKey              = AccentOption.lime.rawValue
    @AppStorage("goalWeightKg")           private var goalWeightKg           = 70.0
    @AppStorage("goal5kSec")              private var goal5kSec              = 1500
    @AppStorage("unitsKg")                private var unitsKg                = true
    @AppStorage("unitsKm")                private var unitsKm                = true
    @AppStorage("liveActivitiesEnabled")  private var liveActivitiesEnabled  = true
    @AppStorage("hkWeightSync")           private var hkWeightSync           = false
    @AppStorage("hkHeartRate")            private var hkHeartRate            = false
    @AppStorage("hkWorkoutExport")        private var hkWorkoutExport        = false
    @State private var showSignOutAlert = false
    @State private var showAppearanceDialog = false
    @State private var showAccentPicker = false
    @State private var totalWorkouts = 0
    @State private var totalRuns = 0
    @State private var streak = 0
    @State private var notificationsEnabled = false

    private var goalSummary: String {
        let wLabel = goalWeightKg.truncatingRemainder(dividingBy: 1) == 0
            ? "\(Int(goalWeightKg)) kg"
            : "\(String(format: "%.1f", goalWeightKg)) kg"
        let mins = goal5kSec / 60
        let secs = goal5kSec % 60
        return "\(wLabel) · \(mins):\(String(format: "%02d", secs))"
    }

    private var unitsSummary: String {
        "\(unitsKg ? "kg" : "lbs") · \(unitsKm ? "km" : "mi")"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ScreenHeader(title: "Profil") {
                    CircleBtn(systemIcon: "gearshape") { showAppearanceDialog = true }
                }

                userCard.padding(.horizontal, Spacing.xl)

                statsRow.padding(.horizontal, Spacing.xl).padding(.top, 12)

                settingsGroup("Persönlich", items: [
                    .link("Ziele", value: goalSummary, route: .goals),
                    .link("Einheiten", value: unitsSummary, route: .units),
                    .link("Verbundene Geräte", value: (hkWeightSync || hkHeartRate || hkWorkoutExport) ? "Apple Health" : "Aus", route: .connectedDevices),
                ])
                .padding(.horizontal, Spacing.xl).padding(.top, 18)

                settingsGroup("App", items: [
                    .picker("Erscheinungsbild", value: colorSchemeLabel) { showAppearanceDialog = true },
                    .colorPicker("Akzentfarbe", color: (AccentOption(rawValue: accentKey) ?? .lime).color) { showAccentPicker = true },
                    .link("Erinnerungen", value: notificationsEnabled ? "An" : "Aus", route: .reminders),
                    .toggle("Live-Aktivitäten", isOn: $liveActivitiesEnabled),
                ])
                .padding(.horizontal, Spacing.xl).padding(.top, 12)

                settingsGroup("Konto", items: [
                    .link("Datenexport", value: "", route: .dataExport),
                    .link("Datenschutz", value: "", route: .privacy),
                    .danger("Abmelden"),
                ])
                .padding(.horizontal, Spacing.xl).padding(.top, 12)

                Text(versionString)
                    .font(.custom(Typography.geistMono, size: 11))
                    .foregroundStyle(t.textMuted)
                    .padding(.top, 24)

                Spacer().frame(height: Spacing.screenSafeBottom)
            }
        }
        .background(t.bg.ignoresSafeArea())
        .navigationBarHidden(true)
        .task { await loadStats() }
        .alert("Abmelden?", isPresented: $showSignOutAlert) {
            Button("Abmelden", role: .destructive) { auth.signOut() }
            Button("Abbrechen", role: .cancel) {}
        }
        .confirmationDialog("Erscheinungsbild", isPresented: $showAppearanceDialog, titleVisibility: .visible) {
            Button("System")  { colorSchemeOverride = "system" }
            Button("Hell")    { colorSchemeOverride = "light"  }
            Button("Dunkel")  { colorSchemeOverride = "dark"   }
            Button("Abbrechen", role: .cancel) {}
        }
        .sheet(isPresented: $showAccentPicker) {
            ThemedRoot {
                AccentColorPickerSheet(selectedKey: $accentKey)
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }

    private func loadStats() async {
        totalWorkouts = ((try? await deps.workouts.fetchWorkouts(limit: 9999)) ?? []).count
        totalRuns     = ((try? await deps.runs.fetchRuns(limit: 9999)) ?? []).count
        streak        = ((try? await deps.supplements.streakDays()) ?? 0) / 7
        let ns = await UNUserNotificationCenter.current().notificationSettings()
        notificationsEnabled = ns.authorizationStatus == .authorized
    }

    private var versionString: String {
        let v = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let b = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "Trackify \(v) (\(b))"
    }

    private var colorSchemeLabel: String {
        switch colorSchemeOverride {
        case "dark":  return "Dunkel"
        case "light": return "Hell"
        default:       return "System"
        }
    }

    private func showAppearancePicker() {
        let options = ["system", "dark", "light"]
        colorSchemeOverride = options[((options.firstIndex(of: colorSchemeOverride) ?? 0) + 1) % 3]
    }

    @ViewBuilder private var userCard: some View {
        Card(pad: Spacing.l) {
            HStack(spacing: 14) {
                Avatar(initials: auth.userInitials.isEmpty ? "?" : auth.userInitials)
                VStack(alignment: .leading, spacing: 4) {
                    Text(auth.userName.isEmpty ? "Unbekannt" : auth.userName)
                        .font(.custom(Typography.geist, size: 17).weight(.semibold))
                        .foregroundStyle(t.text)
                    Text(auth.userEmail.isEmpty ? "–" : auth.userEmail)
                        .font(.custom(Typography.geistMono, size: 12))
                        .foregroundStyle(t.textMuted)
                }
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "bolt.fill").font(.system(size: 10))
                    Text("PRO")
                        .font(.custom(Typography.geistMono, size: 11).weight(.bold))
                        .kerning(0.5)
                }
                .foregroundStyle(t.accentText)
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(Capsule().fill(t.accent))
            }
        }
    }

    @ViewBuilder private var statsRow: some View {
        NavigationLink(value: ProfileRoute.insights) {
            HStack(spacing: 0) {
                statCell(label: "Workouts", value: "\(totalWorkouts)")
                Divider().background(t.border)
                statCell(label: "Läufe", value: "\(totalRuns)")
                Divider().background(t.border)
                statCell(label: "Streak", value: streak > 0 ? "\(streak)W" : "–")
            }
            .padding(.vertical, 16)
            .background(RoundedRectangle(cornerRadius: Radii.card, style: .continuous).fill(t.surface))
            .overlay(RoundedRectangle(cornerRadius: Radii.card, style: .continuous).stroke(t.border, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder private func statCell(label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(value).font(Typography.number(22)).foregroundStyle(t.text)
            Text(label).font(.custom(Typography.geistMono, size: 11)).foregroundStyle(t.textMuted)
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder private func settingsGroup(_ title: String, items: [SettingItem]) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text(title.uppercased())
                    .font(Typography.eyebrow).kerning(Tracking.eyebrow)
                    .foregroundStyle(t.textMuted)
                Spacer()
            }
            .padding(.bottom, Spacing.m)

            Card(pad: 0) {
                ForEach(items.indices, id: \.self) { i in
                    settingRow(items[i])
                    if i < items.count - 1 {
                        Divider().background(t.border).padding(.horizontal, Spacing.l)
                    }
                }
            }
        }
    }

    @ViewBuilder private func settingRow(_ item: SettingItem) -> some View {
        HStack {
            switch item {
            case .navigation(let label, let value):
                Text(label).font(.custom(Typography.geist, size: 15)).foregroundStyle(t.text)
                Spacer()
                if !value.isEmpty {
                    Text(value).font(.custom(Typography.geistMono, size: 13)).foregroundStyle(t.textMuted)
                }
                Image(systemName: "chevron.right").font(.system(size: 12)).foregroundStyle(t.textMuted)

            case .link(let label, let value, let route):
                NavigationLink(value: route) {
                    HStack {
                        Text(label).font(.custom(Typography.geist, size: 15)).foregroundStyle(t.text)
                        Spacer()
                        if !value.isEmpty {
                            Text(value).font(.custom(Typography.geistMono, size: 13)).foregroundStyle(t.textMuted)
                        }
                        Image(systemName: "chevron.right").font(.system(size: 12)).foregroundStyle(t.textMuted)
                    }
                }
                .buttonStyle(.plain)

            case .picker(let label, let value, let action):
                Text(label).font(.custom(Typography.geist, size: 15)).foregroundStyle(t.text)
                Spacer()
                Button(action: action) {
                    HStack(spacing: 4) {
                        Text(value).font(.custom(Typography.geistMono, size: 13)).foregroundStyle(t.textMuted)
                        Image(systemName: "chevron.right").font(.system(size: 12)).foregroundStyle(t.textMuted)
                    }
                }
                .buttonStyle(.plain)

            case .colorPicker(let label, let color, let action):
                Text(label).font(.custom(Typography.geist, size: 15)).foregroundStyle(t.text)
                Spacer()
                Button(action: action) {
                    HStack(spacing: 8) {
                        Circle().fill(color).frame(width: 18, height: 18)
                            .overlay(Circle().stroke(t.border, lineWidth: 1))
                        Image(systemName: "chevron.right").font(.system(size: 12)).foregroundStyle(t.textMuted)
                    }
                }
                .buttonStyle(.plain)

            case .toggle(let label, let binding):
                Text(label).font(.custom(Typography.geist, size: 15)).foregroundStyle(t.text)
                Spacer()
                Toggle("", isOn: binding).tint(t.accent).labelsHidden()

            case .danger(let label):
                Button { showSignOutAlert = true } label: {
                    Text(label).font(.custom(Typography.geist, size: 15)).foregroundStyle(t.danger)
                }
                .buttonStyle(.plain)
                Spacer()
            }
        }
        .padding(.horizontal, Spacing.l).padding(.vertical, 14)
    }
}

enum SettingItem {
    case navigation(String, value: String)
    case link(String, value: String, route: ProfileRoute)
    case picker(String, value: String, action: () -> Void)
    case colorPicker(String, color: Color, action: () -> Void)
    case toggle(String, isOn: Binding<Bool>)
    case danger(String)
}

// MARK: - Accent color picker sheet

struct AccentColorPickerSheet: View {
    @Environment(\.theme) private var t
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedKey: String

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("AKZENTFARBE")
                    .font(Typography.eyebrow).kerning(1.0)
                    .foregroundStyle(t.textMuted)
                Spacer()
                Button("Fertig") { dismiss() }
                    .font(.custom(Typography.geist, size: 15).weight(.semibold))
                    .foregroundStyle(t.text)
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.top, 28).padding(.bottom, 20)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4), spacing: 12) {
                ForEach(AccentOption.allCases, id: \.self) { option in
                    let isSelected = selectedKey == option.rawValue
                    Button {
                        withAnimation(.spring(response: 0.22, dampingFraction: 0.7)) {
                            selectedKey = option.rawValue
                        }
                    } label: {
                        VStack(spacing: 8) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(option.color)
                                    .frame(height: 56)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .stroke(Color.white.opacity(isSelected ? 0.35 : 0), lineWidth: 2)
                                    )
                                if isSelected {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundStyle(option.textColor)
                                }
                            }
                            Text(option.label)
                                .font(.custom(Typography.geistMono, size: 11).weight(isSelected ? .semibold : .regular))
                                .foregroundStyle(isSelected ? t.text : t.textMuted)
                        }
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(isSelected ? t.surface2 : t.surface)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(isSelected ? t.borderStrong : t.border,
                                        lineWidth: isSelected ? 1.5 : 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Spacing.xl)

            Spacer()
        }
        .background(t.bg.ignoresSafeArea())
    }
}

#Preview {
    ThemedRoot { NavigationStack { ProfileView() } }
        .environment(AuthState())
        .environment(AppDependencies.mock())
}
