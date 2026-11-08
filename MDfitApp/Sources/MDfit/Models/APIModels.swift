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
struct APIDataResponse<T: Decodable>: Decodable {
    let success: Bool
    let data: T
    let message: String?
    let timestamp: Date?

    init(success: Bool = true, data: T, message: String? = nil, timestamp: Date? = nil) {
        self.success = success
        self.data = data
        self.message = message
        self.timestamp = timestamp ?? Date()
    }
}

/// Standard wrapper for list API responses
struct APIListResponse<T: Decodable>: Decodable {
    let success: Bool
    let data: [T]
    let pagination: APIPagination?
    let message: String?
    let timestamp: Date?
}

/// Pagination information for list responses
struct APIPagination: Codable {
    let page: Int
    let perPage: Int
    let totalPages: Int
    let totalItems: Int

    var hasNextPage: Bool {
        page < totalPages
    }

    var hasPreviousPage: Bool {
        page > 1
    }

    init(page: Int, perPage: Int, totalPages: Int, totalItems: Int) {
        self.page = page
        self.perPage = perPage
        self.totalPages = totalPages
        self.totalItems = totalItems
    }
}

/// Error response from API
struct APIErrorResponse: Decodable, Error {
    let success: Bool
    let error: APIErrorDetail
    let timestamp: Date?

    struct APIErrorDetail: Decodable {
        let code: String
        let message: String
        let field: String?
        let details: [String: String]?
    }
}

// MARK: - Authentication Models

/// Login request
struct LoginRequest: Encodable {
    let email: String
    let password: String
    let deviceId: String?
    let platform: String = "iOS"

    init(email: String, password: String, deviceId: String? = nil) {
        self.email = email
        self.password = password
        self.deviceId = deviceId
    }
}

/// Login response
struct LoginResponse: Decodable {
    let user: UserResponse
    let accessToken: String
    let refreshToken: String?
    let expiresIn: TimeInterval
}

/// Registration request
struct RegisterRequest: Encodable {
    let email: String
    let password: String
    let firstName: String
    let lastName: String
    let phone: String?
    let dateOfBirth: Date?
    let acceptedTerms: Bool
    let marketingOptIn: Bool

