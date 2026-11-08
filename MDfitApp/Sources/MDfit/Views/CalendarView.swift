import SwiftUI
import EventKit

// MARK: - Calendar View

struct CalendarView: View {
    @StateObject private var viewModel = CalendarViewModel()
    @State private var selectedDate = Date()
    @State private var showingAddSheet = false
    @State private var showingSyncAlert = false
    @State private var currentMonth = Date()

    private let calendar = Calendar.current
    private let daysOfWeek = ["S", "M", "T", "W", "T", "F", "S"]

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient.mdBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Calendar Header with Month Navigation
                        calendarHeader

                        // Days of Week Header
                        daysOfWeekHeader

                        // Calendar Grid
                        calendarGrid

                        // Selected Date Events
                        selectedDateSection

                        // Upcoming Events
                        upcomingEventsSection
                    }
                    .padding()
                }
            }
            .navigationTitle("Calendar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            Task { await syncToiOSCalendar() }
                        } label: {
                            Label("Sync to iOS Calendar", systemImage: "arrow.triangle.2.circlepath")
                        }

                        Button {
                            showingAddSheet = true
                        } label: {
                            Label("Add Workout", systemImage: "plus")
                        }

                        Button {
                            Task { await viewModel.requestPermissions() }
                        } label: {
                            Label("Enable Notifications", systemImage: "bell")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(.mdGold)
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddWorkoutToCalendarSheet(selectedDate: selectedDate)
            }
            .alert("Calendar Synced", isPresented: $showingSyncAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Your MD Fit workouts have been added to your iOS Calendar. You'll receive reminders for all scheduled activities.")
            }
            .onAppear {
                Task { await viewModel.requestPermissions() }
            }
        }
    }

    // MARK: - Calendar Header

    private var calendarHeader: some View {
        HStack {
            Button {
                withAnimation { previousMonth() }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.mdGold)
                    .frame(width: 44, height: 44)
            }

            Spacer()

            VStack(spacing: 2) {
                Text(monthYearString(from: currentMonth))
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)

                if !viewModel.calendarService.isAuthorized {
                    Text("Tap ••• to enable calendar sync")
                        .font(.system(size: 11))
                        .foregroundColor(.mdGold.opacity(0.8))
                }
            }

            Spacer()

            Button {
                withAnimation { nextMonth() }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.mdGold)
                    .frame(width: 44, height: 44)
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Days of Week Header

    private var daysOfWeekHeader: some View {
        HStack(spacing: 0) {
            ForEach(daysOfWeek, id: \.self) { day in
                Text(day)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white.opacity(0.6))
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 8)
    }

    // MARK: - Calendar Grid

    private var calendarGrid: some View {
        let days = generateDaysInMonth()
        let rows = days.chunked(into: 7)

        return VStack(spacing: 8) {
            ForEach(rows.indices, id: \.self) { rowIndex in
                HStack(spacing: 4) {
                    ForEach(rows[rowIndex].indices, id: \.self) { dayIndex in
                        let day = rows[rowIndex][dayIndex]
                        CalendarDayCell(
                            day: day,
                            isSelected: calendar.isDate(day.date, inSameDayAs: selectedDate),
                            isToday: calendar.isDateInToday(day.date),
                            hasWorkout: hasWorkoutOnDate(day.date),
                            hasEvent: hasEventOnDate(day.date),
                            isCurrentMonth: day.isCurrentMonth
                        ) {
                            withAnimation(.spring(response: 0.3)) {
                                selectedDate = day.date
                                viewModel.loadEvents(for: day.date)
                            }
                        }
                    }
                }
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
    }

    // MARK: - Selected Date Section

    private var selectedDateSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(selectedDateString)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)

                Spacer()

                Button {
                    showingAddSheet = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                        Text("Add")
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.mdBlueDark)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.mdGold)
                    .cornerRadius(8)
                }
            }

            if workoutsForSelectedDate.isEmpty && eventsForSelectedDate.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 40))
                        .foregroundColor(.white.opacity(0.3))

                    Text("No activities scheduled")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.5))

                    Button {
                        showingAddSheet = true
                    } label: {
                        Text("Schedule a Workout")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.mdGold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
            } else {
                VStack(spacing: 8) {
                    ForEach(workoutsForSelectedDate) { workout in
                        ScheduledWorkoutRow(workout: workout)
                    }

                    ForEach(eventsForSelectedDate) { event in
                        ScheduledEventRow(event: event)
                    }
                }
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
    }

    // MARK: - Upcoming Events Section

    private var upcomingEventsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Upcoming This Week")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)

                Spacer()

                if viewModel.calendarService.isAuthorized {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12))
                        Text("Synced")
                            .font(.system(size: 11))
                    }
                    .foregroundColor(.mdSuccess)
                }
            }

            ForEach(upcomingWorkouts) { workout in
                UpcomingWorkoutRow(workout: workout)
            }

            ForEach(Event.samples) { event in
                UpcomingEventRow(event: event)
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
    }

    // MARK: - Helpers

    private var selectedDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: selectedDate)
    }

    private func monthYearString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }

    private func previousMonth() {
        currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
    }

    private func nextMonth() {
        currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
    }

    private func generateDaysInMonth() -> [CalendarDay] {
        var days: [CalendarDay] = []

        let startOfMonth = currentMonth.startOfMonth
        let daysInMonth = currentMonth.daysInMonth

        // Get the weekday of the first day (1 = Sunday)
        let firstWeekday = calendar.component(.weekday, from: startOfMonth)

        // Add days from previous month
        let previousMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
        let daysInPreviousMonth = previousMonth.daysInMonth

        for i in (1..<firstWeekday).reversed() {
            let day = daysInPreviousMonth - i + 1
            if let date = calendar.date(byAdding: .day, value: -i, to: startOfMonth) {
                days.append(CalendarDay(date: date, day: day, isCurrentMonth: false))
            }
        }

        // Add days of current month
        for day in 1...daysInMonth {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) {
                days.append(CalendarDay(date: date, day: day, isCurrentMonth: true))
            }
        }

        // Add days from next month to fill the grid
        let remainingDays = 42 - days.count // 6 rows × 7 days
        for day in 1...remainingDays {
            if let date = calendar.date(byAdding: .day, value: daysInMonth + day - 1, to: startOfMonth) {
                days.append(CalendarDay(date: date, day: day, isCurrentMonth: false))
            }
        }

        return days
    }

    private func hasWorkoutOnDate(_ date: Date) -> Bool {
        // Check scheduled workouts
        return scheduledWorkouts.contains { calendar.isDate($0.scheduledDate ?? Date(), inSameDayAs: date) }
    }

    private func hasEventOnDate(_ date: Date) -> Bool {
        return Event.samples.contains { calendar.isDate($0.startDate, inSameDayAs: date) }
    }

    private var workoutsForSelectedDate: [ScheduledWorkout] {
        scheduledWorkouts.filter { calendar.isDate($0.scheduledDate ?? Date(), inSameDayAs: selectedDate) }
    }

    private var eventsForSelectedDate: [Event] {
        Event.samples.filter { calendar.isDate($0.startDate, inSameDayAs: selectedDate) }
    }

    private var upcomingWorkouts: [ScheduledWorkout] {
        let weekFromNow = calendar.date(byAdding: .day, value: 7, to: Date()) ?? Date()
        return scheduledWorkouts.filter {
            guard let date = $0.scheduledDate else { return false }
            return date > Date() && date < weekFromNow
        }
    }

    // Sample scheduled workouts
    private var scheduledWorkouts: [ScheduledWorkout] {
        [
            ScheduledWorkout(
                id: "sw1",
                workout: Workout.sample,
                scheduledDate: calendar.date(byAdding: .day, value: 1, to: Date()),
                reminderSet: true
            ),
            ScheduledWorkout(
                id: "sw2",
                workout: Workout.sample,
                scheduledDate: calendar.date(byAdding: .day, value: 3, to: Date()),
                reminderSet: true
            )
        ]
    }

    // MARK: - iOS Calendar Sync

    private func syncToiOSCalendar() async {
        let granted = await viewModel.calendarService.requestAccess()

        if granted {
            // Sync all scheduled workouts to iOS Calendar
            for scheduledWorkout in scheduledWorkouts {
                if let date = scheduledWorkout.scheduledDate {
                    do {
                        _ = try await viewModel.calendarService.addWorkoutToCalendar(
                            workout: scheduledWorkout.workout,
                            date: date,
                            lengthMinutes: scheduledWorkout.workout.lengthMinutes
                        )
                    } catch {
                        print("Failed to sync workout: \(error)")
                    }
                }
            }

            await MainActor.run {
                showingSyncAlert = true
            }
        }
    }
}

