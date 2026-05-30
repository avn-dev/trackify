import Foundation

@MainActor
protocol WorkoutRepository {
    func fetchWorkouts(limit: Int) async throws -> [Workout]
    func fetchWorkout(id: UUID) async throws -> Workout?
    func save(_ workout: Workout) async throws
    func delete(_ workout: Workout) async throws
    func weeklyVolume() async throws -> [DayVolume]
    func weeklyCount() async throws -> Int
    func fetchSets(exerciseName: String, limit: Int) async throws -> [WorkoutSet]
    func fetchAllSets(limit: Int) async throws -> [WorkoutSet]
    func fetchWorkouts(since: Date) async throws -> [Workout]
    func applySetEdits(_ edits: [(id: UUID, weightKg: Double, reps: Int, rir: Int?)], forWorkoutID: UUID) async throws
}

struct DayVolume: Identifiable {
    var id: String { dayLabel }
    var dayLabel: String
    var volumeKg: Double
    var hasWorkout: Bool
    var isToday: Bool
}
