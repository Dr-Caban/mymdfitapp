import Foundation
import SwiftUI

// MARK: - Streak Service

@MainActor
class StreakService: ObservableObject {
    static let shared = StreakService()

    @Published var currentStreak: Int = 0
    @Published var longestStreak: Int = 0
    @Published var totalWorkouts: Int = 0
    @Published var totalMinutes: Int = 0
    @Published var lastActiveDate: Date?
    @Published var achievements: [Achievement] = []
    @Published var weeklyActivity: [Bool] = Array(repeating: false, count: 7)

    private let defaults = UserDefaults.standard

    private init() {
        loadData()
        checkStreakStatus()
    }

    // MARK: - Record Activity

    func recordActivity(type: ActivityType, minutes: Int = 0) {
        let today = Calendar.current.startOfDay(for: Date())
        let lastActive = lastActiveDate.map { Calendar.current.startOfDay(for: $0) }

        // Update streak
        if let lastActive = lastActive {
            let daysBetween = Calendar.current.dateComponents([.day], from: lastActive, to: today).day ?? 0

            if daysBetween == 0 {
                // Already active today, just update stats
            } else if daysBetween == 1 {
                // Consecutive day - increment streak
                currentStreak += 1
            } else {
                // Streak broken - reset
                currentStreak = 1
            }
        } else {
            // First activity ever
            currentStreak = 1
        }

        // Update longest streak
        if currentStreak > longestStreak {
            longestStreak = currentStreak
        }

        // Update totals
        if type == .workout {
            totalWorkouts += 1
            totalMinutes += minutes
        }

        // Update weekly activity
        updateWeeklyActivity(for: today)

        // Update last active
        lastActiveDate = Date()

        // Check for new achievements
        checkAchievements()

        // Save
        saveData()
    }

    // MARK: - Weekly Activity

    private func updateWeeklyActivity(for date: Date) {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
        // Convert to 0-indexed starting Monday
        let index = (weekday + 5) % 7
        weeklyActivity[index] = true
    }

    func resetWeeklyActivityIfNeeded() {
        let calendar = Calendar.current
        if let lastActive = lastActiveDate {
            let lastWeek = calendar.component(.weekOfYear, from: lastActive)
            let thisWeek = calendar.component(.weekOfYear, from: Date())
            if lastWeek != thisWeek {
                weeklyActivity = Array(repeating: false, count: 7)
            }
        }
    }

    // MARK: - Streak Status

    private func checkStreakStatus() {
        guard let lastActive = lastActiveDate else { return }

        let today = Calendar.current.startOfDay(for: Date())
        let lastActiveDay = Calendar.current.startOfDay(for: lastActive)
        let daysBetween = Calendar.current.dateComponents([.day], from: lastActiveDay, to: today).day ?? 0

        if daysBetween > 1 {
            // Streak is broken
            currentStreak = 0
        }

        resetWeeklyActivityIfNeeded()
    }

    var isActiveToday: Bool {
        guard let lastActive = lastActiveDate else { return false }
        return Calendar.current.isDateInToday(lastActive)
    }

    var streakAtRisk: Bool {
        guard let lastActive = lastActiveDate else { return false }
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        return Calendar.current.isDate(lastActive, inSameDayAs: yesterday) && !isActiveToday
    }

    // MARK: - Achievements

    private func checkAchievements() {
        var newAchievements: [Achievement] = []

        // Streak achievements
        if currentStreak >= 3 && !hasAchievement(.streak3) {
            newAchievements.append(.streak3)
        }
        if currentStreak >= 7 && !hasAchievement(.streak7) {
            newAchievements.append(.streak7)
        }
        if currentStreak >= 14 && !hasAchievement(.streak14) {
            newAchievements.append(.streak14)
        }
        if currentStreak >= 30 && !hasAchievement(.streak30) {
            newAchievements.append(.streak30)
        }
        if currentStreak >= 100 && !hasAchievement(.streak100) {
            newAchievements.append(.streak100)
        }

        // Workout achievements
        if totalWorkouts >= 1 && !hasAchievement(.firstWorkout) {
            newAchievements.append(.firstWorkout)
        }
        if totalWorkouts >= 10 && !hasAchievement(.workouts10) {
            newAchievements.append(.workouts10)
        }
        if totalWorkouts >= 50 && !hasAchievement(.workouts50) {
            newAchievements.append(.workouts50)
        }
        if totalWorkouts >= 100 && !hasAchievement(.workouts100) {
            newAchievements.append(.workouts100)
        }

        // Time achievements
        if totalMinutes >= 60 && !hasAchievement(.hour1) {
            newAchievements.append(.hour1)
        }
        if totalMinutes >= 600 && !hasAchievement(.hours10) {
            newAchievements.append(.hours10)
        }
        if totalMinutes >= 3000 && !hasAchievement(.hours50) {
            newAchievements.append(.hours50)
        }

        // Perfect week
        if weeklyActivity.allSatisfy({ $0 }) && !hasAchievement(.perfectWeek) {
            newAchievements.append(.perfectWeek)
        }

        achievements.append(contentsOf: newAchievements)
    }