// MARK: - Calendar Day Model

struct CalendarDay: Identifiable {
    let id = UUID()
    let date: Date
    let day: Int
    let isCurrentMonth: Bool
}

// MARK: - Scheduled Workout Model

struct ScheduledWorkout: Identifiable {
    let id: String
    let workout: Workout
    let scheduledDate: Date?
    var reminderSet: Bool
    var calendarEventId: String?
}

// MARK: - Calendar Day Cell

struct CalendarDayCell: View {
    let day: CalendarDay
    let isSelected: Bool
    let isToday: Bool
    let hasWorkout: Bool
    let hasEvent: Bool
    let isCurrentMonth: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text("\(day.day)")
                    .font(.system(size: 16, weight: isSelected || isToday ? .bold : .regular))
                    .foregroundColor(foregroundColor)

                // Activity indicators
                HStack(spacing: 3) {
                    if hasWorkout {
                        Circle()
                            .fill(Color.mdGold)
                            .frame(width: 5, height: 5)
                    }
                    if hasEvent {
                        Circle()
                            .fill(Color.mdBlueLight)
                            .frame(width: 5, height: 5)
                    }
                }
                .frame(height: 5)
            }
            .frame(width: 40, height: 50)
            .background(backgroundColor)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isToday ? Color.mdGold : Color.clear, lineWidth: 2)
            )
        }
    }

    private var foregroundColor: Color {
        if isSelected {
            return .mdBlueDark
        } else if !isCurrentMonth {
            return .white.opacity(0.3)
        } else {
            return .white
        }
    }

    private var backgroundColor: Color {
        if isSelected {
            return .mdGold
        } else {
            return .clear
        }
    }
}

