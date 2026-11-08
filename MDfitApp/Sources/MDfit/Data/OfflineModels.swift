//
//  OfflineModels.swift
//  MDfit
//
//  SwiftData models for offline caching, action queuing, and sync tracking.
//  Enables full offline support for MD Fit workout and exercise data.
//

import Foundation

// MARK: - Offline Action Types (Available without SwiftData)

/// Type of offline action
enum OfflineActionType: String, Codable {
    case createWorkout = "create_workout"
    case updateWorkout = "update_workout"
    case deleteWorkout = "delete_workout"
    case completeWorkout = "complete_workout"
    case completeExercise = "complete_exercise"
    case enrollProgram = "enroll_program"
    case updateProgress = "update_progress"
    case logActivity = "log_activity"
    case updatePreferences = "update_preferences"
    case custom = "custom"
}

/// Status of offline action
enum OfflineActionStatus: String, Codable {
    case pending = "pending"
    case inProgress = "in_progress"
    case completed = "completed"
    case failed = "failed"
    case cancelled = "cancelled"
}

#if os(iOS)
import SwiftData

// MARK: - Cached Exercise

/// SwiftData model for offline-cached exercise data
@Model
final class CachedExercise {
    // MARK: - Primary Key
    @Attribute(.unique) var exerciseId: String

    // MARK: - Core Data
    var name: String
    var videoAssetId: String?
    var bodyRegionRaw: String
    var muscleEmphasis: [String]
    var categoryRaw: String
    var equipmentRaw: [String]
    var levelRaw: String
    var cues: [String]
    var tempo: String?
    var modifications: [String]
    var exclusions: [String]
    var safetyNotes: String?
    var approvalStatusRaw: String
    var tags: [String]

    // MARK: - Prescription (Default)
    var defaultSets: Int?
    var defaultReps: Int?
    var defaultRepRange: String?
    var defaultTempo: String?
    var defaultDuration: Int?
    var defaultIntensity: String?
    var defaultRest: Int?

    // MARK: - Sync Metadata
    var cachedAt: Date
    var updatedAt: Date
    var serverUpdatedAt: Date
    var syncVersion: Int
    var needsSync: Bool

    // MARK: - Video Cache Status
    var videoDownloaded: Bool
    var videoLocalPath: String?
    var videoFileSize: Int64?
    var thumbnailLocalPath: String?

    // MARK: - Initialization

    init(
        exerciseId: String,
        name: String,
        videoAssetId: String? = nil,
        bodyRegionRaw: String,
        muscleEmphasis: [String] = [],
        categoryRaw: String,
        equipmentRaw: [String] = [],
        levelRaw: String,
        cues: [String] = [],
        tempo: String? = nil,
        modifications: [String] = [],
        exclusions: [String] = [],
        safetyNotes: String? = nil,
        approvalStatusRaw: String = "approved",
        tags: [String] = [],
        defaultSets: Int? = nil,
        defaultReps: Int? = nil,
        defaultRepRange: String? = nil,
        defaultTempo: String? = nil,
        defaultDuration: Int? = nil,
        defaultIntensity: String? = nil,
        defaultRest: Int? = nil,
        serverUpdatedAt: Date = Date()
    ) {
        self.exerciseId = exerciseId
        self.name = name
        self.videoAssetId = videoAssetId
        self.bodyRegionRaw = bodyRegionRaw
        self.muscleEmphasis = muscleEmphasis
        self.categoryRaw = categoryRaw
        self.equipmentRaw = equipmentRaw
        self.levelRaw = levelRaw
        self.cues = cues
        self.tempo = tempo
        self.modifications = modifications
        self.exclusions = exclusions
        self.safetyNotes = safetyNotes
        self.approvalStatusRaw = approvalStatusRaw
        self.tags = tags
        self.defaultSets = defaultSets
        self.defaultReps = defaultReps
        self.defaultRepRange = defaultRepRange
        self.defaultTempo = defaultTempo
        self.defaultDuration = defaultDuration
        self.defaultIntensity = defaultIntensity
        self.defaultRest = defaultRest
        self.cachedAt = Date()
        self.updatedAt = Date()
        self.serverUpdatedAt = serverUpdatedAt
        self.syncVersion = 1
        self.needsSync = false
        self.videoDownloaded = false
        self.videoLocalPath = nil
        self.videoFileSize = nil
        self.thumbnailLocalPath = nil
    }

