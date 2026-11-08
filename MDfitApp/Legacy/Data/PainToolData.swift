import Foundation

// MARK: - Pain Tool Data
// Generated from MD_Fit referred pain docs and body image regions

extension PainPattern {

    // MARK: - All Patterns

    static let allPatterns: [PainPattern] = [
        // Neck & Head
        neckScalene,
        occipitalRidge,

        // Shoulder Complex
        shoulderInfraspinatus,
        shoulderSupraspinatus,
        shoulderSubscapularis,
        shoulderPecMinor,

        // Upper Back
        upperBackSerratus,

        // Chest
        chestPecMajor,
        chestScaleneReferred,

        // Lower Back
        lowerBackQuadratusLumborum,
        lowerBackPsoas,
        lowerBackIliacus,

        // Abdominal
        abdominalExternalOblique,

        // Hip & Glute
        hipGluteMinimus,
        hipPectineus,
        groinPsoas,

        // Leg
        calfSoleus,
        hamstringReferred,

        // Arm
        forearmWrist
    ]

    // MARK: - Pattern Lookup

    static func patterns(for region: BodyRegion) -> [PainPattern] {
        allPatterns.filter { pattern in
            pattern.bodyRegion == region ||
            pattern.referredAreas.contains(region)
        }
    }

    // MARK: - Neck & Head Patterns

    static let neckScalene = PainPattern(
        id: "pain_neck_scalene",
        bodyRegion: .neck,
        referredAreas: [.shoulders, .chest, .arms],
        commonCauses: [
            "Forward head posture",
            "Desk work / computer use",
            "Stress / tension holding",
            "Breathing dysfunction",
            "Sleeping position"
        ],
        redFlags: [
            "Numbness/tingling down arm",
            "Difficulty swallowing",
            "Severe headache with neck stiffness",
            "Loss of balance or coordination"
        ],
        suggestedExerciseIds: ["NK_MOB_SCALENE_RELEASE_RHB", "NK_MOB_ECCENTRIC_SCALENE_DROP_RHB"],
        educationalContent: """
        The scalene muscles run along the side of your neck and can refer pain to the chest, shoulder, and arm when tight. \
        This pattern is often mistaken for heart or shoulder problems. Gentle release work and postural improvements typically help.
        """,
        disclaimer: PainPattern.defaultDisclaimer
    )

    static let occipitalRidge = PainPattern(
        id: "pain_occipital",
        bodyRegion: .neck,
        referredAreas: [.neck],
        commonCauses: [
            "Tension headaches",
            "Forward head posture",
            "Eye strain",
            "TMJ dysfunction",
            "Stress"
        ],
        redFlags: [
            "Sudden severe headache (worst of your life)",
            "Headache with fever and stiff neck",
            "Vision changes with headache",
            "Headache after head injury"
        ],
        suggestedExerciseIds: ["NK_MOB_SCALENE_RELEASE_RHB"],
        educationalContent: """
        Pain at the base of the skull often originates from tight suboccipital muscles or levator scapulae. \
        These muscles become overworked from poor posture and screen time.
        """,
        disclaimer: PainPattern.defaultDisclaimer
    )

    // MARK: - Shoulder Complex Patterns

    static let shoulderInfraspinatus = PainPattern(
        id: "pain_shoulder_infraspinatus",
        bodyRegion: .shoulders,
        referredAreas: [.arms, .neck],
        commonCauses: [
            "Overhead activities",
            "Side sleeping",
            "Rotator cuff weakness",
            "Poor posture",
            "Repetitive arm movements"
        ],
        redFlags: [
            "Inability to raise arm",
            "Significant weakness",
            "Deformity after injury",
            "Severe swelling"
        ],
        suggestedExerciseIds: ["SH_RT_RC_INTERNAL_ROTATION_RHB", "SP_RT_THREAD_THE_NEEDLE_MOB"],
        educationalContent: """
        The infraspinatus is a rotator cuff muscle on the back of your shoulder blade. When tight or irritated, \
        it can refer pain deep into the front of the shoulder and down the arm. External rotation exercises and gentle stretching help.
        """,
        disclaimer: PainPattern.defaultDisclaimer
    )

    static let shoulderSupraspinatus = PainPattern(
        id: "pain_shoulder_supraspinatus",
        bodyRegion: .shoulders,
        referredAreas: [.arms],
        commonCauses: [
            "Overhead reaching",
            "Carrying heavy bags",
            "Rotator cuff strain",
            "Poor shoulder mechanics"
        ],
        redFlags: [
            "Complete inability to lift arm",
            "Pain at rest that worsens",
            "Night pain preventing sleep"
        ],
        suggestedExerciseIds: ["SH_RT_RC_INTERNAL_ROTATION_RHB", "SH_PL_FACE_PULL_ACT"],
        educationalContent: """
        The supraspinatus initiates arm lifting and is commonly involved in rotator cuff issues. \
        Pain typically refers to the outside of the shoulder and upper arm.
        """,
        disclaimer: PainPattern.defaultDisclaimer
    )

