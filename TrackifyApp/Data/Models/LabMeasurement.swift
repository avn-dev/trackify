import Foundation
import SwiftData

@Model
final class LabMeasurement {
    @Attribute(.unique) var id: UUID
    var userID: UUID
    var takenAt: Date
    var source: String
    var rawPDFURLString: String?
    @Relationship(deleteRule: .cascade) var values: [LabValue]

    init(id: UUID = UUID(), userID: UUID, takenAt: Date = .now,
         source: String = "Manuell", rawPDFURLString: String? = nil) {
        self.id = id
        self.userID = userID
        self.takenAt = takenAt
        self.source = source
        self.rawPDFURLString = rawPDFURLString
        self.values = []
    }
}

@Model
final class LabValue {
    @Attribute(.unique) var id: UUID
    var measurementID: UUID
    var marker: String
    var value: Double
    var unit: String
    var refLow: Double
    var refHigh: Double
    var category: String

    var status: LabStatus {
        if value < refLow { return .low }
        if value > refHigh { return .high }
        return .normal
    }

    init(id: UUID = UUID(), measurementID: UUID, marker: String,
         value: Double, unit: String, refLow: Double, refHigh: Double, category: String) {
        self.id = id
        self.measurementID = measurementID
        self.marker = marker
        self.value = value
        self.unit = unit
        self.refLow = refLow
        self.refHigh = refHigh
        self.category = category
    }
}

enum LabStatus: Hashable {
    case normal, low, high

    var label: String {
        switch self {
        case .normal: "Normal"
        case .low:    "Zu niedrig"
        case .high:   "Zu hoch"
        }
    }
}