    // MARK: - Conversion

    /// Convert from API model to cached model
    static func from(_ exercise: Exercise) -> CachedExercise {
        CachedExercise(
            exerciseId: exercise.id,
            name: exercise.name,
            videoAssetId: exercise.videoAssetId,
            bodyRegionRaw: exercise.bodyRegion.rawValue,
            muscleEmphasis: exercise.muscleEmphasis,
            categoryRaw: exercise.category.rawValue,
            equipmentRaw: exercise.equipment.map { $0.rawValue },
            levelRaw: exercise.level.rawValue,
            cues: exercise.cues,
            tempo: exercise.tempo,
            modifications: exercise.modifications,
            exclusions: exercise.exclusions,
            safetyNotes: exercise.safetyNotes,
            approvalStatusRaw: exercise.approvalStatus.rawValue,
            tags: exercise.tags,
            defaultSets: exercise.defaultPrescription.sets,
            defaultReps: exercise.defaultPrescription.reps,
            defaultRepRange: exercise.defaultPrescription.repRange,
            defaultTempo: exercise.defaultPrescription.tempo,
            defaultDuration: exercise.defaultPrescription.duration,
            defaultIntensity: exercise.defaultPrescription.intensity,
            defaultRest: exercise.defaultPrescription.rest,
            serverUpdatedAt: exercise.updatedAt
        )
    }

    /// Convert cached model back to API model
    func toExercise() -> Exercise {
        Exercise(
            id: exerciseId,
            name: name,
            videoAssetId: videoAssetId,
            bodyRegion: BodyRegion(rawValue: bodyRegionRaw) ?? .fullBody,
            muscleEmphasis: muscleEmphasis,
            category: ExerciseCategory(rawValue: categoryRaw) ?? .strengthening,
            equipment: equipmentRaw.compactMap { Equipment(rawValue: $0) },
            level: DifficultyLevel(rawValue: levelRaw) ?? .intermediate,
            cues: cues,
            tempo: tempo,
            defaultPrescription: Prescription(
                sets: defaultSets,
                reps: defaultReps,
                repRange: defaultRepRange,
                tempo: defaultTempo,
                duration: defaultDuration,
                distance: nil,
                intensity: defaultIntensity,
                load: nil,
                rest: defaultRest,
                coachingCues: nil,
                modification: nil,
                stopRules: nil
            ),
            modifications: modifications,
            exclusions: exclusions,
            safetyNotes: safetyNotes,
            approvalStatus: ApprovalStatus(rawValue: approvalStatusRaw) ?? .approved,
            tags: tags,
            createdAt: cachedAt,
            updatedAt: serverUpdatedAt
        )
    }

    /// Update from API model
    func update(from exercise: Exercise) {
        name = exercise.name
        videoAssetId = exercise.videoAssetId
        bodyRegionRaw = exercise.bodyRegion.rawValue
        muscleEmphasis = exercise.muscleEmphasis
        categoryRaw = exercise.category.rawValue
        equipmentRaw = exercise.equipment.map { $0.rawValue }
        levelRaw = exercise.level.rawValue
        cues = exercise.cues
        tempo = exercise.tempo
        modifications = exercise.modifications
        exclusions = exercise.exclusions
        safetyNotes = exercise.safetyNotes
        approvalStatusRaw = exercise.approvalStatus.rawValue
        tags = exercise.tags
        defaultSets = exercise.defaultPrescription.sets
        defaultReps = exercise.defaultPrescription.reps
        defaultRepRange = exercise.defaultPrescription.repRange
        defaultTempo = exercise.defaultPrescription.tempo
        defaultDuration = exercise.defaultPrescription.duration
        defaultIntensity = exercise.defaultPrescription.intensity
        defaultRest = exercise.defaultPrescription.rest
        serverUpdatedAt = exercise.updatedAt
        updatedAt = Date()
        syncVersion += 1
    }
}

