import Foundation
import SwiftUI

// MARK: - Pain Tool Data Model
// Body map → 32 regions → 26 pain tracks → video levels = 50 XP

// MARK: - Body Map Regions (32 tappable regions, front/back, L/R mirrored)

enum BodyMapRegion: String, CaseIterable, Codable, Hashable {
    // Head & Neck
    case headFront = "head_front"
    case headBack = "head_back"
    case neckFront = "neck_front"
    case neckBack = "neck_back"

    // Shoulders (L/R)
    case shoulderFrontLeft = "shoulder_front_left"
    case shoulderFrontRight = "shoulder_front_right"
    case shoulderBackLeft = "shoulder_back_left"
    case shoulderBackRight = "shoulder_back_right"

    // Arms (L/R)
    case upperArmFrontLeft = "upper_arm_front_left"
    case upperArmFrontRight = "upper_arm_front_right"
    case upperArmBackLeft = "upper_arm_back_left"
    case upperArmBackRight = "upper_arm_back_right"
    case forearmLeft = "forearm_left"
    case forearmRight = "forearm_right"
    case handLeft = "hand_left"
    case handRight = "hand_right"

    // Torso
    case chestLeft = "chest_left"
    case chestRight = "chest_right"
    case abdomenUpper = "abdomen_upper"
    case abdomenLower = "abdomen_lower"
    case upperBackLeft = "upper_back_left"
    case upperBackRight = "upper_back_right"
    case midBack = "mid_back"
    case lowerBackLeft = "lower_back_left"
    case lowerBackRight = "lower_back_right"

    // Hips & Glutes
    case hipFrontLeft = "hip_front_left"
    case hipFrontRight = "hip_front_right"
    case gluteLeft = "glute_left"
    case gluteRight = "glute_right"

    // Legs
    case thighFrontLeft = "thigh_front_left"
    case thighFrontRight = "thigh_front_right"
    case thighBackLeft = "thigh_back_left"
    case thighBackRight = "thigh_back_right"
    case kneeLeft = "knee_left"
    case kneeRight = "knee_right"
    case calfLeft = "calf_left"
    case calfRight = "calf_right"
    case ankleLeft = "ankle_left"
    case ankleRight = "ankle_right"
    case footLeft = "foot_left"
    case footRight = "foot_right"

    var displayName: String {
        switch self {
        case .headFront, .headBack: return "Head"
        case .neckFront, .neckBack: return "Neck"
        case .shoulderFrontLeft, .shoulderBackLeft: return "Left Shoulder"
        case .shoulderFrontRight, .shoulderBackRight: return "Right Shoulder"
        case .upperArmFrontLeft, .upperArmBackLeft: return "Left Upper Arm"
        case .upperArmFrontRight, .upperArmBackRight: return "Right Upper Arm"
        case .forearmLeft: return "Left Forearm"
        case .forearmRight: return "Right Forearm"
        case .handLeft: return "Left Hand"
        case .handRight: return "Right Hand"
        case .chestLeft: return "Left Chest"
        case .chestRight: return "Right Chest"
        case .abdomenUpper: return "Upper Abdomen"
        case .abdomenLower: return "Lower Abdomen"
        case .upperBackLeft: return "Left Upper Back"
        case .upperBackRight: return "Right Upper Back"
        case .midBack: return "Mid Back"
        case .lowerBackLeft: return "Left Lower Back"
        case .lowerBackRight: return "Right Lower Back"
        case .hipFrontLeft: return "Left Hip"
        case .hipFrontRight: return "Right Hip"
        case .gluteLeft: return "Left Glute"
        case .gluteRight: return "Right Glute"
        case .thighFrontLeft, .thighBackLeft: return "Left Thigh"
        case .thighFrontRight, .thighBackRight: return "Right Thigh"
        case .kneeLeft: return "Left Knee"
        case .kneeRight: return "Right Knee"
        case .calfLeft: return "Left Calf"
        case .calfRight: return "Right Calf"
        case .ankleLeft: return "Left Ankle"
        case .ankleRight: return "Right Ankle"
        case .footLeft: return "Left Foot"
        case .footRight: return "Right Foot"
        }
    }

