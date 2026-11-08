import Foundation

// MARK: - Exercise Database Entry
// Lightweight struct for video-based exercise metadata
// Parsed from video filenames using convention: REGION_CATEGORY_MOVEMENT_SUBTYPE.mp4

struct ExerciseEntry: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let videoFilename: String
    let bodyRegion: VideoBodyRegion
    let category: VideoCategory
    let exerciseType: ExerciseType
    let level: DifficultyLevel

    // Computed property for display name
    var displayName: String {
        name
    }
}

// MARK: - Video Body Region (from filename codes)

enum VideoBodyRegion: String, Codable, CaseIterable, Hashable {
    case wrist = "WR"
    case elbow = "EL"
    case shoulder = "SH"
    case neck = "NK"
    case spine = "SP"
    case core = "CO"
    case hip = "HP"
    case knee = "KN"
    case ankle = "AN"
    case lowerBody = "LB"
    case fullBody = "FB"

    var displayName: String {
        switch self {
        case .wrist: return "Wrist"
        case .elbow: return "Elbow"
        case .shoulder: return "Shoulder"
        case .neck: return "Neck"
        case .spine: return "Spine"
        case .core: return "Core"
        case .hip: return "Hip"
        case .knee: return "Knee"
        case .ankle: return "Ankle"
        case .lowerBody: return "Lower Body"
        case .fullBody: return "Full Body"
        }
    }

    // Map to main BodyRegion enum for compatibility
    var bodyRegion: BodyRegion {
        switch self {
        case .wrist: return .arms
        case .elbow: return .arms
        case .shoulder: return .shoulders
        case .neck: return .neck
        case .spine: return .upperBack
        case .core: return .core
        case .hip: return .hips
        case .knee: return .knees
        case .ankle: return .ankles
        case .lowerBody: return .quadriceps
        case .fullBody: return .fullBody
        }
    }

    static func from(_ code: String) -> VideoBodyRegion? {
        return VideoBodyRegion(rawValue: code.uppercased())
    }
}

// MARK: - Video Category (from filename codes)

enum VideoCategory: String, Codable, CaseIterable, Hashable {
    case conditioning = "CO"
    case extensionEx = "EX"
    case rotation = "RT"
    case squat = "SQ"
    case gait = "GT"
    case pull = "PL"
    case press = "PR"
    case lunge = "LN"
    case hinge = "HN"
    case abduction = "AB"
    case mobility = "MOB"
    case carry = "CR"
    case push = "PU"
    case power = "PWR"

    var displayName: String {
        switch self {
        case .conditioning: return "Conditioning"
        case .extensionEx: return "Extension"
        case .rotation: return "Rotation"
        case .squat: return "Squat"
        case .gait: return "Gait"
        case .pull: return "Pull"
        case .press: return "Press"
        case .lunge: return "Lunge"
        case .hinge: return "Hinge"
        case .abduction: return "Abduction"
        case .mobility: return "Mobility"
        case .carry: return "Carry"
        case .push: return "Push"
        case .power: return "Power"
        }
    }

    // Map to main ExerciseCategory enum for compatibility
    var exerciseCategory: ExerciseCategory {
        switch self {
        case .conditioning: return .cardio
        case .extensionEx: return .strengthening
        case .rotation: return .mobility
        case .squat: return .strengthening
        case .gait: return .warmUp
        case .pull: return .strengthening
        case .press: return .strengthening
        case .lunge: return .strengthening
        case .hinge: return .strengthening
        case .abduction: return .strengthening
        case .mobility: return .mobility
        case .carry: return .stability
        case .push: return .strengthening
        case .power: return .power
        }
    }

    static func from(_ code: String) -> VideoCategory? {
        return VideoCategory(rawValue: code.uppercased())
    }
}

// MARK: - Exercise Type (subtype from filename)

enum ExerciseType: String, Codable, CaseIterable, Hashable {
    case rehab = "RHB"
    case mobility = "MOB"
    case strength = "STR"
    case activation = "ACT"
    case power = "PWR"

    var displayName: String {
        switch self {
        case .rehab: return "Rehab"
        case .mobility: return "Mobility"
        case .strength: return "Strength"
        case .activation: return "Activation"
        case .power: return "Power"
        }
    }

    // Map to DifficultyLevel for level inference
    var inferredLevel: DifficultyLevel {
        switch self {
        case .rehab: return .beginner
        case .mobility: return .beginner
        case .activation: return .beginner
        case .strength: return .intermediate
        case .power: return .advanced
        }
    }