// MARK: - Cached Workout

/// SwiftData model for offline-cached workout data
@Model
final class CachedWorkout {
    // MARK: - Primary Key
    @Attribute(.unique) var workoutId: String

    // MARK: - Core Data
    var userId: String?
    var name: String?
    var goalTypeRaw: String
    var locationRaw: String
    var difficultyRaw: String
    var lengthMinutes: Int
    var exercisesPerRound: Int
    var totalRounds: Int
    var restBetweenExercises: Int
    var restBetweenRounds: Int

    // MARK: - Add-ons
    var warmUp: Bool
    var coolDown: Bool
    var mobilityFlexibility: Bool
    var coreWork: Bool
    var balanceStability: Bool
    var sportSpecific: Bool
    var equipmentRestrictions: Bool
    var restrictedEquipmentRaw: [String]?

    // MARK: - Exercises (Stored as JSON for flexibility)
    var exercisesJSON: Data?

    // MARK: - Schedule & Completion
    var scheduledDate: Date?
    var completedAt: Date?

    // MARK: - Sync Metadata
    var cachedAt: Date
    var updatedAt: Date
    var serverUpdatedAt: Date
    var syncVersion: Int
    var needsSync: Bool
    var isLocalOnly: Bool  // Created offline, never synced

    // MARK: - Initialization

    init(
        workoutId: String,
        userId: String? = nil,
        name: String? = nil,
        goalTypeRaw: String,
        locationRaw: String,
        difficultyRaw: String,
        lengthMinutes: Int,
        exercisesPerRound: Int,
        totalRounds: Int,
        restBetweenExercises: Int,
        restBetweenRounds: Int,
        warmUp: Bool = false,
        coolDown: Bool = false,
        mobilityFlexibility: Bool = false,
        coreWork: Bool = false,
        balanceStability: Bool = false,
        sportSpecific: Bool = false,
        equipmentRestrictions: Bool = false,
        restrictedEquipmentRaw: [String]? = nil,
        exercisesJSON: Data? = nil,
        scheduledDate: Date? = nil,
        completedAt: Date? = nil,
        serverUpdatedAt: Date = Date(),
        isLocalOnly: Bool = false
    ) {
        self.workoutId = workoutId
        self.userId = userId
        self.name = name
        self.goalTypeRaw = goalTypeRaw
        self.locationRaw = locationRaw
        self.difficultyRaw = difficultyRaw
        self.lengthMinutes = lengthMinutes
        self.exercisesPerRound = exercisesPerRound
        self.totalRounds = totalRounds
        self.restBetweenExercises = restBetweenExercises
        self.restBetweenRounds = restBetweenRounds
        self.warmUp = warmUp
        self.coolDown = coolDown
        self.mobilityFlexibility = mobilityFlexibility
        self.coreWork = coreWork
        self.balanceStability = balanceStability
        self.sportSpecific = sportSpecific
        self.equipmentRestrictions = equipmentRestrictions
        self.restrictedEquipmentRaw = restrictedEquipmentRaw
        self.exercisesJSON = exercisesJSON
        self.scheduledDate = scheduledDate
        self.completedAt = completedAt
        self.cachedAt = Date()
        self.updatedAt = Date()
        self.serverUpdatedAt = serverUpdatedAt
        self.syncVersion = 1
        self.needsSync = isLocalOnly
        self.isLocalOnly = isLocalOnly
    }

    // MARK: - Computed Properties

    var isCompleted: Bool {
        completedAt != nil
    }

    // MARK: - Exercise Serialization

    func setExercises(_ exercises: [WorkoutExercise]) {
        let encoder = JSONEncoder()
        exercisesJSON = try? encoder.encode(exercises)
    }

