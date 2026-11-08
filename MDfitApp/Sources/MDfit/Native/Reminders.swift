import UIKit
import UserNotifications

/// Local "keep your streak" reminder: if today's daily goal isn't met yet, nudge at 7 PM; cancel it as soon
/// as the goal is met. Local notifications need no server and no push certificate.
@MainActor
enum Reminders {
    private static let streakId = "mdfit-streak-today"
    private static let askedKey = "mdfit.asked.notifications"

    /// Asked once: the first time the signed-in member app loads, or after the first finished workout.
    static func requestPermissionIfNeeded() {
        guard !UserDefaults.standard.bool(forKey: askedKey) else { return }
        UserDefaults.standard.set(true, forKey: askedKey)
        Task {
            let granted = (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])) ?? false
            if granted { UIApplication.shared.registerForRemoteNotifications() }
        }
    }

    /// Apple's device token can change, so it is fetched on every launch and sent to the server by the page.
    static func registerForPushIfAllowed() {
        Task {
            let status = await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
            if status == .authorized || status == .provisional { UIApplication.shared.registerForRemoteNotifications() }
        }
    }

    static func updateStreakReminder(qualifying: Bool, remaining: Int, streak: Int) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [streakId])
        guard !qualifying else { return }

        var at = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        at.hour = 19
        at.minute = 0
        guard let fire = Calendar.current.date(from: at), fire > Date() else { return }   // already past 7 PM

        let content = UNMutableNotificationContent()
        if streak > 0 {
            content.title = "Keep your \(streak)-day streak going 🔥"
            content.body = remaining > 0
                ? "You're \(remaining) XP from today's goal. A quick workout or a few activities will do it."
                : "Log today's workout or activities before midnight."
        } else {
            content.title = "Start a streak today"
            content.body = "A quick workout or a few daily activities hits today's goal."
        }
        content.sound = .default
        content.userInfo = ["route": "home"]

        let request = UNNotificationRequest(
            identifier: streakId, content: content,
            trigger: UNCalendarNotificationTrigger(dateMatching: at, repeats: false))
        Task {
            let status = await center.notificationSettings().authorizationStatus
            guard status == .authorized || status == .provisional else { return }
            try? await center.add(request)
        }
    }
}
