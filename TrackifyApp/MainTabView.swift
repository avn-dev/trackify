import SwiftUI

enum Tab: String, CaseIterable {
    case home, train, run, body, me
}

struct MainTabView: View {
    @State private var active: Tab = .home
    @AppStorage(AccentOption.storageKey) private var accentKey = AccentOption.lime.rawValue

    var body: some View {
        TabView(selection: $active) {
            HomeView()
                .tabItem { Label("Home", systemImage: "house") }
                .tag(Tab.home)

            TrainingTabView()
                .tabItem { Label("Training", systemImage: "dumbbell") }
                .tag(Tab.train)

            RunHistoryView()
                .tabItem { Label("Cardio", systemImage: "figure.run") }
                .tag(Tab.run)

            BodyTabView()
                .tabItem { Label("Körper", systemImage: "figure.stand") }
                .tag(Tab.body)

            ProfileTabView()
                .tabItem { Label("Profil", systemImage: "person.crop.circle") }
                .tag(Tab.me)
        }
        .tint((AccentOption(rawValue: accentKey) ?? .lime).color)
        .onReceive(NotificationCenter.default.publisher(for: .supplementDeepLink)) { _ in
            withAnimation(.easeOut(duration: 0.2)) { active = .body }
        }
    }
}


// MARK: - Body tab stack (hub → weight / bodyfat / measurements / lab / supplements)

struct BodyTabView: View {
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            BodyHubView()
                .navigationDestination(for: BodyRoute.self) { route in
                    switch route {
                    case .weight:       WeightView()
                    case .bodyFat:      BodyFatView()
                    case .measurements: MeasurementsView()
                    case .lab:          LabOverviewView()
                    case .supplements:  SupplementOverviewView()
                    }
                }
        }
        .onAppear { handlePendingDeepLink() }
        .onReceive(NotificationCenter.default.publisher(for: .supplementDeepLink)) { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                path = NavigationPath()
                path.append(BodyRoute.supplements)
            }
        }
    }

    private func handlePendingDeepLink() {
        // Handles case where tab was just switched due to a deep-link
        // and BodyTabView is appearing for the first time
    }
}

// MARK: - Profile tab stack

struct ProfileTabView: View {
    var body: some View {
        NavigationStack {
            ProfileView()
                .navigationDestination(for: ProfileRoute.self) { route in
                    switch route {
                    case .insights:          InsightsView()
                    case .dataExport:        DataExportView()
                    case .privacy:           PrivacyView()
                    case .goals:             GoalsView()
                    case .units:             UnitsView()
                    case .connectedDevices:  ConnectedDevicesView()
                    case .reminders:         RemindersView()
                    }
                }
        }
    }
}

enum ProfileRoute: Hashable { case insights, dataExport, privacy, goals, units, connectedDevices, reminders }

// MARK: - Training tab stack

struct TrainingTabView: View {
    var body: some View {
        NavigationStack {
            TrainingPlanView()
                .navigationDestination(for: ExerciseRoute.self) { route in
                    ExerciseDetailView(exerciseName: route.name, muscleLabel: route.muscle)
                }
        }
    }
}

enum BodyRoute: Hashable {
    case weight, bodyFat, measurements, lab, supplements
}

struct BodyHubView: View {
    @Environment(\.theme) private var t
    @Environment(AppDependencies.self) private var deps
    @State private var latestWeight: BodyMetric?
    @State private var latestBodyFat: BodyMetric?
    @State private var supplementCount: Int = 0
    @State private var labTotal: Int = 0
    @State private var labNormal: Int = 0

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ScreenHeader(title: "Körper", eyebrow: "Gesundheit & Maße")

                VStack(spacing: 10) {
                    HStack(spacing: 10) {
                        hubTile(route: .weight,
                                icon: "scalemass.fill",
                                label: "Gewicht",
                                value: latestWeight.map { "\(Formatters.compact($0.value)) kg" } ?? "–")
                        hubTile(route: .bodyFat,
                                icon: "chart.pie.fill",
                                label: "Körperfett",
                                value: latestBodyFat.map { "\(Formatters.compact($0.value)) %" } ?? "–")
                    }
                    hubTileWide(route: .measurements,
                                icon: "ruler.fill",
                                label: "Körpermaße",
                                subtitle: "Brust, Taille, Hüfte & mehr")
                }
                .padding(.horizontal, Spacing.xl)

                SectionHead(label: "Tracking").padding(.top, 18)

                VStack(spacing: 10) {
                    hubTileWide(route: .lab,
                                icon: "drop.fill",
                                label: "Blutwerte",
                                subtitle: labTotal > 0 ? "\(labNormal)/\(labTotal) im Normbereich" : "Noch keine Messung")
                    hubTileWide(route: .supplements,
                                icon: "pills.fill",
                                label: "Supplements",
                                subtitle: supplementCount > 0 ? "\(supplementCount) aktiv" : "Keine eingetragen")
                }
                .padding(.horizontal, Spacing.xl)
                .padding(.bottom, Spacing.screenSafeBottom)
            }
        }
        .background(t.bg.ignoresSafeArea())
        .navigationBarHidden(true)
        .task { await loadData() }
    }

    private func loadData() async {
        latestWeight  = try? await deps.body.latestMetric(type: .weight)
        latestBodyFat = try? await deps.body.latestMetric(type: .bodyFat)
        supplementCount = ((try? await deps.supplements.fetchSupplements()) ?? []).count
        if let m = try? await deps.lab.latestMeasurement() {
            labTotal  = m.values.count
            labNormal = m.values.filter { $0.status == .normal }.count
        }
    }

    @ViewBuilder private func hubTile(route: BodyRoute, icon: String, label: String, value: String) -> some View {
        NavigationLink(value: route) {
            Card(pad: Spacing.l) {
                VStack(alignment: .leading, spacing: 8) {
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundStyle(t.accent)
                    Spacer(minLength: 12)
                    Text(value)
                        .font(Typography.number(22))
                        .foregroundStyle(t.text)
                    Text(label)
                        .font(.custom(Typography.geist, size: 13))
                        .foregroundStyle(t.textMuted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(minHeight: 110)
            }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder private func hubTileWide(route: BodyRoute, icon: String, label: String, subtitle: String) -> some View {
        NavigationLink(value: route) {
            Card(pad: Spacing.l) {
                HStack(spacing: 14) {
                    Image(systemName: icon)
                        .font(.system(size: 22))
                        .foregroundStyle(t.accent)
                        .frame(width: 40, height: 40)
                        .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(t.surface2))
                    VStack(alignment: .leading, spacing: 3) {
                        Text(label)
                            .font(.custom(Typography.geist, size: 15).weight(.semibold))
                            .foregroundStyle(t.text)
                        Text(subtitle)
                            .font(.custom(Typography.geistMono, size: 12))
                            .foregroundStyle(t.textMuted)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(t.textMuted)
                }
            }
        }
        .buttonStyle(.plain)
    }
}
