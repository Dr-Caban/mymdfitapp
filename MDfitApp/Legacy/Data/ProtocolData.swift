import Foundation

// MARK: - Protocol Data
// Generated from week images - standard rehab progression pattern

extension Program {

    // MARK: - All Protocols

    static let allProtocols: [Program] = [
        backStability12Week,
        shoulderScalene6Week,
        hip6Week,
        knee6Week,
        golferElbow4Week,
        tennisElbow4Week,
        plantarFasciitis4Week
    ]

    // MARK: - Protocol Lookup

    static func protocolsForRegion(_ region: BodyRegion) -> [Program] {
        switch region {
        case .lowerBack:
            return [backStability12Week]
        case .shoulders, .neck:
            return [shoulderScalene6Week]
        case .hips, .glutes:
            return [hip6Week]
        case .knees, .quadriceps:
            return [knee6Week]
        case .arms:
            return [golferElbow4Week, tennisElbow4Week]
        case .feet, .ankles, .calves:
            return [plantarFasciitis4Week]
        default:
            return []
        }
    }

    // MARK: - 12 Week Back Stability

    static let backStability12Week = Program(
        id: "protocol_back_stability_12",
        name: "12-Week Back Stability Program",
        description: "Progressive back stability protocol focusing on core activation, glute engagement, and spinal mobility. Builds from foundation work to functional movement.",
        category: .lowerBackSI,
        difficulty: .beginner,
        durationWeeks: 12,
        thumbnailURL: nil,
        weeks: backStabilityWeeks,
        price: nil,
        isPremium: false,
        isPublished: true,
        createdAt: Date(),
        updatedAt: Date()
    )

    private static let backStabilityWeeks: [ProgramWeek] = [
        ProgramWeek(id: "bs_w0", weekNumber: 0, name: "Foundation", days: standardRehabDays(prefix: "bs_w0", focus: "Core awareness, breathing")),
        ProgramWeek(id: "bs_w1", weekNumber: 1, name: "Week 1", days: standardRehabDays(prefix: "bs_w1", focus: "Glute activation basics")),
        ProgramWeek(id: "bs_w2", weekNumber: 2, name: "Week 2", days: standardRehabDays(prefix: "bs_w2", focus: "Hip hinge introduction")),
        ProgramWeek(id: "bs_w3", weekNumber: 3, name: "Week 3", days: standardRehabDays(prefix: "bs_w3", focus: "Spinal mobility")),
        ProgramWeek(id: "bs_w4", weekNumber: 4, name: "Week 4", days: standardRehabDays(prefix: "bs_w4", focus: "Core endurance")),
        ProgramWeek(id: "bs_w5", weekNumber: 5, name: "Week 5", days: standardRehabDays(prefix: "bs_w5", focus: "Single leg stability")),
        ProgramWeek(id: "bs_w6", weekNumber: 6, name: "Week 6", days: standardRehabDays(prefix: "bs_w6", focus: "Load introduction")),
        ProgramWeek(id: "bs_w7", weekNumber: 7, name: "Week 7", days: standardRehabDays(prefix: "bs_w7", focus: "Rotation work")),
        ProgramWeek(id: "bs_w8", weekNumber: 8, name: "Week 8", days: standardRehabDays(prefix: "bs_w8", focus: "Power development")),
        ProgramWeek(id: "bs_w9", weekNumber: 9, name: "Week 9", days: standardRehabDays(prefix: "bs_w9", focus: "Functional integration")),
        ProgramWeek(id: "bs_w10", weekNumber: 10, name: "Week 10", days: standardRehabDays(prefix: "bs_w10", focus: "Sport-specific prep")),
        ProgramWeek(id: "bs_w11", weekNumber: 11, name: "Week 11-12", days: standardRehabDays(prefix: "bs_w11", focus: "Maintenance & independence"))
    ]

    // MARK: - 6 Week Shoulder/Scalene Protocol