    var isFrontView: Bool {
        switch self {
        case .headFront, .neckFront, .shoulderFrontLeft, .shoulderFrontRight,
             .upperArmFrontLeft, .upperArmFrontRight, .chestLeft, .chestRight,
             .abdomenUpper, .abdomenLower, .hipFrontLeft, .hipFrontRight,
             .thighFrontLeft, .thighFrontRight, .forearmLeft, .forearmRight,
             .handLeft, .handRight, .kneeLeft, .kneeRight, .ankleLeft, .ankleRight,
             .footLeft, .footRight:
            return true
        default:
            return false
        }
    }

    var isLeftSide: Bool {
        rawValue.contains("left") || rawValue.contains("Left")
    }

    /// Simplified area for pain log (9 areas)
    var painLogArea: PainLogArea {
        switch self {
        case .headFront, .headBack: return .head
        case .neckFront, .neckBack: return .neck
        case .shoulderFrontLeft, .shoulderFrontRight, .shoulderBackLeft, .shoulderBackRight,
             .upperArmFrontLeft, .upperArmFrontRight, .upperArmBackLeft, .upperArmBackRight,
             .forearmLeft, .forearmRight, .handLeft, .handRight:
            return .arms
        case .chestLeft, .chestRight, .upperBackLeft, .upperBackRight, .midBack:
            return .upperBack
        case .abdomenUpper, .abdomenLower:
            return .core
        case .lowerBackLeft, .lowerBackRight:
            return .lowerBack
        case .hipFrontLeft, .hipFrontRight, .gluteLeft, .gluteRight:
            return .hips
        case .thighFrontLeft, .thighFrontRight, .thighBackLeft, .thighBackRight, .kneeLeft, .kneeRight:
            return .legs
        case .calfLeft, .calfRight, .ankleLeft, .ankleRight, .footLeft, .footRight:
            return .feetAnkles
        }
    }
}

// MARK: - Pain Log Areas (9 simplified areas for logging)

enum PainLogArea: String, CaseIterable, Codable {
    case head
    case neck
    case arms
    case upperBack = "upper_back"
    case core
    case lowerBack = "lower_back"
    case hips
    case legs
    case feetAnkles = "feet_ankles"

    var displayName: String {
        switch self {
        case .head: return "Head"
        case .neck: return "Neck"
        case .arms: return "Arms"
        case .upperBack: return "Upper Back"
        case .core: return "Core"
        case .lowerBack: return "Lower Back"
        case .hips: return "Hips"
        case .legs: return "Legs"
        case .feetAnkles: return "Feet & Ankles"
        }
    }

    var icon: String {
        switch self {
        case .head: return "brain.head.profile"
        case .neck: return "person.crop.circle"
        case .arms: return "hand.raised.fill"
        case .upperBack: return "figure.stand"
        case .core: return "figure.core.training"
        case .lowerBack: return "figure.walk"
        case .hips: return "figure.stand"
        case .legs: return "figure.run"
        case .feetAnkles: return "shoeprints.fill"
        }
    }
}

// MARK: - Pain Track (26 built-in tracks)

struct PainTrack: Identifiable, Codable {
    let id: String
    let title: String
    let region: BodyMapRegion
    let muscleIds: [String]  // Related muscles
    let referredPainZones: [ReferredPainZone]  // Red ellipses on body map
    let triggerPoints: [TriggerPoint]  // × marks on body map
    let levels: [TrackLevel]
    let note: String?

    struct ReferredPainZone: Codable {
        let x: CGFloat
        let y: CGFloat
        let radiusX: CGFloat
        let radiusY: CGFloat
    }

    struct TriggerPoint: Codable {
        let x: CGFloat
        let y: CGFloat
    }

    struct TrackLevel: Identifiable, Codable {
        let id: String
        let title: String
        let videos: [TrackVideo]
    }

    struct TrackVideo: Identifiable, Codable {
        let id: String
        let file: String
        let name: String
        let isComingSoon: Bool
    }

    /// Playing a track earns 50 XP (program kind)
    static let xpReward = 50
}

// MARK: - Muscle Report (67 muscles)