// MARK: - Scheduled Workout Row

struct ScheduledWorkoutRow: View {
    let workout: ScheduledWorkout

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.mdGold.opacity(0.2))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: "figure.mixed.cardio")
                        .foregroundColor(.mdGold)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(workout.workout.name ?? "Workout")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)

                HStack(spacing: 8) {
                    Text("\(workout.workout.lengthMinutes) min")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))

                    if workout.reminderSet {
                        HStack(spacing: 2) {
                            Image(systemName: "bell.fill")
                                .font(.system(size: 9))
                            Text("Reminder set")
                                .font(.system(size: 10))
                        }
                        .foregroundColor(.mdGold)
                    }
                }
            }

            Spacer()

            Button {
                // Start workout
            } label: {
                Text("Start")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.mdBlue)
                    .cornerRadius(6)
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}

// MARK: - Scheduled Event Row

struct ScheduledEventRow: View {
    let event: Event

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.mdBlue.opacity(0.2))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: event.type.icon)
                        .foregroundColor(.mdBlue)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(event.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)

                Text(event.formattedTimeRange)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.6))
            }

            Spacer()

            if let spots = event.spotsRemaining {
                Text("\(spots) spots")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.mdGold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.mdGold.opacity(0.1))
                    .cornerRadius(4)
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}

// MARK: - Upcoming Workout Row

struct UpcomingWorkoutRow: View {
    let workout: ScheduledWorkout

    var body: some View {
        HStack(spacing: 12) {
            VStack {
                Text(workout.scheduledDate ?? Date(), format: .dateTime.weekday(.abbreviated))
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.mdGold)
                Text(workout.scheduledDate ?? Date(), format: .dateTime.day())
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
            }
            .frame(width: 44)

            VStack(alignment: .leading, spacing: 2) {
                Text(workout.workout.name ?? "Workout")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                Text("\(workout.workout.lengthMinutes) min • \(workout.workout.difficulty.displayName)")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.6))
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.4))
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Upcoming Event Row

struct UpcomingEventRow: View {
    let event: Event

    var body: some View {
        HStack(spacing: 12) {
            VStack {
                Text(event.startDate, format: .dateTime.weekday(.abbreviated))
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.mdBlue)
                Text(event.startDate, format: .dateTime.day())
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
            }
            .frame(width: 44)

            VStack(alignment: .leading, spacing: 2) {
                Text(event.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                Text(event.formattedTimeRange)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.6))
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.4))
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Add Workout Sheet

