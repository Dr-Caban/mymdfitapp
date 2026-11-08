import Foundation
import EventKit
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Calendar Service

@MainActor
final class CalendarService: ObservableObject {
    static let shared = CalendarService()

    private let eventStore = EKEventStore()

    @Published private(set) var isAuthorized = false
    @Published private(set) var calendars: [EKCalendar] = []
    @Published private(set) var mdFitCalendar: EKCalendar?

    private let calendarTitle = "MD Fit"

    private init() {
        checkAuthorizationStatus()
    }

    // MARK: - Authorization

    func requestAccess() async -> Bool {
        // iOS 16 compatible: use requestAccess(to:) with completion handler
        return await withCheckedContinuation { continuation in
            eventStore.requestAccess(to: .event) { [weak self] granted, error in
                if let error = error {
                    print("Calendar access error: \(error)")
                }

                Task { @MainActor in
                    self?.isAuthorized = granted
                    if granted {
                        await self?.setupCalendars()
                    }
                    continuation.resume(returning: granted)
                }
            }
        }
    }

    func checkAuthorizationStatus() {
        let status = EKEventStore.authorizationStatus(for: .event)
        // iOS 16: .authorized is the correct status
        isAuthorized = status == .authorized
    }

    private func setupCalendars() async {
        await loadCalendars()
        await findOrCreateMDFitCalendar()
    }

    private func loadCalendars() async {
        let cals = eventStore.calendars(for: .event)
        await MainActor.run {
            calendars = cals
        }
    }

    // MARK: - MD Fit Calendar

    private func findOrCreateMDFitCalendar() async {
        // Try to find existing MD Fit calendar
        if let existing = calendars.first(where: { $0.title == calendarTitle }) {
            await MainActor.run {
                mdFitCalendar = existing
            }
            return
        }

        // Create new calendar
        let calendar = EKCalendar(for: .event, eventStore: eventStore)
        calendar.title = calendarTitle
        #if canImport(UIKit)
        calendar.cgColor = UIColor(Color.mdBlue).cgColor
        #endif

        // Use default local calendar source
        if let source = eventStore.sources.first(where: { $0.sourceType == .local }) {
            calendar.source = source
        } else if let source = eventStore.defaultCalendarForNewEvents?.source {
            calendar.source = source
        }

        do {
            try eventStore.saveCalendar(calendar, commit: true)
            await MainActor.run {
                mdFitCalendar = calendar
            }
        } catch {
            print("Failed to create MD Fit calendar: \(error)")
        }
    }

    // MARK: - Add Events

    /// Add a workout to the calendar
    func addWorkoutToCalendar(
        workout: Workout,
        date: Date,
        lengthMinutes: Int
    ) async throws -> String {
        guard isAuthorized else {
            throw CalendarError.notAuthorized
        }

        guard let calendar = mdFitCalendar else {
            throw CalendarError.noCalendar
        }

        let event = EKEvent(eventStore: eventStore)
        event.title = "🏋️ \(workout.name ?? "Workout")"
        event.startDate = date
        event.endDate = Calendar.current.date(
            byAdding: .minute,
            value: lengthMinutes,
            to: date
        )
        event.calendar = calendar
        event.notes = buildWorkoutNotes(workout)

        // Add workout reminder
        let alarm = EKAlarm(relativeOffset: -30 * 60) // 30 minutes before
        event.addAlarm(alarm)

        // Custom data
        event.url = URL(string: "mdfit://workout/\(workout.id)")

        try eventStore.save(event, span: .thisEvent)

        return event.eventIdentifier
    }

    /// Add an MD Fit event to the calendar
    func addEventToCalendar(event: Event) async throws -> String {
        guard isAuthorized else {
            throw CalendarError.notAuthorized
        }

        guard let calendar = mdFitCalendar else {
            throw CalendarError.noCalendar
        }

        let ekEvent = EKEvent(eventStore: eventStore)
        ekEvent.title = "📅 \(event.title)"
        ekEvent.startDate = event.startDate
        ekEvent.endDate = event.endDate
        ekEvent.calendar = calendar
        ekEvent.notes = event.description
        ekEvent.location = event.location.address ?? event.location.name

        // Add reminder based on event type
        let reminderOffset: TimeInterval
        switch event.type {
        case .groupClass, .workshop:
            reminderOffset = -60 * 60 // 1 hour
        case .oneOnOne:
            reminderOffset = -24 * 60 * 60 // 1 day
        default:
            reminderOffset = -30 * 60 // 30 minutes
        }

        let alarm = EKAlarm(relativeOffset: reminderOffset)
        ekEvent.addAlarm(alarm)

        ekEvent.url = URL(string: "mdfit://event/\(event.id)")

        try eventStore.save(ekEvent, span: .thisEvent)

        return ekEvent.eventIdentifier
    }

    /// Add a program workout day to the calendar
    func addProgramDayToCalendar(
        program: Program,
        week: Int,
        day: Int,
        date: Date,
        durationMinutes: Int = 45
    ) async throws -> String {
        guard isAuthorized else {
            throw CalendarError.notAuthorized
        }

        guard let calendar = mdFitCalendar else {
            throw CalendarError.noCalendar
        }

        let event = EKEvent(eventStore: eventStore)
        event.title = "💪 \(program.name) - Week \(week), Day \(day)"
        event.startDate = date
        event.endDate = Calendar.current.date(
            byAdding: .minute,
            value: durationMinutes,
            to: date
        )
        event.calendar = calendar
        event.notes = "Program: \(program.name)\nWeek \(week) of \(program.durationWeeks)"

        let alarm = EKAlarm(relativeOffset: -30 * 60)
        event.addAlarm(alarm)

        event.url = URL(string: "mdfit://program/\(program.id)/week/\(week)/day/\(day)")

        try eventStore.save(event, span: .thisEvent)

        return event.eventIdentifier
    }