    func getExercises() -> [WorkoutExercise] {
        guard let data = exercisesJSON else { return [] }
        let decoder = JSONDecoder()
        return (try? decoder.decode([WorkoutExercise].self, from: data)) ?? []
    }

    // MARK: - Conversion

    static func from(_ workout: Workout) -> CachedWorkout {
        let cached = CachedWorkout(
            workoutId: workout.id,
            userId: workout.userId,
            name: workout.name,
            goalTypeRaw: workout.goalType.rawValue,
            locationRaw: workout.location.rawValue,
            difficultyRaw: workout.difficulty.rawValue,
            lengthMinutes: workout.lengthMinutes,
            exercisesPerRound: workout.exercisesPerRound,
            totalRounds: workout.totalRounds,
            restBetweenExercises: workout.restBetweenExercises,
            restBetweenRounds: workout.restBetweenRounds,
            warmUp: workout.addOns.warmUp,
            coolDown: workout.addOns.coolDown,
            mobilityFlexibility: workout.addOns.mobilityFlexibility,
            coreWork: workout.addOns.coreWork,
            balanceStability: workout.addOns.balanceStability,
            sportSpecific: workout.addOns.sportSpecific,
            equipmentRestrictions: workout.addOns.equipmentRestrictions,
            restrictedEquipmentRaw: workout.addOns.restrictedEquipment?.map { $0.rawValue },
            scheduledDate: workout.scheduledDate,
            completedAt: workout.completedAt,
            serverUpdatedAt: workout.updatedAt
        )
        cached.setExercises(workout.exercises)
        return cached
    }

    func toWorkout() -> Workout {
        Workout(
            id: workoutId,
            userId: userId,
            name: name,
            goalType: WorkoutGoalType(rawValue: goalTypeRaw) ?? .fullBody,
            location: WorkoutLocation(rawValue: locationRaw) ?? .home,
            difficulty: DifficultyLevel(rawValue: difficultyRaw) ?? .intermediate,
            lengthMinutes: lengthMinutes,
            exercisesPerRound: exercisesPerRound,
            totalRounds: totalRounds,
            restBetweenExercises: restBetweenExercises,
            restBetweenRounds: restBetweenRounds,
            addOns: WorkoutAddOns(
                warmUp: warmUp,
                coolDown: coolDown,
                mobilityFlexibility: mobilityFlexibility,
                coreWork: coreWork,
                balanceStability: balanceStability,
                sportSpecific: sportSpecific,
                equipmentRestrictions: equipmentRestrictions,
                restrictedEquipment: restrictedEquipmentRaw?.compactMap { Equipment(rawValue: $0) }
            ),
            exercises: getExercises(),
            scheduledDate: scheduledDate,
            completedAt: completedAt,
            createdAt: cachedAt,
            updatedAt: serverUpdatedAt
        )
    }

    func update(from workout: Workout) {
        userId = workout.userId
        name = workout.name
        goalTypeRaw = workout.goalType.rawValue
        locationRaw = workout.location.rawValue
        difficultyRaw = workout.difficulty.rawValue
        lengthMinutes = workout.lengthMinutes
        exercisesPerRound = workout.exercisesPerRound
        totalRounds = workout.totalRounds
        restBetweenExercises = workout.restBetweenExercises
        restBetweenRounds = workout.restBetweenRounds
        warmUp = workout.addOns.warmUp
        coolDown = workout.addOns.coolDown
        mobilityFlexibility = workout.addOns.mobilityFlexibility
        coreWork = workout.addOns.coreWork
        balanceStability = workout.addOns.balanceStability
        sportSpecific = workout.addOns.sportSpecific
        equipmentRestrictions = workout.addOns.equipmentRestrictions
        restrictedEquipmentRaw = workout.addOns.restrictedEquipment?.map { $0.rawValue }
        setExercises(workout.exercises)
        scheduledDate = workout.scheduledDate
        completedAt = workout.completedAt
        serverUpdatedAt = workout.updatedAt
        updatedAt = Date()
        syncVersion += 1
    }
}

// MARK: - Cached Program

