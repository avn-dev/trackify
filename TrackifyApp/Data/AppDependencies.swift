import SwiftUI
import SwiftData

/// Single dependency container injected into the SwiftUI environment.
/// Access in views via: @Environment(AppDependencies.self) private var deps
@MainActor @Observable
final class AppDependencies {
    let workouts: any WorkoutRepository
    let runs: any RunRepository
    let body: any BodyMetricRepository
    let lab: any LabRepository
    let supplements: any SupplementRepository

    @MainActor
    init(modelContext: ModelContext) {
        workouts    = SwiftDataWorkoutRepository(context: modelContext)
        runs        = SwiftDataRunRepository(context: modelContext)
        body        = SwiftDataBodyMetricRepository(context: modelContext)
        lab         = SwiftDataLabRepository(context: modelContext)
        supplements = SwiftDataSupplementRepository(context: modelContext)
    }

    @MainActor
    static func mock() -> AppDependencies {
        let schema = Schema([
            UserProfile.self, Workout.self, WorkoutSet.self, Exercise.self,
            Run.self, BodyMetric.self, LabMeasurement.self, LabValue.self,
            Supplement.self, SupplementIntake.self,
        ])
        let container = try! ModelContainer(for: schema, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        return AppDependencies(modelContext: container.mainContext)
    }
}
