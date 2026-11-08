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

    // Computed: formatted duration from prescription
    var formattedDuration: String? {
        if let duration = defaultPrescription.duration {
            if duration >= 60 {
                return "\(duration / 60) min"
            } else {
                return "\(duration) sec"
            }
        } else if let sets = defaultPrescription.sets, let reps = defaultPrescription.reps {
            return "\(sets) × \(reps) reps"
        } else if let sets = defaultPrescription.sets, let repRange = defaultPrescription.repRange {
            return "\(sets) × \(repRange) reps"
        }
        return nil
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

    var icon: String {
        switch self {
        case .neck: return "person.crop.circle"
        case .shoulders: return "figure.arms.open"
        case .upperBack: return "figure.stand"
        case .chest: return "heart.fill"
        case .arms: return "hand.raised.fill"
        case .core: return "figure.core.training"
        case .lowerBack: return "figure.walk"
        case .hips: return "figure.stand"
        case .glutes: return "figure.walk"
        case .quadriceps: return "figure.run"
        case .hamstrings: return "figure.run"
        case .knees: return "figure.walk"
        case .calves: return "shoeprints.fill"
        case .ankles: return "shoeprints.fill"
        case .feet: return "shoeprints.fill"
        case .fullBody: return "figure.mixed.cardio"
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

    var icon: String {
        switch self {
        case .none: return "hand.raised.fill"
        case .dumbbells: return "dumbbell.fill"
        case .barbell: return "dumbbell.fill"
        case .kettlebell: return "scalemass.fill"
        case .resistanceBand: return "lasso"
        case .cablesMachine: return "gearshape.fill"
        case .medicineBall: return "circle.fill"
        case .foamRoller: return "cylinder.fill"
        case .yogaMat: return "rectangle.fill"
        case .pullUpBar: return "minus.rectangle.fill"
        case .bench: return "rectangle.fill"
        case .box: return "square.fill"
        case .trx: return "lasso"
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

    // MARK: - Full Exercise Library
    static let samples: [Exercise] = [
        sample,

        // NECK
        Exercise(id: "NK_MOB_SCALENE_RELEASE_RHB", name: "Scalene Release", videoAssetId: "NK_MOB_SCALENE_RELEASE_RHB", bodyRegion: .neck, muscleEmphasis: ["scalenes", "SCM"], category: .rehab, equipment: [.none], level: .beginner, cues: ["Tilt head away from tight side", "Gentle stretch, no forcing", "Hold and breathe"], tempo: "hold 30s", defaultPrescription: .init(sets: 1, reps: 3, duration: 30, rest: 0), modifications: [], exclusions: ["cervical instability"], safetyNotes: "Gentle pressure only, stop if dizzy", approvalStatus: .approved, tags: ["neck", "scalene", "release", "rehab"], createdAt: Date(), updatedAt: Date()),
        Exercise(id: "NK_STR_CHIN_TUCK", name: "Chin Tuck", videoAssetId: "NK_STR_CHIN_TUCK", bodyRegion: .neck, muscleEmphasis: ["deep cervical flexors"], category: .strengthening, equipment: [.none], level: .beginner, cues: ["Draw chin straight back", "Create a double chin", "Hold 5 seconds"], tempo: "hold", defaultPrescription: .init(sets: 3, reps: 10, rest: 30), modifications: ["Perform against wall"], exclusions: [], safetyNotes: nil, approvalStatus: .approved, tags: ["neck", "posture", "cervical"], createdAt: Date(), updatedAt: Date()),
        Exercise(id: "NK_MOB_NECK_ROTATION", name: "Neck Rotations", videoAssetId: "NK_MOB_NECK_ROTATION", bodyRegion: .neck, muscleEmphasis: ["SCM", "levator scapulae"], category: .mobility, equipment: [.none], level: .beginner, cues: ["Turn head slowly side to side", "Keep shoulders relaxed", "Move through full range"], tempo: "slow", defaultPrescription: .init(sets: 2, reps: 10, rest: 0), modifications: [], exclusions: [], safetyNotes: nil, approvalStatus: .approved, tags: ["neck", "mobility", "warmup"], createdAt: Date(), updatedAt: Date()),
        Exercise(id: "NK_STR_ISOMETRIC_NECK", name: "Isometric Neck Strengthening", videoAssetId: "NK_STR_ISOMETRIC_NECK", bodyRegion: .neck, muscleEmphasis: ["neck extensors", "neck flexors"], category: .strengthening, equipment: [.none], level: .beginner, cues: ["Press head into hand", "Hold without moving", "Resist in all directions"], tempo: "hold 10s", defaultPrescription: .init(sets: 3, reps: 5, duration: 10, rest: 30), modifications: [], exclusions: [], safetyNotes: "Use gentle pressure", approvalStatus: .approved, tags: ["neck", "isometric", "strengthening"], createdAt: Date(), updatedAt: Date()),

        // SHOULDERS
        Exercise(id: "SH_MOB_SHOULDER_CIRCLES", name: "Shoulder Circles", videoAssetId: "SH_MOB_SHOULDER_CIRCLES", bodyRegion: .shoulders, muscleEmphasis: ["deltoids", "rotator cuff"], category: .mobility, equipment: [.none], level: .beginner, cues: ["Roll shoulders forward", "Then backward", "Full circles"], tempo: "slow", defaultPrescription: .init(sets: 2, reps: 15, rest: 0), modifications: [], exclusions: [], safetyNotes: nil, approvalStatus: .approved, tags: ["shoulder", "warmup", "mobility"], createdAt: Date(), updatedAt: Date()),
        Exercise(id: "SH_STR_BAND_PULL_APART", name: "Band Pull Apart", videoAssetId: "SH_STR_BAND_PULL_APART", bodyRegion: .shoulders, muscleEmphasis: ["rear deltoids", "rhomboids"], category: .strengthening, equipment: [.resistanceBand], level: .beginner, cues: ["Hold band at shoulder width", "Pull apart squeezing shoulder blades", "Control return"], tempo: "2-1-2", defaultPrescription: .init(sets: 3, reps: 15, rest: 30), modifications: ["Adjust band tension"], exclusions: [], safetyNotes: nil, approvalStatus: .approved, tags: ["shoulder", "band", "upper back"], createdAt: Date(), updatedAt: Date()),
        Exercise(id: "SH_MOB_WALL_SLIDES", name: "Wall Slides", videoAssetId: "SH_MOB_WALL_SLIDES", bodyRegion: .shoulders, muscleEmphasis: ["serratus anterior", "lower traps"], category: .mobility, equipment: [.none], level: .beginner, cues: ["Press back and arms into wall", "Slide arms up overhead", "Keep contact throughout"], tempo: "slow", defaultPrescription: .init(sets: 3, reps: 10, rest: 30), modifications: ["Start with foam roller"], exclusions: [], safetyNotes: nil, approvalStatus: .approved, tags: ["shoulder", "mobility", "posture"], createdAt: Date(), updatedAt: Date()),
        Exercise(id: "SH_STR_OVERHEAD_PRESS", name: "Dumbbell Overhead Press", videoAssetId: "SH_STR_OVERHEAD_PRESS", bodyRegion: .shoulders, muscleEmphasis: ["deltoids", "triceps"], category: .strengthening, equipment: [.dumbbells], level: .intermediate, cues: ["Press weights overhead", "Keep core tight", "Lower with control"], tempo: "2-0-2", defaultPrescription: .init(sets: 3, reps: 12, rest: 60), modifications: ["Seated version"], exclusions: ["shoulder impingement"], safetyNotes: "Don't overarch back", approvalStatus: .approved, tags: ["shoulder", "press", "strength"], createdAt: Date(), updatedAt: Date()),
        Exercise(id: "SH_MOB_SLEEPER_STRETCH", name: "Sleeper Stretch", videoAssetId: "SH_MOB_SLEEPER_STRETCH", bodyRegion: .shoulders, muscleEmphasis: ["posterior capsule", "infraspinatus"], category: .stretching, equipment: [.yogaMat], level: .beginner, cues: ["Lie on side", "Press wrist toward floor", "Hold gentle stretch"], tempo: "hold 30s", defaultPrescription: .init(sets: 2, reps: 3, duration: 30, rest: 0), modifications: [], exclusions: ["shoulder instability"], safetyNotes: "Gentle pressure only", approvalStatus: .approved, tags: ["shoulder", "stretch", "rotator cuff"], createdAt: Date(), updatedAt: Date()),
        Exercise(id: "SH_STR_LATERAL_RAISE", name: "Lateral Raise", videoAssetId: "SH_STR_LATERAL_RAISE", bodyRegion: .shoulders, muscleEmphasis: ["lateral deltoid"], category: .strengthening, equipment: [.dumbbells], level: .beginner, cues: ["Raise arms to sides", "Stop at shoulder height", "Control the descent"], tempo: "2-1-3", defaultPrescription: .init(sets: 3, reps: 12, rest: 45), modifications: ["Use light weights"], exclusions: [], safetyNotes: nil, approvalStatus: .approved, tags: ["shoulder", "deltoid", "isolation"], createdAt: Date(), updatedAt: Date()),
        Exercise(id: "SH_RHB_EXTERNAL_ROTATION", name: "External Rotation", videoAssetId: "SH_RHB_EXTERNAL_ROTATION", bodyRegion: .shoulders, muscleEmphasis: ["infraspinatus", "teres minor"], category: .rehab, equipment: [.resistanceBand], level: .beginner, cues: ["Keep elbow at side", "Rotate arm outward", "Control return"], tempo: "2-1-2", defaultPrescription: .rehab, modifications: ["Use towel under arm"], exclusions: [], safetyNotes: nil, approvalStatus: .approved, tags: ["shoulder", "rotator cuff", "rehab"], createdAt: Date(), updatedAt: Date()),

        // UPPER BACK
        Exercise(id: "UB_MOB_THREAD_THE_NEEDLE", name: "Thread the Needle", videoAssetId: "UB_MOB_THREAD_THE_NEEDLE", bodyRegion: .upperBack, muscleEmphasis: ["thoracic spine", "rhomboids"], category: .mobility, equipment: [.yogaMat], level: .beginner, cues: ["Start on hands and knees", "Thread arm under body", "Rotate and reach to ceiling"], tempo: "slow", defaultPrescription: .init(sets: 2, reps: 8, rest: 0), modifications: ["Place head on block if needed"], exclusions: [], safetyNotes: nil, approvalStatus: .approved, tags: ["thoracic", "rotation", "mobility"], createdAt: Date(), updatedAt: Date()),
        Exercise(id: "UB_STR_BENT_OVER_ROW", name: "Bent Over Row", videoAssetId: "UB_STR_BENT_OVER_ROW", bodyRegion: .upperBack, muscleEmphasis: ["lats", "rhomboids", "rear deltoids"], category: .strengthening, equipment: [.dumbbells], level: .intermediate, cues: ["Hinge at hips", "Pull elbows back", "Squeeze shoulder blades"], tempo: "2-1-2", defaultPrescription: .init(sets: 3, reps: 12, rest: 60), modifications: ["Single arm on bench"], exclusions: [], safetyNotes: "Keep spine neutral", approvalStatus: .approved, tags: ["back", "row", "strength"], createdAt: Date(), updatedAt: Date()),
        Exercise(id: "UB_MOB_THORACIC_EXTENSION", name: "Thoracic Extension", videoAssetId: "UB_MOB_THORACIC_EXTENSION", bodyRegion: .upperBack, muscleEmphasis: ["thoracic spine"], category: .mobility, equipment: [.foamRoller], level: .beginner, cues: ["Place roller under upper back", "Support head", "Extend over roller"], tempo: "slow", defaultPrescription: .init(sets: 2, reps: 10, rest: 0), modifications: ["Use rolled towel"], exclusions: [], safetyNotes: nil, approvalStatus: .approved, tags: ["thoracic", "extension", "mobility"], createdAt: Date(), updatedAt: Date()),
        Exercise(id: "UB_STR_FACE_PULL", name: "Face Pull", videoAssetId: "UB_STR_FACE_PULL", bodyRegion: .upperBack, muscleEmphasis: ["rear deltoids", "rhomboids", "external rotators"], category: .strengthening, equipment: [.resistanceBand], level: .beginner, cues: ["Pull toward face", "Spread hands apart at end", "Squeeze shoulder blades"], tempo: "2-1-2", defaultPrescription: .init(sets: 3, reps: 15, rest: 45), modifications: ["Use cable machine"], exclusions: [], safetyNotes: nil, approvalStatus: .approved, tags: ["upper back", "posture", "rotator cuff"], createdAt: Date(), updatedAt: Date()),
        Exercise(id: "UB_MOB_CAT_COW", name: "Cat-Cow Stretch", videoAssetId: "UB_MOB_CAT_COW", bodyRegion: .upperBack, muscleEmphasis: ["spine", "core"], category: .mobility, equipment: [.yogaMat], level: .beginner, cues: ["Inhale, arch spine", "Exhale, round spine", "Move slowly"], tempo: "breath", defaultPrescription: .init(sets: 1, reps: 10, rest: 0), modifications: [], exclusions: [], safetyNotes: nil, approvalStatus: .approved, tags: ["spine", "mobility", "warmup"], createdAt: Date(), updatedAt: Date()),

        // CHEST
        Exercise(id: "CH_STR_PUSH_UP", name: "Push-Up", videoAssetId: "CH_STR_PUSH_UP", bodyRegion: .chest, muscleEmphasis: ["pectorals", "triceps", "anterior deltoid"], category: .strengthening, equipment: [.none], level: .beginner, cues: ["Keep body in straight line", "Lower chest to floor", "Push back up"], tempo: "2-0-2", defaultPrescription: .init(sets: 3, reps: 10, rest: 60), modifications: ["Knees down", "Incline push-up"], exclusions: [], safetyNotes: "Don't flare elbows", approvalStatus: .approved, tags: ["chest", "push", "bodyweight"], createdAt: Date(), updatedAt: Date()),
        Exercise(id: "CH_STR_DUMBBELL_PRESS", name: "Dumbbell Chest Press", videoAssetId: "CH_STR_DUMBBELL_PRESS", bodyRegion: .chest, muscleEmphasis: ["pectorals", "triceps"], category: .strengthening, equipment: [.dumbbells, .bench], level: .intermediate, cues: ["Press weights up", "Lower to chest level", "Keep feet planted"], tempo: "2-1-2", defaultPrescription: .init(sets: 3, reps: 12, rest: 60), modifications: ["Floor press"], exclusions: [], safetyNotes: nil, approvalStatus: .approved, tags: ["chest", "press", "strength"], createdAt: Date(), updatedAt: Date()),
        Exercise(id: "CH_MOB_DOORWAY_STRETCH", name: "Doorway Chest Stretch", videoAssetId: "CH_MOB_DOORWAY_STRETCH", bodyRegion: .chest, muscleEmphasis: ["pectorals", "anterior deltoid"], category: .stretching, equipment: [.none], level: .beginner, cues: ["Place forearm on doorway", "Step through gently", "Feel stretch in chest"], tempo: "hold 30s", defaultPrescription: .init(sets: 2, reps: 3, duration: 30, rest: 0), modifications: [], exclusions: [], safetyNotes: nil, approvalStatus: .approved, tags: ["chest", "stretch", "posture"], createdAt: Date(), updatedAt: Date()),
        Exercise(id: "CH_STR_CABLE_FLY", name: "Cable Chest Fly", videoAssetId: "CH_STR_CABLE_FLY", bodyRegion: .chest, muscleEmphasis: ["pectorals"], category: .strengthening, equipment: [.cablesMachine], level: .intermediate, cues: ["Bring hands together", "Slight bend in elbows", "Squeeze chest"], tempo: "2-1-2", defaultPrescription: .init(sets: 3, reps: 12, rest: 45), modifications: ["Use bands"], exclusions: [], safetyNotes: nil, approvalStatus: .approved, tags: ["chest", "fly", "isolation"], createdAt: Date(), updatedAt: Date()),

        // ARMS
        Exercise(id: "AR_STR_BICEP_CURL", name: "Bicep Curl", videoAssetId: "AR_STR_BICEP_CURL", bodyRegion: .arms, muscleEmphasis: ["biceps brachii"], category: .strengthening, equipment: [.dumbbells], level: .beginner, cues: ["Keep elbows stationary", "Curl weight up", "Lower with control"], tempo: "2-0-2", defaultPrescription: .init(sets: 3, reps: 12, rest: 45), modifications: ["Hammer curl"], exclusions: [], safetyNotes: nil, approvalStatus: .approved, tags: ["arms", "biceps", "curl"], createdAt: Date(), updatedAt: Date()),
        Exercise(id: "AR_STR_TRICEP_EXTENSION", name: "Tricep Extension", videoAssetId: "AR_STR_TRICEP_EXTENSION", bodyRegion: .arms, muscleEmphasis: ["triceps"], category: .strengthening, equipment: [.dumbbells], level: .beginner, cues: ["Keep upper arm still", "Extend at elbow", "Control the negative"], tempo: "2-0-2", defaultPrescription: .init(sets: 3, reps: 12, rest: 45), modifications: ["Use band"], exclusions: [], safetyNotes: nil, approvalStatus: .approved, tags: ["arms", "triceps", "extension"], createdAt: Date(), updatedAt: Date()),
        Exercise(id: "AR_STR_HAMMER_CURL", name: "Hammer Curl", videoAssetId: "AR_STR_HAMMER_CURL", bodyRegion: .arms, muscleEmphasis: ["biceps", "brachialis"], category: .strengthening, equipment: [.dumbbells], level: .beginner, cues: ["Neutral grip", "Curl up", "Control descent"], tempo: "2-0-2", defaultPrescription: .init(sets: 3, reps: 12, rest: 45), modifications: [], exclusions: [], safetyNotes: nil, approvalStatus: .approved, tags: ["arms", "biceps", "hammer"], createdAt: Date(), updatedAt: Date()),
        Exercise(id: "AR_STR_TRICEP_DIP", name: "Tricep Dip", videoAssetId: "AR_STR_TRICEP_DIP", bodyRegion: .arms, muscleEmphasis: ["triceps", "chest"], category: .strengthening, equipment: [.bench], level: .intermediate, cues: ["Lower body down", "Keep elbows back", "Push up"], tempo: "2-0-2", defaultPrescription: .init(sets: 3, reps: 10, rest: 60), modifications: ["Bench dips"], exclusions: ["shoulder issues"], safetyNotes: "Don't go too deep", approvalStatus: .approved, tags: ["arms", "triceps", "dip"], createdAt: Date(), updatedAt: Date()),
        Exercise(id: "AR_MOB_WRIST_CIRCLES", name: "Wrist Circles", videoAssetId: "AR_MOB_WRIST_CIRCLES", bodyRegion: .arms, muscleEmphasis: ["forearm flexors", "extensors"], category: .mobility, equipment: [.none], level: .beginner, cues: ["Make circles with wrists", "Both directions", "Keep arms still"], tempo: "slow", defaultPrescription: .init(sets: 2, reps: 10, rest: 0), modifications: [], exclusions: [], safetyNotes: nil, approvalStatus: .approved, tags: ["wrist", "mobility", "warmup"], createdAt: Date(), updatedAt: Date()),

        // CORE
        Exercise(id: "CO_STR_PLANK", name: "Plank", videoAssetId: "CO_STR_PLANK", bodyRegion: .core, muscleEmphasis: ["rectus abdominis", "transverse abdominis"], category: .strengthening, equipment: [.yogaMat], level: .beginner, cues: ["Keep body in straight line", "Engage core", "Don't let hips sag"], tempo: "hold", defaultPrescription: .init(sets: 3, duration: 30, rest: 60), modifications: ["Knee plank"], exclusions: [], safetyNotes: nil, approvalStatus: .approved, tags: ["core", "plank", "stability"], createdAt: Date(), updatedAt: Date()),
        Exercise(id: "CO_STR_DEAD_BUG", name: "Dead Bug", videoAssetId: "CO_STR_DEAD_BUG", bodyRegion: .core, muscleEmphasis: ["deep core", "hip flexors"], category: .stability, equipment: [.yogaMat], level: .beginner, cues: ["Press low back into floor", "Move opposite arm and leg", "Keep core engaged"], tempo: "slow", defaultPrescription: .init(sets: 3, reps: 10, rest: 45), modifications: ["Just legs"], exclusions: [], safetyNotes: nil, approvalStatus: .approved, tags: ["core", "stability", "rehab"], createdAt: Date(), updatedAt: Date()),
        Exercise(id: "CO_STR_BIRD_DOG", name: "Bird Dog", videoAssetId: "CO_STR_BIRD_DOG", bodyRegion: .core, muscleEmphasis: ["core", "glutes", "erector spinae"], category: .stability, equipment: [.yogaMat], level: .beginner, cues: ["Extend opposite arm and leg", "Keep hips level", "Return with control"], tempo: "slow", defaultPrescription: .init(sets: 3, reps: 10, rest: 45), modifications: [], exclusions: [], safetyNotes: nil, approvalStatus: .approved, tags: ["core", "stability", "back"], createdAt: Date(), updatedAt: Date()),
        Exercise(id: "CO_STR_PALLOF_PRESS", name: "Pallof Press", videoAssetId: "CO_STR_PALLOF_PRESS", bodyRegion: .core, muscleEmphasis: ["obliques", "core stability"], category: .strengthening, equipment: [.resistanceBand], level: .intermediate, cues: ["Stand sideways to anchor", "Press band straight out", "Resist rotation"], tempo: "2-1-2", defaultPrescription: .init(sets: 3, reps: 10, rest: 45), modifications: ["Kneel"], exclusions: [], safetyNotes: nil, approvalStatus: .approved, tags: ["core", "anti-rotation", "stability"], createdAt: Date(), updatedAt: Date()),
        Exercise(id: "CO_STR_SIDE_PLANK", name: "Side Plank", videoAssetId: "CO_STR_SIDE_PLANK", bodyRegion: .core, muscleEmphasis: ["obliques", "quadratus lumborum"], category: .strengthening, equipment: [.yogaMat], level: .intermediate, cues: ["Stack feet or stagger", "Lift hips high", "Keep body straight"], tempo: "hold", defaultPrescription: .init(sets: 3, duration: 20, rest: 45), modifications: ["Knee down"], exclusions: [], safetyNotes: nil, approvalStatus: .approved, tags: ["core", "obliques", "stability"], createdAt: Date(), updatedAt: Date()),
        Exercise(id: "CO_STR_HOLLOW_BODY", name: "Hollow Body Hold", videoAssetId: "CO_STR_HOLLOW_BODY", bodyRegion: .core, muscleEmphasis: ["rectus abdominis", "hip flexors"], category: .strengthening, equipment: [.yogaMat], level: .intermediate, cues: ["Press low back into floor", "Lift legs and shoulders", "Hold position"], tempo: "hold", defaultPrescription: .init(sets: 3, duration: 20, rest: 45), modifications: ["Bend knees"], exclusions: [], safetyNotes: nil, approvalStatus: .approved, tags: ["core", "gymnastics", "strength"], createdAt: Date(), updatedAt: Date()),

        // LOWER BACK
        Exercise(id: "LB_MOB_CHILD_POSE", name: "Child's Pose", videoAssetId: "LB_MOB_CHILD_POSE", bodyRegion: .lowerBack, muscleEmphasis: ["erector spinae", "lats"], category: .stretching, equipment: [.yogaMat], level: .beginner, cues: ["Sit back on heels", "Reach arms forward", "Relax and breathe"], tempo: "hold", defaultPrescription: .init(sets: 1, duration: 60, rest: 0), modifications: ["Knees wide"], exclusions: [], safetyNotes: nil, approvalStatus: .approved, tags: ["back", "stretch", "relaxation"], createdAt: Date(), updatedAt: Date()),
        Exercise(id: "LB_STR_SUPERMAN", name: "Superman", videoAssetId: "LB_STR_SUPERMAN", bodyRegion: .lowerBack, muscleEmphasis: ["erector spinae", "glutes"], category: .strengthening, equipment: [.yogaMat], level: .beginner, cues: ["Lift arms and legs", "Squeeze glutes", "Hold briefly"], tempo: "2-1-2", defaultPrescription: .init(sets: 3, reps: 10, rest: 45), modifications: ["Alternate limbs"], exclusions: ["acute back pain"], safetyNotes: "Don't hyperextend", approvalStatus: .approved, tags: ["back", "extension", "strength"], createdAt: Date(), updatedAt: Date()),
        Exercise(id: "LB_MOB_PELVIC_TILT", name: "Pelvic Tilt", videoAssetId: "LB_MOB_PELVIC_TILT", bodyRegion: .lowerBack, muscleEmphasis: ["abdominals", "pelvic floor"], category: .mobility, equipment: [.yogaMat], level: .beginner, cues: ["Flatten low back to floor", "Tilt pelvis up", "Release and repeat"], tempo: "slow", defaultPrescription: .init(sets: 2, reps: 15, rest: 0), modifications: [], exclusions: [], safetyNotes: nil, approvalStatus: .approved, tags: ["back", "mobility", "pelvis"], createdAt: Date(), updatedAt: Date()),
        Exercise(id: "LB_RHB_KNEE_TO_CHEST", name: "Knee to Chest Stretch", videoAssetId: "LB_RHB_KNEE_TO_CHEST", bodyRegion: .lowerBack, muscleEmphasis: ["lower back", "glutes"], category: .stretching, equipment: [.yogaMat], level: .beginner, cues: ["Pull knee toward chest", "Keep other leg flat", "Hold and breathe"], tempo: "hold 30s", defaultPrescription: .init(sets: 2, reps: 2, duration: 30, rest: 0), modifications: ["Both knees"], exclusions: [], safetyNotes: nil, approvalStatus: .approved, tags: ["back", "stretch", "hip"], createdAt: Date(), updatedAt: Date()),

        // HIPS
        Exercise(id: "HP_MOB_9090_HIP_SWITCH", name: "90/90 Hip Switch", videoAssetId: "HP_MOB_9090_HIP_SWITCH", bodyRegion: .hips, muscleEmphasis: ["hip rotators", "glutes"], category: .mobility, equipment: [.yogaMat], level: .beginner, cues: ["Sit with legs in 90/90 position", "Switch sides smoothly", "Keep spine tall"], tempo: "controlled", defaultPrescription: .init(sets: 2, reps: 10, rest: 0), modifications: ["Sit on yoga block for elevation"], exclusions: ["hip replacement precautions"], safetyNotes: nil, approvalStatus: .approved, tags: ["hip", "rotation", "mobility"], createdAt: Date(), updatedAt: Date()),
        Exercise(id: "HP_STR_STANDING_HIPABAD", name: "Standing Hip Abduction", videoAssetId: "HP_STR_STANDING_HIPABAD", bodyRegion: .hips, muscleEmphasis: ["glute medius", "TFL"], category: .strengthening, equipment: [.none], level: .beginner, cues: ["Stand tall, hold wall if needed", "Lift leg to side", "Control the return"], tempo: "2-0-2", defaultPrescription: .init(sets: 3, reps: 12, rest: 30), modifications: ["Add band for resistance"], exclusions: [], safetyNotes: nil, approvalStatus: .approved, tags: ["hip", "glute", "abduction"], createdAt: Date(), updatedAt: Date()),
        Exercise(id: "HP_MOB_HIP_FLEXOR_STRETCH", name: "Hip Flexor Stretch", videoAssetId: "HP_MOB_HIP_FLEXOR_STRETCH", bodyRegion: .hips, muscleEmphasis: ["iliopsoas", "rectus femoris"], category: .stretching, equipment: [.yogaMat], level: .beginner, cues: ["Kneel on one knee", "Push hips forward", "Keep torso upright"], tempo: "hold 30s", defaultPrescription: .init(sets: 2, reps: 2, duration: 30, rest: 0), modifications: ["Use pad under knee"], exclusions: [], safetyNotes: nil, approvalStatus: .approved, tags: ["hip", "stretch", "flexor"], createdAt: Date(), updatedAt: Date()),
        Exercise(id: "HP_STR_CLAMSHELL", name: "Clamshell", videoAssetId: "HP_STR_CLAMSHELL", bodyRegion: .hips, muscleEmphasis: ["glute medius"], category: .strengthening, equipment: [.resistanceBand], level: .beginner, cues: ["Lie on side, knees bent", "Open top knee like clamshell", "Keep feet together"], tempo: "2-1-2", defaultPrescription: .init(sets: 3, reps: 15, rest: 30), modifications: ["No band"], exclusions: [], safetyNotes: nil, approvalStatus: .approved, tags: ["hip", "glute", "rehab"], createdAt: Date(), updatedAt: Date()),
        Exercise(id: "HP_MOB_PIGEON_POSE", name: "Pigeon Pose", videoAssetId: "HP_MOB_PIGEON_POSE", bodyRegion: .hips, muscleEmphasis: ["piriformis", "glutes"], category: .stretching, equipment: [.yogaMat], level: .intermediate, cues: ["Bring shin forward", "Square hips", "Fold forward"], tempo: "hold 60s", defaultPrescription: .init(sets: 2, reps: 1, duration: 60, rest: 0), modifications: ["Figure 4 lying down"], exclusions: ["knee issues"], safetyNotes: "Pad knee if needed", approvalStatus: .approved, tags: ["hip", "stretch", "piriformis"], createdAt: Date(), updatedAt: Date()),
        Exercise(id: "HP_STR_FIRE_HYDRANT", name: "Fire Hydrant", videoAssetId: "HP_STR_FIRE_HYDRANT", bodyRegion: .hips, muscleEmphasis: ["glute medius", "hip abductors"], category: .strengthening, equipment: [.yogaMat], level: .beginner, cues: ["On hands and knees", "Lift knee to side", "Keep hips stable"], tempo: "2-0-2", defaultPrescription: .init(sets: 3, reps: 12, rest: 30), modifications: ["Add band"], exclusions: [], safetyNotes: nil, approvalStatus: .approved, tags: ["hip", "glute", "stability"], createdAt: Date(), updatedAt: Date()),

        // GLUTES
        Exercise(id: "GL_STR_GLUTE_BRIDGE", name: "Glute Bridge", videoAssetId: "GL_STR_GLUTE_BRIDGE", bodyRegion: .glutes, muscleEmphasis: ["gluteus maximus", "hamstrings"], category: .strengthening, equipment: [.yogaMat], level: .beginner, cues: ["Press through heels", "Lift hips up", "Squeeze glutes at top"], tempo: "2-1-2", defaultPrescription: .init(sets: 3, reps: 15, rest: 45), modifications: ["Single leg"], exclusions: [], safetyNotes: nil, approvalStatus: .approved, tags: ["glutes", "bridge", "strength"], createdAt: Date(), updatedAt: Date()),
        Exercise(id: "GL_STR_HIP_THRUST", name: "Hip Thrust", videoAssetId: "GL_STR_HIP_THRUST", bodyRegion: .glutes, muscleEmphasis: ["gluteus maximus"], category: .strengthening, equipment: [.bench, .barbell], level: .intermediate, cues: ["Back against bench", "Drive through heels", "Squeeze at top"], tempo: "2-1-2", defaultPrescription: .init(sets: 3, reps: 12, rest: 60), modifications: ["Bodyweight only"], exclusions: [], safetyNotes: nil, approvalStatus: .approved, tags: ["glutes", "thrust", "strength"], createdAt: Date(), updatedAt: Date()),
        Exercise(id: "GL_STR_SINGLE_LEG_BRIDGE", name: "Single Leg Glute Bridge", videoAssetId: "GL_STR_SINGLE_LEG_BRIDGE", bodyRegion: .glutes, muscleEmphasis: ["gluteus maximus"], category: .strengthening, equipment: [.yogaMat], level: .intermediate, cues: ["Extend one leg", "Press through grounded heel", "Keep hips level"], tempo: "2-1-2", defaultPrescription: .init(sets: 3, reps: 10, rest: 45), modifications: [], exclusions: [], safetyNotes: nil, approvalStatus: .approved, tags: ["glutes", "unilateral", "strength"], createdAt: Date(), updatedAt: Date()),
        Exercise(id: "GL_STR_DONKEY_KICK", name: "Donkey Kick", videoAssetId: "GL_STR_DONKEY_KICK", bodyRegion: .glutes, muscleEmphasis: ["gluteus maximus"], category: .strengthening, equipment: [.yogaMat], level: .beginner, cues: ["On hands and knees", "Kick leg back and up", "Squeeze glute"], tempo: "2-1-2", defaultPrescription: .init(sets: 3, reps: 15, rest: 30), modifications: ["Add band"], exclusions: [], safetyNotes: nil, approvalStatus: .approved, tags: ["glutes", "kickback", "isolation"], createdAt: Date(), updatedAt: Date()),

        // QUADRICEPS
        Exercise(id: "QD_STR_SQUAT", name: "Squat", videoAssetId: "QD_STR_SQUAT", bodyRegion: .quadriceps, muscleEmphasis: ["quadriceps", "glutes"], category: .strengthening, equipment: [.none], level: .beginner, cues: ["Feet shoulder width", "Sit back and down", "Keep chest up"], tempo: "2-0-2", defaultPrescription: .init(sets: 3, reps: 15, rest: 60), modifications: ["Box squat"], exclusions: [], safetyNotes: "Knees track over toes", approvalStatus: .approved, tags: ["legs", "squat", "compound"], createdAt: Date(), updatedAt: Date()),
        Exercise(id: "QD_STR_GOBLET_SQUAT", name: "Goblet Squat", videoAssetId: "QD_STR_GOBLET_SQUAT", bodyRegion: .quadriceps, muscleEmphasis: ["quadriceps", "glutes", "core"], category: .strengthening, equipment: [.dumbbells], level: .beginner, cues: ["Hold weight at chest", "Squat deep", "Drive up through heels"], tempo: "2-0-2", defaultPrescription: .init(sets: 3, reps: 12, rest: 60), modifications: ["Bodyweight"], exclusions: [], safetyNotes: nil, approvalStatus: .approved, tags: ["legs", "squat", "goblet"], createdAt: Date(), updatedAt: Date()),
        Exercise(id: "QD_STR_LUNGE", name: "Forward Lunge", videoAssetId: "QD_STR_LUNGE", bodyRegion: .quadriceps, muscleEmphasis: ["quadriceps", "glutes"], category: .strengthening, equipment: [.none], level: .beginner, cues: ["Step forward", "Lower until both knees at 90°", "Push back to start"], tempo: "2-0-2", defaultPrescription: .init(sets: 3, reps: 12, rest: 60), modifications: ["Reverse lunge"], exclusions: [], safetyNotes: "Don't let knee pass toes", approvalStatus: .approved, tags: ["legs", "lunge", "unilateral"], createdAt: Date(), updatedAt: Date()),
        Exercise(id: "QD_MOB_QUAD_STRETCH", name: "Standing Quad Stretch", videoAssetId: "QD_MOB_QUAD_STRETCH", bodyRegion: .quadriceps, muscleEmphasis: ["quadriceps"], category: .stretching, equipment: [.none], level: .beginner, cues: ["Pull heel to glute", "Keep knees together", "Stand tall"], tempo: "hold 30s", defaultPrescription: .init(sets: 2, reps: 2, duration: 30, rest: 0), modifications: ["Hold wall"], exclusions: [], safetyNotes: nil, approvalStatus: .approved, tags: ["quad", "stretch", "standing"], createdAt: Date(), updatedAt: Date()),
        Exercise(id: "QD_STR_STEP_UP", name: "Step Up", videoAssetId: "QD_STR_STEP_UP", bodyRegion: .quadriceps, muscleEmphasis: ["quadriceps", "glutes"], category: .strengthening, equipment: [.box], level: .beginner, cues: ["Step onto box", "Drive through heel", "Control descent"], tempo: "2-0-2", defaultPrescription: .init(sets: 3, reps: 10, rest: 45), modifications: ["Lower box"], exclusions: [], safetyNotes: nil, approvalStatus: .approved, tags: ["legs", "step", "unilateral"], createdAt: Date(), updatedAt: Date()),

        // HAMSTRINGS
        Exercise(id: "HM_STR_ROMANIAN_DEADLIFT", name: "Romanian Deadlift", videoAssetId: "HM_STR_ROMANIAN_DEADLIFT", bodyRegion: .hamstrings, muscleEmphasis: ["hamstrings", "glutes", "erector spinae"], category: .strengthening, equipment: [.dumbbells], level: .intermediate, cues: ["Hinge at hips", "Keep back flat", "Feel stretch in hamstrings"], tempo: "3-0-2", defaultPrescription: .init(sets: 3, reps: 10, rest: 60), modifications: ["Single leg"], exclusions: [], safetyNotes: "Keep back neutral", approvalStatus: .approved, tags: ["hamstrings", "hinge", "strength"], createdAt: Date(), updatedAt: Date()),
        Exercise(id: "HM_MOB_HAMSTRING_STRETCH", name: "Standing Hamstring Stretch", videoAssetId: "HM_MOB_HAMSTRING_STRETCH", bodyRegion: .hamstrings, muscleEmphasis: ["hamstrings"], category: .stretching, equipment: [.none], level: .beginner, cues: ["Place heel on surface", "Hinge forward", "Keep leg straight"], tempo: "hold 30s", defaultPrescription: .init(sets: 2, reps: 2, duration: 30, rest: 0), modifications: ["Lying down"], exclusions: [], safetyNotes: nil, approvalStatus: .approved, tags: ["hamstrings", "stretch"], createdAt: Date(), updatedAt: Date()),
        Exercise(id: "HM_STR_NORDIC_CURL", name: "Nordic Hamstring Curl", videoAssetId: "HM_STR_NORDIC_CURL", bodyRegion: .hamstrings, muscleEmphasis: ["hamstrings"], category: .strengthening, equipment: [.none], level: .advanced, cues: ["Kneel with feet anchored", "Lower body forward slowly", "Use hands to push back"], tempo: "3-0-1", defaultPrescription: .init(sets: 3, reps: 5, rest: 90), modifications: ["Use band assist"], exclusions: [], safetyNotes: "Eccentric focus", approvalStatus: .approved, tags: ["hamstrings", "nordic", "eccentric"], createdAt: Date(), updatedAt: Date()),
        Exercise(id: "HM_STR_LEG_CURL", name: "Lying Leg Curl", videoAssetId: "HM_STR_LEG_CURL", bodyRegion: .hamstrings, muscleEmphasis: ["hamstrings"], category: .strengthening, equipment: [.cablesMachine], level: .beginner, cues: ["Curl heels toward glutes", "Control the descent", "Don't lift hips"], tempo: "2-1-2", defaultPrescription: .init(sets: 3, reps: 12, rest: 45), modifications: ["Stability ball"], exclusions: [], safetyNotes: nil, approvalStatus: .approved, tags: ["hamstrings", "curl", "isolation"], createdAt: Date(), updatedAt: Date()),

        // KNEES
        Exercise(id: "KN_RHB_TERMINAL_KNEE_EXT", name: "Terminal Knee Extension", videoAssetId: "KN_RHB_TERMINAL_KNEE_EXT", bodyRegion: .knees, muscleEmphasis: ["VMO", "quadriceps"], category: .rehab, equipment: [.resistanceBand], level: .beginner, cues: ["Band behind knee", "Straighten knee fully", "Squeeze quad"], tempo: "2-1-2", defaultPrescription: .rehab, modifications: [], exclusions: [], safetyNotes: nil, approvalStatus: .approved, tags: ["knee", "VMO", "rehab"], createdAt: Date(), updatedAt: Date()),
        Exercise(id: "KN_STR_WALL_SIT", name: "Wall Sit", videoAssetId: "KN_STR_WALL_SIT", bodyRegion: .knees, muscleEmphasis: ["quadriceps"], category: .strengthening, equipment: [.none], level: .beginner, cues: ["Back against wall", "Thighs parallel to floor", "Hold position"], tempo: "hold", defaultPrescription: .init(sets: 3, duration: 30, rest: 60), modifications: ["Higher position"], exclusions: [], safetyNotes: nil, approvalStatus: .approved, tags: ["knee", "quad", "isometric"], createdAt: Date(), updatedAt: Date()),
        Exercise(id: "KN_RHB_STRAIGHT_LEG_RAISE", name: "Straight Leg Raise", videoAssetId: "KN_RHB_STRAIGHT_LEG_RAISE", bodyRegion: .knees, muscleEmphasis: ["quadriceps", "hip flexors"], category: .rehab, equipment: [.yogaMat], level: .beginner, cues: ["Lie on back", "Tighten quad", "Lift leg straight up"], tempo: "2-0-2", defaultPrescription: .rehab, modifications: [], exclusions: [], safetyNotes: nil, approvalStatus: .approved, tags: ["knee", "quad", "rehab"], createdAt: Date(), updatedAt: Date()),

        // CALVES
        Exercise(id: "CA_RHB_ECCENTRIC_CALF_DROP", name: "Eccentric Calf Drops", videoAssetId: "CA_RHB_ECCENTRIC_CALF_DROP", bodyRegion: .calves, muscleEmphasis: ["gastrocnemius", "soleus"], category: .rehab, equipment: [.none], level: .beginner, cues: ["Rise up on toes", "Slowly lower heels below step", "Control the descent 3-5 seconds"], tempo: "3-1-0", defaultPrescription: .rehab, modifications: ["Use wall for balance"], exclusions: ["acute Achilles rupture"], safetyNotes: "Stop if sharp pain", approvalStatus: .approved, tags: ["calf", "eccentric", "rehab", "plantar"], createdAt: Date(), updatedAt: Date()),
        Exercise(id: "CA_STR_CALF_RAISE", name: "Standing Calf Raise", videoAssetId: "CA_STR_CALF_RAISE", bodyRegion: .calves, muscleEmphasis: ["gastrocnemius"], category: .strengthening, equipment: [.none], level: .beginner, cues: ["Rise up on toes", "Pause at top", "Lower with control"], tempo: "2-1-2", defaultPrescription: .init(sets: 3, reps: 15, rest: 45), modifications: ["Single leg"], exclusions: [], safetyNotes: nil, approvalStatus: .approved, tags: ["calf", "raise", "strength"], createdAt: Date(), updatedAt: Date()),
        Exercise(id: "CA_MOB_CALF_STRETCH", name: "Calf Stretch", videoAssetId: "CA_MOB_CALF_STRETCH", bodyRegion: .calves, muscleEmphasis: ["gastrocnemius", "soleus"], category: .stretching, equipment: [.none], level: .beginner, cues: ["Step back", "Keep heel down", "Lean into wall"], tempo: "hold 30s", defaultPrescription: .init(sets: 2, reps: 2, duration: 30, rest: 0), modifications: ["Bent knee for soleus"], exclusions: [], safetyNotes: nil, approvalStatus: .approved, tags: ["calf", "stretch"], createdAt: Date(), updatedAt: Date()),

        // ANKLES
        Exercise(id: "AN_MOB_ANKLE_CIRCLES", name: "Ankle Circles", videoAssetId: "AN_MOB_ANKLE_CIRCLES", bodyRegion: .ankles, muscleEmphasis: ["ankle joint"], category: .mobility, equipment: [.none], level: .beginner, cues: ["Circle ankle clockwise", "Then counterclockwise", "Full range of motion"], tempo: "slow", defaultPrescription: .init(sets: 2, reps: 10, rest: 0), modifications: [], exclusions: [], safetyNotes: nil, approvalStatus: .approved, tags: ["ankle", "mobility", "warmup"], createdAt: Date(), updatedAt: Date()),
        Exercise(id: "AN_MOB_ANKLE_DORSIFLEXION", name: "Ankle Dorsiflexion Stretch", videoAssetId: "AN_MOB_ANKLE_DORSIFLEXION", bodyRegion: .ankles, muscleEmphasis: ["ankle", "calf"], category: .mobility, equipment: [.none], level: .beginner, cues: ["Knee over toes", "Drive knee forward", "Keep heel down"], tempo: "hold", defaultPrescription: .init(sets: 2, reps: 10, duration: 5, rest: 0), modifications: [], exclusions: [], safetyNotes: nil, approvalStatus: .approved, tags: ["ankle", "mobility", "dorsiflexion"], createdAt: Date(), updatedAt: Date()),
        Exercise(id: "AN_STR_SINGLE_LEG_BALANCE", name: "Single Leg Balance", videoAssetId: "AN_STR_SINGLE_LEG_BALANCE", bodyRegion: .ankles, muscleEmphasis: ["ankle stabilizers"], category: .stability, equipment: [.none], level: .beginner, cues: ["Stand on one leg", "Maintain balance", "Progress to eyes closed"], tempo: "hold 30s", defaultPrescription: .init(sets: 3, duration: 30, rest: 30), modifications: ["Touch wall"], exclusions: [], safetyNotes: nil, approvalStatus: .approved, tags: ["ankle", "balance", "stability"], createdAt: Date(), updatedAt: Date()),

        // FEET
        Exercise(id: "FT_MOB_TOE_YOGA", name: "Toe Yoga", videoAssetId: "FT_MOB_TOE_YOGA", bodyRegion: .feet, muscleEmphasis: ["intrinsic foot muscles"], category: .mobility, equipment: [.none], level: .beginner, cues: ["Lift big toe, keep others down", "Then reverse", "Spread toes"], tempo: "slow", defaultPrescription: .init(sets: 2, reps: 10, rest: 0), modifications: [], exclusions: [], safetyNotes: nil, approvalStatus: .approved, tags: ["feet", "toes", "mobility"], createdAt: Date(), updatedAt: Date()),
        Exercise(id: "FT_RHB_PLANTAR_FASCIA_ROLL", name: "Plantar Fascia Roll", videoAssetId: "FT_RHB_PLANTAR_FASCIA_ROLL", bodyRegion: .feet, muscleEmphasis: ["plantar fascia"], category: .rehab, equipment: [.none], level: .beginner, cues: ["Roll ball under foot", "Apply moderate pressure", "Cover entire arch"], tempo: "slow", defaultPrescription: .init(sets: 1, duration: 60, rest: 0), modifications: ["Use frozen water bottle"], exclusions: [], safetyNotes: nil, approvalStatus: .approved, tags: ["feet", "plantar", "release"], createdAt: Date(), updatedAt: Date()),
        Exercise(id: "FT_STR_SHORT_FOOT", name: "Short Foot Exercise", videoAssetId: "FT_STR_SHORT_FOOT", bodyRegion: .feet, muscleEmphasis: ["arch muscles"], category: .strengthening, equipment: [.none], level: .beginner, cues: ["Draw arch up", "Don't curl toes", "Hold 5 seconds"], tempo: "hold", defaultPrescription: .init(sets: 3, reps: 10, duration: 5, rest: 30), modifications: [], exclusions: [], safetyNotes: nil, approvalStatus: .approved, tags: ["feet", "arch", "strength"], createdAt: Date(), updatedAt: Date()),

        // FULL BODY
        Exercise(id: "FB_CAR_BURPEE", name: "Burpee", videoAssetId: "FB_CAR_BURPEE", bodyRegion: .fullBody, muscleEmphasis: ["full body"], category: .cardio, equipment: [.none], level: .intermediate, cues: ["Squat down", "Jump back to plank", "Jump forward and up"], tempo: "fast", defaultPrescription: .init(sets: 3, reps: 10, rest: 60), modifications: ["Step back"], exclusions: [], safetyNotes: nil, approvalStatus: .approved, tags: ["cardio", "full body", "explosive"], createdAt: Date(), updatedAt: Date()),
        Exercise(id: "FB_STR_DEADLIFT", name: "Deadlift", videoAssetId: "FB_STR_DEADLIFT", bodyRegion: .fullBody, muscleEmphasis: ["glutes", "hamstrings", "back"], category: .strengthening, equipment: [.barbell], level: .intermediate, cues: ["Hinge at hips", "Keep bar close", "Drive through floor"], tempo: "2-0-2", defaultPrescription: .init(sets: 3, reps: 8, rest: 90), modifications: ["Dumbbell deadlift"], exclusions: ["back injury"], safetyNotes: "Keep back neutral", approvalStatus: .approved, tags: ["strength", "compound", "posterior chain"], createdAt: Date(), updatedAt: Date()),
        Exercise(id: "FB_WRM_JUMPING_JACK", name: "Jumping Jacks", videoAssetId: "FB_WRM_JUMPING_JACK", bodyRegion: .fullBody, muscleEmphasis: ["full body"], category: .warmUp, equipment: [.none], level: .beginner, cues: ["Jump feet out", "Arms overhead", "Return to start"], tempo: "fast", defaultPrescription: .init(sets: 2, reps: 20, rest: 30), modifications: ["Step out"], exclusions: [], safetyNotes: nil, approvalStatus: .approved, tags: ["warmup", "cardio", "full body"], createdAt: Date(), updatedAt: Date()),
        Exercise(id: "FB_STR_KETTLEBELL_SWING", name: "Kettlebell Swing", videoAssetId: "FB_STR_KETTLEBELL_SWING", bodyRegion: .fullBody, muscleEmphasis: ["glutes", "hamstrings", "core"], category: .power, equipment: [.kettlebell], level: .intermediate, cues: ["Hinge and swing back", "Drive hips forward", "Float at top"], tempo: "explosive", defaultPrescription: .init(sets: 3, reps: 15, rest: 60), modifications: ["Deadlift to practice hinge"], exclusions: [], safetyNotes: "Don't use back", approvalStatus: .approved, tags: ["power", "kettlebell", "hinge"], createdAt: Date(), updatedAt: Date()),
        Exercise(id: "FB_CAR_MOUNTAIN_CLIMBER", name: "Mountain Climbers", videoAssetId: "FB_CAR_MOUNTAIN_CLIMBER", bodyRegion: .fullBody, muscleEmphasis: ["core", "shoulders", "hip flexors"], category: .cardio, equipment: [.none], level: .beginner, cues: ["Start in plank", "Drive knees to chest", "Keep hips low"], tempo: "fast", defaultPrescription: .init(sets: 3, reps: 20, rest: 45), modifications: ["Slower pace"], exclusions: [], safetyNotes: nil, approvalStatus: .approved, tags: ["cardio", "core", "bodyweight"], createdAt: Date(), updatedAt: Date()),
        Exercise(id: "FB_PWR_BOX_JUMP", name: "Box Jump", videoAssetId: "FB_PWR_BOX_JUMP", bodyRegion: .fullBody, muscleEmphasis: ["legs", "glutes"], category: .power, equipment: [.box], level: .intermediate, cues: ["Swing arms back", "Explode up", "Land softly"], tempo: "explosive", defaultPrescription: .init(sets: 3, reps: 8, rest: 60), modifications: ["Step up"], exclusions: [], safetyNotes: "Start low", approvalStatus: .approved, tags: ["power", "plyometric", "legs"], createdAt: Date(), updatedAt: Date()),

        // SPORT SPECIFIC - GOLF
        Exercise(id: "SP_GOL_CABLE_SWING", name: "Cable Golf Swing", videoAssetId: "SP_GOL_CABLE_SWING", bodyRegion: .fullBody, muscleEmphasis: ["obliques", "lats", "glutes"], category: .sport, equipment: [.cablesMachine], level: .intermediate, cues: ["Mimic golf swing", "Rotate through hips", "Control cable"], tempo: "explosive", defaultPrescription: .init(sets: 3, reps: 10, rest: 60), modifications: ["Use band"], exclusions: [], safetyNotes: nil, approvalStatus: .approved, tags: ["golf", "rotation", "sport"], createdAt: Date(), updatedAt: Date()),
        Exercise(id: "SP_GOL_MED_BALL_RELEASE", name: "Lateral Med Ball Release", videoAssetId: "SP_GOL_MED_BALL_RELEASE", bodyRegion: .fullBody, muscleEmphasis: ["obliques", "hips"], category: .power, equipment: [.medicineBall], level: .intermediate, cues: ["Rotate and throw", "Release at peak", "Follow through"], tempo: "explosive", defaultPrescription: .init(sets: 3, reps: 8, rest: 60), modifications: ["Lighter ball"], exclusions: [], safetyNotes: nil, approvalStatus: .approved, tags: ["golf", "power", "rotation"], createdAt: Date(), updatedAt: Date()),
        Exercise(id: "SP_GOL_SWITCH_ROW", name: "Golfer Switch Row", videoAssetId: "SP_GOL_SWITCH_ROW", bodyRegion: .upperBack, muscleEmphasis: ["lats", "rhomboids", "core"], category: .sport, equipment: [.cablesMachine], level: .intermediate, cues: ["Pull and rotate", "Switch sides fluidly", "Engage core"], tempo: "controlled", defaultPrescription: .init(sets: 3, reps: 12, rest: 45), modifications: ["Use band"], exclusions: [], safetyNotes: nil, approvalStatus: .approved, tags: ["golf", "row", "rotation"], createdAt: Date(), updatedAt: Date()),

        // SPORT SPECIFIC - RUNNING
        Exercise(id: "SP_RUN_A_SKIP", name: "A-Skip", videoAssetId: "SP_RUN_A_SKIP", bodyRegion: .fullBody, muscleEmphasis: ["hip flexors", "calves"], category: .warmUp, equipment: [.none], level: .beginner, cues: ["High knee skip", "Drive knee up", "Quick ground contact"], tempo: "fast", defaultPrescription: .init(sets: 2, reps: 20, rest: 30), modifications: [], exclusions: [], safetyNotes: nil, approvalStatus: .approved, tags: ["running", "drills", "warmup"], createdAt: Date(), updatedAt: Date()),
        Exercise(id: "SP_RUN_HIGH_KNEES", name: "High Knees", videoAssetId: "SP_RUN_HIGH_KNEES", bodyRegion: .fullBody, muscleEmphasis: ["hip flexors", "core"], category: .warmUp, equipment: [.none], level: .beginner, cues: ["Drive knees up fast", "Stay on toes", "Pump arms"], tempo: "fast", defaultPrescription: .init(sets: 3, reps: 20, rest: 30), modifications: ["March in place"], exclusions: [], safetyNotes: nil, approvalStatus: .approved, tags: ["running", "warmup", "cardio"], createdAt: Date(), updatedAt: Date()),
        Exercise(id: "SP_RUN_BUTT_KICKS", name: "Butt Kicks", videoAssetId: "SP_RUN_BUTT_KICKS", bodyRegion: .hamstrings, muscleEmphasis: ["hamstrings"], category: .warmUp, equipment: [.none], level: .beginner, cues: ["Kick heels to glutes", "Stay upright", "Quick rhythm"], tempo: "fast", defaultPrescription: .init(sets: 3, reps: 20, rest: 30), modifications: [], exclusions: [], safetyNotes: nil, approvalStatus: .approved, tags: ["running", "warmup", "hamstrings"], createdAt: Date(), updatedAt: Date()),

        // COOL DOWN
        Exercise(id: "CD_STR_FORWARD_FOLD", name: "Standing Forward Fold", videoAssetId: "CD_STR_FORWARD_FOLD", bodyRegion: .hamstrings, muscleEmphasis: ["hamstrings", "spine"], category: .coolDown, equipment: [.none], level: .beginner, cues: ["Fold from hips", "Let head hang", "Relax and breathe"], tempo: "hold 30s", defaultPrescription: .init(sets: 1, duration: 30, rest: 0), modifications: ["Bend knees"], exclusions: [], safetyNotes: nil, approvalStatus: .approved, tags: ["cooldown", "stretch", "hamstrings"], createdAt: Date(), updatedAt: Date()),
        Exercise(id: "CD_STR_SUPINE_TWIST", name: "Supine Spinal Twist", videoAssetId: "CD_STR_SUPINE_TWIST", bodyRegion: .lowerBack, muscleEmphasis: ["spine", "obliques"], category: .coolDown, equipment: [.yogaMat], level: .beginner, cues: ["Lie on back", "Drop knees to side", "Keep shoulders down"], tempo: "hold 30s", defaultPrescription: .init(sets: 1, reps: 2, duration: 30, rest: 0), modifications: [], exclusions: [], safetyNotes: nil, approvalStatus: .approved, tags: ["cooldown", "stretch", "spine"], createdAt: Date(), updatedAt: Date()),
        Exercise(id: "CD_STR_CORPSE_POSE", name: "Corpse Pose (Savasana)", videoAssetId: "CD_STR_CORPSE_POSE", bodyRegion: .fullBody, muscleEmphasis: ["full body relaxation"], category: .coolDown, equipment: [.yogaMat], level: .beginner, cues: ["Lie flat on back", "Arms at sides", "Close eyes, breathe"], tempo: "hold", defaultPrescription: .init(sets: 1, duration: 120, rest: 0), modifications: ["Bolster under knees"], exclusions: [], safetyNotes: nil, approvalStatus: .approved, tags: ["cooldown", "relaxation", "breathing"], createdAt: Date(), updatedAt: Date())
    ]
}
