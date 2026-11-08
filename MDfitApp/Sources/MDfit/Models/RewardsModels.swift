import Foundation
import SwiftUI

// MARK: - XP System (Duolingo-style gamification)

/// XP is never stored - it's recomputed from facts (workouts, pain logs, activities, etc.)
/// This ensures progress can't be gamed by editing a counter

// MARK: - Gem Ladder (8 tiers)

enum GemTier: Int, CaseIterable, Codable {
    case peridot = 1
    case garnet = 2
    case onyx = 3
    case emerald = 4  // Olympic League starts here
    case ruby = 5
    case sapphire = 6
    case diamond = 7
    case platinum = 8

    var displayName: String {
        switch self {
        case .peridot: return "Peridot"
        case .garnet: return "Garnet"
        case .onyx: return "Onyx"
        case .emerald: return "Emerald"
        case .ruby: return "Ruby"
        case .sapphire: return "Sapphire"
        case .diamond: return "Diamond"
        case .platinum: return "Platinum"
        }
    }

    var color: Color {
        switch self {
        case .peridot: return Color(hex: "9ac85a")
        case .garnet: return Color(hex: "c13a5c")
        case .onyx: return Color(hex: "1a1a1a")
        case .emerald: return Color(hex: "2fa06a")
        case .ruby: return Color(hex: "d8213c")
        case .sapphire: return Color(hex: "1d49a8")
        case .diamond: return Color(hex: "c6edff")
        case .platinum: return Color(hex: "e5e5e5")
        }
    }

    var xpThreshold: Int {
        switch self {
        case .peridot: return 0
        case .garnet: return 51
        case .onyx: return 501
        case .emerald: return 2501    // Olympic League opens here
        case .ruby: return 7501
        case .sapphire: return 15001
        case .diamond: return 30001
        case .platinum: return 60001
        }
    }

    var mohsHardness: Double {
        switch self {
        case .peridot: return 6.5
        case .garnet: return 7.0
        case .onyx: return 7.0
        case .emerald: return 7.75
        case .ruby: return 9.0
        case .sapphire: return 9.0
        case .diamond: return 10.0
        case .platinum: return 0
        }
    }

    var icon: String {
        "diamond.fill"
    }

    var nextTier: GemTier? {
        GemTier(rawValue: self.rawValue + 1)
    }

    static func from(xp: Int) -> GemTier {
        for tier in GemTier.allCases.reversed() {
            if xp >= tier.xpThreshold {
                return tier
            }
        }
        return .peridot
    }
}

// MARK: - League System

enum League: String, CaseIterable, Codable {
    case pro
    case olympic

    var displayName: String {
        switch self {
        case .pro: return "Pro League"
        case .olympic: return "Olympic League"
        }
    }

    var icon: String {
        switch self {
        case .pro: return "star.fill"
        case .olympic: return "crown.fill"
        }
    }

    var color: Color {
        switch self {
        case .pro: return .mdGold
        case .olympic: return Color(hex: "2fa06a") // Emerald
        }
    }

    /// League is determined by lifetime XP (2,501 = Emerald = Olympic)
    static func from(xp: Int) -> League {
        xp >= GemTier.emerald.xpThreshold ? .olympic : .pro
    }
}

// MARK: - Badges (14 total)

enum Badge: String, CaseIterable, Codable {
    case firstWorkout = "first-workout"      // Complete 1 workout
    case workouts10 = "workouts-10"          // Complete 10 workouts
    case workouts50 = "workouts-50"          // Complete 50 workouts
    case workouts100 = "workouts-100"        // Complete 100 workouts
    case streak3 = "streak-3"                // 3 consecutive workout days
    case streak7 = "streak-7"                // 7 consecutive workout days
    case streak30 = "streak-30"              // 30 consecutive workout days
    case week3 = "week-3"                    // 3 workouts Mon-Sun
    case hours10 = "hours-10"                // 600 minutes total
    case explorer = "explorer"               // All 5 generator goals
    case checkin7 = "checkin-7"              // 7 check-ins
    case pain5 = "pain-5"                    // 5 pain log entries
    case painDown = "pain-down"              // Any area drops ≥3 points
    case firstVisit = "first-visit"          // First completed visit

