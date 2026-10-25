import Foundation

// MARK: - Exercise

struct Exercise: Identifiable, Codable, Hashable {
    let id: String
    var name: String
    var videoAssetId: String?
    var bodyRegion: BodyRegion
    var muscleEmphasis: [String]
    var category: ExerciseCategory
    var equipment: [Equipment]
    var level: DifficultyLevel
    var cues: [String]
    var tempo: String?
    var defaultPrescription: Prescription
    var modifications: [String]
    var exclusions: [String]           // contraindications
    var safetyNotes: String?
    var approvalStatus: ApprovalStatus
    var tags: [String]
    var createdAt: Date
    var updatedAt: Date

    // Computed: video URL from naming convention
    // REGION_CATEGORY_MOVEMENT_SUBTYPE.mp4
    var videoFilename: String {
        "\(bodyRegion.rawValue.uppercased())_\(category.rawValue.uppercased())_\(name.replacingOccurrences(of: " ", with: "_").uppercased()).mp4"
    }
}

// MARK: - Body Region

enum BodyRegion: String, Codable, CaseIterable, Hashable {
    case neck
    case shoulders
    case upperBack = "upper_back"
    case chest
    case arms
    case core
    case lowerBack = "lower_back"
    case hips
    case glutes
    case quadriceps
    case hamstrings
    case knees
    case calves
    case ankles
    case feet
    case fullBody = "full_body"

    var displayName: String {
        switch self {
        case .neck: return "Neck"
        case .shoulders: return "Shoulders"
        case .upperBack: return "Upper Back"
        case .chest: return "Chest"
        case .arms: return "Arms"
        case .core: return "Core"
        case .lowerBack: return "Lower Back"
        case .hips: return "Hips"
        case .glutes: return "Glutes"
        case .quadriceps: return "Quadriceps"
        case .hamstrings: return "Hamstrings"
        case .knees: return "Knees"
        case .calves: return "Calves"
        case .ankles: return "Ankles"
        case .feet: return "Feet"
        case .fullBody: return "Full Body"
        }
    }
}

// MARK: - Exercise Category

enum ExerciseCategory: String, Codable, CaseIterable, Hashable {
    case mobility
    case stretching
    case strengthening
    case stability
    case power
    case cardio
    case warmUp = "warm_up"
    case coolDown = "cool_down"
    case rehab
    case sport

    var displayName: String {
        switch self {
        case .mobility: return "Mobility"
        case .stretching: return "Stretching"
        case .strengthening: return "Strengthening"
        case .stability: return "Stability"
        case .power: return "Power"
        case .cardio: return "Cardio"
        case .warmUp: return "Warm Up"
        case .coolDown: return "Cool Down"
        case .rehab: return "Rehab"
        case .sport: return "Sport-Specific"
        }
    }

    var icon: String {
        switch self {
        case .mobility: return "figure.flexibility"
        case .stretching: return "figure.cooldown"
        case .strengthening: return "dumbbell.fill"
        case .stability: return "figure.stand"
        case .power: return "bolt.fill"
        case .cardio: return "heart.fill"
        case .warmUp: return "flame.fill"
        case .coolDown: return "snowflake"
        case .rehab: return "cross.case.fill"
        case .sport: return "sportscourt.fill"
        }
    }
}

// MARK: - Equipment

enum Equipment: String, Codable, CaseIterable, Hashable {
    case none
    case dumbbells
    case barbell
    case kettlebell
    case resistanceBand = "resistance_band"
    case cablesMachine = "cables_machine"
    case medicineBall = "medicine_ball"
    case foamRoller = "foam_roller"
    case yogaMat = "yoga_mat"
    case pullUpBar = "pull_up_bar"
    case bench
    case box
    case trx

    var displayName: String {
        switch self {
        case .none: return "No Equipment"
        case .dumbbells: return "Dumbbells"
        case .barbell: return "Barbell"
        case .kettlebell: return "Kettlebell"
        case .resistanceBand: return "Resistance Band"
        case .cablesMachine: return "Cables/Machine"
        case .medicineBall: return "Medicine Ball"
        case .foamRoller: return "Foam Roller"
        case .yogaMat: return "Yoga Mat"
        case .pullUpBar: return "Pull-Up Bar"
        case .bench: return "Bench"
        case .box: return "Box/Step"
        case .trx: return "TRX/Suspension"
        }
    }
}

// MARK: - Difficulty Level

enum DifficultyLevel: String, Codable, CaseIterable, Hashable {
    case beginner
    case intermediate
    case advanced
    case elite

    var displayName: String {
        rawValue.capitalized
    }
}

// MARK: - Approval Status

enum ApprovalStatus: String, Codable, Hashable {
    case draft
    case pendingReview = "pending_review"
    case approved
    case archived
}

// MARK: - Prescription (lives on WorkoutExercise)

struct Prescription: Codable, Hashable {
    var sets: Int?
    var reps: Int?                      // or rep range "8-12"
    var repRange: String?
    var tempo: String?                  // e.g., "3-1-2-0"
    var duration: Int?                  // seconds
    var distance: Double?               // meters
    var intensity: String?              // "moderate", "high", RPE
    var load: String?                   // "bodyweight", "light", "heavy"
    var rest: Int?                      // seconds between sets
    var coachingCues: [String]?
    var modification: String?
    var stopRules: String?              // "stop if pain > 5"

    static let `default` = Prescription(
        sets: 3,
        reps: 10,
        repRange: nil,
        tempo: nil,
        duration: nil,
        distance: nil,
        intensity: "moderate",
        load: nil,
        rest: 60,
        coachingCues: nil,
        modification: nil,
        stopRules: nil
    )

    // Rehab prescription (slow, pain-limited)
    static let rehab = Prescription(
        sets: 1,
        reps: nil,
        repRange: "3-10",
        tempo: "slow",
        duration: nil,
        distance: nil,
        intensity: "pain-limited",
        load: nil,
        rest: nil,
        coachingCues: ["Move slowly", "Stop if pain increases"],
        modification: nil,
        stopRules: "Stop if pain exceeds 5/10"
    )
}

// MARK: - Sample Data

extension Exercise {
    static let sample = Exercise(
        id: "ex_001",
        name: "Cat Cow",
        videoAssetId: "vid_001",
        bodyRegion: .lowerBack,
        muscleEmphasis: ["erector spinae", "abdominals"],
        category: .mobility,
        equipment: [.yogaMat],
        level: .beginner,
        cues: ["Start on hands and knees", "Inhale, drop belly, lift chest (Cow)", "Exhale, round spine, tuck chin (Cat)"],
        tempo: "slow",
        defaultPrescription: .init(sets: 1, reps: 10, rest: 0),
        modifications: ["Pad knees if sensitive"],
        exclusions: ["acute back injury"],
        safetyNotes: "Move within pain-free range",
        approvalStatus: .approved,
        tags: ["spine", "warmup", "mobility"],
        createdAt: Date(),
        updatedAt: Date()
    )
}
