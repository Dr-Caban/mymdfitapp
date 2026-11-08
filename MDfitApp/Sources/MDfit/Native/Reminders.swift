import Foundation
import UserNotifications

/// Local "keep your streak" reminder: if today's daily goal isn't met yet, nudge at 7 PM; cancel it as soon
/// as the goal is met. Local notifications need no server and no push certificate.
@MainActor
enum Reminders {
    private static let streakId = "mdfit-streak-today"
    private static let askedKey = "mdfit.asked.notifications"

    /// Asked once, right after the member finishes a workout (not on first launch).
    static func requestPermissionIfNeeded() {
        guard !UserDefaults.standard.bool(forKey: askedKey) else { return }
        UserDefaults.standard.set(true, forKey: askedKey)
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
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