    static let shoulderSubscapularis = PainPattern(
        id: "pain_shoulder_subscapularis",
        bodyRegion: .shoulders,
        referredAreas: [.arms, .chest],
        commonCauses: [
            "Internal rotation overuse",
            "Desk posture (rounded shoulders)",
            "Swimming / throwing sports",
            "Tight pectorals"
        ],
        redFlags: [
            "Shoulder instability / dislocation history",
            "Severe weakness in rotation"
        ],
        suggestedExerciseIds: ["SH_RT_RC_INTERNAL_ROTATION_RHB", "SP_RT_THREAD_THE_NEEDLE_MOB"],
        educationalContent: """
        The subscapularis sits between your shoulder blade and ribs. When problematic, it can cause \
        deep shoulder pain, difficulty reaching behind your back, and referred pain to the wrist.
        """,
        disclaimer: PainPattern.defaultDisclaimer
    )

    static let shoulderPecMinor = PainPattern(
        id: "pain_shoulder_pec_minor",
        bodyRegion: .shoulders,
        referredAreas: [.chest, .arms],
        commonCauses: [
            "Rounded shoulder posture",
            "Desk work",
            "Tight chest muscles",
            "Breathing dysfunction"
        ],
        redFlags: [
            "Chest pain with shortness of breath",
            "Pain radiating to jaw or left arm (seek emergency care)"
        ],
        suggestedExerciseIds: ["SP_RT_THORACIC_OPEN_BOOK_MOB", "SP_RT_BASEBALL_CABLE_STRETCH_MOB"],
        educationalContent: """
        The pec minor attaches to your ribs and shoulder blade. When tight, it pulls the shoulder forward \
        and can compress nerves, causing numbness or pain down the arm.
        """,
        disclaimer: PainPattern.defaultDisclaimer
    )

    // MARK: - Upper Back Patterns

    static let upperBackSerratus = PainPattern(
        id: "pain_upper_back_serratus",
        bodyRegion: .upperBack,
        referredAreas: [.chest, .arms],
        commonCauses: [
            "Prolonged sitting",
            "Shallow breathing",
            "Overhead activities",
            "Coughing / respiratory illness"
        ],
        redFlags: [
            "Difficulty breathing deeply",
            "Sharp pain with breathing"
        ],
        suggestedExerciseIds: ["SP_RT_THREAD_THE_NEEDLE_MOB", "SP_RT_THORACIC_OPEN_BOOK_MOB"],
        educationalContent: """
        The serratus muscles wrap around your ribs and can refer pain along the side of your body. \
        Deep breathing exercises and thoracic mobility work typically provide relief.
        """,
        disclaimer: PainPattern.defaultDisclaimer
    )

    // MARK: - Chest Patterns

    static let chestPecMajor = PainPattern(
        id: "pain_chest_pec_major",
        bodyRegion: .chest,
        referredAreas: [.shoulders, .arms],
        commonCauses: [
            "Bench press / pushing exercises",
            "Rounded posture",
            "Desk work",
            "Driving position"
        ],
        redFlags: [
            "Chest pain with shortness of breath",
            "Pain with exertion (seek emergency evaluation)",
            "Pain radiating to jaw or left arm"
        ],
        suggestedExerciseIds: ["SP_RT_THORACIC_OPEN_BOOK_MOB", "SP_CR_FARMER_CARRY_ACT"],
        educationalContent: """
        The pectoralis major can refer pain to the front of the shoulder and down the arm. \
        Important: Always rule out cardiac causes for chest pain before assuming muscular origin.
        """,
        disclaimer: PainPattern.defaultDisclaimer
    )

    static let chestScaleneReferred = PainPattern(
        id: "pain_chest_scalene_referred",
        bodyRegion: .chest,
        referredAreas: [.neck, .shoulders],
        commonCauses: [
            "Scalene muscle tension",
            "Forward head posture",
            "Anxiety / stress breathing"
        ],
        redFlags: [
            "Chest pain with exertion",
            "Shortness of breath",
            "Pain radiating to arm"
        ],
        suggestedExerciseIds: ["NK_MOB_SCALENE_RELEASE_RHB", "NK_MOB_ECCENTRIC_SCALENE_DROP_RHB"],
        educationalContent: """
        Scalene muscles in the neck can refer pain to the chest, mimicking heart or lung problems. \
        This is more common in people with forward head posture and stress-related breathing patterns.
        """,
        disclaimer: PainPattern.defaultDisclaimer
    )

