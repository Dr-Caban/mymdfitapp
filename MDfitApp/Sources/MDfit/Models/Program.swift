import Foundation

// MARK: - Program

struct Program: Identifiable, Codable, Hashable {
    let id: String
    var name: String
    var description: String
    var category: ProgramCategory
    var difficulty: DifficultyLevel
    var durationWeeks: Int
    var thumbnailURL: URL?
    var weeks: [ProgramWeek]
    var price: Decimal?                 // nil = included with membership
    var isPremium: Bool
    var isPublished: Bool
    var createdAt: Date
    var updatedAt: Date

    var totalWorkouts: Int {
        weeks.reduce(0) { $0 + $1.days.count }
    }

    var formattedPrice: String {
        guard let price = price else { return "Included" }
        return "$\(price)"
    }
}

// MARK: - Program Category

enum ProgramCategory: String, Codable, CaseIterable, Hashable {
    case golf
    case pickleball
    case running
    case ski
    case shoulderRelease = "shoulder_release"
    case plantarFascia = "plantar_fascia"
    case lowerBackSI = "lower_back_si"
    case mobility
    case strength
    case weightLoss = "weight_loss"
    case hiit
    case general

    var displayName: String {
        switch self {
        case .golf: return "Golf"
        case .pickleball: return "Pickleball"
        case .running: return "Running"
        case .ski: return "Ski"
        case .shoulderRelease: return "Shoulder Release"
        case .plantarFascia: return "Plantar Fascia"
        case .lowerBackSI: return "Lower Back / SI"
        case .mobility: return "Mobility"
        case .strength: return "Strength"
        case .weightLoss: return "Weight Loss"
        case .hiit: return "HIIT"
        case .general: return "General Fitness"
        }
    }

    var icon: String {
        switch self {
        case .golf: return "figure.golf"
        case .pickleball: return "figure.pickleball"
        case .running: return "figure.run"
        case .ski: return "figure.skiing.downhill"
        case .shoulderRelease: return "figure.arms.open"
        case .plantarFascia: return "foot.fill"
        case .lowerBackSI: return "figure.walk"
        case .mobility: return "figure.flexibility"
        case .strength: return "dumbbell.fill"
        case .weightLoss: return "scalemass.fill"
        case .hiit: return "bolt.heart.fill"
        case .general: return "figure.mixed.cardio"
        }
    }
}

// MARK: - Program Week

struct ProgramWeek: Identifiable, Codable, Hashable {
    let id: String
    var weekNumber: Int
    var name: String?                   // "Foundation Week", etc.
    var days: [ProgramDay]
}

// MARK: - Program Day

struct ProgramDay: Identifiable, Codable, Hashable {
    let id: String
    var dayNumber: Int                  // 1-7 within week
    var dayOfWeek: DayOfWeek?          // Mon, Wed, Fri or flexible
    var name: String?                   // "Lower Body Power"
    var workoutId: String?
    var exercises: [WorkoutExercise]
    var isRestDay: Bool
    var isFreeformActivity: Bool        // "Active recovery - your choice"
    var notes: String?
}

enum DayOfWeek: String, Codable, CaseIterable, Hashable {
    case monday, tuesday, wednesday, thursday, friday, saturday, sunday

    var shortName: String {
        String(rawValue.prefix(3)).capitalized
    }
}

// MARK: - Enrollment

struct Enrollment: Identifiable, Codable, Hashable {
    let id: String
    var userId: String
    var programId: String
    var program: Program?
    var startDate: Date
    var currentWeek: Int
    var currentDay: Int
    var completedWorkouts: [String]     // workout IDs
    var status: EnrollmentStatus
    var createdAt: Date
    var updatedAt: Date

    var progressPercentage: Double {
        guard let program = program, program.totalWorkouts > 0 else { return 0 }
        return Double(completedWorkouts.count) / Double(program.totalWorkouts) * 100
    }
}

enum EnrollmentStatus: String, Codable, Hashable {
    case active
    case paused
    case completed
    case abandoned
}

// MARK: - Sample Data

extension Program {
    static let sample = Program(
        id: "prog_001",
        name: "8-Week Running: Beginner",
        description: "Build proper running mechanics from the ground up. Focus on midfoot landing, glute activation, trunk rotation, and efficient form.",
        category: .running,
        difficulty: .beginner,
        durationWeeks: 8,
        thumbnailURL: nil,
        weeks: [],
        price: nil,
        isPremium: true,
        isPublished: true,
        createdAt: Date(),
        updatedAt: Date()
    )

    static let samples: [Program] = [
        sample,
        Program(
            id: "prog_002",
            name: "Golf Rotational Power",
            description: "Develop explosive rotational power for a more powerful swing.",
            category: .golf,
            difficulty: .intermediate,
            durationWeeks: 6,
            thumbnailURL: nil,
            weeks: [],
            price: 49.99,
            isPremium: true,
            isPublished: true,
            createdAt: Date(),
            updatedAt: Date()
        ),
        Program(
            id: "prog_003",
            name: "Lower Back & SI Relief",
            description: "Targeted mobility and strengthening for lower back and SI joint issues.",
            category: .lowerBackSI,
            difficulty: .beginner,
            durationWeeks: 4,
            thumbnailURL: nil,
            weeks: [],
            price: nil,
            isPremium: false,
            isPublished: true,
            createdAt: Date(),
            updatedAt: Date()
        )
    ]
}