struct AddWorkoutToCalendarSheet: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var calendarService = CalendarService.shared
    @StateObject private var notificationService = NotificationService.shared

    let selectedDate: Date
    @State private var selectedTime = Date()
    @State private var selectedWorkout: Workout = .sample
    @State private var setReminder = true
    @State private var reminderMinutes = 30
    @State private var syncToiOS = true
    @State private var isScheduling = false
    @State private var showSuccess = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.mdBlueDark.ignoresSafeArea()

                Form {
                    Section {
                        DatePicker(
                            "Date",
                            selection: .constant(selectedDate),
                            displayedComponents: .date
                        )
                        .disabled(true)

                        DatePicker(
                            "Time",
                            selection: $selectedTime,
                            displayedComponents: .hourAndMinute
                        )
                    } header: {
                        Text("Schedule")
                    }

                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(selectedWorkout.name ?? "Workout")
                                .font(.headline)
                            Text("\(selectedWorkout.lengthMinutes) min • \(selectedWorkout.difficulty.displayName)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    } header: {
                        Text("Workout")
                    }

                    Section {
                        Toggle("Set Reminder", isOn: $setReminder)

                        if setReminder {
                            Picker("Remind me", selection: $reminderMinutes) {
                                Text("15 minutes before").tag(15)
                                Text("30 minutes before").tag(30)
                                Text("1 hour before").tag(60)
                                Text("1 day before").tag(1440)
                            }
                        }
                    } header: {
                        Text("Notifications")
                    }

                    Section {
                        Toggle(isOn: $syncToiOS) {
                            HStack {
                                Image(systemName: "calendar")
                                    .foregroundColor(.mdBlue)
                                Text("Add to iOS Calendar")
                            }
                        }

                        if syncToiOS {
                            Text("This will appear in your Calendar app and sync across all your devices.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } header: {
                        Text("Calendar Sync")
                    }

                    Section {
                        Button {
                            scheduleWorkout()
                        } label: {
                            HStack {
                                Spacer()
                                if isScheduling {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text("Schedule Workout")
                                        .font(.headline)
                                }
                                Spacer()
                            }
                        }
                        .listRowBackground(Color.mdGold)
                        .foregroundColor(.mdBlueDark)
                        .disabled(isScheduling)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Add to Calendar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("Workout Scheduled!", isPresented: $showSuccess) {
                Button("Done") { dismiss() }
            } message: {
                Text("Your workout has been added to your calendar\(setReminder ? " with a reminder" : "").")
            }
        }
    }

    private func scheduleWorkout() {
        isScheduling = true

        Task {
            // Combine selected date and time
            let calendar = Calendar.current
            var components = calendar.dateComponents([.year, .month, .day], from: selectedDate)
            let timeComponents = calendar.dateComponents([.hour, .minute], from: selectedTime)
            components.hour = timeComponents.hour
            components.minute = timeComponents.minute
            let scheduledDate = calendar.date(from: components) ?? selectedDate

            // Sync to iOS Calendar
            if syncToiOS {
                _ = await calendarService.requestAccess()
                do {
                    _ = try await calendarService.addWorkoutToCalendar(
                        workout: selectedWorkout,
                        date: scheduledDate,
                        lengthMinutes: selectedWorkout.lengthMinutes
                    )
                } catch {
                    print("Calendar sync error: \(error)")
                }
            }

            // Set notification reminder
            if setReminder {
                _ = await notificationService.requestAuthorization()
                do {
                    try await notificationService.scheduleWorkoutReminder(
                        workout: selectedWorkout,
                        scheduledDate: scheduledDate,
                        reminderMinutesBefore: reminderMinutes
                    )
                } catch {
                    print("Notification error: \(error)")
                }
            }

            await MainActor.run {
                isScheduling = false
                showSuccess = true
            }
        }
    }
}

// MARK: - Event Samples Extension

extension Event {
    static let samples: [Event] = [
        sample,
        Event(
            id: "evt_002",
            title: "Lower Back Workshop",
            description: "Learn proper mechanics for a healthy lower back",
            type: .workshop,
            startDate: Calendar.current.date(byAdding: .day, value: 3, to: Date())!,
            endDate: Calendar.current.date(byAdding: .hour, value: 2, to: Calendar.current.date(byAdding: .day, value: 3, to: Date())!)!,
            location: .clinic,
            capacity: 20,
            enrolledCount: 14,
            price: 49,
            isRecurring: false,
            recurrenceRule: nil,
            requiresRegistration: true,
            registrationDeadline: nil,
            imageURL: nil,
            createdBy: "admin_001",
            createdAt: Date(),
            updatedAt: Date()
        )
    ]
}

// MARK: - Array Chunking Extension

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

// Note: DayOfWeek enum is defined in Program.swift

struct CalendarView_Previews: PreviewProvider {
    static var previews: some View {
        CalendarView()
    }
}
