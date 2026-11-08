import Foundation

// MARK: - Library System
// 5 types of saved items: saved workouts (50), built workouts (50),
// pinned programs (12), assigned programs (12), favorites (500)

// MARK: - Library Item Kind

enum LibraryItemKind: String, Codable, CaseIterable {
    case saved          // Saved generated workout (max 50) - earns 30 XP
    case custom         // Built workout (max 50) - earns 35 XP
    case pinned         // Pinned content program (max 12) - earns 50 XP
    case assigned       // Admin-assigned program (max 12) - earns 50 XP
    case favorite       // Favorite video (max 500) - earns 2 XP action
}

// MARK: - Library Item

struct LibraryItem: Identifiable, Codable {
    let id: String
    let clientId: String
    let kind: LibraryItemKind
    let ref: String  // Reference ID (program, video, or workout)
    let name: String
    let body: LibraryItemBody?
    let sourceProgramId: String?  // If saved from a content program
    let createdAt: Date
    let assignedBy: String?  // Admin ID if assigned
    let noteEncrypted: String?  // Encrypted note from admin
}

struct LibraryItemBody: Codable {
    let title: String
    let goal: String?
    let location: String?
    let level: String?
    let circuit: [LibraryCircuitItem]?
}

struct LibraryCircuitItem: Codable {
    let exerciseId: String
    let sets: Int
    let reps: Int?
    let seconds: Int?
}

// MARK: - Library Limits

struct LibraryLimits {
    static let savedWorkouts = 50
    static let customWorkouts = 50
    static let pinnedPrograms = 12
    static let assignedPrograms = 12
    static let favorites = 500
}

// MARK: - Content Programs (23 built-in)

struct ContentProgram: Identifiable, Codable {
    let id: String
    let title: String
    let category: ProgramCategory
    let level: DifficultyLevel
    let location: String?
    let weeks: Int
    let seed: Int?  // For deterministic generation
    let access: String  // "free", "member", "premium"
    let summary: String
    let notes: String?
    let image: String?
    let sport: String?
    let days: [ContentProgramDay]
    let resources: [String]?  // Additional resource URLs
    let hasProtocolSheet: Bool  // 17 of 23 have week-by-week protocol sheets
}

struct ContentProgramDay: Identifiable, Codable {
    let id: String
    let name: String
    let goal: String?
    let length: Int?  // minutes
    let rounds: Int?
    let restEx: Int?  // Rest between exercises
    let restRound: Int?  // Rest between rounds
    let circuit: [ContentCircuitItem]?  // Fixed circuit, or nil to generate
    let seedOffset: Int?  // For generation: seed + seedOffset + i×101
}

struct ContentCircuitItem: Codable {
    let exerciseId: String
    let sets: Int
}

// MARK: - Built-in Programs (23 total)