/// SwiftData model for offline-cached program data
@Model
final class CachedProgram {
    // MARK: - Primary Key
    @Attribute(.unique) var programId: String

    // MARK: - Core Data
    var name: String
    var programDescription: String
    var categoryRaw: String
    var difficultyRaw: String
    var durationWeeks: Int
    var thumbnailURL: String?
    var price: Double?
    var isPremium: Bool
    var isPublished: Bool

    // MARK: - Weeks (Stored as JSON)
    var weeksJSON: Data?

    // MARK: - Enrollment Status
    var isEnrolled: Bool
    var currentWeek: Int?
    var currentDay: Int?
    var enrollmentStartDate: Date?
    var completedWorkoutIds: [String]?

    // MARK: - Sync Metadata
    var cachedAt: Date
    var updatedAt: Date
    var serverUpdatedAt: Date
    var syncVersion: Int
    var needsSync: Bool

    // MARK: - Downloaded Content
    var videosDownloaded: Bool
    var downloadedVideoIds: [String]?
    var totalDownloadSize: Int64?

    // MARK: - Initialization

    init(
        programId: String,
        name: String,
        programDescription: String,
        categoryRaw: String,
        difficultyRaw: String,
        durationWeeks: Int,
        thumbnailURL: String? = nil,
        price: Double? = nil,
        isPremium: Bool = false,
        isPublished: Bool = true,
        weeksJSON: Data? = nil,
        isEnrolled: Bool = false,
        currentWeek: Int? = nil,
        currentDay: Int? = nil,
        enrollmentStartDate: Date? = nil,
        completedWorkoutIds: [String]? = nil,
        serverUpdatedAt: Date = Date()
    ) {
        self.programId = programId
        self.name = name
        self.programDescription = programDescription
        self.categoryRaw = categoryRaw
        self.difficultyRaw = difficultyRaw
        self.durationWeeks = durationWeeks
        self.thumbnailURL = thumbnailURL
        self.price = price
        self.isPremium = isPremium
        self.isPublished = isPublished
        self.weeksJSON = weeksJSON
        self.isEnrolled = isEnrolled
        self.currentWeek = currentWeek
        self.currentDay = currentDay
        self.enrollmentStartDate = enrollmentStartDate
        self.completedWorkoutIds = completedWorkoutIds
        self.cachedAt = Date()
        self.updatedAt = Date()
        self.serverUpdatedAt = serverUpdatedAt
        self.syncVersion = 1
        self.needsSync = false
        self.videosDownloaded = false
        self.downloadedVideoIds = nil
        self.totalDownloadSize = nil
    }

    // MARK: - Week Serialization

    func setWeeks(_ weeks: [ProgramWeek]) {
        let encoder = JSONEncoder()
        weeksJSON = try? encoder.encode(weeks)
    }

    func getWeeks() -> [ProgramWeek] {
        guard let data = weeksJSON else { return [] }
        let decoder = JSONDecoder()
        return (try? decoder.decode([ProgramWeek].self, from: data)) ?? []
    }

    // MARK: - Conversion

    static func from(_ program: Program) -> CachedProgram {
        let cached = CachedProgram(
            programId: program.id,
            name: program.name,
            programDescription: program.description,
            categoryRaw: program.category.rawValue,
            difficultyRaw: program.difficulty.rawValue,
            durationWeeks: program.durationWeeks,
            thumbnailURL: program.thumbnailURL?.absoluteString,
            price: program.price.map { NSDecimalNumber(decimal: $0).doubleValue },
            isPremium: program.isPremium,
            isPublished: program.isPublished,
            serverUpdatedAt: program.updatedAt
        )
        cached.setWeeks(program.weeks)
        return cached
    }

    func toProgram() -> Program {
        Program(
            id: programId,
            name: name,
            description: programDescription,
            category: ProgramCategory(rawValue: categoryRaw) ?? .general,
            difficulty: DifficultyLevel(rawValue: difficultyRaw) ?? .intermediate,
            durationWeeks: durationWeeks,
            thumbnailURL: thumbnailURL.flatMap { URL(string: $0) },
            weeks: getWeeks(),
            price: price.map { Decimal($0) },
            isPremium: isPremium,
            isPublished: isPublished,
            createdAt: cachedAt,
            updatedAt: serverUpdatedAt
        )
    }