    static func from(_ code: String) -> ExerciseType? {
        return ExerciseType(rawValue: code.uppercased())
    }
}

// MARK: - Exercise Database

struct ExerciseDatabase {

    /// All exercises parsed from video filenames
    static let exercises: [ExerciseEntry] = [
        // Ankle Exercises
        ExerciseEntry(
            id: "AN_CO_ECCENTRIC_CALF_DROPS_RHB",
            name: "Eccentric Calf Drops",
            videoFilename: "AN_CO_ECCENTRIC_CALF_DROPS_RHB.mp4",
            bodyRegion: .ankle,
            category: .conditioning,
            exerciseType: .rehab,
            level: .beginner
        ),
        ExerciseEntry(
            id: "AN_MOB_KNEEL_PLANTAR_FASCIA_MOB",
            name: "Kneel Plantar Fascia",
            videoFilename: "AN_MOB_KNEEL_PLANTAR_FASCIA_MOB.mp4",
            bodyRegion: .ankle,
            category: .mobility,
            exerciseType: .mobility,
            level: .beginner
        ),
        ExerciseEntry(
            id: "AN_MOB_SEATED_PLANTAR_FASCIA_MOB",
            name: "Seated Plantar Fascia",
            videoFilename: "AN_MOB_SEATED_PLANTAR_FASCIA_MOB.mp4",
            bodyRegion: .ankle,
            category: .mobility,
            exerciseType: .mobility,
            level: .beginner
        ),

        // Core Exercises
        ExerciseEntry(
            id: "CO_CO_DEAD_BUG_STR",
            name: "Dead Bug",
            videoFilename: "CO_CO_DEAD_BUG_STR.mp4",
            bodyRegion: .core,
            category: .conditioning,
            exerciseType: .strength,
            level: .intermediate
        ),
        ExerciseEntry(
            id: "CO_RT_LANDMINE_PRESS_TWIST_PWR",
            name: "Landmine Press Twist",
            videoFilename: "CO_RT_LANDMINE_PRESS_TWIST_PWR.mp4",
            bodyRegion: .core,
            category: .rotation,
            exerciseType: .power,
            level: .advanced
        ),

        // Elbow Exercises
        ExerciseEntry(
            id: "EL_EX_OVERHEAD_TRICEP_EXTENSION_STR",
            name: "Overhead Tricep Extension",
            videoFilename: "EL_EX_OVERHEAD_TRICEP_EXTENSION_STR.mp4",
            bodyRegion: .elbow,
            category: .extensionEx,
            exerciseType: .strength,
            level: .intermediate
        ),

        // Full Body Exercises
        ExerciseEntry(
            id: "FB_CO_BURPEE_MOB",
            name: "Burpee",
            videoFilename: "FB_CO_BURPEE_MOB.mp4",
            bodyRegion: .fullBody,
            category: .conditioning,
            exerciseType: .mobility,
            level: .beginner
        ),

        // Hip Exercises
        ExerciseEntry(
            id: "HP_AB_STANDING_HIPABAD_MOB",
            name: "Standing Hip Abduction",
            videoFilename: "HP_AB_STANDING_HIPABAD_MOB.mp4",
            bodyRegion: .hip,
            category: .abduction,
            exerciseType: .mobility,
            level: .beginner
        ),
        ExerciseEntry(
            id: "HP_GT_GLUTE_WALK_ACT",
            name: "Glute Walk",
            videoFilename: "HP_GT_GLUTE_WALK_ACT.mp4",
            bodyRegion: .hip,
            category: .gait,
            exerciseType: .activation,
            level: .beginner
        ),
        ExerciseEntry(
            id: "HP_HN_CABLE_PULL_THROUGH_STR",
            name: "Cable Pull Through",
            videoFilename: "HP_HN_CABLE_PULL_THROUGH_STR.mp4",
            bodyRegion: .hip,
            category: .hinge,
            exerciseType: .strength,
            level: .intermediate
        ),
        ExerciseEntry(
            id: "HP_HN_ROMANIAN_DEADLIFT_STR",
            name: "Romanian Deadlift",
            videoFilename: "HP_HN_ROMANIAN_DEADLIFT_STR.mp4",
            bodyRegion: .hip,
            category: .hinge,
            exerciseType: .strength,
            level: .intermediate
        ),
        ExerciseEntry(
            id: "HP_LN_BULGARIAN_SPLIT_SQUAT_MOB",
            name: "Bulgarian Split Squat",
            videoFilename: "HP_LN_BULGARIAN_SPLIT_SQUAT_MOB.mp4",
            bodyRegion: .hip,
            category: .lunge,
            exerciseType: .mobility,
            level: .beginner
        ),
        ExerciseEntry(
            id: "HP_RT_9090_HIP_SWITCH_MOB",
            name: "90/90 Hip Switch",
            videoFilename: "HP_RT_9090_HIP_SWITCH_MOB.mp4",
            bodyRegion: .hip,
            category: .rotation,
            exerciseType: .mobility,
            level: .beginner
        ),
        ExerciseEntry(
            id: "HP_RT_STANDING_CLAMSHELL_MOB",
            name: "Standing Clamshell",
            videoFilename: "HP_RT_STANDING_CLAMSHELL_MOB.mp4",
            bodyRegion: .hip,
            category: .rotation,
            exerciseType: .mobility,
            level: .beginner
        ),
        ExerciseEntry(
            id: "HP_SQ_COSSACK_SQUAT_MOB",
            name: "Cossack Squat",
            videoFilename: "HP_SQ_COSSACK_SQUAT_MOB.mp4",
            bodyRegion: .hip,
            category: .squat,
            exerciseType: .mobility,
            level: .beginner
        ),

        // Knee Exercises
        ExerciseEntry(
            id: "KN_MOB_KNEE_CIRCLES_RHB",
            name: "Knee Circles",
            videoFilename: "KN_MOB_KNEE_CIRCLES_RHB.mp4",
            bodyRegion: .knee,
            category: .mobility,
            exerciseType: .rehab,
            level: .beginner
        ),
        ExerciseEntry(
            id: "KN_SQ_SISSY_SQUAT_STR",
            name: "Sissy Squat",
            videoFilename: "KN_SQ_SISSY_SQUAT_STR.mp4",
            bodyRegion: .knee,
            category: .squat,
            exerciseType: .strength,
            level: .intermediate
        ),

        // Lower Body Exercises
        ExerciseEntry(
            id: "LB_GT_HEEL_WALK_ACT",
            name: "Heel Walk",
            videoFilename: "LB_GT_HEEL_WALK_ACT.mp4",
            bodyRegion: .lowerBody,
            category: .gait,
            exerciseType: .activation,
            level: .beginner
        ),
        ExerciseEntry(
            id: "LB_GT_TOE_WALK_ACT",
            name: "Toe Walk",
            videoFilename: "LB_GT_TOE_WALK_ACT.mp4",
            bodyRegion: .lowerBody,
            category: .gait,
            exerciseType: .activation,
            level: .beginner
        ),
        ExerciseEntry(
            id: "LB_PWR_LONG_JUMP_PWR",
            name: "Long Jump",
            videoFilename: "LB_PWR_LONG_JUMP_PWR.mp4",
            bodyRegion: .lowerBody,
            category: .power,
            exerciseType: .power,
            level: .advanced
        ),

        // Neck Exercises
        ExerciseEntry(
            id: "NK_MOB_ECCENTRIC_SCALENE_DROP_RHB",
            name: "Eccentric Scalene Drop",
            videoFilename: "NK_MOB_ECCENTRIC_SCALENE_DROP_RHB.mp4",
            bodyRegion: .neck,
            category: .mobility,
            exerciseType: .rehab,
            level: .beginner
        ),
        ExerciseEntry(
            id: "NK_MOB_SCALENE_RELEASE_RHB",
            name: "Scalene Release",
            videoFilename: "NK_MOB_SCALENE_RELEASE_RHB.mp4",
            bodyRegion: .neck,
            category: .mobility,
            exerciseType: .rehab,
            level: .beginner
        ),

        // Shoulder Exercises
        ExerciseEntry(
            id: "SH_PL_FACE_PULL_ACT",
            name: "Face Pull",
            videoFilename: "SH_PL_FACE_PULL_ACT.mp4",
            bodyRegion: .shoulder,
            category: .pull,
            exerciseType: .activation,
            level: .beginner
        ),
        ExerciseEntry(
            id: "SH_PR_INCLINE_BENCH_PRESS_STR",
            name: "Incline Bench Press",
            videoFilename: "SH_PR_INCLINE_BENCH_PRESS_STR.mp4",
            bodyRegion: .shoulder,
            category: .press,
            exerciseType: .strength,
            level: .intermediate
        ),
        ExerciseEntry(
            id: "SH_PU_BENCH_PRESS_STR",
            name: "Bench Press",
            videoFilename: "SH_PU_BENCH_PRESS_STR.mp4",
            bodyRegion: .shoulder,
            category: .push,
            exerciseType: .strength,
            level: .intermediate
        ),
        ExerciseEntry(
            id: "SH_RT_RC_INTERNAL_ROTATION_RHB",
            name: "Rotator Cuff Internal Rotation",
            videoFilename: "SH_RT_RC_INTERNAL_ROTATION_RHB.mp4",
            bodyRegion: .shoulder,
            category: .rotation,
            exerciseType: .rehab,
            level: .beginner
        ),

        // Spine Exercises
        ExerciseEntry(
            id: "SP_CO_GHD_SIT_UP_MOB",
            name: "GHD Sit Up",
            videoFilename: "SP_CO_GHD_SIT_UP_MOB.mp4",
            bodyRegion: .spine,
            category: .conditioning,
            exerciseType: .mobility,
            level: .beginner
        ),
        ExerciseEntry(
            id: "SP_CO_WALL_BALL_SIT_UP_MOB",
            name: "Wall Ball Sit Up",
            videoFilename: "SP_CO_WALL_BALL_SIT_UP_MOB.mp4",
            bodyRegion: .spine,
            category: .conditioning,
            exerciseType: .mobility,
            level: .beginner
        ),
        ExerciseEntry(
            id: "SP_CR_FARMER_CARRY_ACT",
            name: "Farmer Carry",
            videoFilename: "SP_CR_FARMER_CARRY_ACT.mp4",
            bodyRegion: .spine,
            category: .carry,
            exerciseType: .activation,
            level: .beginner
        ),
        ExerciseEntry(
            id: "SP_MOB_CAT_COW_DESK_VARIATION_MOB",
            name: "Cat Cow Desk Variation",
            videoFilename: "SP_MOB_CAT_COW_DESK_VARIATION_MOB.mp4",
            bodyRegion: .spine,
            category: .mobility,
            exerciseType: .mobility,
            level: .beginner
        ),
        ExerciseEntry(
            id: "SP_MOB_PIKE_FORWARD_FOLD_MOB",
            name: "Pike Forward Fold",
            videoFilename: "SP_MOB_PIKE_FORWARD_FOLD_MOB.mp4",
            bodyRegion: .spine,
            category: .mobility,
            exerciseType: .mobility,
            level: .beginner
        ),
        ExerciseEntry(
            id: "SP_RT_BASEBALL_CABLE_STRETCH_MOB",
            name: "Baseball Cable Stretch",
            videoFilename: "SP_RT_BASEBALL_CABLE_STRETCH_MOB.mp4",
            bodyRegion: .spine,
            category: .rotation,
            exerciseType: .mobility,
            level: .beginner
        ),
        ExerciseEntry(
            id: "SP_RT_LYING_OPEN_BOOK_MOB",
            name: "Lying Open Book",
            videoFilename: "SP_RT_LYING_OPEN_BOOK_MOB.mp4",
            bodyRegion: .spine,
            category: .rotation,
            exerciseType: .mobility,
            level: .beginner
        ),
        ExerciseEntry(
            id: "SP_RT_QUADRUPED_TSPINE_ROTATION_MOB",
            name: "Quadruped T-Spine Rotation",
            videoFilename: "SP_RT_QUADRUPED_TSPINE_ROTATION_MOB.mp4",
            bodyRegion: .spine,
            category: .rotation,
            exerciseType: .mobility,
            level: .beginner
        ),
        ExerciseEntry(
            id: "SP_RT_THORACIC_OPEN_BOOK_MOB",
            name: "Thoracic Open Book",
            videoFilename: "SP_RT_THORACIC_OPEN_BOOK_MOB.mp4",
            bodyRegion: .spine,
            category: .rotation,
            exerciseType: .mobility,
            level: .beginner
        ),
        ExerciseEntry(
            id: "SP_RT_THREAD_THE_NEEDLE_MOB",
            name: "Thread the Needle",
            videoFilename: "SP_RT_THREAD_THE_NEEDLE_MOB.mp4",
            bodyRegion: .spine,
            category: .rotation,
            exerciseType: .mobility,
            level: .beginner
        ),

        // Wrist Exercises
        ExerciseEntry(
            id: "WR_CO_ECCENTRIC_WRIST_DROPS_RHB",
            name: "Eccentric Wrist Drops",
            videoFilename: "WR_CO_ECCENTRIC_WRIST_DROPS_RHB.mp4",
            bodyRegion: .wrist,
            category: .conditioning,
            exerciseType: .rehab,
            level: .beginner
        ),
        ExerciseEntry(
            id: "WR_RT_WEIGHTED_WRIST_CIRCLES_ACT",
            name: "Weighted Wrist Circles",
            videoFilename: "WR_RT_WEIGHTED_WRIST_CIRCLES_ACT.mp4",
            bodyRegion: .wrist,
            category: .rotation,
            exerciseType: .activation,
            level: .beginner
        ),
    ]