    static let shoulderScalene6Week = Program(
        id: "protocol_shoulder_scalene_6",
        name: "6-Week Shoulder & Scalene Release",
        description: "Progressive protocol addressing shoulder and neck tension. Focuses on scalene release, rotator cuff activation, and postural correction.",
        category: .shoulderRelease,
        difficulty: .beginner,
        durationWeeks: 6,
        thumbnailURL: nil,
        weeks: shoulderWeeks,
        price: nil,
        isPremium: false,
        isPublished: true,
        createdAt: Date(),
        updatedAt: Date()
    )

    private static let shoulderWeeks: [ProgramWeek] = [
        ProgramWeek(id: "sh_w1", weekNumber: 1, name: "Week 1", days: standardRehabDays(prefix: "sh_w1", focus: "Scalene release, posture")),
        ProgramWeek(id: "sh_w2", weekNumber: 2, name: "Week 2", days: standardRehabDays(prefix: "sh_w2", focus: "Thoracic mobility")),
        ProgramWeek(id: "sh_w3", weekNumber: 3, name: "Week 3", days: standardRehabDays(prefix: "sh_w3", focus: "Rotator cuff activation")),
        ProgramWeek(id: "sh_w4", weekNumber: 4, name: "Week 4", days: standardRehabDays(prefix: "sh_w4", focus: "Scapular stability")),
        ProgramWeek(id: "sh_w5", weekNumber: 5, name: "Week 5", days: standardRehabDays(prefix: "sh_w5", focus: "Strength integration")),
        ProgramWeek(id: "sh_w6", weekNumber: 6, name: "Week 6", days: standardRehabDays(prefix: "sh_w6", focus: "Maintenance routine"))
    ]

    // MARK: - 6 Week Hip Protocol

    static let hip6Week = Program(
        id: "protocol_hip_6",
        name: "6-Week Hip Mobility & Stability",
        description: "Address hip pain and stiffness through progressive mobility, glute activation, and functional movement patterns.",
        category: .mobility,
        difficulty: .beginner,
        durationWeeks: 6,
        thumbnailURL: nil,
        weeks: hipWeeks,
        price: nil,
        isPremium: false,
        isPublished: true,
        createdAt: Date(),
        updatedAt: Date()
    )

    private static let hipWeeks: [ProgramWeek] = [
        ProgramWeek(id: "hp_w1", weekNumber: 1, name: "Week 1", days: standardRehabDays(prefix: "hp_w1", focus: "Hip flexor release")),
        ProgramWeek(id: "hp_w2", weekNumber: 2, name: "Week 2", days: standardRehabDays(prefix: "hp_w2", focus: "Glute activation")),
        ProgramWeek(id: "hp_w3", weekNumber: 3, name: "Week 3", days: standardRehabDays(prefix: "hp_w3", focus: "Hip rotation mobility")),
        ProgramWeek(id: "hp_w4", weekNumber: 4, name: "Week 4", days: standardRehabDays(prefix: "hp_w4", focus: "Single leg stability")),
        ProgramWeek(id: "hp_w5", weekNumber: 5, name: "Week 5", days: standardRehabDays(prefix: "hp_w5", focus: "Strength building")),
        ProgramWeek(id: "hp_w6", weekNumber: 6, name: "Week 6", days: standardRehabDays(prefix: "hp_w6", focus: "Functional movement"))
    ]

    // MARK: - 6 Week Knee Protocol

    static let knee6Week = Program(
        id: "protocol_knee_6",
        name: "6-Week Knee Stability Protocol",
        description: "Progressive knee rehabilitation focusing on quad strengthening, hip stability, and proper movement mechanics.",
        category: .mobility,
        difficulty: .beginner,
        durationWeeks: 6,
        thumbnailURL: nil,
        weeks: kneeWeeks,
        price: nil,
        isPremium: false,
        isPublished: true,
        createdAt: Date(),
        updatedAt: Date()
    )

