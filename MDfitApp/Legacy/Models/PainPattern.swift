import Foundation
import CoreGraphics

// MARK: - Pain Pattern (for Pain Tool)

struct PainPattern: Identifiable, Codable, Hashable {
    let id: String
    var bodyRegion: BodyRegion
    var referredAreas: [BodyRegion]     // where pain may radiate
    var commonCauses: [String]
    var redFlags: [String]              // when to seek immediate help
    var suggestedExerciseIds: [String]
    var educationalContent: String
    var disclaimer: String

    static let defaultDisclaimer = """
    This tool is for educational purposes only and does not constitute medical advice or diagnosis. \
    If you are experiencing severe pain, numbness, weakness, or other concerning symptoms, \
    please consult a healthcare professional immediately.
    """
}

// MARK: - Body Map Selection

struct BodyMapSelection: Codable, Hashable {
    var view: BodyView                  // front or back
    var region: BodyRegion
    var specificPoint: CGPoint?         // tap location for precision

    enum BodyView: String, Codable, Hashable {
        case front
        case back
    }

    // Custom Hashable conformance since CGPoint is not Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(view)
        hasher.combine(region)
        if let point = specificPoint {
            hasher.combine(point.x)
            hasher.combine(point.y)
        }
    }

    static func == (lhs: BodyMapSelection, rhs: BodyMapSelection) -> Bool {
        lhs.view == rhs.view &&
        lhs.region == rhs.region &&
        lhs.specificPoint?.x == rhs.specificPoint?.x &&
        lhs.specificPoint?.y == rhs.specificPoint?.y
    }
}

// MARK: - Pain Tool Result

struct PainToolResult: Identifiable, Codable {
    let id: String
    var userId: String?
    var selections: [BodyMapSelection]
    var matchedPatterns: [PainPattern]
    var suggestedExercises: [Exercise]
    var createdAt: Date

    var primaryRegion: BodyRegion? {
        selections.first?.region
    }
}

// MARK: - Red Flag Warning

struct RedFlagWarning: Identifiable {
    let id = UUID()
    var title: String
    var description: String
    var actionRequired: String

    static let severeNeurological = RedFlagWarning(
        title: "Seek Immediate Care",
        description: "Numbness, tingling, or weakness spreading to arms/legs may indicate a serious condition.",
        actionRequired: "Contact your doctor or visit urgent care today."
    )

    static let suddenOnset = RedFlagWarning(
        title: "Sudden Severe Pain",
        description: "Sudden onset of severe pain without injury may require evaluation.",
        actionRequired: "If pain is unbearable or accompanied by other symptoms, seek medical attention."
    )
}

// MARK: - Sample Data

extension PainPattern {
    static let lowerBack = PainPattern(
        id: "pain_lower_back",
        bodyRegion: .lowerBack,
        referredAreas: [.hips, .glutes, .hamstrings],
        commonCauses: [
            "Prolonged sitting",
            "Poor posture",
            "Weak core muscles",
            "Tight hip flexors",
            "Disc issues"
        ],
        redFlags: [
            "Loss of bladder or bowel control",
            "Progressive leg weakness",
            "Numbness in groin area",
            "Severe pain that doesn't improve with rest"
        ],
        suggestedExerciseIds: ["ex_001", "ex_002", "ex_003"],
        educationalContent: """
        Lower back pain is often caused by muscle tension, poor movement patterns, or weakness in supporting muscles. \
        The exercises suggested here focus on gentle mobility, core activation, and hip flexibility to address common causes.
        """,
        disclaimer: PainPattern.defaultDisclaimer
    )

    static let samples: [PainPattern] = [
        lowerBack,
        PainPattern(
            id: "pain_shoulder",
            bodyRegion: .shoulders,
            referredAreas: [.neck, .upperBack, .arms],
            commonCauses: [
                "Rotator cuff tension",
                "Poor desk posture",
                "Overhead movement patterns",
                "Sleeping position"
            ],
            redFlags: [
                "Inability to raise arm",
                "Severe swelling",
                "Deformity after injury"
            ],
            suggestedExerciseIds: ["ex_010", "ex_011"],
            educationalContent: "Shoulder pain often originates from the rotator cuff muscles or surrounding tension.",
            disclaimer: PainPattern.defaultDisclaimer
        )
    ]
}