    func update(from program: Program) {
        name = program.name
        programDescription = program.description
        categoryRaw = program.category.rawValue
        difficultyRaw = program.difficulty.rawValue
        durationWeeks = program.durationWeeks
        thumbnailURL = program.thumbnailURL?.absoluteString
        price = program.price.map { NSDecimalNumber(decimal: $0).doubleValue }
        isPremium = program.isPremium
        isPublished = program.isPublished
        setWeeks(program.weeks)
        serverUpdatedAt = program.updatedAt
        updatedAt = Date()
        syncVersion += 1
    }
}

// MARK: - Offline Action

/// Represents an action queued while offline
@Model
final class OfflineAction {
    // MARK: - Primary Key
    @Attribute(.unique) var actionId: String

    // MARK: - Action Type
    var actionTypeRaw: String
    var entityType: String           // "workout", "exercise", "program", etc.
    var entityId: String

    // MARK: - Payload
    var payloadJSON: Data?           // The action data
    var requestPath: String?         // API endpoint path
    var httpMethod: String?          // GET, POST, PUT, DELETE

    // MARK: - Status
    var statusRaw: String
    var createdAt: Date
    var attemptedAt: Date?
    var completedAt: Date?
    var failedAt: Date?
    var errorMessage: String?
    var retryCount: Int
    var maxRetries: Int

    // MARK: - Priority & Ordering
    var priority: Int                // Higher = more important
    var sequenceNumber: Int          // Ensures ordering

    // MARK: - Dependencies
    var dependsOnActionId: String?   // Must complete this action first

    // MARK: - Initialization

    init(
        actionId: String = UUID().uuidString,
        actionType: OfflineActionType,
        entityType: String,
        entityId: String,
        payload: Encodable? = nil,
        requestPath: String? = nil,
        httpMethod: String? = nil,
        priority: Int = 0,
        sequenceNumber: Int = 0,
        dependsOnActionId: String? = nil,
        maxRetries: Int = 3
    ) {
        self.actionId = actionId
        self.actionTypeRaw = actionType.rawValue
        self.entityType = entityType
        self.entityId = entityId
        self.requestPath = requestPath
        self.httpMethod = httpMethod
        self.statusRaw = OfflineActionStatus.pending.rawValue
        self.createdAt = Date()
        self.attemptedAt = nil
        self.completedAt = nil
        self.failedAt = nil
        self.errorMessage = nil
        self.retryCount = 0
        self.maxRetries = maxRetries
        self.priority = priority
        self.sequenceNumber = sequenceNumber
        self.dependsOnActionId = dependsOnActionId

        if let payload = payload {
            let encoder = JSONEncoder()
            self.payloadJSON = try? encoder.encode(AnyEncodableWrapper(payload))
        }
    }

    // MARK: - Computed Properties

    var actionType: OfflineActionType {
        OfflineActionType(rawValue: actionTypeRaw) ?? .custom
    }

    var status: OfflineActionStatus {
        get { OfflineActionStatus(rawValue: statusRaw) ?? .pending }
        set { statusRaw = newValue.rawValue }
    }

    var canRetry: Bool {
        status == .failed && retryCount < maxRetries
    }

    var isStale: Bool {
        // Actions older than 7 days are considered stale
        Date().timeIntervalSince(createdAt) > 7 * 24 * 60 * 60
    }

    // MARK: - Payload Access

    func getPayload<T: Decodable>(as type: T.Type) -> T? {
        guard let data = payloadJSON else { return nil }
        let decoder = JSONDecoder()
        return try? decoder.decode(type, from: data)
    }

    // MARK: - Status Updates

    func markInProgress() {
        status = .inProgress
        attemptedAt = Date()
    }

    func markCompleted() {
        status = .completed
        completedAt = Date()
    }

