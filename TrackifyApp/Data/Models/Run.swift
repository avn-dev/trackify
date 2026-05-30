import Foundation
import SwiftData

@Model
final class Run {
    @Attribute(.unique) var id: UUID
    var userID: UUID
    var startedAt: Date
    var endedAt: Date
    var distanceM: Double
    var durationS: Int
    var gainM: Double
    var polyline: Data
    var splitsJSON: String

    var paceSecPerKm: Int {
        distanceM > 0 ? Int(Double(durationS) / (distanceM / 1000)) : 0
    }

    var distanceKm: Double { distanceM / 1000 }

    init(id: UUID = UUID(), userID: UUID, startedAt: Date = .now, endedAt: Date = .now,
         distanceM: Double = 0, durationS: Int = 0, gainM: Double = 0,
         polyline: Data = Data(), splitsJSON: String = "[]") {
        self.id = id
        self.userID = userID
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.distanceM = distanceM
        self.durationS = durationS
        self.gainM = gainM
        self.polyline = polyline
        self.splitsJSON = splitsJSON
    }
}

struct RunSplit: Codable, Identifiable {
    var id: Int { km }
    var km: Int
    var paceSecPerKm: Int
    var avgBpm: Int?
}
