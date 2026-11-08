import SwiftUI
import WidgetKit

// MARK: - Widget Provider

struct MDfitWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> MDfitWidgetEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (MDfitWidgetEntry) -> Void) {
        let entry = MDfitWidgetData.shared.loadWidgetData()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MDfitWidgetEntry>) -> Void) {
        let entry = MDfitWidgetData.shared.loadWidgetData()

        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Small Widget: Streak & XP

struct SmallStreakWidget: View {
    let entry: MDfitWidgetEntry

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [.widgetCharcoal, .widgetBlack],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 6)
                        .frame(width: 60, height: 60)

                    Circle()
                        .trim(from: 0, to: entry.isStreakAtRisk ? 0.85 : 1.0)
                        .stroke(
                            LinearGradient(
                                colors: entry.isStreakAtRisk ? [.orange, .red] : [.widgetGold, .orange],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 6, lineCap: .round)
                        )
                        .frame(width: 60, height: 60)
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: 0) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(entry.isStreakAtRisk ? .orange : .widgetGold)

                        Text("\(entry.streak)")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                }

                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.widgetGold)

                    Text("\(entry.xp) XP")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.white.opacity(0.1))
                .cornerRadius(8)

                if entry.isStreakAtRisk {
                    Text("At Risk!")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.orange)
                }
            }
            .padding()
        }
    }
}

// MARK: - Medium Widget: Today's Workout

struct MediumWorkoutWidget: View {
    let entry: MDfitWidgetEntry

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [.widgetCharcoal, .widgetBlack],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            HStack(spacing: 16) {
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.1), lineWidth: 4)
                            .frame(width: 50, height: 50)

                        VStack(spacing: 0) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.widgetGold)

                            Text("\(entry.streak)")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        }
                    }

                    Text("Streak")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.6))
                }
                .frame(width: 70)

                Divider()
                    .background(Color.white.opacity(0.2))

                VStack(alignment: .leading, spacing: 8) {
                    if let workout = entry.todayWorkout {
                        HStack {
                            Image(systemName: workout.goalIcon)
                                .font(.system(size: 14))
                                .foregroundColor(.widgetBlue)

                            Text(workout.name)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                                .lineLimit(1)

                            Spacer()

                            if workout.isCompleted {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                        }

                        HStack(spacing: 12) {
                            Label(workout.formattedDuration, systemImage: "clock")
                            Label("\(workout.exerciseCount) exercises", systemImage: "list.bullet")
                        }
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.6))
                    } else {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("No workout scheduled")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))

                            Text("Tap to generate one")
                                .font(.system(size: 11))
                                .foregroundColor(.widgetGold)
                        }
                    }

                    if let event = entry.nextEvent {
                        Divider()
                            .background(Color.white.opacity(0.1))

                        HStack {
                            Image(systemName: event.typeIcon)
                                .font(.system(size: 12))
                                .foregroundColor(.widgetBlue)

                            Text(event.title)
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.8))

                            Spacer()

                            Text(event.formattedTime)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.widgetGold)
                        }
                    }
                }

                Spacer()
            }
            .padding()
        }
    }
}

// MARK: - Large Widget: Week Calendar