    private static let kneeWeeks: [ProgramWeek] = [
        ProgramWeek(id: "kn_w1", weekNumber: 1, name: "Week 1", days: standardRehabDays(prefix: "kn_w1", focus: "Quad activation, swelling")),
        ProgramWeek(id: "kn_w2", weekNumber: 2, name: "Week 2", days: standardRehabDays(prefix: "kn_w2", focus: "Range of motion")),
        ProgramWeek(id: "kn_w3", weekNumber: 3, name: "Week 3", days: standardRehabDays(prefix: "kn_w3", focus: "Hip strengthening")),
        ProgramWeek(id: "kn_w4", weekNumber: 4, name: "Week 4", days: standardRehabDays(prefix: "kn_w4", focus: "Balance & stability")),
        ProgramWeek(id: "kn_w5", weekNumber: 5, name: "Week 5", days: standardRehabDays(prefix: "kn_w5", focus: "Functional strength")),
        ProgramWeek(id: "kn_w6", weekNumber: 6, name: "Week 6", days: standardRehabDays(prefix: "kn_w6", focus: "Return to activity"))
    ]

    // MARK: - 4 Week Golfer's Elbow

    static let golferElbow4Week = Program(
        id: "protocol_golfer_elbow_4",
        name: "4-Week Golfer's Elbow Protocol",
        description: "Eccentric-focused protocol for medial epicondylitis (golfer's elbow). Progressive loading to rebuild tendon capacity.",
        category: .rehab,
        difficulty: .beginner,
        durationWeeks: 4,
        thumbnailURL: nil,
        weeks: golferElbowWeeks,
        price: nil,
        isPremium: false,
        isPublished: true,
        createdAt: Date(),
        updatedAt: Date()
    )

    private static let golferElbowWeeks: [ProgramWeek] = [
        ProgramWeek(id: "ge_w1", weekNumber: 1, name: "Week 1", days: standardRehabDays(prefix: "ge_w1", focus: "Pain reduction, gentle mobility")),
        ProgramWeek(id: "ge_w2", weekNumber: 2, name: "Week 2", days: standardRehabDays(prefix: "ge_w2", focus: "Eccentric loading begins")),
        ProgramWeek(id: "ge_w3", weekNumber: 3, name: "Week 3", days: standardRehabDays(prefix: "ge_w3", focus: "Progressive load increase")),
        ProgramWeek(id: "ge_w4", weekNumber: 4, name: "Week 4", days: standardRehabDays(prefix: "ge_w4", focus: "Functional grip strength"))
    ]

    // MARK: - 4 Week Tennis Elbow

    static let tennisElbow4Week = Program(
        id: "protocol_tennis_elbow_4",
        name: "4-Week Tennis Elbow Protocol",
        description: "Eccentric-focused protocol for lateral epicondylitis (tennis elbow). Progressive wrist extensor strengthening.",
        category: .rehab,
        difficulty: .beginner,
        durationWeeks: 4,
        thumbnailURL: nil,
        weeks: tennisElbowWeeks,
        price: nil,
        isPremium: false,
        isPublished: true,
        createdAt: Date(),
        updatedAt: Date()
    )

    private static let tennisElbowWeeks: [ProgramWeek] = [
        ProgramWeek(id: "te_w1", weekNumber: 1, name: "Week 1", days: standardRehabDays(prefix: "te_w1", focus: "Pain reduction, gentle stretching")),
        ProgramWeek(id: "te_w2", weekNumber: 2, name: "Week 2", days: standardRehabDays(prefix: "te_w2", focus: "Eccentric wrist exercises")),
        ProgramWeek(id: "te_w3", weekNumber: 3, name: "Week 3", days: standardRehabDays(prefix: "te_w3", focus: "Progressive resistance")),
        ProgramWeek(id: "te_w4", weekNumber: 4, name: "Week 4", days: standardRehabDays(prefix: "te_w4", focus: "Functional strengthening"))
    ]

