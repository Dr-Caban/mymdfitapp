import Foundation

#if os(iOS)
import SwiftUI
import WidgetKit
import ActivityKit

// MARK: - Widget Colors

enum MDWidgetColors {
    static let gold = Color(red: 0.831, green: 0.659, blue: 0.294)
    static let blue = Color(red: 0.0, green: 0.322, blue: 0.647)
    static let charcoal = Color(red: 0.11, green: 0.11, blue: 0.13)
    static let black = Color(red: 0.067, green: 0.067, blue: 0.09)
}

extension Color {
    static let widgetGold = MDWidgetColors.gold
    static let widgetBlue = MDWidgetColors.blue
    static let widgetCharcoal = MDWidgetColors.charcoal
    static let widgetBlack = MDWidgetColors.black
}

// MARK: - Widget Entry

struct MDfitWidgetEntry: TimelineEntry {
    let date: Date
    let streak: Int
    let isStreakAtRisk: Bool
    let xp: Int
    let level: Int
    let rank: String
    let todayWorkout: WidgetWorkout?
    let nextEvent: WidgetEvent?
    let weekWorkouts: [Bool]

    static var placeholder: MDfitWidgetEntry {
        MDfitWidgetEntry(
            date: Date(),
            streak: 12,
            isStreakAtRisk: false,
            xp: 2450,
            level: 7,
            rank: "Silver",
            todayWorkout: WidgetWorkout(
                id: "sample",
                name: "Upper Body Strength",
                goalType: "upperBody",
                duration: 45,
                exerciseCount: 8,
                isCompleted: false
            ),
            nextEvent: WidgetEvent(
                id: "event1",
                title: "Mobility Class",
                startTime: Date().addingTimeInterval(3600),
                type: "class",
                location: "Main Studio"
            ),
            weekWorkouts: [true, true, false, true, false, false, false]
        )
    }

    static var atRisk: MDfitWidgetEntry {
        MDfitWidgetEntry(
            date: Date(),
            streak: 30,
            isStreakAtRisk: true,
            xp: 5200,
            level: 12,
            rank: "Gold",
            todayWorkout: nil,
            nextEvent: nil,
            weekWorkouts: [true, true, true, true, true, true, false]
        )
    }
}

// MARK: - Widget Workout Model

struct WidgetWorkout: Codable {
    let id: String
    let name: String
    let goalType: String
    let duration: Int
    let exerciseCount: Int
    let isCompleted: Bool

    var formattedDuration: String {
        "\(duration) min"
    }

    var goalIcon: String {
        switch goalType.lowercased() {
        case "upperbody", "upper body":
            return "figure.arms.open"
        case "lowerbody", "lower body":
            return "figure.run"
        case "fullbody", "full body":
            return "figure.mixed.cardio"
        case "cardio":
            return "heart.fill"
        default:
            return "dumbbell.fill"
        }
    }
}

// MARK: - Widget Event Model

struct WidgetEvent: Codable {
    let id: String
    let title: String
    let startTime: Date
    let type: String
    let location: String?

    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: startTime)
    }

    var typeIcon: String {
        switch type.lowercased() {
        case "class":
            return "person.3.fill"
        case "appointment":
            return "calendar.badge.clock"
        case "workshop":
            return "graduationcap.fill"
        default:
            return "calendar"
        }
    }
}

// MARK: - Live Activity Attributes

