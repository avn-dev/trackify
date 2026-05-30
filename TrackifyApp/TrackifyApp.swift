import SwiftUI
import SwiftData
import UserNotifications

@main
struct TrackifyApp: App {
    @AppStorage("colorSchemeOverride") private var colorSchemeOverride = "system"

    let sharedModelContainer: ModelContainer
    let appDeps: AppDependencies
    private static let notificationDelegate = NotificationDelegate()

    @MainActor
    init() {
        UNUserNotificationCenter.current().delegate = Self.notificationDelegate
        let schema = Schema([
            UserProfile.self,
            Workout.self,
            WorkoutSet.self,
            Exercise.self,
            Run.self,
            BodyMetric.self,
            LabMeasurement.self,
            LabValue.self,
            Supplement.self,
            SupplementIntake.self,
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            sharedModelContainer = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
        appDeps = AppDependencies(modelContext: sharedModelContainer.mainContext)
    }

    var body: some Scene {
        WindowGroup {
            ThemedRoot {
                RootView()
            }
            .environment(appDeps)
            .preferredColorScheme(resolvedScheme)
        }
        .modelContainer(sharedModelContainer)
    }

    private var resolvedScheme: ColorScheme? {
        switch colorSchemeOverride {
        case "dark":  return .dark
        case "light": return .light
        default:      return nil
        }
    }
}
