import Foundation
import UserNotifications

extension Notification.Name {
    static let supplementDeepLink = Notification.Name("trackify.supplementDeepLink")
}

final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {

    // Show notification banner even when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }

    // Handle tap on a delivered notification
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        if let idString = response.notification.request.content.userInfo["supplementID"] as? String {
            NotificationCenter.default.post(
                name: .supplementDeepLink,
                object: nil,
                userInfo: ["supplementID": idString]
            )
        }
        completionHandler()
    }
}