struct MuscleReport: Identifiable, Codable {
    let id: String
    let name: String
    let origin: String
    let insertion: String
    let action: String
    let nerve: String
    let symptoms: [String]
    let questions: [SelfCheckQuestion]
    let tests: [MuscleTest]
    let causes: [String]
    let mimics: [String]  // Conditions that mimic this
    let redFlags: [String]
    let habits: [String]
    let expect: String
    let seePro: String
    let muscleProtocol: MuscleProtocol

    struct SelfCheckQuestion: Codable {
        let question: String
        let weight: Double  // 0.0-1.0
    }

    struct MuscleTest: Codable {
        let name: String
        let how: String
        let positive: String  // What indicates positive
    }

    struct MuscleProtocol: Codable {
        let calm: [ProtocolExercise]
        let restore: [ProtocolExercise]
        let strengthen: [ProtocolExercise]
    }

    struct ProtocolExercise: Codable {
        let exerciseId: String
        let name: String
        let sets: Int?
        let reps: Int?
        let duration: Int?  // seconds
    }

    /// Playing a muscleProtocol earns 50 XP (program kind)
    static let xpReward = 50

    /// Self-check scoring thresholds
    static let strongMatchThreshold = 0.6   // ≥60%
    static let possibleMatchThreshold = 0.3 // ≥30%
}

// MARK: - Pain Log Entry

struct PainLogEntry: Identifiable, Codable {
    let id: String
    let area: PainLogArea
    let level: Int  // 0-10
    let note: String?  // Encrypted
    let date: Date
    let createdAt: Date

    /// First 3 pain logs per day earn 5 XP each
    static let xpReward = 5
    static let dailyCap = 3
}

// MARK: - Intake Pain Assessment (14 sided areas - clinical)

struct IntakePainAssessment: Codable {
    let complaint: String
    let areas: [IntakeBodyArea]  // 14 sided areas (different from app's 9)
    let started: Date
    let how: String?
    let painNow: Int  // 0-10
    let painWorst: Int?
    let painBest: Int?
    let feels: [String]  // Descriptors
    let spreads: Bool?
    let worse: String?
    let better: String?
    let timeOfDay: String?
    let limits: String?
    let treated: String?
    let imaging: String?
    let goals: String
}

enum IntakeBodyArea: String, CaseIterable, Codable {
    case headLeft = "head_left"
    case headRight = "head_right"
    case neckLeft = "neck_left"
    case neckRight = "neck_right"
    case shoulderLeft = "shoulder_left"
    case shoulderRight = "shoulder_right"
    case armLeft = "arm_left"
    case armRight = "arm_right"
    case chestLeft = "chest_left"
    case chestRight = "chest_right"
    case backLeft = "back_left"
    case backRight = "back_right"
    case hipLeft = "hip_left"
    case hipRight = "hip_right"
    case legLeft = "leg_left"
    case legRight = "leg_right"
    case footLeft = "foot_left"
    case footRight = "foot_right"

    var displayName: String {
        let base = rawValue.replacingOccurrences(of: "_left", with: " (L)")
            .replacingOccurrences(of: "_right", with: " (R)")
            .capitalized
        return base
    }
}

// MARK: - Pain History (for trends)

struct PainHistory: Codable {
    let entries: [PainLogEntry]
    let byArea: [PainLogArea: [PainLogEntry]]
    let trends: [PainLogArea: PainTrend]

    struct PainTrend: Codable {
        let area: PainLogArea
        let firstLevel: Int
        let latestLevel: Int
        let change: Int  // Positive = worse, negative = better
        let improvementBadgeEligible: Bool  // Drop of ≥3
    }
}

// MARK: - Track Enrollment (for progress state)

struct TrackEnrollment: Identifiable, Codable {
    let id: String
    let clientId: String
    let trackId: String
    let currentLevel: Int
    let startedAt: Date
    let lastPlayedAt: Date?
    let completed: Bool

    /// Only current or next level earns XP (no farming level 1)
}

// MARK: - Sample Pain Tracks