    // MARK: - Lower Back Patterns

    static let lowerBackQuadratusLumborum = PainPattern(
        id: "pain_lower_back_ql",
        bodyRegion: .lowerBack,
        referredAreas: [.hips, .glutes],
        commonCauses: [
            "Prolonged sitting",
            "Side bending activities",
            "Carrying bags on one side",
            "Hip imbalance",
            "Sleeping position"
        ],
        redFlags: [
            "Loss of bladder/bowel control",
            "Progressive leg weakness",
            "Numbness in groin area",
            "Severe pain that doesn't improve"
        ],
        suggestedExerciseIds: ["SP_RT_THREAD_THE_NEEDLE_MOB", "HP_RT_9090_HIP_SWITCH_MOB", "SP_MOB_PIKE_FORWARD_FOLD_MOB"],
        educationalContent: """
        The quadratus lumborum (QL) connects your pelvis to your spine and ribs. When tight, \
        it can cause deep low back and hip pain, often worse on one side.
        """,
        disclaimer: PainPattern.defaultDisclaimer
    )

    static let lowerBackPsoas = PainPattern(
        id: "pain_lower_back_psoas",
        bodyRegion: .lowerBack,
        referredAreas: [.hips, .quadriceps],
        commonCauses: [
            "Prolonged sitting",
            "Hip flexor tightness",
            "Running / sprinting",
            "Core weakness"
        ],
        redFlags: [
            "Severe pain with hip flexion",
            "Fever with back pain",
            "Unexplained weight loss"
        ],
        suggestedExerciseIds: ["HP_LN_BULGARIAN_SPLIT_SQUAT_MOB", "HP_RT_9090_HIP_SWITCH_MOB"],
        educationalContent: """
        The psoas connects your spine to your leg and is the primary hip flexor. \
        When tight from sitting, it can pull on the lower back and cause pain.
        """,
        disclaimer: PainPattern.defaultDisclaimer
    )

    static let lowerBackIliacus = PainPattern(
        id: "pain_lower_back_iliacus",
        bodyRegion: .lowerBack,
        referredAreas: [.hips, .quadriceps],
        commonCauses: [
            "Sitting posture",
            "Hip flexor overuse",
            "Running",
            "Stair climbing"
        ],
        redFlags: [
            "Groin pain with fever",
            "Inability to bear weight"
        ],
        suggestedExerciseIds: ["HP_LN_BULGARIAN_SPLIT_SQUAT_MOB", "HP_RT_9090_HIP_SWITCH_MOB"],
        educationalContent: """
        The iliacus lines the inside of your pelvis and works with the psoas to flex your hip. \
        It can refer pain to the groin and front of the thigh.
        """,
        disclaimer: PainPattern.defaultDisclaimer
    )

    // MARK: - Abdominal Pattern

    static let abdominalExternalOblique = PainPattern(
        id: "pain_abdominal_oblique",
        bodyRegion: .core,
        referredAreas: [.hips, .lowerBack],
        commonCauses: [
            "Rotational sports",
            "Core weakness",
            "Poor lifting mechanics",
            "Coughing / sneezing"
        ],
        redFlags: [
            "Severe abdominal pain",
            "Abdominal rigidity",
            "Blood in stool or urine"
        ],
        suggestedExerciseIds: ["CO_CO_DEAD_BUG_STR", "SP_CO_WALL_BALL_SIT_UP_MOB"],
        educationalContent: """
        The external obliques help rotate and side-bend your trunk. \
        They can refer pain to the lower abdomen and groin area.
        """,
        disclaimer: PainPattern.defaultDisclaimer
    )

    // MARK: - Hip & Glute Patterns

    static let hipGluteMinimus = PainPattern(
        id: "pain_hip_glute_minimus",
        bodyRegion: .glutes,
        referredAreas: [.hips, .hamstrings, .calves],
        commonCauses: [
            "Prolonged sitting",
            "Sleeping on side",
            "Walking/running asymmetry",
            "Hip weakness"
        ],
        redFlags: [
            "Groin pain with fever",
            "Inability to bear weight",
            "Hip giving way"
        ],
        suggestedExerciseIds: ["HP_AB_STANDING_HIPABAD_MOB", "HP_RT_STANDING_CLAMSHELL_MOB", "HP_GT_GLUTE_WALK_ACT"],
        educationalContent: """
        The glute minimus can cause pain that mimics sciatica, referring down the outside of the leg. \
        Strengthening hip abductors and improving hip mobility typically helps.
        """,
        disclaimer: PainPattern.defaultDisclaimer
    )

