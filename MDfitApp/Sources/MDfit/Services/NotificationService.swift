import Foundation
import UserNotifications
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Notification Service

@MainActor
final class NotificationService: NSObject, ObservableObject {
    static let shared = NotificationService()

    @Published private(set) var isAuthorized = false
    @Published private(set) var deviceToken: String?
    @Published private(set) var pendingNotifications: [UNNotificationRequest] = []

    private let center = UNUserNotificationCenter.current()

    override private init() {
        super.init()
        center.delegate = self
        checkAuthorizationStatus()
    }

    // MARK: - Authorization

    func requestAuthorization() async -> Bool {
        do {
            let options: UNAuthorizationOptions = [.alert, .badge, .sound, .provisional]
            let granted = try await center.requestAuthorization(options: options)
            await MainActor.run {
                isAuthorized = granted
            }

            if granted {
                await registerForRemoteNotifications()
            }

            return granted
        } catch {
            print("Notification authorization error: \(error)")
            return false
        }
    }

    func checkAuthorizationStatus() {
        center.getNotificationSettings { [weak self] settings in
            Task { @MainActor in
                self?.isAuthorized = settings.authorizationStatus == .authorized ||
                                     settings.authorizationStatus == .provisional
            }
        }
    }

    private func registerForRemoteNotifications() async {
        #if canImport(UIKit)
        await MainActor.run {
            UIApplication.shared.registerForRemoteNotifications()
        }
        #endif
    }

    func handleDeviceToken(_ token: Data) {
        let tokenString = token.map { String(format: "%02.2hhx", $0) }.joined()
        deviceToken = tokenString
        print("APNs Device Token: \(tokenString)")
        // TODO: Send token to backend
    }

    func handleRegistrationError(_ error: Error) {
        print("Failed to register for remote notifications: \(error)")
    }

    // MARK: - Schedule Notifications