    var displayName: String {
        switch self {
        case .firstWorkout: return "First Steps"
        case .workouts10: return "Getting Started"
        case .workouts50: return "Dedicated"
        case .workouts100: return "Centurion"
        case .streak3: return "Three Day Streak"
        case .streak7: return "Week Warrior"
        case .streak30: return "Monthly Master"
        case .week3: return "Weekly Warrior"
        case .hours10: return "10 Hour Club"
        case .explorer: return "Explorer"
        case .checkin7: return "Consistent"
        case .pain5: return "Pain Logger"
        case .painDown: return "Feeling Better"
        case .firstVisit: return "In Person"
        }
    }

    var description: String {
        switch self {
        case .firstWorkout: return "Complete your first workout"
        case .workouts10: return "Complete 10 workouts"
        case .workouts50: return "Complete 50 workouts"
        case .workouts100: return "Complete 100 workouts"
        case .streak3: return "Work out 3 days in a row"
        case .streak7: return "Work out 7 days in a row"
        case .streak30: return "Work out 30 days in a row"
        case .week3: return "Complete 3 workouts in one week"
        case .hours10: return "Log 10 hours of exercise"
        case .explorer: return "Try all 5 generator goals"
        case .checkin7: return "Check in 7 times"
        case .pain5: return "Log pain 5 times"
        case .painDown: return "See pain improve by 3+ points"
        case .firstVisit: return "Complete your first in-person visit"
        }
    }

    var icon: String {
        switch self {
        case .firstWorkout: return "figure.walk"
        case .workouts10, .workouts50, .workouts100: return "flame.fill"
        case .streak3, .streak7, .streak30: return "bolt.fill"
        case .week3: return "calendar"
        case .hours10: return "clock.fill"
        case .explorer: return "map.fill"
        case .checkin7: return "checkmark.circle.fill"
        case .pain5: return "heart.text.square.fill"
        case .painDown: return "arrow.down.heart.fill"
        case .firstVisit: return "building.2.fill"
        }
    }

    var target: Int {
        switch self {
        case .firstWorkout: return 1
        case .workouts10: return 10
        case .workouts50: return 50
        case .workouts100: return 100
        case .streak3: return 3
        case .streak7: return 7
        case .streak30: return 30
        case .week3: return 3
        case .hours10: return 600  // minutes
        case .explorer: return 5   // goals
        case .checkin7: return 7
        case .pain5: return 5
        case .painDown: return 3   // point drop
        case .firstVisit: return 1
        }
    }

    /// Each badge earns +25 XP when unlocked
    static let xpReward = 25
}

// MARK: - XP Constants

struct XPConstants {
    // Workout XP (only best per day counts)
    static let workoutNormal = 30      // Generated workout
    static let workoutCustom = 35      // Built workout
    static let workoutChallenge = 30   // Challenge workout
    static let workoutProgram = 50     // Program/pain track/protocol

    // Challenge XP
    static let challengeDone = 10      // Completing a challenge
    static let challengeSent = 5       // Sending first challenge of day

    // Pain log XP (first 3 per day)
    static let painLog = 5
    static let painLogDailyCap = 3

    // Visit XP
    static let visitCompleted = 50

    // Badge XP
    static let badgeEarned = 25

    // Check-in XP (vitals: weight, sleep, HR, etc.)
    static let checkin = 5
    static let checkinDailyCap = 2

    // Booking XP
    static let booking = 15
    static let bookingDailyCap = 2

    // Daily goal levels
    static let goalBeginner = 50
    static let goalIntermediate = 75
    static let goalPro = 100
}

// MARK: - App Actions (XP per action with daily caps)

struct AppAction: Identifiable, Codable {
    let id: String
    let xp: Int
    let dailyCap: Int

    static let video = AppAction(id: "video", xp: 2, dailyCap: 10)
    static let lecture = AppAction(id: "lecture", xp: 10, dailyCap: 3)
    static let message = AppAction(id: "message", xp: 3, dailyCap: 3)
    static let reaction = AppAction(id: "reaction", xp: 1, dailyCap: 3)
    static let favorite = AppAction(id: "favorite", xp: 2, dailyCap: 5)
    static let program = AppAction(id: "program", xp: 5, dailyCap: 3)
    static let generate = AppAction(id: "generate", xp: 2, dailyCap: 3)
    static let share = AppAction(id: "share", xp: 5, dailyCap: 1)
    static let profile = AppAction(id: "profile", xp: 5, dailyCap: 1)
    static let bookingAction = AppAction(id: "booking", xp: 15, dailyCap: 2)