    // MARK: - Remove Events

    func removeEvent(identifier: String) throws {
        guard let event = eventStore.event(withIdentifier: identifier) else {
            throw CalendarError.eventNotFound
        }

        try eventStore.remove(event, span: .thisEvent)
    }

    func removeAllMDFitEvents() throws {
        guard let calendar = mdFitCalendar else { return }

        let predicate = eventStore.predicateForEvents(
            withStart: Date.distantPast,
            end: Date.distantFuture,
            calendars: [calendar]
        )

        let events = eventStore.events(matching: predicate)
        for event in events {
            try eventStore.remove(event, span: .thisEvent)
        }
    }

    // MARK: - Fetch Events

    func fetchMDFitEvents(from startDate: Date, to endDate: Date) -> [EKEvent] {
        guard let calendar = mdFitCalendar else { return [] }

        let predicate = eventStore.predicateForEvents(
            withStart: startDate,
            end: endDate,
            calendars: [calendar]
        )

        return eventStore.events(matching: predicate)
    }

    func fetchAllEvents(from startDate: Date, to endDate: Date) -> [EKEvent] {
        let predicate = eventStore.predicateForEvents(
            withStart: startDate,
            end: endDate,
            calendars: nil
        )

        return eventStore.events(matching: predicate)
    }

    // MARK: - Schedule Program

    /// Schedule an entire program starting from a date
    func scheduleProgram(
        program: Program,
        startDate: Date,
        preferredTime: Date,
        daysPerWeek: [Int] // 1 = Sunday, 7 = Saturday
    ) async throws -> [String] {
        var eventIdentifiers: [String] = []

        let timeComponents = Calendar.current.dateComponents([.hour, .minute], from: preferredTime)

        var currentDate = startDate
        var currentWeek = 1
        var currentDay = 1

        let totalDays = program.durationWeeks * (daysPerWeek.count)

        while currentDay <= totalDays {
            // Check if current weekday is in preferred days
            let weekday = Calendar.current.component(.weekday, from: currentDate)

            if daysPerWeek.contains(weekday) {
                // Set the preferred time
                var dateComponents = Calendar.current.dateComponents(
                    [.year, .month, .day],
                    from: currentDate
                )
                dateComponents.hour = timeComponents.hour
                dateComponents.minute = timeComponents.minute

                if let scheduledDate = Calendar.current.date(from: dateComponents) {
                    let weekNumber = ((currentDay - 1) / daysPerWeek.count) + 1
                    let dayInWeek = ((currentDay - 1) % daysPerWeek.count) + 1

                    let identifier = try await addProgramDayToCalendar(
                        program: program,
                        week: weekNumber,
                        day: dayInWeek,
                        date: scheduledDate
                    )

                    eventIdentifiers.append(identifier)
                }

                currentDay += 1
            }

            // Move to next day
            currentDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }

        return eventIdentifiers
    }

    // MARK: - Helpers

    private func buildWorkoutNotes(_ workout: Workout) -> String {
        var notes = "MD Fit Workout\n\n"
        notes += "Goal: \(workout.goalType.displayName)\n"
        notes += "Location: \(workout.location.displayName)\n"
        notes += "Duration: \(workout.lengthMinutes) minutes\n"
        notes += "Difficulty: \(workout.difficulty.displayName)\n\n"

        if !workout.exercises.isEmpty {
            notes += "Exercises:\n"
            for (index, workoutExercise) in workout.exercises.enumerated() {
                // In real app, would lookup exercise name from ID
                notes += "  \(index + 1). Exercise ID: \(workoutExercise.exerciseId)\n"
            }
        }

        return notes
    }
}

// MARK: - Calendar Errors

enum CalendarError: LocalizedError {
    case notAuthorized
    case noCalendar
    case eventNotFound
    case saveFailed

    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Calendar access not authorized. Please enable in Settings."
        case .noCalendar:
            return "MD Fit calendar not found."
        case .eventNotFound:
            return "Calendar event not found."
        case .saveFailed:
            return "Failed to save calendar event."
        }
    }
}

// MARK: - Calendar View Model

@MainActor
final class CalendarViewModel: ObservableObject {
    let calendarService = CalendarService.shared
    let notificationService = NotificationService.shared

    @Published var selectedDate = Date()
    @Published var eventsForSelectedDate: [EKEvent] = []
    @Published var isLoading = false

    func requestPermissions() async {
        _ = await calendarService.requestAccess()
        _ = await notificationService.requestAuthorization()
    }

    func loadEvents(for date: Date) {
        isLoading = true

        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay) ?? date

        eventsForSelectedDate = calendarService.fetchMDFitEvents(from: startOfDay, to: endOfDay)

        isLoading = false
    }

    func scheduleWorkout(_ workout: Workout, at date: Date) async throws {
        // Add to calendar
        _ = try await calendarService.addWorkoutToCalendar(
            workout: workout,
            date: date,
            lengthMinutes: workout.lengthMinutes
        )

        // Schedule notification
        try await notificationService.scheduleWorkoutReminder(
            workout: workout,
            scheduledDate: date
        )

        // Refresh events
        loadEvents(for: selectedDate)
    }
}

// MARK: - Calendar Date Extension

extension Date {
    var startOfMonth: Date {
        Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: self)) ?? self
    }

    var endOfMonth: Date {
        Calendar.current.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth) ?? self
    }

    var daysInMonth: Int {
        Calendar.current.range(of: .day, in: .month, for: self)?.count ?? 30
    }
}