    /// Schedule a workout reminder
    func scheduleWorkoutReminder(
        workout: Workout,
        scheduledDate: Date,
        reminderMinutesBefore: Int = 30
    ) async throws {
        let reminderDate = Calendar.current.date(
            byAdding: .minute,
            value: -reminderMinutesBefore,
            to: scheduledDate
        ) ?? scheduledDate

        let content = UNMutableNotificationContent()
        content.title = "Workout Reminder"
        content.body = "\(workout.name) starts in \(reminderMinutesBefore) minutes"
        content.sound = .default
        content.categoryIdentifier = NotificationCategory.workout.rawValue
        content.userInfo = [
            "type": "workout_reminder",
            "workout_id": workout.id,
            "scheduled_date": scheduledDate.timeIntervalSince1970
        ]

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: reminderDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(
            identifier: "workout_\(workout.id)_\(scheduledDate.timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )

        try await center.add(request)
    }

    /// Schedule an event reminder
    func scheduleEventReminder(
        event: Event,
        reminderMinutesBefore: Int = 60
    ) async throws {
        let reminderDate = Calendar.current.date(
            byAdding: .minute,
            value: -reminderMinutesBefore,
            to: event.startDate
        ) ?? event.startDate

        let content = UNMutableNotificationContent()
        content.title = "Upcoming Event"
        content.body = "\(event.title) starts in \(formatMinutes(reminderMinutesBefore))"
        content.sound = .default
        content.categoryIdentifier = NotificationCategory.event.rawValue
        content.userInfo = [
            "type": "event_reminder",
            "event_id": event.id
        ]

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: reminderDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(
            identifier: "event_\(event.id)",
            content: content,
            trigger: trigger
        )

        try await center.add(request)
    }

    /// Schedule program day reminder
    func scheduleProgramReminder(
        program: Program,
        dayNumber: Int,
        scheduledDate: Date
    ) async throws {
        let content = UNMutableNotificationContent()
        content.title = program.name
        content.body = "Day \(dayNumber) is ready! Let's keep the momentum going."
        content.sound = .default
        content.categoryIdentifier = NotificationCategory.program.rawValue
        content.userInfo = [
            "type": "program_reminder",
            "program_id": program.id,
            "day_number": dayNumber
        ]

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: scheduledDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(
            identifier: "program_\(program.id)_day_\(dayNumber)",
            content: content,
            trigger: trigger
        )

        try await center.add(request)
    }

    /// Schedule streak reminder (daily at user's preferred time)
    func scheduleStreakReminder(at time: Date) async throws {
        let content = UNMutableNotificationContent()
        content.title = "Keep Your Streak!"
        content.body = "Don't break your streak - just 5 minutes today can make a difference"
        content.sound = .default
        content.categoryIdentifier = NotificationCategory.streak.rawValue
        content.userInfo = ["type": "streak_reminder"]

        var components = Calendar.current.dateComponents([.hour, .minute], from: time)
        components.second = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        let request = UNNotificationRequest(
            identifier: "streak_daily",
            content: content,
            trigger: trigger
        )

        try await center.add(request)
    }

    // MARK: - Cancel Notifications

    func cancelNotification(identifier: String) {
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    func cancelWorkoutReminder(workoutId: String) {
        center.getPendingNotificationRequests { [weak self] requests in
            let toRemove = requests
                .filter { $0.identifier.hasPrefix("workout_\(workoutId)") }
                .map(\.identifier)
            self?.center.removePendingNotificationRequests(withIdentifiers: toRemove)
        }
    }

    func cancelEventReminder(eventId: String) {
        center.removePendingNotificationRequests(withIdentifiers: ["event_\(eventId)"])
    }

    func cancelAllNotifications() {
        center.removeAllPendingNotificationRequests()
    }

    func cancelStreakReminder() {
        center.removePendingNotificationRequests(withIdentifiers: ["streak_daily"])
    }

    // MARK: - Fetch Pending

    func fetchPendingNotifications() async {
        let requests = await center.pendingNotificationRequests()
        await MainActor.run {
            pendingNotifications = requests
        }
    }

    // MARK: - Helpers

    private func formatMinutes(_ minutes: Int) -> String {
        if minutes < 60 {
            return "\(minutes) minutes"
        } else if minutes == 60 {
            return "1 hour"
        } else {
            let hours = minutes / 60
            let mins = minutes % 60
            if mins == 0 {
                return "\(hours) hours"
            } else {
                return "\(hours)h \(mins)m"
            }
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationService: UNUserNotificationCenterDelegate {
    /// Handle notification when app is in foreground
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        // Show notification even when app is in foreground
        return [.banner, .sound, .badge]
    }

    /// Handle notification tap
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let userInfo = response.notification.request.content.userInfo

        guard let type = userInfo["type"] as? String else { return }

        await MainActor.run {
            handleNotificationTap(type: type, userInfo: userInfo, actionIdentifier: response.actionIdentifier)
        }
    }

    @MainActor
    private func handleNotificationTap(type: String, userInfo: [AnyHashable: Any], actionIdentifier: String) {
        switch type {
        case "workout_reminder":
            if let workoutId = userInfo["workout_id"] as? String {
                NotificationCenter.default.post(
                    name: .openWorkout,
                    object: nil,
                    userInfo: ["workout_id": workoutId]
                )
            }

        case "event_reminder":
            if let eventId = userInfo["event_id"] as? String {
                NotificationCenter.default.post(
                    name: .openEvent,
                    object: nil,
                    userInfo: ["event_id": eventId]
                )
            }

        case "program_reminder":
            if let programId = userInfo["program_id"] as? String,
               let dayNumber = userInfo["day_number"] as? Int {
                NotificationCenter.default.post(
                    name: .openProgramDay,
                    object: nil,
                    userInfo: ["program_id": programId, "day_number": dayNumber]
                )
            }

        case "streak_reminder":
            NotificationCenter.default.post(name: .openDashboard, object: nil)

        default:
            break
        }
    }
}

// MARK: - Notification Categories

enum NotificationCategory: String {
    case workout = "WORKOUT"
    case event = "EVENT"
    case program = "PROGRAM"
    case streak = "STREAK"
    case announcement = "ANNOUNCEMENT"
}

// MARK: - Notification Actions

enum NotificationAction: String {
    case start = "START_ACTION"
    case snooze = "SNOOZE_ACTION"
    case dismiss = "DISMISS_ACTION"
}

// MARK: - Setup Categories

extension NotificationService {
    func setupNotificationCategories() {
        // Workout category with actions
        let startWorkoutAction = UNNotificationAction(
            identifier: NotificationAction.start.rawValue,
            title: "Start Now",
            options: [.foreground]
        )

        let snoozeAction = UNNotificationAction(
            identifier: NotificationAction.snooze.rawValue,
            title: "Remind in 15 min",
            options: []
        )

        let workoutCategory = UNNotificationCategory(
            identifier: NotificationCategory.workout.rawValue,
            actions: [startWorkoutAction, snoozeAction],
            intentIdentifiers: [],
            options: []
        )

        // Event category
        let viewEventAction = UNNotificationAction(
            identifier: NotificationAction.start.rawValue,
            title: "View Event",
            options: [.foreground]
        )

        let eventCategory = UNNotificationCategory(
            identifier: NotificationCategory.event.rawValue,
            actions: [viewEventAction],
            intentIdentifiers: [],
            options: []
        )

        // Program category
        let startProgramAction = UNNotificationAction(
            identifier: NotificationAction.start.rawValue,
            title: "Start Today's Workout",
            options: [.foreground]
        )

        let programCategory = UNNotificationCategory(
            identifier: NotificationCategory.program.rawValue,
            actions: [startProgramAction, snoozeAction],
            intentIdentifiers: [],
            options: []
        )

        // Streak category
        let quickWorkoutAction = UNNotificationAction(
            identifier: NotificationAction.start.rawValue,
            title: "Quick 5-Min Workout",
            options: [.foreground]
        )

        let streakCategory = UNNotificationCategory(
            identifier: NotificationCategory.streak.rawValue,
            actions: [quickWorkoutAction],
            intentIdentifiers: [],
            options: []
        )

        center.setNotificationCategories([
            workoutCategory,
            eventCategory,
            programCategory,
            streakCategory
        ])
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let openWorkout = Notification.Name("openWorkout")
    static let openEvent = Notification.Name("openEvent")
    static let openProgramDay = Notification.Name("openProgramDay")
    static let openDashboard = Notification.Name("openDashboard")
}