    // MARK: - 4 Week Plantar Fasciitis

    static let plantarFasciitis4Week = Program(
        id: "protocol_plantar_fasciitis_4",
        name: "4-Week Plantar Fasciitis Protocol",
        description: "Address heel and arch pain through calf work, plantar fascia mobilization, and foot strengthening.",
        category: .plantarFascia,
        difficulty: .beginner,
        durationWeeks: 4,
        thumbnailURL: nil,
        weeks: plantarWeeks,
        price: nil,
        isPremium: false,
        isPublished: true,
        createdAt: Date(),
        updatedAt: Date()
    )

    private static let plantarWeeks: [ProgramWeek] = [
        ProgramWeek(id: "pf_w1", weekNumber: 1, name: "Week 1", days: standardRehabDays(prefix: "pf_w1", focus: "Pain relief, calf release")),
        ProgramWeek(id: "pf_w2", weekNumber: 2, name: "Week 2", days: standardRehabDays(prefix: "pf_w2", focus: "Plantar fascia mobility")),
        ProgramWeek(id: "pf_w3", weekNumber: 3, name: "Week 3", days: standardRehabDays(prefix: "pf_w3", focus: "Eccentric calf work")),
        ProgramWeek(id: "pf_w4", weekNumber: 4, name: "Week 4", days: standardRehabDays(prefix: "pf_w4", focus: "Foot strength, return to activity"))
    ]

    // MARK: - Helper: Standard Rehab Days (3x/week)

    private static func standardRehabDays(prefix: String, focus: String) -> [ProgramDay] {
        [
            ProgramDay(
                id: "\(prefix)_d1",
                dayNumber: 1,
                dayOfWeek: .monday,
                name: focus,
                workoutId: nil,
                exercises: [],
                isRestDay: false,
                isFreeformActivity: false,
                notes: nil
            ),
            ProgramDay(
                id: "\(prefix)_d2",
                dayNumber: 2,
                dayOfWeek: .tuesday,
                name: nil,
                workoutId: nil,
                exercises: [],
                isRestDay: true,
                isFreeformActivity: false,
                notes: "Rest or light walking"
            ),
            ProgramDay(
                id: "\(prefix)_d3",
                dayNumber: 3,
                dayOfWeek: .wednesday,
                name: focus,
                workoutId: nil,
                exercises: [],
                isRestDay: false,
                isFreeformActivity: false,
                notes: nil
            ),
            ProgramDay(
                id: "\(prefix)_d4",
                dayNumber: 4,
                dayOfWeek: .thursday,
                name: nil,
                workoutId: nil,
                exercises: [],
                isRestDay: true,
                isFreeformActivity: false,
                notes: "Rest or light walking"
            ),
            ProgramDay(
                id: "\(prefix)_d5",
                dayNumber: 5,
                dayOfWeek: .friday,
                name: focus,
                workoutId: nil,
                exercises: [],
                isRestDay: false,
                isFreeformActivity: false,
                notes: nil
            ),
            ProgramDay(
                id: "\(prefix)_d6",
                dayNumber: 6,
                dayOfWeek: .saturday,
                name: nil,
                workoutId: nil,
                exercises: [],
                isRestDay: true,
                isFreeformActivity: true,
                notes: "Active recovery - light movement of choice"
            ),
            ProgramDay(
                id: "\(prefix)_d7",
                dayNumber: 7,
                dayOfWeek: .sunday,
                name: nil,
                workoutId: nil,
                exercises: [],
                isRestDay: true,
                isFreeformActivity: false,
                notes: "Full rest"
            )
        ]
    }
}

// MARK: - Add rehab category to ProgramCategory

extension ProgramCategory {
    static let rehab = ProgramCategory.general // Placeholder until we add rehab case
}