    // MARK: - Query Methods

    /// Get exercises by body region
    static func exercises(for region: VideoBodyRegion) -> [ExerciseEntry] {
        exercises.filter { $0.bodyRegion == region }
    }

    /// Get exercises by category
    static func exercises(for category: VideoCategory) -> [ExerciseEntry] {
        exercises.filter { $0.category == category }
    }

    /// Get exercises by type
    static func exercises(for type: ExerciseType) -> [ExerciseEntry] {
        exercises.filter { $0.exerciseType == type }
    }

    /// Get exercises by difficulty level
    static func exercises(for level: DifficultyLevel) -> [ExerciseEntry] {
        exercises.filter { $0.level == level }
    }

    /// Find exercise by ID
    static func exercise(withId id: String) -> ExerciseEntry? {
        exercises.first { $0.id == id }
    }

    /// Find exercise by video filename
    static func exercise(withFilename filename: String) -> ExerciseEntry? {
        exercises.first { $0.videoFilename == filename }
    }

    /// Get all unique body regions in the database
    static var availableRegions: [VideoBodyRegion] {
        Array(Set(exercises.map { $0.bodyRegion })).sorted { $0.displayName < $1.displayName }
    }

    /// Get all unique categories in the database
    static var availableCategories: [VideoCategory] {
        Array(Set(exercises.map { $0.category })).sorted { $0.displayName < $1.displayName }
    }