extension PainTrack {
    static let samples: [PainTrack] = [
        PainTrack(
            id: "track-lower-back",
            title: "Lower Back Pain",
            region: .lowerBackLeft,
            muscleIds: ["quadratus_lumborum", "erector_spinae", "multifidus"],
            referredPainZones: [
                ReferredPainZone(x: 0.5, y: 0.55, radiusX: 0.15, radiusY: 0.1)
            ],
            triggerPoints: [
                TriggerPoint(x: 0.45, y: 0.52),
                TriggerPoint(x: 0.55, y: 0.52)
            ],
            levels: [
                TrackLevel(id: "lb-1", title: "Level 1: Calm", videos: [
                    TrackVideo(id: "v1", file: "LB_CALM_1.mp4", name: "Gentle Cat Cow", isComingSoon: false)
                ]),
                TrackLevel(id: "lb-2", title: "Level 2: Restore", videos: [
                    TrackVideo(id: "v2", file: "LB_RESTORE_1.mp4", name: "Bird Dog", isComingSoon: false)
                ]),
                TrackLevel(id: "lb-3", title: "Level 3: Strengthen", videos: [
                    TrackVideo(id: "v3", file: "LB_STRENGTH_1.mp4", name: "Dead Bug", isComingSoon: false)
                ])
            ],
            note: "Follow levels in order for best results"
        ),
        PainTrack(
            id: "track-neck",
            title: "Neck Pain",
            region: .neckBack,
            muscleIds: ["upper_trapezius", "levator_scapulae", "SCM"],
            referredPainZones: [
                ReferredPainZone(x: 0.5, y: 0.12, radiusX: 0.1, radiusY: 0.08)
            ],
            triggerPoints: [
                TriggerPoint(x: 0.4, y: 0.15),
                TriggerPoint(x: 0.6, y: 0.15)
            ],
            levels: [
                TrackLevel(id: "nk-1", title: "Level 1: Release", videos: [
                    TrackVideo(id: "v4", file: "NK_RELEASE_1.mp4", name: "Neck Rolls", isComingSoon: false)
                ])
            ],
            note: nil
        )
    ]
}

// MARK: - Sample Muscle Reports

extension MuscleReport {
    static let samples: [MuscleReport] = [
        MuscleReport(
            id: "muscle-upper-trapezius",
            name: "Upper Trapezius",
            origin: "External occipital protuberance, superior nuchal line, ligamentum nuchae, spinous processes C7-T12",
            insertion: "Lateral third of clavicle, acromion, spine of scapula",
            action: "Elevates scapula, extends and rotates head",
            nerve: "Accessory nerve (CN XI), C3-C4",
            symptoms: [
                "Neck stiffness",
                "Shoulder tension",
                "Tension headaches",
                "Pain at base of skull"
            ],
            questions: [
                SelfCheckQuestion(question: "Do you have neck stiffness?", weight: 0.3),
                SelfCheckQuestion(question: "Do you get tension headaches?", weight: 0.2),
                SelfCheckQuestion(question: "Does your shoulder feel elevated?", weight: 0.2)
            ],
            tests: [
                MuscleTest(name: "Palpation", how: "Press on upper trapezius near shoulder", positive: "Tenderness or trigger point")
            ],
            causes: ["Poor posture", "Stress", "Desk work", "Heavy bags"],
            mimics: ["Cervical disc", "Thoracic outlet syndrome"],
            redFlags: ["Numbness in arms", "Weakness", "Severe headache"],
            habits: ["Take breaks from desk", "Shoulder shrugs", "Posture check"],
            expect: "Improvement in 2-4 weeks with consistent work",
            seePro: "If symptoms persist beyond 4 weeks or worsen",
            muscleProtocol: MuscleProtocol(
                calm: [ProtocolExercise(exerciseId: "ex_001", name: "Neck Stretch", sets: 1, reps: nil, duration: 30)],
                restore: [ProtocolExercise(exerciseId: "ex_002", name: "Chin Tucks", sets: 2, reps: 10, duration: nil)],
                strengthen: [ProtocolExercise(exerciseId: "ex_003", name: "Prone Y Raise", sets: 3, reps: 12, duration: nil)]
            )
        )
    ]
}