struct WorkoutActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var currentExerciseName: String
        var currentExerciseIndex: Int
        var totalExercises: Int
        var currentSet: Int
        var totalSets: Int
        var repsRemaining: Int?
        var timerSeconds: Int?
        var isResting: Bool
        var restSecondsRemaining: Int?
        var elapsedSeconds: Int
        var caloriesBurned: Int

        var exerciseProgress: String {
            "\(currentExerciseIndex)/\(totalExercises)"
        }

        var setProgress: String {
            "Set \(currentSet)/\(totalSets)"
        }

        var progress: Double {
            guard totalExercises > 0 else { return 0 }
            return Double(currentExerciseIndex - 1) / Double(totalExercises)
        }

        var formattedTime: String {
            let minutes = elapsedSeconds / 60
            let seconds = elapsedSeconds % 60
            return String(format: "%02d:%02d", minutes, seconds)
        }

        static var preview: ContentState {
            ContentState(
                currentExerciseName: "Bench Press",
                currentExerciseIndex: 3,
                totalExercises: 8,
                currentSet: 2,
                totalSets: 4,
                repsRemaining: 10,
                timerSeconds: nil,
                isResting: false,
                restSecondsRemaining: nil,
                elapsedSeconds: 754,
                caloriesBurned: 145
            )
        }

        static var resting: ContentState {
            ContentState(
                currentExerciseName: "Bench Press",
                currentExerciseIndex: 3,
                totalExercises: 8,
                currentSet: 2,
                totalSets: 4,
                repsRemaining: nil,
                timerSeconds: nil,
                isResting: true,
                restSecondsRemaining: 45,
                elapsedSeconds: 780,
                caloriesBurned: 150
            )
        }
    }

    var workoutId: String
    var workoutName: String
    var goalType: String
    var startTime: Date
    var estimatedDurationMinutes: Int

    static var preview: WorkoutActivityAttributes {
        WorkoutActivityAttributes(
            workoutId: "workout123",
            workoutName: "Upper Body Strength",
            goalType: "upperBody",
            startTime: Date(),
            estimatedDurationMinutes: 45
        )
    }
}

// MARK: - Widget Data Sharing

@MainActor
final class MDfitWidgetData: ObservableObject {
    static let shared = MDfitWidgetData()

    private let suiteName = "group.com.mdfit.app"
    private let defaults: UserDefaults?

    private init() {
        defaults = UserDefaults(suiteName: suiteName)
    }

    func saveWidgetData(
        streak: Int,
        isStreakAtRisk: Bool,
        xp: Int,
        level: Int,
        rank: String,
        todayWorkout: WidgetWorkout?,
        nextEvent: WidgetEvent?,
        weekWorkouts: [Bool]
    ) {
        defaults?.set(streak, forKey: "widget_streak")
        defaults?.set(isStreakAtRisk, forKey: "widget_streak_at_risk")
        defaults?.set(xp, forKey: "widget_xp")
        defaults?.set(level, forKey: "widget_level")
        defaults?.set(rank, forKey: "widget_rank")

        if let workout = todayWorkout,
           let data = try? JSONEncoder().encode(workout) {
            defaults?.set(data, forKey: "widget_today_workout")
        } else {
            defaults?.removeObject(forKey: "widget_today_workout")
        }

        if let event = nextEvent,
           let data = try? JSONEncoder().encode(event) {
            defaults?.set(data, forKey: "widget_next_event")
        } else {
            defaults?.removeObject(forKey: "widget_next_event")
        }

        defaults?.set(weekWorkouts, forKey: "widget_week_workouts")

        WidgetCenter.shared.reloadAllTimelines()
    }

    func loadWidgetData() -> MDfitWidgetEntry {
        let streak = defaults?.integer(forKey: "widget_streak") ?? 0
        let isStreakAtRisk = defaults?.bool(forKey: "widget_streak_at_risk") ?? false
        let xp = defaults?.integer(forKey: "widget_xp") ?? 0
        let level = defaults?.integer(forKey: "widget_level") ?? 1
        let rank = defaults?.string(forKey: "widget_rank") ?? "Bronze"

        var todayWorkout: WidgetWorkout?
        if let data = defaults?.data(forKey: "widget_today_workout") {
            todayWorkout = try? JSONDecoder().decode(WidgetWorkout.self, from: data)
        }

        var nextEvent: WidgetEvent?
        if let data = defaults?.data(forKey: "widget_next_event") {
            nextEvent = try? JSONDecoder().decode(WidgetEvent.self, from: data)
        }

        let weekWorkouts = defaults?.array(forKey: "widget_week_workouts") as? [Bool] ?? Array(repeating: false, count: 7)

        return MDfitWidgetEntry(
            date: Date(),
            streak: streak,
            isStreakAtRisk: isStreakAtRisk,
            xp: xp,
            level: level,
            rank: rank,
            todayWorkout: todayWorkout,
            nextEvent: nextEvent,
            weekWorkouts: weekWorkouts
        )
    }
}

#endif // os(iOS)