    static let hipPectineus = PainPattern(
        id: "pain_hip_pectineus",
        bodyRegion: .hips,
        referredAreas: [.quadriceps],
        commonCauses: [
            "Groin strain",
            "Hip adductor overuse",
            "Sudden direction changes",
            "Wide squatting"
        ],
        redFlags: [
            "Severe groin pain after injury",
            "Unable to lift leg"
        ],
        suggestedExerciseIds: ["HP_RT_9090_HIP_SWITCH_MOB", "HP_SQ_COSSACK_SQUAT_MOB"],
        educationalContent: """
        The pectineus is a hip adductor that can refer pain to the inner thigh and groin. \
        It's commonly involved in groin strains.
        """,
        disclaimer: PainPattern.defaultDisclaimer
    )

    static let groinPsoas = PainPattern(
        id: "pain_groin_psoas",
        bodyRegion: .hips,
        referredAreas: [.lowerBack, .quadriceps],
        commonCauses: [
            "Hip flexor tightness",
            "Prolonged sitting",
            "Running",
            "Kicking sports"
        ],
        redFlags: [
            "Groin lump",
            "Severe pain with hip movement",
            "Fever with groin pain"
        ],
        suggestedExerciseIds: ["HP_LN_BULGARIAN_SPLIT_SQUAT_MOB", "HP_RT_9090_HIP_SWITCH_MOB"],
        educationalContent: """
        Psoas-related groin pain is common in athletes and desk workers. \
        The muscle can refer pain to the front of the hip and inner thigh.
        """,
        disclaimer: PainPattern.defaultDisclaimer
    )

    // MARK: - Leg Patterns

    static let calfSoleus = PainPattern(
        id: "pain_calf_soleus",
        bodyRegion: .calves,
        referredAreas: [.ankles, .feet],
        commonCauses: [
            "Running / walking",
            "High heels",
            "Calf weakness",
            "Achilles issues",
            "Plantar fasciitis connection"
        ],
        redFlags: [
            "Sudden calf pain with 'pop'",
            "Calf swelling with warmth (DVT risk)",
            "Inability to walk on toes"
        ],
        suggestedExerciseIds: ["AN_CO_ECCENTRIC_CALF_DROPS_RHB", "AN_MOB_SEATED_PLANTAR_FASCIA_MOB", "LB_GT_HEEL_WALK_ACT", "LB_GT_TOE_WALK_ACT"],
        educationalContent: """
        The soleus can refer pain to the heel and bottom of the foot, often mimicking plantar fasciitis. \
        Eccentric calf exercises and plantar fascia mobility work together address this pattern.
        """,
        disclaimer: PainPattern.defaultDisclaimer
    )

    static let hamstringReferred = PainPattern(
        id: "pain_hamstring",
        bodyRegion: .hamstrings,
        referredAreas: [.glutes, .knees],
        commonCauses: [
            "Sitting posture",
            "Running",
            "Glute weakness (hamstring compensation)",
            "Sciatic nerve irritation"
        ],
        redFlags: [
            "Sudden severe pain with 'pop'",
            "Significant bruising",
            "Numbness/tingling down leg"
        ],
        suggestedExerciseIds: ["HP_HN_ROMANIAN_DEADLIFT_STR", "HP_RT_9090_HIP_SWITCH_MOB"],
        educationalContent: """
        Hamstring pain can originate from the muscle itself or be referred from the glutes or lower back. \
        Often, strengthening the glutes reduces hamstring strain.
        """,
        disclaimer: PainPattern.defaultDisclaimer
    )

    // MARK: - Arm Pattern

    static let forearmWrist = PainPattern(
        id: "pain_forearm_wrist",
        bodyRegion: .arms,
        referredAreas: [],
        commonCauses: [
            "Typing / mouse use",
            "Gripping activities",
            "Tennis / golf",
            "Weightlifting"
        ],
        redFlags: [
            "Numbness in thumb/fingers",
            "Weakness in grip",
            "Wrist deformity after injury"
        ],
        suggestedExerciseIds: ["WR_CO_ECCENTRIC_WRIST_DROPS_RHB", "WR_RT_WEIGHTED_WRIST_CIRCLES_ACT", "SP_CR_FARMER_CARRY_ACT"],
        educationalContent: """
        Forearm muscles can refer pain to the wrist and hand. \
        Eccentric wrist exercises and grip strengthening often provide relief.
        """,
        disclaimer: PainPattern.defaultDisclaimer
    )
}
