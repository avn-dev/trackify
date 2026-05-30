import Foundation
import SwiftData

@MainActor
final class SwiftDataWorkoutRepository: WorkoutRepository {
    private let context: ModelContext

    init(context: ModelContext) { self.context = context }

    func fetchWorkouts(limit: Int) throws -> [Workout] {
        var descriptor = FetchDescriptor<Workout>(
            sortBy: [SortDescriptor(\.startedAt, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        return try context.fetch(descriptor)
    }

    func fetchWorkout(id: UUID) throws -> Workout? {
        let descriptor = FetchDescriptor<Workout>(
            predicate: #Predicate { $0.id == id }
        )
        return try context.fetch(descriptor).first
    }

    func save(_ workout: Workout) throws {
        context.insert(workout)
        try context.save()
    }

    func delete(_ workout: Workout) throws {
        context.delete(workout)
        try context.save()
    }

    func weeklyVolume() throws -> [DayVolume] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        guard let weekStart = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)),
              let weekEnd = cal.date(byAdding: .day, value: 7, to: weekStart) else { return [] }

        let descriptor = FetchDescriptor<Workout>(
            predicate: #Predicate { $0.startedAt >= weekStart && $0.startedAt < weekEnd }
        )
        let weekWorkouts = try context.fetch(descriptor)

        let dayNames = ["Mo", "Di", "Mi", "Do", "Fr", "Sa", "So"]
        return (0..<7).compactMap { offset -> DayVolume? in
            guard let day = cal.date(byAdding: .day, value: offset, to: weekStart),
                  let next = cal.date(byAdding: .day, value: 1, to: day) else { return nil }
            let dayWorkouts = weekWorkouts.filter { $0.startedAt >= day && $0.startedAt < next }
            return DayVolume(
                dayLabel: dayNames[offset],
                volumeKg: dayWorkouts.reduce(0) { $0 + $1.volumeKg },
                hasWorkout: !dayWorkouts.isEmpty,
                isToday: cal.isDate(day, inSameDayAs: today)
            )
        }
    }

    func fetchSets(exerciseName: String, limit: Int) throws -> [WorkoutSet] {
        var descriptor = FetchDescriptor<WorkoutSet>(
            predicate: #Predicate { $0.exerciseName == exerciseName },
            sortBy: [SortDescriptor(\.doneAt, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        return try context.fetch(descriptor)
    }

    func fetchAllSets(limit: Int) throws -> [WorkoutSet] {
        var descriptor = FetchDescriptor<WorkoutSet>(
            sortBy: [SortDescriptor(\.doneAt, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        return try context.fetch(descriptor)
    }

    func weeklyCount() throws -> Int {
        let cal = Calendar.current
        guard let monday = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())),
              let sunday = cal.date(byAdding: .day, value: 7, to: monday) else { return 0 }
        let descriptor = FetchDescriptor<Workout>(
            predicate: #Predicate { $0.startedAt >= monday && $0.startedAt < sunday }
        )
        return try context.fetch(descriptor).count
    }

    func fetchWorkouts(since: Date) throws -> [Workout] {
        var desc = FetchDescriptor<Workout>(
            predicate: #Predicate { $0.startedAt >= since },
            sortBy: [SortDescriptor(\.startedAt, order: .reverse)]
        )
        desc.fetchLimit = 9999
        return try context.fetch(desc)
    }

    func applySetEdits(_ edits: [(id: UUID, weightKg: Double, reps: Int, rir: Int?)], forWorkoutID: UUID) throws {
        for edit in edits {
            let setID = edit.id
            let desc = FetchDescriptor<WorkoutSet>(predicate: #Predicate { $0.id == setID })
            if let s = try context.fetch(desc).first {
                s.weightKg = edit.weightKg
                s.reps     = edit.reps
                s.rir      = edit.rir
            }
        }
        let wdesc = FetchDescriptor<Workout>(predicate: #Predicate { $0.id == forWorkoutID })
        if let w = try context.fetch(wdesc).first {
            w.volumeKg = w.sets.reduce(0.0) { $0 + $1.weightKg * Double($1.reps) }
        }
        try context.save()
    }
}