struct LargeCalendarWidget: View {
    let entry: MDfitWidgetEntry
    private let weekdays = ["M", "T", "W", "T", "F", "S", "S"]

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [.widgetCharcoal, .widgetBlack],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("This Week")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)

                        Text(weekRangeString)
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.6))
                    }

                    Spacer()

                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.widgetGold)

                        Text("\(entry.streak)")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                }

                HStack(spacing: 8) {
                    ForEach(0..<7, id: \.self) { index in
                        VStack(spacing: 4) {
                            Text(weekdays[index])
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.white.opacity(0.5))

                            ZStack {
                                Circle()
                                    .fill(dayBackgroundColor(for: index))
                                    .frame(width: 32, height: 32)

                                if entry.weekWorkouts[index] {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.white)
                                } else {
                                    Text(dayNumber(for: index))
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.white.opacity(0.6))
                                }
                            }
                        }
                    }
                }

                Divider()
                    .background(Color.white.opacity(0.1))

                if let workout = entry.todayWorkout {
                    HStack(spacing: 12) {
                        Image(systemName: workout.goalIcon)
                            .font(.system(size: 20))
                            .foregroundColor(.widgetBlue)
                            .frame(width: 40, height: 40)
                            .background(Color.widgetBlue.opacity(0.15))
                            .cornerRadius(8)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(workout.name)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)

                            HStack(spacing: 8) {
                                Label(workout.formattedDuration, systemImage: "clock")
                                Label("\(workout.exerciseCount) ex", systemImage: "list.bullet")
                            }
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.6))
                        }

                        Spacer()

                        if workout.isCompleted {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.green)
                        } else {
                            Image(systemName: "play.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.widgetGold)
                        }
                    }
                    .padding(10)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(10)
                }

                if let event = entry.nextEvent {
                    HStack(spacing: 10) {
                        Image(systemName: event.typeIcon)
                            .font(.system(size: 16))
                            .foregroundColor(.widgetBlue)
                            .frame(width: 32, height: 32)
                            .background(Color.widgetBlue.opacity(0.15))
                            .cornerRadius(6)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(event.title)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)

                            if let location = event.location {
                                Text(location)
                                    .font(.system(size: 10))
                                    .foregroundColor(.white.opacity(0.5))
                            }
                        }

                        Spacer()

                        Text(event.formattedTime)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.widgetGold)
                    }
                    .padding(8)
                    .background(Color.white.opacity(0.03))
                    .cornerRadius(8)
                }

                Spacer()
            }
            .padding()
        }
    }

    private var weekRangeString: String {
        let calendar = Calendar.current
        let today = Date()
        guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)),
              let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart) else {
            return ""
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "\(formatter.string(from: weekStart)) - \(formatter.string(from: weekEnd))"
    }

    private func dayBackgroundColor(for index: Int) -> Color {
        if entry.weekWorkouts[index] {
            return isToday(index) ? .widgetGold : .green.opacity(0.7)
        }
        return .white.opacity(0.08)
    }

    private func isToday(_ index: Int) -> Bool {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: Date())
        let todayIndex = (weekday + 5) % 7
        return index == todayIndex
    }

    private func dayNumber(for index: Int) -> String {
        let calendar = Calendar.current
        guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())),
              let date = calendar.date(byAdding: .day, value: index, to: weekStart) else {
            return ""
        }
        return "\(calendar.component(.day, from: date))"
    }
}

// MARK: - Lock Screen Widget

struct LockScreenStreakWidget: View {
    let entry: MDfitWidgetEntry

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()

            VStack(spacing: 2) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 18))
                    .foregroundColor(entry.isStreakAtRisk ? .orange : .widgetGold)

                Text("\(entry.streak)")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
        }
    }
}

// MARK: - Widget Configurations

struct MDfitSmallWidget: Widget {
    let kind: String = "MDfitSmallWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MDfitWidgetProvider()) { entry in
            SmallStreakWidget(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Streak & XP")
        .description("Track your current streak and XP.")
        .supportedFamilies([.systemSmall])
    }
}

struct MDfitMediumWidget: Widget {
    let kind: String = "MDfitMediumWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MDfitWidgetProvider()) { entry in
            MediumWorkoutWidget(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Today's Workout")
        .description("View today's workout and upcoming events.")
        .supportedFamilies([.systemMedium])
    }
}

struct MDfitLargeWidget: Widget {
    let kind: String = "MDfitLargeWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MDfitWidgetProvider()) { entry in
            LargeCalendarWidget(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Week Calendar")
        .description("See your workout schedule for the week.")
        .supportedFamilies([.systemLarge])
    }
}

struct MDfitLockScreenWidget: Widget {
    let kind: String = "MDfitLockScreenWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MDfitWidgetProvider()) { entry in
            LockScreenStreakWidget(entry: entry)
        }
        .configurationDisplayName("Streak")
        .description("Quick view of your streak.")
        .supportedFamilies([.accessoryCircular])
    }
}
