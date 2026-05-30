import Foundation
import SwiftData

enum MuscleGroup: String, Codable, CaseIterable {
    case chest, back, legs, shoulders, arms, core, fullBody

    var label: String {
        switch self {
        case .chest:     "Brust"
        case .back:      "Rücken"
        case .legs:      "Beine"
        case .shoulders: "Schultern"
        case .arms:      "Arme"
        case .core:      "Core"
        case .fullBody:  "Ganzkörper"
        }
    }
}

@Model
final class Exercise {
    @Attribute(.unique) var id: UUID
    var name: String
    var muscleGroup: MuscleGroup
    var demoVideoURL: URL?

    init(id: UUID = UUID(), name: String, muscleGroup: MuscleGroup, demoVideoURL: URL? = nil) {
        self.id = id
        self.name = name
        self.muscleGroup = muscleGroup
        self.demoVideoURL = demoVideoURL
    }
}

@Model
final class Workout {
    @Attribute(.unique) var id: UUID
    var userID: UUID
    var planDay: String?
    var startedAt: Date
    var endedAt: Date?
    var volumeKg: Double
    @Relationship(deleteRule: .cascade) var sets: [WorkoutSet]

    init(id: UUID = UUID(), userID: UUID, planDay: String? = nil,
         startedAt: Date = .now, endedAt: Date? = nil, volumeKg: Double = 0) {
        self.id = id
        self.userID = userID
        self.planDay = planDay
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.volumeKg = volumeKg
        self.sets = []
    }
}

@Model
final class WorkoutSet {
    @Attribute(.unique) var id: UUID
    var workoutID: UUID
    var exerciseID: UUID
    var exerciseName: String
    var setNo: Int
    var weightKg: Double
    var reps: Int
    var rir: Int?
    var doneAt: Date

    init(id: UUID = UUID(), workoutID: UUID, exerciseID: UUID, exerciseName: String,
         setNo: Int, weightKg: Double, reps: Int, rir: Int? = nil, doneAt: Date = .now) {
        self.id = id
        self.workoutID = workoutID
        self.exerciseID = exerciseID
        self.exerciseName = exerciseName
        self.setNo = setNo
        self.weightKg = weightKg
        self.reps = reps
        self.rir = rir
        self.doneAt = doneAt
    }
}
