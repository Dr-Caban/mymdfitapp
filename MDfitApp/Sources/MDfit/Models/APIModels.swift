//
//  APIModels.swift
//  MDfit
//
//  Codable models for API responses from both local CMS and remote backend.
//  These models provide a consistent interface for data exchange regardless
//  of the data source.
//

import Foundation

// MARK: - Generic API Responses

/// Standard wrapper for single-item API responses
public struct APIDataResponse<T: Decodable>: Decodable {
    public let success: Bool
    public let data: T
    public let message: String?
    public let timestamp: Date?

    public init(success: Bool = true, data: T, message: String? = nil, timestamp: Date? = nil) {
        self.success = success
        self.data = data
        self.message = message
        self.timestamp = timestamp ?? Date()
    }
}

/// Standard wrapper for list API responses
public struct APIListResponse<T: Decodable>: Decodable {
    public let success: Bool
    public let data: [T]
    public let pagination: APIPagination?
    public let message: String?
    public let timestamp: Date?
}

/// Pagination information for list responses
public struct APIPagination: Codable {
    public let page: Int
    public let perPage: Int
    public let totalPages: Int
    public let totalItems: Int

    public var hasNextPage: Bool {
        page < totalPages
    }

    public var hasPreviousPage: Bool {
        page > 1
    }

    public init(page: Int, perPage: Int, totalPages: Int, totalItems: Int) {
        self.page = page
        self.perPage = perPage
        self.totalPages = totalPages
        self.totalItems = totalItems
    }
}

/// Error response from API
public struct APIErrorResponse: Decodable, Error {
    public let success: Bool
    public let error: APIErrorDetail
    public let timestamp: Date?

    public struct APIErrorDetail: Decodable {
        public let code: String
        public let message: String
        public let field: String?
        public let details: [String: String]?
    }
}

// MARK: - Authentication Models

/// Login request
public struct LoginRequest: Encodable {
    public let email: String
    public let password: String
    public let deviceId: String?
    public let platform: String = "iOS"

    public init(email: String, password: String, deviceId: String? = nil) {
        self.email = email
        self.password = password
        self.deviceId = deviceId
    }
}

/// Login response
public struct LoginResponse: Decodable {
    public let user: UserResponse
    public let accessToken: String
    public let refreshToken: String?
    public let expiresIn: TimeInterval
}

/// Registration request
public struct RegisterRequest: Encodable {
    public let email: String
    public let password: String
    public let firstName: String
    public let lastName: String
    public let phone: String?
    public let dateOfBirth: Date?
    public let acceptedTerms: Bool
    public let marketingOptIn: Bool

    public init(
        email: String,
        password: String,
        firstName: String,
        lastName: String,
        phone: String? = nil,
        dateOfBirth: Date? = nil,
        acceptedTerms: Bool = true,
        marketingOptIn: Bool = false
    ) {
        self.email = email
        self.password = password
        self.firstName = firstName
        self.lastName = lastName
        self.phone = phone
        self.dateOfBirth = dateOfBirth
        self.acceptedTerms = acceptedTerms
        self.marketingOptIn = marketingOptIn
    }
}

/// Token refresh request
public struct RefreshTokenRequest: Encodable {
    public let refreshToken: String

    public init(refreshToken: String) {
        self.refreshToken = refreshToken
    }
}

/// Token refresh response
public struct RefreshTokenResponse: Decodable {
    public let accessToken: String
    public let refreshToken: String?
    public let expiresIn: TimeInterval
}

// MARK: - User Models

/// User response from API
public struct UserResponse: Decodable {
    public let id: String
    public let email: String
    public let firstName: String
    public let lastName: String
    public let phone: String?
    public let avatarUrl: URL?
    public let dateOfBirth: Date?
    public let subscription: SubscriptionResponse?
    public let entitlements: [EntitlementResponse]
    public let preferences: UserPreferencesResponse?
    public let isAdmin: Bool
    public let createdAt: Date
    public let updatedAt: Date