    static let all: [AppAction] = [
        .video, .lecture, .message, .reaction, .favorite,
        .program, .generate, .share, .profile, .bookingAction
    ]
}

// MARK: - Daily Activities (18 default)

struct DailyActivity: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let description: String
    let xp: Int
    let icon: String
    let isAuto: Bool  // Auto activities can't be manually checked

    static let sunlight = DailyActivity(id: "sunlight", name: "Sunlight", description: "20 minutes outside in daylight.", xp: 15, icon: "sun.max.fill", isAuto: false)
    static let walk = DailyActivity(id: "walk", name: "Walk", description: "A 10+ minute walk.", xp: 15, icon: "figure.walk", isAuto: false)
    static let acupressureMat = DailyActivity(id: "acupressure", name: "Acupressure mat", description: "10 to 20 minutes lying or standing on the mat.", xp: 15, icon: "bed.double.fill", isAuto: false)
    static let sauna = DailyActivity(id: "sauna", name: "Sauna", description: "15 to 20 minutes in a sauna or steam room.", xp: 15, icon: "flame.fill", isAuto: false)
    static let foamRolling = DailyActivity(id: "foam_rolling", name: "Foam rolling", description: "10 minutes rolling the areas that feel tight.", xp: 15, icon: "cylinder.fill", isAuto: false)
    static let stretching = DailyActivity(id: "stretching", name: "Stretching", description: "5 to 10 minutes of gentle stretching.", xp: 5, icon: "figure.cooldown", isAuto: false)
    static let iceBath = DailyActivity(id: "ice_bath", name: "Ice bath", description: "Cold plunge or ice bath, 2 to 5 minutes. Never alone; skip it if your doctor said to avoid cold.", xp: 20, icon: "snowflake", isAuto: false)
    static let yoga = DailyActivity(id: "yoga", name: "Yoga", description: "20+ minutes of yoga practice.", xp: 20, icon: "figure.mind.and.body", isAuto: false)
    static let healthShot = DailyActivity(id: "health_shot", name: "Health shot", description: "Your daily wellness shot (ginger, turmeric, greens).", xp: 5, icon: "cup.and.saucer.fill", isAuto: false)
    static let noScreens = DailyActivity(id: "no_screens", name: "No screens after 9 PM", description: "Put devices away after 9 PM for better sleep.", xp: 15, icon: "moon.fill", isAuto: false)
    static let prayer = DailyActivity(id: "prayer", name: "Prayer", description: "A few quiet minutes of prayer.", xp: 10, icon: "hands.sparkles.fill", isAuto: false)
    static let massage = DailyActivity(id: "massage", name: "Massage", description: "Professional massage or self-massage with tools.", xp: 20, icon: "hand.raised.fill", isAuto: false)
    static let meditation = DailyActivity(id: "meditation", name: "Meditation", description: "10 minutes of meditation.", xp: 10, icon: "brain.head.profile", isAuto: false)
    static let journaling = DailyActivity(id: "journaling", name: "Journaling", description: "Write in your journal for a few minutes.", xp: 5, icon: "book.fill", isAuto: false)
    static let grounding = DailyActivity(id: "grounding", name: "Grounding", description: "Bare feet on grass, sand or soil for a few minutes.", xp: 5, icon: "leaf.fill", isAuto: false)
    static let redLight = DailyActivity(id: "red_light", name: "Red light", description: "10+ minutes of red light therapy.", xp: 10, icon: "lightbulb.fill", isAuto: false)
    static let boxBreathing = DailyActivity(id: "box_breathing", name: "Box breathing", description: "4-4-4-4 breathing for 5 minutes.", xp: 5, icon: "wind", isAuto: false)
    static let activeRecreation = DailyActivity(id: "active_recreation", name: "Active recreation", description: "Sports, hiking, swimming, or other active fun.", xp: 10, icon: "sportscourt.fill", isAuto: false)

    // Auto activities (mirrored from challenge flow)
    static let sendChallenge = DailyActivity(id: "send_challenge", name: "Sending challenge", description: "Send a workout challenge to a friend.", xp: 5, icon: "paperplane.fill", isAuto: true)
    static let doChallenge = DailyActivity(id: "do_challenge", name: "Doing challenge", description: "Complete a challenge from a friend.", xp: 10, icon: "checkmark.circle.fill", isAuto: true)

    static let allActivities: [DailyActivity] = [
        .sunlight, .walk, .acupressureMat, .sauna, .foamRolling, .stretching,
        .iceBath, .yoga, .healthShot, .noScreens, .prayer, .massage,
        .meditation, .journaling, .grounding, .redLight, .boxBreathing, .activeRecreation,
        .sendChallenge, .doChallenge
    ]

    static let manualActivities: [DailyActivity] = allActivities.filter { !$0.isAuto }
}

