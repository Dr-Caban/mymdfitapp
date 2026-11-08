import Foundation

// MARK: - Workout

struct Workout: Identifiable, Codable, Hashable {
    let id: String
    var userId: String?
    var name: String?
    var goalType: WorkoutGoalType
    var location: WorkoutLocation
    var difficulty: DifficultyLevel
    var lengthMinutes: Int
    var exercisesPerRound: Int
    var totalRounds: Int
    var restBetweenExercises: Int       // seconds
    var restBetweenRounds: Int          // seconds
    var addOns: WorkoutAddOns
    var exercises: [WorkoutExercise]
    var scheduledDate: Date?
    var completedAt: Date?
    var createdAt: Date
    var updatedAt: Date

    var isCompleted: Bool {
        completedAt != nil
    }

    var totalExerciseCount: Int {
        exercisesPerRound * totalRounds
    }

    var formattedLength: String {
        if lengthMinutes >= 60 {
            let hours = lengthMinutes / 60
            let mins = lengthMinutes % 60
            return mins > 0 ? "\(hours)h \(mins)m" : "\(hours) Hour\(hours > 1 ? "s" : "")"
        }
        return "\(lengthMinutes) Min"
    }
}

// MARK: - Workout Goal Type

// MARK: - Session Type

enum SessionType: String, Codable, CaseIterable, Hashable {
    case workout
    case rehab

    var displayName: String {
        switch self {
        case .workout: return "Workout"
        case .rehab: return "Rehab"
        }
    }
}

// MARK: - Workout Goal Type

enum WorkoutGoalType: String, Codable, CaseIterable, Hashable {
    case upperBody = "upper_body"
    case lowerBody = "lower_body"
    case fullBody = "full_body"
    case core
    case mobility
    case cardio
    case environmental              // Swim, Run, Bike

    var displayName: String {
        switch self {
        case .upperBody: return "Upper Body"
        case .lowerBody: return "Lower Body"
        case .fullBody: return "Full Body"
        case .core: return "Core & Spine"
        case .mobility: return "Mobility & Recovery"
        case .cardio: return "Cardio"
        case .environmental: return "Environmental"
        }
    }

    var subtitle: String? {
        switch self {
        case .environmental: return "Swim • Run • Bike"
        default: return nil
        }
    }

    var icon: String {
        switch self {
        case .upperBody: return "figure.arms.open"
        case .lowerBody: return "figure.walk"
        case .fullBody: return "figure.mixed.cardio"
        case .core: return "figure.core.training"
        case .mobility: return "figure.flexibility"
        case .cardio: return "heart.fill"
        case .environmental: return "leaf.fill"
        }
    }
}

// MARK: - Workout Location

enum WorkoutLocation: String, Codable, CaseIterable, Hashable {
    case home
    case gym
    case outdoor
    case office
    case pool
    case custom

    var displayName: String {
        switch self {
        case .office: return "Office / Desk"
        default: return rawValue.capitalized
        }
    }

    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .gym: return "dumbbell.fill"
        case .outdoor: return "sun.max.fill"
        case .office: return "desktopcomputer"
        case .pool: return "figure.pool.swim"
        case .custom: return "mappin.circle.fill"
        }
    }
}

// MARK: - Workout Add-Ons

struct WorkoutAddOns: Codable, Hashable {
    var warmUp: Bool = false
    var coolDown: Bool = false
    var mobilityFlexibility: Bool = false
    var coreWork: Bool = false
    var balanceStability: Bool = false
    var sportSpecific: Bool = false
    var noEquipment: Bool = false
    var equipmentRestrictions: Bool = false
    var restrictedEquipment: [Equipment]? = nil
}

// MARK: - Workout Exercise (with prescription)

struct WorkoutExercise: Identifiable, Codable, Hashable {
    let id: String
    var exerciseId: String
    var exercise: Exercise?             // populated when fetched
    var roundNumber: Int
    var orderInRound: Int
    var prescription: Prescription
    var isCompleted: Bool = false
    var completedAt: Date?

    var displayOrder: Int {
        (roundNumber - 1) * 100 + orderInRound
    }
}

// MARK: - Generator Settings (for UI state)

struct WorkoutGeneratorSettings: Codable, Hashable {
    var sessionType: SessionType = .workout
    var goalType: WorkoutGoalType = .fullBody
    var location: WorkoutLocation = .home
    var difficulty: DifficultyLevel = .intermediate
    var lengthMinutes: Int = 45
    var exercisesPerRound: Int = 10
    var totalRounds: Int = 6
    var restBetweenExercises: Int = 0
    var restBetweenRounds: Int = 0
    var addOns: WorkoutAddOns = WorkoutAddOns()

    // Available options from screenshot
    static let lengthOptions = [5, 10, 15, 20, 30, 45, 60, 90, 120, 180, 240]
    static let exercisesPerRoundOptions = [2, 3, 4, 5, 6, 8, 10, 12]
    static let roundOptions = [1, 2, 3, 4, 5, 6, 8, 10]
    static let restOptions = [0, 15, 30, 45, 60, 90, 120, 180]

    mutating func randomize() {
        sessionType = Bool.random() ? .workout : .rehab
        goalType = WorkoutGoalType.allCases.randomElement() ?? .fullBody
        location = WorkoutLocation.allCases.randomElement() ?? .home
        difficulty = DifficultyLevel.allCases.randomElement() ?? .intermediate
        lengthMinutes = Self.lengthOptions.randomElement() ?? 60
        exercisesPerRound = Self.exercisesPerRoundOptions.randomElement() ?? 5
        totalRounds = Self.roundOptions.randomElement() ?? 2
        restBetweenExercises = Self.restOptions.randomElement() ?? 30
        restBetweenRounds = Self.restOptions.randomElement() ?? 60
    }
}

// MARK: - Sample Data

extension Workout {
    static let sample = Workout(
        id: "wkt_001",
        userId: "user_001",
        name: "Full Body Power",
        goalType: .fullBody,
        location: .home,
        difficulty: .intermediate,
        lengthMinutes: 60,
        exercisesPerRound: 5,
        totalRounds: 2,
        restBetweenExercises: 0,
        restBetweenRounds: 0,
        addOns: WorkoutAddOns(warmUp: true, coolDown: true),
        exercises: [],
        scheduledDate: Date(),
        completedAt: nil,
        createdAt: Date(),
        updatedAt: Date()
    )
}