    private func hasAchievement(_ achievement: Achievement) -> Bool {
        achievements.contains(achievement)
    }

    // MARK: - Persistence

    private func loadData() {
        currentStreak = defaults.integer(forKey: "streak_current")
        longestStreak = defaults.integer(forKey: "streak_longest")
        totalWorkouts = defaults.integer(forKey: "streak_totalWorkouts")
        totalMinutes = defaults.integer(forKey: "streak_totalMinutes")

        if let lastActiveTimestamp = defaults.object(forKey: "streak_lastActive") as? Date {
            lastActiveDate = lastActiveTimestamp
        }

        if let achievementData = defaults.data(forKey: "streak_achievements"),
           let decoded = try? JSONDecoder().decode([Achievement].self, from: achievementData) {
            achievements = decoded
        }

        if let weeklyData = defaults.array(forKey: "streak_weekly") as? [Bool] {
            weeklyActivity = weeklyData
        }
    }

    private func saveData() {
        defaults.set(currentStreak, forKey: "streak_current")
        defaults.set(longestStreak, forKey: "streak_longest")
        defaults.set(totalWorkouts, forKey: "streak_totalWorkouts")
        defaults.set(totalMinutes, forKey: "streak_totalMinutes")
        defaults.set(lastActiveDate, forKey: "streak_lastActive")
        defaults.set(weeklyActivity, forKey: "streak_weekly")

        if let encoded = try? JSONEncoder().encode(achievements) {
            defaults.set(encoded, forKey: "streak_achievements")
        }
    }
}

// MARK: - Activity Type

enum ActivityType {
    case workout
    case video
    case painTool
    case program
}

// MARK: - Achievement

enum Achievement: String, Codable, CaseIterable {
    // Streaks
    case streak3 = "streak_3"
    case streak7 = "streak_7"
    case streak14 = "streak_14"
    case streak30 = "streak_30"
    case streak100 = "streak_100"

    // Workouts
    case firstWorkout = "first_workout"
    case workouts10 = "workouts_10"
    case workouts50 = "workouts_50"
    case workouts100 = "workouts_100"

    // Time
    case hour1 = "hour_1"
    case hours10 = "hours_10"
    case hours50 = "hours_50"

    // Special
    case perfectWeek = "perfect_week"
    case earlyBird = "early_bird"
    case nightOwl = "night_owl"
    case painWarrior = "pain_warrior"

    var title: String {
        switch self {
        case .streak3: return "Getting Started"
        case .streak7: return "Week Warrior"
        case .streak14: return "Committed"
        case .streak30: return "Monthly Master"
        case .streak100: return "Unstoppable"
        case .firstWorkout: return "First Steps"
        case .workouts10: return "Building Momentum"
        case .workouts50: return "Dedicated"
        case .workouts100: return "Century Club"
        case .hour1: return "Hour One"
        case .hours10: return "Ten Hours Strong"
        case .hours50: return "Fifty Hour Fighter"
        case .perfectWeek: return "Perfect Week"
        case .earlyBird: return "Early Bird"
        case .nightOwl: return "Night Owl"
        case .painWarrior: return "Pain Warrior"
        }
    }

    var description: String {
        switch self {
        case .streak3: return "3 day streak"
        case .streak7: return "7 day streak"
        case .streak14: return "14 day streak"
        case .streak30: return "30 day streak"
        case .streak100: return "100 day streak"
        case .firstWorkout: return "Complete your first workout"
        case .workouts10: return "Complete 10 workouts"
        case .workouts50: return "Complete 50 workouts"
        case .workouts100: return "Complete 100 workouts"
        case .hour1: return "1 hour of exercise"
        case .hours10: return "10 hours of exercise"
        case .hours50: return "50 hours of exercise"
        case .perfectWeek: return "Active every day for a week"
        case .earlyBird: return "Workout before 7am"
        case .nightOwl: return "Workout after 10pm"
        case .painWarrior: return "Complete 10 Pain Tool sessions"
        }
    }

    var icon: String {
        switch self {
        case .streak3, .streak7, .streak14, .streak30, .streak100:
            return "flame.fill"
        case .firstWorkout, .workouts10, .workouts50, .workouts100:
            return "figure.run"
        case .hour1, .hours10, .hours50:
            return "clock.fill"
        case .perfectWeek:
            return "star.fill"
        case .earlyBird:
            return "sunrise.fill"
        case .nightOwl:
            return "moon.fill"
        case .painWarrior:
            return "bolt.heart.fill"
        }
    }

    var color: Color {
        switch self {
        case .streak3: return .orange
        case .streak7: return .orange
        case .streak14: return .red
        case .streak30: return .purple
        case .streak100: return .yellow
        case .firstWorkout: return .green
        case .workouts10: return .blue
        case .workouts50: return .indigo
        case .workouts100: return .purple
        case .hour1: return .cyan
        case .hours10: return .teal
        case .hours50: return .mint
        case .perfectWeek: return .yellow
        case .earlyBird: return .orange
        case .nightOwl: return .indigo
        case .painWarrior: return .red
        }
    }
}
