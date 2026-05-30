import Foundation
import SwiftData

enum SupplementKind: String, Codable, CaseIterable {
    case supplement, medication, herbal

    var label: String {
        switch self {
        case .supplement: "Supplement"
        case .medication: "Medikament"
        case .herbal:     "Pflanzlich"
        }
    }
}

@Model
final class Supplement {
    @Attribute(.unique) var id: UUID
    var userID: UUID
    var name: String
    var kind: SupplementKind
    var dose: String
    var form: String
    var stockUnits: Int
    var frequency: String
    var times: [String]
    var withFood: Bool
    var reminderOn: Bool
    var trackStock: Bool
    var note: String?
    @Relationship(deleteRule: .cascade) var intakes: [SupplementIntake]

    init(id: UUID = UUID(), userID: UUID, name: String, kind: SupplementKind = .supplement,
         dose: String = "", form: String = "Kapsel", stockUnits: Int = 0,
         frequency: String = "daily", times: [String] = [], withFood: Bool = false,
         reminderOn: Bool = true, trackStock: Bool = true, note: String? = nil) {
        self.id = id
        self.userID = userID
        self.name = name
        self.kind = kind
        self.dose = dose
        self.form = form
        self.stockUnits = stockUnits
        self.frequency = frequency
        self.times = times
        self.withFood = withFood
        self.reminderOn = reminderOn
        self.trackStock = trackStock
        self.note = note
        self.intakes = []
    }
}

@Model
final class SupplementIntake {
    @Attribute(.unique) var id: UUID
    var supplementID: UUID
    var plannedAt: Date
    var takenAt: Date?
    var skipped: Bool

    init(id: UUID = UUID(), supplementID: UUID, plannedAt: Date,
         takenAt: Date? = nil, skipped: Bool = false) {
        self.id = id
        self.supplementID = supplementID
        self.plannedAt = plannedAt
        self.takenAt = takenAt
        self.skipped = skipped
    }
}