    init(
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
struct RefreshTokenRequest: Encodable {
    let refreshToken: String

    init(refreshToken: String) {
        self.refreshToken = refreshToken
    }
}

/// Token refresh response
struct RefreshTokenResponse: Decodable {
    let accessToken: String
    let refreshToken: String?
    let expiresIn: TimeInterval
}

// MARK: - User Models

/// User response from API
struct UserResponse: Decodable {
    let id: String
    let email: String
    let firstName: String
    let lastName: String
    let phone: String?
    let avatarUrl: URL?
    let dateOfBirth: Date?
    let subscription: SubscriptionResponse?
    let entitlements: [EntitlementResponse]
    let preferences: UserPreferencesResponse?
    let isAdmin: Bool
    let createdAt: Date
    let updatedAt: Date

    /// Convert to domain User model
    func toDomain() -> User {
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
struct UpdateProfileRequest: Encodable {
    let firstName: String?
    let lastName: String?
    let phone: String?
    let dateOfBirth: Date?

    init(firstName: String? = nil, lastName: String? = nil, phone: String? = nil, dateOfBirth: Date? = nil) {
        self.firstName = firstName
        self.lastName = lastName
        self.phone = phone
        self.dateOfBirth = dateOfBirth
    }
}

/// User preferences response
struct UserPreferencesResponse: Decodable {
    let defaultLocation: String?
    let defaultDifficulty: String?
    let availableEquipment: [String]?
    let excludedMovements: [String]?
    let notificationsEnabled: Bool?
    let workoutReminders: Bool?
    let reminderTime: Date?
    let calendarSync: Bool?

    func toDomain() -> UserPreferences {
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
struct SubscriptionResponse: Decodable {
    let id: String
    let tier: String
    let status: String
    let pricePerMonth: Decimal
    let startDate: Date
    let currentPeriodEnd: Date
    let cancelAtPeriodEnd: Bool
    let paymentMethod: String?

    func toDomain() -> Subscription {
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
struct EntitlementResponse: Decodable {
    let id: String
    let type: String
    let resourceId: String?
    let grantedAt: Date
    let expiresAt: Date?
    let source: String

    func toDomain() -> Entitlement {
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
struct ExerciseResponse: Decodable {
    let id: String
    let name: String
    let videoAssetId: String?
    let videoUrl: URL?
    let thumbnailUrl: URL?
    let bodyRegion: String
    let muscleEmphasis: [String]
    let category: String
    let equipment: [String]
    let level: String
    let cues: [String]
    let tempo: String?
    let defaultPrescription: PrescriptionResponse
    let modifications: [String]
    let exclusions: [String]
    let safetyNotes: String?
    let approvalStatus: String
    let tags: [String]
    let createdAt: Date
    let updatedAt: Date

    func toDomain() -> Exercise {
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
struct PrescriptionResponse: Decodable {
    let sets: Int?
    let reps: Int?
    let repRange: String?
    let tempo: String?
    let duration: Int?
    let distance: Double?
    let intensity: String?
    let load: String?
    let rest: Int?
    let coachingCues: [String]?
    let modification: String?
    let stopRules: String?

    func toDomain() -> Prescription {
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
struct ProgramResponse: Decodable {
    let id: String
    let name: String
    let description: String
    let category: String
    let difficulty: String
    let durationWeeks: Int
    let thumbnailUrl: URL?
    let weeks: [ProgramWeekResponse]
    let price: Decimal?
    let isPremium: Bool
    let isPublished: Bool
    let createdAt: Date
    let updatedAt: Date

    func toDomain() -> Program {
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
struct ProgramWeekResponse: Decodable {
    let id: String
    let weekNumber: Int
    let name: String?
    let days: [ProgramDayResponse]

    func toDomain() -> ProgramWeek {
        ProgramWeek(
            id: id,
            weekNumber: weekNumber,
            name: name,
            days: days.map { $0.toDomain() }
        )
    }
}

/// Program day response
struct ProgramDayResponse: Decodable {
    let id: String
    let dayNumber: Int
    let dayOfWeek: String?
    let name: String?
    let workoutId: String?
    let exercises: [WorkoutExerciseResponse]
    let isRestDay: Bool
    let isFreeformActivity: Bool
    let notes: String?

    func toDomain() -> ProgramDay {
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
struct WorkoutExerciseResponse: Decodable {
    let id: String
    let exerciseId: String
    let exercise: ExerciseResponse?
    let roundNumber: Int
    let orderInRound: Int
    let prescription: PrescriptionResponse
    let isCompleted: Bool
    let completedAt: Date?

    func toDomain() -> WorkoutExercise {
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
struct EnrollmentResponse: Decodable {
    let id: String
    let userId: String
    let programId: String
    let program: ProgramResponse?
    let startDate: Date
    let currentWeek: Int
    let currentDay: Int
    let completedWorkouts: [String]
    let status: String
    let createdAt: Date
    let updatedAt: Date

    func toDomain() -> Enrollment {
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
struct EnrollProgramRequest: Encodable {
    let programId: String
    let startDate: Date?

    init(programId: String, startDate: Date? = nil) {
        self.programId = programId
        self.startDate = startDate
    }
}

// MARK: - Pain Tool Models

/// Pain mapping response from API
struct PainMappingResponse: Decodable {
    let id: String
    let name: String
    let bodyRegion: String
    let referredAreas: [String]
    let commonCauses: [String]
    let redFlags: [String]
    let suggestedExerciseIds: [String]
    let suggestedExercises: [ExerciseResponse]?
    let educationalContent: String
    let disclaimer: String
    let thumbnailUrl: URL?
    let severity: String
    let isActive: Bool

    func toDomain() -> PainMapping {
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
struct WorkoutResponse: Decodable {
    let id: String
    let userId: String?
    let name: String?
    let goalType: String
    let location: String
    let difficulty: String
    let lengthMinutes: Int
    let exercisesPerRound: Int
    let totalRounds: Int
    let restBetweenExercises: Int
    let restBetweenRounds: Int
    let addOns: WorkoutAddOnsResponse
    let exercises: [WorkoutExerciseResponse]
    let scheduledDate: Date?
    let completedAt: Date?
    let createdAt: Date
    let updatedAt: Date

    func toDomain() -> Workout {
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
struct WorkoutAddOnsResponse: Decodable {
    let warmUp: Bool
    let coolDown: Bool
    let mobilityFlexibility: Bool
    let coreWork: Bool
    let balanceStability: Bool
    let sportSpecific: Bool
    let equipmentRestrictions: Bool
    let restrictedEquipment: [String]?

    func toDomain() -> WorkoutAddOns {
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
struct GenerateWorkoutRequest: Encodable {
    let goalType: String
    let location: String
    let difficulty: String
    let lengthMinutes: Int
    let exercisesPerRound: Int
    let totalRounds: Int
    let restBetweenExercises: Int
    let restBetweenRounds: Int
    let addOns: WorkoutAddOnsRequest

    init(from settings: WorkoutGeneratorSettings) {
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
struct WorkoutAddOnsRequest: Encodable {
    let warmUp: Bool
    let coolDown: Bool
    let mobilityFlexibility: Bool
    let coreWork: Bool
    let balanceStability: Bool
    let sportSpecific: Bool
    let equipmentRestrictions: Bool
    let restrictedEquipment: [String]?

    init(from addOns: WorkoutAddOns) {
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
struct CompleteWorkoutRequest: Encodable {
    let workoutId: String
    let completedAt: Date
    let duration: Int?  // actual duration in seconds
    let notes: String?
    let rating: Int?    // 1-5 stars

    init(workoutId: String, completedAt: Date = Date(), duration: Int? = nil, notes: String? = nil, rating: Int? = nil) {
        self.workoutId = workoutId
        self.completedAt = completedAt
        self.duration = duration
        self.notes = notes
        self.rating = rating
    }
}

// MARK: - Video Review Models (Future)

/// Submit video review request
struct SubmitReviewRequest: Encodable {
    let exerciseId: String?
    let notes: String?

    init(exerciseId: String? = nil, notes: String? = nil) {
        self.exerciseId = exerciseId
        self.notes = notes
    }
}

/// Video review response
struct ReviewSubmissionResponse: Decodable {
    let id: String
    let userId: String
    let videoUrl: URL
    let exerciseId: String?
    let notes: String?
    let status: String
    let feedback: String?
    let feedbackVideoUrl: URL?
    let submittedAt: Date
    let reviewedAt: Date?

    func toDomain() -> ReviewSubmission {
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
struct EventResponse: Decodable {
    let id: String
    let title: String
    let description: String?
    let eventType: String
    let startDate: Date
    let endDate: Date
    let location: String?
    let isVirtual: Bool
    let virtualMeetingUrl: URL?
    let capacity: Int?
    let registeredCount: Int
    let price: Decimal?
    let isRecurring: Bool
    let recurrenceRule: String?
    let hostId: String
    let createdAt: Date
    let updatedAt: Date

    func toDomain() -> Event {
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
struct RegisterEventRequest: Encodable {
    let eventId: String
    let notes: String?

    init(eventId: String, notes: String? = nil) {
        self.eventId = eventId
        self.notes = notes
    }
}

// MARK: - Analytics Models (Admin)

/// Dashboard stats response
struct DashboardStatsResponse: Decodable {
    let totalUsers: Int
    let activeUsers: Int
    let totalWorkoutsCompleted: Int
    let totalVideoViews: Int
    let activeSubscriptions: Int
    let mrr: Decimal
    let churnRate: Double
    let topExercises: [TopExerciseResponse]
    let topPrograms: [TopProgramResponse]
    let periodStart: Date
    let periodEnd: Date
}

/// Top exercise stats
struct TopExerciseResponse: Decodable {
    let exerciseId: String
    let name: String
    let viewCount: Int
    let completionCount: Int
}

/// Top program stats
struct TopProgramResponse: Decodable {
    let programId: String
    let name: String
    let enrollmentCount: Int
    let completionRate: Double
}

// MARK: - Search Models

/// Search request
struct SearchRequest: Encodable {
    let query: String
    let types: [String]?      // ["exercise", "program", "event"]
    let filters: SearchFilters?
    let page: Int?
    let perPage: Int?

    init(query: String, types: [String]? = nil, filters: SearchFilters? = nil, page: Int? = nil, perPage: Int? = nil) {
        self.query = query
        self.types = types
        self.filters = filters
        self.page = page
        self.perPage = perPage
    }
}

/// Search filters
struct SearchFilters: Encodable {
    let bodyRegion: String?
    let category: String?
    let difficulty: String?
    let equipment: [String]?

    init(bodyRegion: String? = nil, category: String? = nil, difficulty: String? = nil, equipment: [String]? = nil) {
        self.bodyRegion = bodyRegion
        self.category = category
        self.difficulty = difficulty
        self.equipment = equipment
    }
}

/// Search results response
struct SearchResultsResponse: Decodable {
    let exercises: [ExerciseResponse]?
    let programs: [ProgramResponse]?
    let events: [EventResponse]?
    let totalResults: Int
    let pagination: APIPagination
}
