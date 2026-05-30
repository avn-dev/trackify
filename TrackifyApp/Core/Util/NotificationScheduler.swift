import Foundation
import UserNotifications

@MainActor
final class NotificationScheduler {

    static let shared = NotificationScheduler()

    func requestAuthorization() async {
        _ = try? await UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        )
    }

    func scheduleSupplements(_ supplements: [Supplement]) async {
        let center = UNUserNotificationCenter.current()

        // Cancel existing supplement notifications before rescheduling
        let existing = await center.pendingNotificationRequests()
        let ids = existing.filter { $0.identifier.hasPrefix("supp-") }.map(\.identifier)
        center.removePendingNotificationRequests(withIdentifiers: ids)

        for supp in supplements where supp.reminderOn {
            for timeStr in supp.times {
                guard let trigger = dailyTrigger(from: timeStr) else { continue }
                let id = "supp-\(supp.id.uuidString)-\(timeStr)"

                let content = UNMutableNotificationContent()
                content.title = supp.name
                content.body = supp.dose + (supp.withFood ? " · mit dem Essen" : "")
                content.sound = .default
                content.userInfo = ["supplementID": supp.id.uuidString]

                let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
                try? await center.add(request)
            }
        }
    }

    func cancelSupplements(ids: [UUID]) {
        let center = UNUserNotificationCenter.current()
        let prefixes = ids.map { "supp-\($0.uuidString)" }
        Task {
            let pending = await center.pendingNotificationRequests()
            let toRemove = pending
                .filter { req in prefixes.contains(where: { req.identifier.hasPrefix($0) }) }
                .map(\.identifier)
            center.removePendingNotificationRequests(withIdentifiers: toRemove)
        }
    }

    private func dailyTrigger(from timeStr: String) -> UNCalendarNotificationTrigger? {
        let parts = timeStr.split(separator: ":").compactMap { Int($0) }
        guard parts.count == 2 else { return nil }
        var comps = DateComponents()
        comps.hour = parts[0]
        comps.minute = parts[1]
        return UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
    }
}