    /// Convert to domain User model
    public func toDomain() -> User {
        User(
            id: id,
            email: email,
            firstName: firstName,
            lastName: lastName,
            phone: phone,
            avatarURL: avatarUrl,
            dateOfBirth: dateOfBirth,
            subscription: subscription?.toDomain(),
            entitlements: entitlements.map { $0.toDomain() },
            preferences: preferences?.toDomain() ?? UserPreferences(),
            isAdmin: isAdmin,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

/// Update profile request
public struct UpdateProfileRequest: Encodable {
    public let firstName: String?
    public let lastName: String?
    public let phone: String?
    public let dateOfBirth: Date?

    public init(firstName: String? = nil, lastName: String? = nil, phone: String? = nil, dateOfBirth: Date? = nil) {
        self.firstName = firstName
        self.lastName = lastName
        self.phone = phone
        self.dateOfBirth = dateOfBirth
    }
}

/// User preferences response
public struct UserPreferencesResponse: Decodable {
    public let defaultLocation: String?
    public let defaultDifficulty: String?
    public let availableEquipment: [String]?
    public let excludedMovements: [String]?
    public let notificationsEnabled: Bool?
    public let workoutReminders: Bool?
    public let reminderTime: Date?
    public let calendarSync: Bool?

    public func toDomain() -> UserPreferences {
        UserPreferences(
            defaultLocation: WorkoutLocation(rawValue: defaultLocation ?? "") ?? .home,
            defaultDifficulty: DifficultyLevel(rawValue: defaultDifficulty ?? "") ?? .intermediate,
            availableEquipment: (availableEquipment ?? []).compactMap { Equipment(rawValue: $0) },
            excludedMovements: excludedMovements ?? [],
            notificationsEnabled: notificationsEnabled ?? true,
            workoutReminders: workoutReminders ?? true,
            reminderTime: reminderTime,
            calendarSync: calendarSync ?? true
        )
    }
}

// MARK: - Subscription Models

/// Subscription response from API
public struct SubscriptionResponse: Decodable {
    public let id: String
    public let tier: String
    public let status: String
    public let pricePerMonth: Decimal
    public let startDate: Date
    public let currentPeriodEnd: Date
    public let cancelAtPeriodEnd: Bool
    public let paymentMethod: String?

    public func toDomain() -> Subscription {
        Subscription(
            id: id,
            tier: SubscriptionTier(rawValue: tier) ?? .free,
            status: SubscriptionStatus(rawValue: status) ?? .expired,
            pricePerMonth: pricePerMonth,
            startDate: startDate,
            currentPeriodEnd: currentPeriodEnd,
            cancelAtPeriodEnd: cancelAtPeriodEnd,
            paymentMethod: paymentMethod
        )
    }
}

/// Entitlement response from API
public struct EntitlementResponse: Decodable {
    public let id: String
    public let type: String
    public let resourceId: String?
    public let grantedAt: Date
    public let expiresAt: Date?
    public let source: String

    public func toDomain() -> Entitlement {
        Entitlement(
            id: id,
            type: EntitlementType(rawValue: type) ?? .premium,
            resourceId: resourceId,
            grantedAt: grantedAt,
            expiresAt: expiresAt,
            source: EntitlementSource(rawValue: source) ?? .admin
        )
    }
}

// MARK: - Exercise Models

/// Exercise response from API
public struct ExerciseResponse: Decodable {
    public let id: String
    public let name: String
    public let videoAssetId: String?
    public let videoUrl: URL?
    public let thumbnailUrl: URL?
    public let bodyRegion: String
    public let muscleEmphasis: [String]
    public let category: String
    public let equipment: [String]
    public let level: String
    public let cues: [String]
    public let tempo: String?
    public let defaultPrescription: PrescriptionResponse
    public let modifications: [String]
    public let exclusions: [String]
    public let safetyNotes: String?
    public let approvalStatus: String
    public let tags: [String]
    public let createdAt: Date
    public let updatedAt: Date

    public func toDomain() -> Exercise {
        Exercise(
            id: id,
            name: name,
            videoAssetId: videoAssetId,
            bodyRegion: BodyRegion(rawValue: bodyRegion) ?? .fullBody,
            muscleEmphasis: muscleEmphasis,
            category: ExerciseCategory(rawValue: category) ?? .strengthening,
            equipment: equipment.compactMap { Equipment(rawValue: $0) },
            level: DifficultyLevel(rawValue: level) ?? .intermediate,
            cues: cues,
            tempo: tempo,
            defaultPrescription: defaultPrescription.toDomain(),
            modifications: modifications,
            exclusions: exclusions,
            safetyNotes: safetyNotes,
            approvalStatus: ApprovalStatus(rawValue: approvalStatus) ?? .draft,
            tags: tags,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

/// Prescription response from API
public struct PrescriptionResponse: Decodable {
    public let sets: Int?
    public let reps: Int?
    public let repRange: String?
    public let tempo: String?
    public let duration: Int?
    public let distance: Double?
    public let intensity: String?
    public let load: String?
    public let rest: Int?
    public let coachingCues: [String]?
    public let modification: String?
    public let stopRules: String?

    public func toDomain() -> Prescription {
        Prescription(
            sets: sets,
            reps: reps,
            repRange: repRange,
            tempo: tempo,
            duration: duration,
            distance: distance,
            intensity: intensity,
            load: load,
            rest: rest,
            coachingCues: coachingCues,
            modification: modification,
            stopRules: stopRules
        )
    }
}

// MARK: - Program Models

/// Program response from API
public struct ProgramResponse: Decodable {
    public let id: String
    public let name: String
    public let description: String
    public let category: String
    public let difficulty: String
    public let durationWeeks: Int
    public let thumbnailUrl: URL?
    public let weeks: [ProgramWeekResponse]
    public let price: Decimal?
    public let isPremium: Bool
    public let isPublished: Bool
    public let createdAt: Date
    public let updatedAt: Date

    public func toDomain() -> Program {
        Program(
            id: id,
            name: name,
            description: description,
            category: ProgramCategory(rawValue: category) ?? .general,
            difficulty: DifficultyLevel(rawValue: difficulty) ?? .intermediate,
            durationWeeks: durationWeeks,
            thumbnailURL: thumbnailUrl,
            weeks: weeks.map { $0.toDomain() },
            price: price,
            isPremium: isPremium,
            isPublished: isPublished,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

/// Program week response
public struct ProgramWeekResponse: Decodable {
    public let id: String
    public let weekNumber: Int
    public let name: String?
    public let days: [ProgramDayResponse]

    public func toDomain() -> ProgramWeek {
        ProgramWeek(
            id: id,
            weekNumber: weekNumber,
            name: name,
            days: days.map { $0.toDomain() }
        )
    }
}

/// Program day response
public struct ProgramDayResponse: Decodable {
    public let id: String
    public let dayNumber: Int
    public let dayOfWeek: String?
    public let name: String?
    public let workoutId: String?
    public let exercises: [WorkoutExerciseResponse]
    public let isRestDay: Bool
    public let isFreeformActivity: Bool
    public let notes: String?

    public func toDomain() -> ProgramDay {
        ProgramDay(
            id: id,
            dayNumber: dayNumber,
            dayOfWeek: dayOfWeek.flatMap { DayOfWeek(rawValue: $0) },
            name: name,
            workoutId: workoutId,
            exercises: exercises.map { $0.toDomain() },
            isRestDay: isRestDay,
            isFreeformActivity: isFreeformActivity,
            notes: notes
        )
    }
}

/// Workout exercise response
public struct WorkoutExerciseResponse: Decodable {
    public let id: String
    public let exerciseId: String
    public let exercise: ExerciseResponse?
    public let roundNumber: Int
    public let orderInRound: Int
    public let prescription: PrescriptionResponse
    public let isCompleted: Bool
    public let completedAt: Date?

    public func toDomain() -> WorkoutExercise {
        WorkoutExercise(
            id: id,
            exerciseId: exerciseId,
            exercise: exercise?.toDomain(),
            roundNumber: roundNumber,
            orderInRound: orderInRound,
            prescription: prescription.toDomain(),
            isCompleted: isCompleted,
            completedAt: completedAt
        )
    }
}

// MARK: - Enrollment Models

/// Program enrollment response
public struct EnrollmentResponse: Decodable {
    public let id: String
    public let userId: String
    public let programId: String
    public let program: ProgramResponse?
    public let startDate: Date
    public let currentWeek: Int
    public let currentDay: Int
    public let completedWorkouts: [String]
    public let status: String
    public let createdAt: Date
    public let updatedAt: Date

    public func toDomain() -> Enrollment {
        Enrollment(
            id: id,
            userId: userId,
            programId: programId,
            program: program?.toDomain(),
            startDate: startDate,
            currentWeek: currentWeek,
            currentDay: currentDay,
            completedWorkouts: completedWorkouts,
            status: EnrollmentStatus(rawValue: status) ?? .active,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

/// Enroll in program request
public struct EnrollProgramRequest: Encodable {
    public let programId: String
    public let startDate: Date?

    public init(programId: String, startDate: Date? = nil) {
        self.programId = programId
        self.startDate = startDate
    }
}

// MARK: - Pain Tool Models

/// Pain mapping response from API
public struct PainMappingResponse: Decodable {
    public let id: String
    public let name: String
    public let bodyRegion: String
    public let referredAreas: [String]
    public let commonCauses: [String]
    public let redFlags: [String]
    public let suggestedExerciseIds: [String]
    public let suggestedExercises: [ExerciseResponse]?
    public let educationalContent: String
    public let disclaimer: String
    public let thumbnailUrl: URL?
    public let severity: String
    public let isActive: Bool

    public func toDomain() -> PainMapping {
        PainMapping(
            id: id,
            name: name,
            bodyRegion: BodyRegion(rawValue: bodyRegion) ?? .lowerBack,
            referredAreas: referredAreas.compactMap { BodyRegion(rawValue: $0) },
            commonCauses: commonCauses,
            redFlags: redFlags,
            suggestedExerciseIds: suggestedExerciseIds,
            educationalContent: educationalContent,
            disclaimer: disclaimer,
            thumbnailUrl: thumbnailUrl,
            severity: PainSeverity(rawValue: severity) ?? .moderate,
            isActive: isActive
        )
    }
}

// MARK: - Workout Models

/// Workout response from API
public struct WorkoutResponse: Decodable {
    public let id: String
    public let userId: String?
    public let name: String?
    public let goalType: String
    public let location: String
    public let difficulty: String
    public let lengthMinutes: Int
    public let exercisesPerRound: Int
    public let totalRounds: Int
    public let restBetweenExercises: Int
    public let restBetweenRounds: Int
    public let addOns: WorkoutAddOnsResponse
    public let exercises: [WorkoutExerciseResponse]
    public let scheduledDate: Date?
    public let completedAt: Date?
    public let createdAt: Date
    public let updatedAt: Date

    public func toDomain() -> Workout {
        Workout(
            id: id,
            userId: userId,
            name: name,
            goalType: WorkoutGoalType(rawValue: goalType) ?? .fullBody,
            location: WorkoutLocation(rawValue: location) ?? .home,
            difficulty: DifficultyLevel(rawValue: difficulty) ?? .intermediate,
            lengthMinutes: lengthMinutes,
            exercisesPerRound: exercisesPerRound,
            totalRounds: totalRounds,
            restBetweenExercises: restBetweenExercises,
            restBetweenRounds: restBetweenRounds,
            addOns: addOns.toDomain(),
            exercises: exercises.map { $0.toDomain() },
            scheduledDate: scheduledDate,
            completedAt: completedAt,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

/// Workout add-ons response
public struct WorkoutAddOnsResponse: Decodable {
    public let warmUp: Bool
    public let coolDown: Bool
    public let mobilityFlexibility: Bool
    public let coreWork: Bool
    public let balanceStability: Bool
    public let sportSpecific: Bool
    public let equipmentRestrictions: Bool
    public let restrictedEquipment: [String]?

    public func toDomain() -> WorkoutAddOns {
        WorkoutAddOns(
            warmUp: warmUp,
            coolDown: coolDown,
            mobilityFlexibility: mobilityFlexibility,
            coreWork: coreWork,
            balanceStability: balanceStability,
            sportSpecific: sportSpecific,
            equipmentRestrictions: equipmentRestrictions,
            restrictedEquipment: restrictedEquipment?.compactMap { Equipment(rawValue: $0) }
        )
    }
}

/// Generate workout request
public struct GenerateWorkoutRequest: Encodable {
    public let goalType: String
    public let location: String
    public let difficulty: String
    public let lengthMinutes: Int
    public let exercisesPerRound: Int
    public let totalRounds: Int
    public let restBetweenExercises: Int
    public let restBetweenRounds: Int
    public let addOns: WorkoutAddOnsRequest

    public init(from settings: WorkoutGeneratorSettings) {
        self.goalType = settings.goalType.rawValue
        self.location = settings.location.rawValue
        self.difficulty = settings.difficulty.rawValue
        self.lengthMinutes = settings.lengthMinutes
        self.exercisesPerRound = settings.exercisesPerRound
        self.totalRounds = settings.totalRounds
        self.restBetweenExercises = settings.restBetweenExercises
        self.restBetweenRounds = settings.restBetweenRounds
        self.addOns = WorkoutAddOnsRequest(from: settings.addOns)
    }
}

/// Workout add-ons request
public struct WorkoutAddOnsRequest: Encodable {
    public let warmUp: Bool
    public let coolDown: Bool
    public let mobilityFlexibility: Bool
    public let coreWork: Bool
    public let balanceStability: Bool
    public let sportSpecific: Bool
    public let equipmentRestrictions: Bool
    public let restrictedEquipment: [String]?

    public init(from addOns: WorkoutAddOns) {
        self.warmUp = addOns.warmUp
        self.coolDown = addOns.coolDown
        self.mobilityFlexibility = addOns.mobilityFlexibility
        self.coreWork = addOns.coreWork
        self.balanceStability = addOns.balanceStability
        self.sportSpecific = addOns.sportSpecific
        self.equipmentRestrictions = addOns.equipmentRestrictions
        self.restrictedEquipment = addOns.restrictedEquipment?.map { $0.rawValue }
    }
}

/// Complete workout request
public struct CompleteWorkoutRequest: Encodable {
    public let workoutId: String
    public let completedAt: Date
    public let duration: Int?  // actual duration in seconds
    public let notes: String?
    public let rating: Int?    // 1-5 stars

    public init(workoutId: String, completedAt: Date = Date(), duration: Int? = nil, notes: String? = nil, rating: Int? = nil) {
        self.workoutId = workoutId
        self.completedAt = completedAt
        self.duration = duration
        self.notes = notes
        self.rating = rating
    }
}

// MARK: - Video Review Models (Future)

/// Submit video review request
public struct SubmitReviewRequest: Encodable {
    public let exerciseId: String?
    public let notes: String?

    public init(exerciseId: String? = nil, notes: String? = nil) {
        self.exerciseId = exerciseId
        self.notes = notes
    }
}

/// Video review response
public struct ReviewSubmissionResponse: Decodable {
    public let id: String
    public let userId: String
    public let videoUrl: URL
    public let exerciseId: String?
    public let notes: String?
    public let status: String
    public let feedback: String?
    public let feedbackVideoUrl: URL?
    public let submittedAt: Date
    public let reviewedAt: Date?

    public func toDomain() -> ReviewSubmission {
        ReviewSubmission(
            id: id,
            userId: userId,
            videoURL: videoUrl,
            exerciseId: exerciseId,
            notes: notes,
            status: ReviewStatus(rawValue: status) ?? .pending,
            feedback: feedback,
            feedbackVideoURL: feedbackVideoUrl,
            submittedAt: submittedAt,
            reviewedAt: reviewedAt
        )
    }
}

// MARK: - Event/Calendar Models

/// Event response from API
public struct EventResponse: Decodable {
    public let id: String
    public let title: String
    public let description: String?
    public let eventType: String
    public let startDate: Date
    public let endDate: Date
    public let location: String?
    public let isVirtual: Bool
    public let virtualMeetingUrl: URL?
    public let capacity: Int?
    public let registeredCount: Int
    public let price: Decimal?
    public let isRecurring: Bool
    public let recurrenceRule: String?
    public let hostId: String
    public let createdAt: Date
    public let updatedAt: Date

    public func toDomain() -> Event {
        Event(
            id: id,
            title: title,
            description: description,
            eventType: EventType(rawValue: eventType) ?? .groupClass,
            startDate: startDate,
            endDate: endDate,
            location: location,
            isVirtual: isVirtual,
            virtualMeetingURL: virtualMeetingUrl,
            capacity: capacity,
            registeredCount: registeredCount,
            price: price,
            isRecurring: isRecurring,
            recurrenceRule: recurrenceRule,
            hostId: hostId,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

/// Register for event request
public struct RegisterEventRequest: Encodable {
    public let eventId: String
    public let notes: String?

    public init(eventId: String, notes: String? = nil) {
        self.eventId = eventId
        self.notes = notes
    }
}

// MARK: - Analytics Models (Admin)

/// Dashboard stats response
public struct DashboardStatsResponse: Decodable {
    public let totalUsers: Int
    public let activeUsers: Int
    public let totalWorkoutsCompleted: Int
    public let totalVideoViews: Int
    public let activeSubscriptions: Int
    public let mrr: Decimal
    public let churnRate: Double
    public let topExercises: [TopExerciseResponse]
    public let topPrograms: [TopProgramResponse]
    public let periodStart: Date
    public let periodEnd: Date
}

/// Top exercise stats
public struct TopExerciseResponse: Decodable {
    public let exerciseId: String
    public let name: String
    public let viewCount: Int
    public let completionCount: Int
}

/// Top program stats
public struct TopProgramResponse: Decodable {
    public let programId: String
    public let name: String
    public let enrollmentCount: Int
    public let completionRate: Double
}

// MARK: - Search Models

/// Search request
public struct SearchRequest: Encodable {
    public let query: String
    public let types: [String]?      // ["exercise", "program", "event"]
    public let filters: SearchFilters?
    public let page: Int?
    public let perPage: Int?

    public init(query: String, types: [String]? = nil, filters: SearchFilters? = nil, page: Int? = nil, perPage: Int? = nil) {
        self.query = query
        self.types = types
        self.filters = filters
        self.page = page
        self.perPage = perPage
    }
}

/// Search filters
public struct SearchFilters: Encodable {
    public let bodyRegion: String?
    public let category: String?
    public let difficulty: String?
    public let equipment: [String]?

    public init(bodyRegion: String? = nil, category: String? = nil, difficulty: String? = nil, equipment: [String]? = nil) {
        self.bodyRegion = bodyRegion
        self.category = category
        self.difficulty = difficulty
        self.equipment = equipment
    }
}

/// Search results response
public struct SearchResultsResponse: Decodable {
    public let exercises: [ExerciseResponse]?
    public let programs: [ProgramResponse]?
    public let events: [EventResponse]?
    public let totalResults: Int
    public let pagination: APIPagination
}
