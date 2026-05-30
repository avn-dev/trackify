import Foundation
import SwiftData

@Model
final class UserProfile {
    @Attribute(.unique) var id: UUID
    var email: String
    var displayName: String
    var unitsKg: Bool
    var unitsKm: Bool
    var createdAt: Date

    init(id: UUID = UUID(), email: String, displayName: String,
         unitsKg: Bool = true, unitsKm: Bool = true, createdAt: Date = .now) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.unitsKg = unitsKg
        self.unitsKm = unitsKm
        self.createdAt = createdAt
    }
}