    /// Get all unique exercise types in the database
    static var availableTypes: [ExerciseType] {
        Array(Set(exercises.map { $0.exerciseType })).sorted { $0.displayName < $1.displayName }
    }

    /// Total count of exercises
    static var count: Int {
        exercises.count
    }
}

// MARK: - Filename Parser Utility

extension ExerciseDatabase {

    /// Parse a video filename to extract metadata
    /// Format: REGION_CATEGORY_MOVEMENT_SUBTYPE.mp4
    static func parseFilename(_ filename: String) -> (
        region: VideoBodyRegion?,
        category: VideoCategory?,
        movement: String,
        type: ExerciseType?
    )? {
        // Remove .mp4 extension if present
        let name = filename.hasSuffix(".mp4")
            ? String(filename.dropLast(4))
            : filename

        let parts = name.split(separator: "_").map(String.init)
        guard parts.count >= 4 else { return nil }

        let region = VideoBodyRegion.from(parts[0])
        let category = VideoCategory.from(parts[1])
        let type = ExerciseType.from(parts.last ?? "")

        // Movement name is everything between category and type
        let movementParts = parts.count > 4
            ? parts[2..<(parts.count - 1)]
            : [parts[2]]
        let movement = movementParts.joined(separator: " ")
            .lowercased()
            .split(separator: " ")
            .map { $0.prefix(1).uppercased() + $0.dropFirst() }
            .joined(separator: " ")

        return (region, category, movement, type)
    }

    /// Convert underscore-separated name to human-readable format
    /// Example: "ECCENTRIC_WRIST_DROPS" -> "Eccentric Wrist Drops"
    static func humanReadableName(_ underscoreName: String) -> String {
        underscoreName
            .lowercased()
            .split(separator: "_")
            .map { word in
                // Handle special cases
                switch word {
                case "ghd": return "GHD"
                case "tspine": return "T-Spine"
                case "rc": return "Rotator Cuff"
                default: return word.prefix(1).uppercased() + word.dropFirst()
                }
            }
            .joined(separator: " ")
    }
}
