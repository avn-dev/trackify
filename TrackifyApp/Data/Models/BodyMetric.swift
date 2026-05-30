import Foundation
import SwiftData

enum BodyMetricType: String, Codable, CaseIterable {
    case weight, bodyFat
    case chest, waist, hips, biceps, thigh, calf, shoulder, forearm, neck, ankle

    var label: String {
        switch self {
        case .weight:   "Gewicht"
        case .bodyFat:  "Körperfett"
        case .chest:    "Brust"
        case .waist:    "Taille"
        case .hips:     "Hüfte"
        case .biceps:   "Bizeps"
        case .thigh:    "Oberschenkel"
        case .calf:     "Wade"
        case .shoulder: "Schulter"
        case .forearm:  "Unterarm"
        case .neck:     "Nacken"
        case .ankle:    "Knöchel"
        }
    }

    var unit: String {
        switch self {
        case .weight:  "kg"
        case .bodyFat: "%"
        default:       "cm"
        }
    }

    // True = higher is better (e.g. muscle measurements), false = lower is better
    var higherIsBetter: Bool {
        switch self {
        case .weight, .bodyFat, .waist, .hips: return false
        default: return true
        }
    }
}

@Model
final class BodyMetric {
    @Attribute(.unique) var id: UUID
    var userID: UUID
    var ts: Date
    var type: BodyMetricType
    var value: Double
    var method: String?

    init(id: UUID = UUID(), userID: UUID, ts: Date = .now,
         type: BodyMetricType, value: Double, method: String? = nil) {
        self.id = id
        self.userID = userID
        self.ts = ts
        self.type = type
        self.value = value
        self.method = method
    }
}