    func markFailed(error: String) {
        status = .failed
        failedAt = Date()
        errorMessage = error
        retryCount += 1
    }

    func reset() {
        status = .pending
        attemptedAt = nil
        failedAt = nil
        errorMessage = nil
    }
}

// Note: OfflineActionType and OfflineActionStatus are defined above the #if block

// MARK: - Sync State

/// Tracks overall sync state for the app
@Model
final class SyncState {
    @Attribute(.unique) var id: String

    // MARK: - Last Sync Times
    var lastExerciseSync: Date?
    var lastWorkoutSync: Date?
    var lastProgramSync: Date?
    var lastFullSync: Date?

    // MARK: - Sync Status
    var isSyncing: Bool
    var lastSyncError: String?
    var pendingActionCount: Int

    // MARK: - Version Tracking
    var exerciseSyncVersion: Int
    var workoutSyncVersion: Int
    var programSyncVersion: Int

    init(id: String = "primary") {
        self.id = id
        self.lastExerciseSync = nil
        self.lastWorkoutSync = nil
        self.lastProgramSync = nil
        self.lastFullSync = nil
        self.isSyncing = false
        self.lastSyncError = nil
        self.pendingActionCount = 0
        self.exerciseSyncVersion = 0
        self.workoutSyncVersion = 0
        self.programSyncVersion = 0
    }
}

// MARK: - Video Download Record

/// Tracks downloaded video files
@Model
final class VideoDownloadRecord {
    @Attribute(.unique) var videoId: String

    var exerciseId: String?
    var remoteURL: String
    var localPath: String
    var fileName: String
    var fileSize: Int64
    var downloadedAt: Date
    var lastAccessedAt: Date
    var accessCount: Int
    var resolution: String
    var duration: TimeInterval
    var expiresAt: Date?           // For auto-cleanup

    // Download status
    var isComplete: Bool
    var bytesDownloaded: Int64
    var downloadProgress: Double

    init(
        videoId: String,
        exerciseId: String? = nil,
        remoteURL: String,
        localPath: String,
        fileName: String,
        fileSize: Int64,
        resolution: String,
        duration: TimeInterval,
        expiresAt: Date? = nil
    ) {
        self.videoId = videoId
        self.exerciseId = exerciseId
        self.remoteURL = remoteURL
        self.localPath = localPath
        self.fileName = fileName
        self.fileSize = fileSize
        self.downloadedAt = Date()
        self.lastAccessedAt = Date()
        self.accessCount = 0
        self.resolution = resolution
        self.duration = duration
        self.expiresAt = expiresAt
        self.isComplete = false
        self.bytesDownloaded = 0
        self.downloadProgress = 0
    }

    var localURL: URL? {
        URL(fileURLWithPath: localPath)
    }

    var isExpired: Bool {
        guard let expiresAt = expiresAt else { return false }
        return Date() > expiresAt
    }

    func recordAccess() {
        lastAccessedAt = Date()
        accessCount += 1
    }
}

// MARK: - Type Erasure Helper

private struct AnyEncodableWrapper: Encodable {
    private let _encode: (Encoder) throws -> Void

    init<T: Encodable>(_ wrapped: T) {
        _encode = wrapped.encode
    }

    func encode(to encoder: Encoder) throws {
        try _encode(encoder)
    }
}

// MARK: - SwiftData Container Configuration

extension ModelContainer {
    /// Create a container configured for MD Fit offline data
    static func mdfitContainer(inMemory: Bool = false) throws -> ModelContainer {
        let schema = Schema([
            CachedExercise.self,
            CachedWorkout.self,
            CachedProgram.self,
            OfflineAction.self,
            SyncState.self,
            VideoDownloadRecord.self
        ])

        let configuration = ModelConfiguration(
            "MDfitOffline",
            schema: schema,
            isStoredInMemoryOnly: inMemory,
            allowsSave: true
        )

        return try ModelContainer(
            for: schema,
            configurations: [configuration]
        )
    }
}

#endif // os(iOS)