// MARK: - Activity Check (one per activity per day)

struct ActivityCheck: Identifiable, Codable {
    let id: String
    let habitId: String
    let date: Date
    let points: Int  // Frozen at check time
    let checkedAt: Date
}

// MARK: - Rewards Response (from server)

struct RewardsResponse: Codable {
    let xp: Int
    let level: Int
    let title: String
    let gem: GemTier
    let todayXp: Int
    let todayParts: TodayParts
    let dailyGoal: Int
    let week: [DayXP]
    let monthXp: Int
    let badges: [BadgeProgress]
    let repairs: RepairInfo
    let overall: OverallRank
    let olympicLevel: Int  // 4 = Emerald

    struct TodayParts: Codable {
        let workouts: Int
        let activities: Int
        let other: Int
    }

    struct DayXP: Codable {
        let date: String
        let xp: Int
    }

    struct BadgeProgress: Codable {
        let id: String
        let progress: Int
        let target: Int
        let earned: Bool
        let earnedOn: Date?
    }

    struct RepairInfo: Codable {
        let earned: Int
        let used: Int
        let available: Int
        let usedDates: [String]
    }

    struct OverallRank: Codable {
        let rank: Int
        let total: Int
        let hidden: Bool
    }
}

// MARK: - Leaderboard

struct LeaderboardEntry: Identifiable, Codable {
    let id: String
    let name: String  // "First L." format
    let xp: Int
    let score: Int  // Period-specific score
    let level: Int
    let gem: GemTier
    let league: League
    let isPacer: Bool  // Synthetic competitor

    var displayName: String { name }
}

struct LeaderboardResponse: Codable {
    let top: [LeaderboardEntry]
    let me: MyRank?
    let period: LeaderboardPeriod
    let league: League
    let resetsOn: Date?
    let olympicXp: Int
    let olympicGem: String

    struct MyRank: Codable {
        let rank: Int
        let score: Int
    }
}

enum LeaderboardPeriod: String, CaseIterable, Codable {
    case day
    case week
    case month
    case all

    var displayName: String {
        switch self {
        case .day: return "Today"
        case .week: return "This Week"
        case .month: return "This Month"
        case .all: return "All Time"
        }
    }
}

// MARK: - Challenges

struct Challenge: Identifiable, Codable {
    let id: String
    let workoutId: String
    let workoutName: String
    let exercises: [ChallengeExercise]
    let fromId: String
    let fromName: String
    let toId: String
    let sentAt: Date
    let status: ChallengeStatus
    let completedAt: Date?

    struct ChallengeExercise: Codable {
        let id: String
        let sets: Int
        let reps: Int?
        let seconds: Int?
    }
}

enum ChallengeStatus: String, Codable {
    case open
    case done
    case expired
}

// MARK: - Streak Info

struct StreakInfo: Codable {
    let current: Int       // Shown streak (with repairs)
    let actual: Int        // Without repairs
    let best: Int
    let missed: Int
    let lifetimeQualifying: Int
    let repairs: RepairWallet

    struct RepairWallet: Codable {
        let available: Int
        let earned: Int
        let used: Int
        let repairedDates: [String]
    }
}

// MARK: - Goal Levels

enum GoalLevel: String, CaseIterable, Codable {
    case beginner
    case intermediate
    case pro

    var xpTarget: Int {
        switch self {
        case .beginner: return 50
        case .intermediate: return 75
        case .pro: return 100
        }
    }

    var displayName: String {
        rawValue.capitalized
    }
}