extension ContentProgram {
    static let builtInPrograms: [ContentProgram] = [
        // REHAB PROTOCOLS
        ContentProgram(
            id: "shoulder-release",
            title: "Shoulder Release Protocol",
            category: .shoulderRelease,
            level: .beginner,
            location: "home",
            weeks: 4,
            seed: 1001,
            access: "member",
            summary: "Targeted release work for shoulder tension and mobility",
            notes: nil,
            image: nil,
            sport: nil,
            days: [],
            resources: nil,
            hasProtocolSheet: true
        ),
        ContentProgram(
            id: "plantar-fascia",
            title: "Plantar Fascia Recovery",
            category: .plantarFascia,
            level: .beginner,
            location: "home",
            weeks: 6,
            seed: 1002,
            access: "member",
            summary: "Relieve plantar fasciitis with progressive mobility and strengthening",
            notes: nil,
            image: nil,
            sport: nil,
            days: [],
            resources: nil,
            hasProtocolSheet: true
        ),
        ContentProgram(
            id: "lower-back-si",
            title: "Lower Back & SI Joint",
            category: .lowerBackSI,
            level: .beginner,
            location: "home",
            weeks: 6,
            seed: 1003,
            access: "member",
            summary: "Address lower back pain and SI joint dysfunction",
            notes: nil,
            image: nil,
            sport: nil,
            days: [],
            resources: nil,
            hasProtocolSheet: true
        ),
        ContentProgram(
            id: "knee-rehab",
            title: "Knee Rehabilitation",
            category: .general,
            level: .beginner,
            location: "home",
            weeks: 8,
            seed: 1004,
            access: "member",
            summary: "Progressive knee strengthening and mobility",
            notes: nil,
            image: nil,
            sport: nil,
            days: [],
            resources: nil,
            hasProtocolSheet: true
        ),
        ContentProgram(
            id: "hip-mobility",
            title: "Hip Mobility Protocol",
            category: .mobility,
            level: .beginner,
            location: "home",
            weeks: 4,
            seed: 1005,
            access: "member",
            summary: "Unlock hip mobility and reduce tightness",
            notes: nil,
            image: nil,
            sport: nil,
            days: [],
            resources: nil,
            hasProtocolSheet: true
        ),

        // SPORT-SPECIFIC
        ContentProgram(
            id: "golf-rotational",
            title: "Golf: Rotational Power",
            category: .golf,
            level: .intermediate,
            location: "gym",
            weeks: 8,
            seed: 2001,
            access: "member",
            summary: "Develop explosive rotational power for a more powerful swing",
            notes: "Cable swing, lateral med-ball release, Golfer Switch Row, reactive jump-lunge",
            image: nil,
            sport: "golf",
            days: [],
            resources: nil,
            hasProtocolSheet: true
        ),
        ContentProgram(
            id: "golf-mobility",
            title: "Golf: Mobility & Flexibility",
            category: .golf,
            level: .beginner,
            location: "home",
            weeks: 6,
            seed: 2002,
            access: "member",
            summary: "Improve range of motion for a better golf swing",
            notes: nil,
            image: nil,
            sport: "golf",
            days: [],
            resources: nil,
            hasProtocolSheet: true
        ),
        ContentProgram(
            id: "pickleball-performance",
            title: "Pickleball Performance",
            category: .pickleball,
            level: .intermediate,
            location: "gym",
            weeks: 6,
            seed: 2003,
            access: "member",
            summary: "Sport-specific conditioning for pickleball players",
            notes: "Tied to 51-item filming checklist",
            image: nil,
            sport: "pickleball",
            days: [],
            resources: nil,
            hasProtocolSheet: true
        ),
        ContentProgram(
            id: "running-beginner",
            title: "Running: Beginner 8-Week",
            category: .running,
            level: .beginner,
            location: "outdoor",
            weeks: 8,
            seed: 2004,
            access: "member",
            summary: "Build proper running mechanics from the ground up",
            notes: "Midfoot landing, glute activation, trunk rotation, shoulders down, slight forward lean",
            image: nil,
            sport: "running",
            days: [],
            resources: nil,
            hasProtocolSheet: true
        ),
        ContentProgram(
            id: "running-advanced",
            title: "Running: Advanced 8-Week",
            category: .running,
            level: .advanced,
            location: "outdoor",
            weeks: 8,
            seed: 2005,
            access: "member",
            summary: "Advanced running mechanics and performance",
            notes: nil,
            image: nil,
            sport: "running",
            days: [],
            resources: nil,
            hasProtocolSheet: true
        ),
        ContentProgram(
            id: "ski-beginner",
            title: "Ski: Beginner Prep",
            category: .ski,
            level: .beginner,
            location: "gym",
            weeks: 6,
            seed: 2006,
            access: "member",
            summary: "Get ready for ski season with foundational strength",
            notes: nil,
            image: nil,
            sport: "ski",
            days: [],
            resources: nil,
            hasProtocolSheet: true
        ),
        ContentProgram(
            id: "ski-intermediate",
            title: "Ski: Intermediate Conditioning",
            category: .ski,
            level: .intermediate,
            location: "gym",
            weeks: 6,
            seed: 2007,
            access: "member",
            summary: "Build ski-specific strength and endurance",
            notes: nil,
            image: nil,
            sport: "ski",
            days: [],
            resources: nil,
            hasProtocolSheet: true
        ),
        ContentProgram(
            id: "ski-advanced",
            title: "Ski: Advanced 8-Week",
            category: .ski,
            level: .advanced,
            location: "gym",
            weeks: 8,
            seed: 2008,
            access: "member",
            summary: "Elite ski conditioning with Mon/Wed/Fri prescriptions",
            notes: nil,
            image: nil,
            sport: "ski",
            days: [],
            resources: nil,
            hasProtocolSheet: true
        ),

        // GENERAL FITNESS
        ContentProgram(
            id: "mobility-daily",
            title: "Daily Mobility",
            category: .mobility,
            level: .beginner,
            location: "home",
            weeks: 4,
            seed: 3001,
            access: "free",
            summary: "Daily mobility routine for better movement quality",
            notes: nil,
            image: nil,
            sport: nil,
            days: [],
            resources: nil,
            hasProtocolSheet: false
        ),
        ContentProgram(
            id: "strength-foundations",
            title: "Strength Foundations",
            category: .strength,
            level: .beginner,
            location: "gym",
            weeks: 8,
            seed: 3002,
            access: "member",
            summary: "Build a solid strength foundation",
            notes: nil,
            image: nil,
            sport: nil,
            days: [],
            resources: nil,
            hasProtocolSheet: true
        ),
        ContentProgram(
            id: "strength-hypertrophy",
            title: "Hypertrophy Program",
            category: .strength,
            level: .intermediate,
            location: "gym",
            weeks: 12,
            seed: 3003,
            access: "member",
            summary: "Build muscle with progressive overload",
            notes: nil,
            image: nil,
            sport: nil,
            days: [],
            resources: nil,
            hasProtocolSheet: true
        ),
        ContentProgram(
            id: "weight-loss-beginner",
            title: "Weight Loss: Beginner",
            category: .weightLoss,
            level: .beginner,
            location: "home",
            weeks: 8,
            seed: 3004,
            access: "member",
            summary: "Sustainable weight loss through movement",
            notes: nil,
            image: nil,
            sport: nil,
            days: [],
            resources: nil,
            hasProtocolSheet: false
        ),
        ContentProgram(
            id: "hiit-express",
            title: "HIIT Express",
            category: .hiit,
            level: .intermediate,
            location: "home",
            weeks: 4,
            seed: 3005,
            access: "member",
            summary: "High-intensity interval training for busy schedules",
            notes: nil,
            image: nil,
            sport: nil,
            days: [],
            resources: nil,
            hasProtocolSheet: false
        ),
        ContentProgram(
            id: "core-strength",
            title: "Core Strength & Stability",
            category: .strength,
            level: .beginner,
            location: "home",
            weeks: 6,
            seed: 3006,
            access: "member",
            summary: "Build a strong, stable core",
            notes: nil,
            image: nil,
            sport: nil,
            days: [],
            resources: nil,
            hasProtocolSheet: false
        ),
        ContentProgram(
            id: "full-body-strength",
            title: "Full Body Strength",
            category: .strength,
            level: .intermediate,
            location: "gym",
            weeks: 8,
            seed: 3007,
            access: "member",
            summary: "Comprehensive full-body strength training",
            notes: nil,
            image: nil,
            sport: nil,
            days: [],
            resources: nil,
            hasProtocolSheet: true
        ),
        ContentProgram(
            id: "functional-fitness",
            title: "Functional Fitness",
            category: .general,
            level: .intermediate,
            location: "gym",
            weeks: 6,
            seed: 3008,
            access: "member",
            summary: "Train for real-life movement patterns",
            notes: nil,
            image: nil,
            sport: nil,
            days: [],
            resources: nil,
            hasProtocolSheet: false
        ),
        ContentProgram(
            id: "posture-correction",
            title: "Posture Correction",
            category: .mobility,
            level: .beginner,
            location: "home",
            weeks: 4,
            seed: 3009,
            access: "free",
            summary: "Fix posture issues from desk work",
            notes: nil,
            image: nil,
            sport: nil,
            days: [],
            resources: nil,
            hasProtocolSheet: false
        ),
        ContentProgram(
            id: "active-recovery",
            title: "Active Recovery",
            category: .mobility,
            level: .beginner,
            location: "home",
            weeks: 2,
            seed: 3010,
            access: "free",
            summary: "Gentle recovery work between intense sessions",
            notes: nil,
            image: nil,
            sport: nil,
            days: [],
            resources: nil,
            hasProtocolSheet: false
        )
    ]

    /// Programs with protocol sheets (17 of 23)
    static var programsWithProtocolSheets: [ContentProgram] {
        builtInPrograms.filter { $0.hasProtocolSheet }
    }

    /// Free programs
    static var freePrograms: [ContentProgram] {
        builtInPrograms.filter { $0.access == "free" }
    }

    /// Sport-specific programs
    static var sportPrograms: [ContentProgram] {
        builtInPrograms.filter { $0.sport != nil }
    }

    /// Rehab protocols
    static var rehabPrograms: [ContentProgram] {
        builtInPrograms.filter {
            [.shoulderRelease, .plantarFascia, .lowerBackSI].contains($0.category)
        }
    }
}
