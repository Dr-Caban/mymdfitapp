import Foundation

struct Exercise: Identifiable, Codable {
    let id: String
    var name: String
    var description: String
    var instructions: [String]
    var videoURL: URL?
    var thumbnailURL: URL?
    var category: ExerciseCategory
    var difficulty: ExerciseDifficulty
    var duration: Int? // seconds
    var reps: Int?
    var sets: Int?
    var targetAreas: [TargetArea]
    var equipment: [String]
    var isPrescribed: Bool

    var formattedDuration: String? {
        guard let duration = duration else { return nil }
        let minutes = duration / 60
        let seconds = duration % 60
        if minutes > 0 {
            return seconds > 0 ? "\(minutes)m \(seconds)s" : "\(minutes)m"
        }
        return "\(seconds)s"
    }
}

enum ExerciseCategory: String, Codable, CaseIterable {
    case mobility
    case stretching
    case strengthening
    case balance
    case posture
    case breathing
    case warmUp = "warm_up"
    case coolDown = "cool_down"

    var displayName: String {
        switch self {
        case .mobility: return "Mobility"
        case .stretching: return "Stretching"
        case .strengthening: return "Strengthening"
        case .balance: return "Balance"
        case .posture: return "Posture"
        case .breathing: return "Breathing"
        case .warmUp: return "Warm Up"
        case .coolDown: return "Cool Down"
        }
    }

    var icon: String {
        switch self {
        case .mobility: return "figure.flexibility"
        case .stretching: return "figure.cooldown"
        case .strengthening: return "dumbbell.fill"
        case .balance: return "figure.stand"
        case .posture: return "figure.american.football"
        case .breathing: return "lungs.fill"
        case .warmUp: return "flame.fill"
        case .coolDown: return "snowflake"
        }
    }
}

enum ExerciseDifficulty: String, Codable, CaseIterable {
    case beginner
    case intermediate
    case advanced

    var displayName: String {
        rawValue.capitalized
    }
}

enum TargetArea: String, Codable, CaseIterable {
    case neck
    case shoulders
    case upperBack = "upper_back"
    case lowerBack = "lower_back"
    case hips
    case knees
    case ankles
    case wrists
    case core
    case fullBody = "full_body"

    var displayName: String {
        switch self {
        case .neck: return "Neck"
        case .shoulders: return "Shoulders"
        case .upperBack: return "Upper Back"
        case .lowerBack: return "Lower Back"
        case .hips: return "Hips"
        case .knees: return "Knees"
        case .ankles: return "Ankles"
        case .wrists: return "Wrists"
        case .core: return "Core"
        case .fullBody: return "Full Body"
        }
    }
}

// MARK: - Sample Data

extension Exercise {
    static let sample = Exercise(
        id: "ex_001",
        name: "Cat-Cow Stretch",
        description: "A gentle flow between two poses that warms up the spine and relieves back tension.",
        instructions: [
            "Start on hands and knees in tabletop position",
            "Inhale, drop belly toward floor, lift chin and chest (Cow)",
            "Exhale, round spine toward ceiling, tuck chin to chest (Cat)",
            "Continue flowing between poses for 1-2 minutes"
        ],
        videoURL: nil,
        thumbnailURL: nil,
        category: .mobility,
        difficulty: .beginner,
        duration: 120,
        reps: nil,
        sets: nil,
        targetAreas: [.lowerBack, .upperBack],
        equipment: ["Yoga mat"],
        isPrescribed: true
    )

    static let samples: [Exercise] = [
        sample,
        Exercise(
            id: "ex_002",
            name: "Hip Flexor Stretch",
            description: "Opens tight hip flexors from prolonged sitting.",
            instructions: [
                "Kneel on one knee with other foot in front",
                "Push hips forward gently",
                "Hold for 30 seconds each side"
            ],
            videoURL: nil,
            thumbnailURL: nil,
            category: .stretching,
            difficulty: .beginner,
            duration: 60,
            reps: nil,
            sets: 2,
            targetAreas: [.hips],
            equipment: [],
            isPrescribed: true
        )
    ]
}
