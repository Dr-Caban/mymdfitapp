//
//  BackendService.swift
//  MDfit
//
//  Backend service that provides a unified interface for content management.
//  Currently reads from local JSON files (CMS), with abstraction for future
//  remote backend integration.
//
//  This allows Dr. Jared to update content by editing JSON files now,
//  with seamless transition to a real backend later.
//

import Foundation
import os.log

// MARK: - Backend Configuration

/// Configuration for the backend service
public struct BackendConfiguration {
    let useLocalCMS: Bool
    let localCMSPath: URL?
    let remoteBaseURL: URL?
    let cacheExpirationInterval: TimeInterval
    let enableOfflineMode: Bool

    public static let `default` = BackendConfiguration(
        useLocalCMS: true,
        localCMSPath: nil,  // Uses bundle by default
        remoteBaseURL: URL(string: "https://api.mdfitsrq.com/api/v1"),
        cacheExpirationInterval: 3600,  // 1 hour
        enableOfflineMode: true
    )

    public static let remote = BackendConfiguration(
        useLocalCMS: false,
        localCMSPath: nil,
        remoteBaseURL: URL(string: "https://api.mdfitsrq.com/api/v1"),
        cacheExpirationInterval: 300,   // 5 minutes
        enableOfflineMode: true
    )

    public init(
        useLocalCMS: Bool,
        localCMSPath: URL? = nil,
        remoteBaseURL: URL? = nil,
        cacheExpirationInterval: TimeInterval = 3600,
        enableOfflineMode: Bool = true
    ) {
        self.useLocalCMS = useLocalCMS
        self.localCMSPath = localCMSPath
        self.remoteBaseURL = remoteBaseURL
        self.cacheExpirationInterval = cacheExpirationInterval
        self.enableOfflineMode = enableOfflineMode
    }
}

// MARK: - Backend Error

/// Errors that can occur during backend operations
public enum BackendError: LocalizedError {
    case contentNotFound(type: String, id: String?)
    case loadingFailed(underlying: Error)
    case decodingFailed(underlying: Error)
    case invalidConfiguration
    case networkUnavailable
    case cacheExpired
    case unauthorized
    case serverError(message: String)

    public var errorDescription: String? {
        switch self {
        case .contentNotFound(let type, let id):
            if let id = id {
                return "\(type) with ID '\(id)' not found."
            }
            return "\(type) content not found."
        case .loadingFailed(let error):
            return "Failed to load content: \(error.localizedDescription)"
        case .decodingFailed(let error):
            return "Failed to decode content: \(error.localizedDescription)"
        case .invalidConfiguration:
            return "Invalid backend configuration."
        case .networkUnavailable:
            return "Network is unavailable. Please check your connection."
        case .cacheExpired:
            return "Cached content has expired."
        case .unauthorized:
            return "You are not authorized to access this content."
        case .serverError(let message):
            return "Server error: \(message)"
        }
    }
}

// MARK: - Content Cache

/// Simple in-memory cache for content with expiration
actor ContentCache {
    private struct CacheEntry<T> {
        let value: T
        let timestamp: Date
        let expirationInterval: TimeInterval

        var isExpired: Bool {
            Date().timeIntervalSince(timestamp) > expirationInterval
        }
    }

    private var cache: [String: Any] = [:]
    private let defaultExpiration: TimeInterval

    init(defaultExpiration: TimeInterval = 3600) {
        self.defaultExpiration = defaultExpiration
    }

    func get<T>(_ key: String) -> T? {
        guard let entry = cache[key] as? CacheEntry<T> else { return nil }
        if entry.isExpired {
            cache.removeValue(forKey: key)
            return nil
        }
        return entry.value
    }

    func set<T>(_ key: String, value: T, expiration: TimeInterval? = nil) {
        let entry = CacheEntry(
            value: value,
            timestamp: Date(),
            expirationInterval: expiration ?? defaultExpiration
        )
        cache[key] = entry
    }

    func remove(_ key: String) {
        cache.removeValue(forKey: key)
    }

    func clear() {
        cache.removeAll()
    }
}

// MARK: - Backend Service

/// Main backend service for MD Fit content management
/// Provides a unified interface for exercises, programs, pain mappings, and user data
public actor BackendService {

    // MARK: - Properties

    private let configuration: BackendConfiguration
    private let cache: ContentCache
    private let logger = Logger(subsystem: "com.mdfit.backend", category: "service")
    private let jsonDecoder: JSONDecoder
    private let jsonEncoder: JSONEncoder

    // Content storage
    private var exercises: [String: Exercise] = [:]
    private var programs: [String: Program] = [:]
    private var painMappings: [String: PainMapping] = [:]
    private var users: [String: User] = [:]
    private var subscriptions: [String: Subscription] = [:]
    private var entitlements: [String: [Entitlement]] = [:]  // userId -> entitlements

    private var isLoaded = false

    // MARK: - Singleton

    public static let shared = BackendService()

    // MARK: - Initialization

    public init(configuration: BackendConfiguration = .default) {
        self.configuration = configuration
        self.cache = ContentCache(defaultExpiration: configuration.cacheExpirationInterval)

        // Configure JSON decoder
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        self.jsonDecoder = decoder

        // Configure JSON encoder
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        self.jsonEncoder = encoder
    }

    // MARK: - Content Loading

    /// Load all content from CMS (local JSON or remote API)
    public func loadContent() async throws {
        if isLoaded { return }

        logger.info("Loading backend content...")

        if configuration.useLocalCMS {
            try await loadLocalContent()
        } else {
            try await loadRemoteContent()
        }

        isLoaded = true
        logger.info("Backend content loaded successfully")
    }

    /// Force reload all content
    public func reloadContent() async throws {
        isLoaded = false
        await cache.clear()
        try await loadContent()
    }

    private func loadLocalContent() async throws {
        // Load exercises
        if let exercisesData = try await loadCMSFile("exercises.json") {
            let response = try jsonDecoder.decode(CMSExercisesResponse.self, from: exercisesData)
            exercises = Dictionary(uniqueKeysWithValues: response.exercises.map { ($0.id, $0) })
            logger.info("Loaded \(self.exercises.count) exercises from local CMS")
        }

        // Load programs
        if let programsData = try await loadCMSFile("programs.json") {
            let response = try jsonDecoder.decode(CMSProgramsResponse.self, from: programsData)
            programs = Dictionary(uniqueKeysWithValues: response.programs.map { ($0.id, $0) })
            logger.info("Loaded \(self.programs.count) programs from local CMS")
        }

        // Load pain mappings
        if let painData = try await loadCMSFile("pain_mappings.json") {
            let response = try jsonDecoder.decode(CMSPainMappingsResponse.self, from: painData)
            painMappings = Dictionary(uniqueKeysWithValues: response.mappings.map { ($0.id, $0) })
            logger.info("Loaded \(self.painMappings.count) pain mappings from local CMS")
        }
    }

    private func loadCMSFile(_ filename: String) async throws -> Data? {
        // Try custom path first
        if let customPath = configuration.localCMSPath {
            let fileURL = customPath.appendingPathComponent(filename)
            if FileManager.default.fileExists(atPath: fileURL.path) {
                return try Data(contentsOf: fileURL)
            }
        }

        // Try bundle
        if let bundleURL = Bundle.main.url(forResource: filename.replacingOccurrences(of: ".json", with: ""), withExtension: "json") {
            return try Data(contentsOf: bundleURL)
        }

        // Try Documents directory (for user-editable content)
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let documentsURL = documentsPath.appendingPathComponent("cms").appendingPathComponent(filename)
        if FileManager.default.fileExists(atPath: documentsURL.path) {
            return try Data(contentsOf: documentsURL)
        }

        logger.warning("CMS file not found: \(filename)")
        return nil
    }

    private func loadRemoteContent() async throws {
        do {
            // Load exercises from API
            let exercisesResponse: CMSExercisesResponse = try await APIClient.shared.get(.videos)
            exercises = Dictionary(uniqueKeysWithValues: exercisesResponse.exercises.map { ($0.id, $0) })
            logger.info("Loaded \(self.exercises.count) exercises from remote API")

            // Load programs from API
            let programsResponse: CMSProgramsResponse = try await APIClient.shared.get(.programs)
            programs = Dictionary(uniqueKeysWithValues: programsResponse.programs.map { ($0.id, $0) })
            logger.info("Loaded \(self.programs.count) programs from remote API")

            // Load pain mappings from API
            let painResponse: CMSPainMappingsResponse = try await APIClient.shared.get(.bodyRegions)
            painMappings = Dictionary(uniqueKeysWithValues: painResponse.mappings.map { ($0.id, $0) })
            logger.info("Loaded \(self.painMappings.count) pain mappings from remote API")

        } catch let error as APIError {
            logger.error("Failed to load remote content: \(error.localizedDescription)")

            // Fall back to local content if remote fails and offline mode is enabled
            if configuration.enableOfflineMode {
                logger.info("Falling back to local CMS content")
                try await loadLocalContent()
            } else {
                throw BackendError.networkUnavailable
            }
        }
    }

    // MARK: - Exercise Operations

    /// Get all exercises
    public func getAllExercises() async throws -> [Exercise] {
        try await ensureLoaded()
        return Array(exercises.values).sorted { $0.name < $1.name }
    }

    /// Get exercise by ID
    public func getExercise(id: String) async throws -> Exercise {
        try await ensureLoaded()
        guard let exercise = exercises[id] else {
            throw BackendError.contentNotFound(type: "Exercise", id: id)
        }
        return exercise
    }

    /// Get exercises by body region
    public func getExercises(forRegion region: BodyRegion) async throws -> [Exercise] {
        try await ensureLoaded()
        return exercises.values.filter { $0.bodyRegion == region }
    }

    /// Get exercises by category
    public func getExercises(forCategory category: ExerciseCategory) async throws -> [Exercise] {
        try await ensureLoaded()
        return exercises.values.filter { $0.category == category }
    }

    /// Get exercises by IDs
    public func getExercises(ids: [String]) async throws -> [Exercise] {
        try await ensureLoaded()
        return ids.compactMap { exercises[$0] }
    }

    /// Search exercises by name, tags, or muscle emphasis
    public func searchExercises(query: String) async throws -> [Exercise] {
        try await ensureLoaded()
        let lowercaseQuery = query.lowercased()
        return exercises.values.filter { exercise in
            exercise.name.lowercased().contains(lowercaseQuery) ||
            exercise.tags.contains { $0.lowercased().contains(lowercaseQuery) } ||
            exercise.muscleEmphasis.contains { $0.lowercased().contains(lowercaseQuery) }
        }
    }

    /// Get approved exercises only
    public func getApprovedExercises() async throws -> [Exercise] {
        try await ensureLoaded()
        return exercises.values.filter { $0.approvalStatus == .approved }
    }

    // MARK: - Program Operations

    /// Get all programs
    public func getAllPrograms() async throws -> [Program] {
        try await ensureLoaded()
        return Array(programs.values).sorted { $0.name < $1.name }
    }

    /// Get program by ID
    public func getProgram(id: String) async throws -> Program {
        try await ensureLoaded()
        guard let program = programs[id] else {
            throw BackendError.contentNotFound(type: "Program", id: id)
        }
        return program
    }

    /// Get programs by category
    public func getPrograms(forCategory category: ProgramCategory) async throws -> [Program] {
        try await ensureLoaded()
        return programs.values.filter { $0.category == category }
    }

    /// Get published programs only
    public func getPublishedPrograms() async throws -> [Program] {
        try await ensureLoaded()
        return programs.values.filter { $0.isPublished }
    }

    /// Get premium programs
    public func getPremiumPrograms() async throws -> [Program] {
        try await ensureLoaded()
        return programs.values.filter { $0.isPremium }
    }

    /// Get free programs (included with membership)
    public func getFreePrograms() async throws -> [Program] {
        try await ensureLoaded()
        return programs.values.filter { !$0.isPremium || $0.price == nil }
    }

    // MARK: - Pain Tool Operations

    /// Get pain mappings for a body region
    public func getPainMappings(forRegion region: BodyRegion) async throws -> [PainMapping] {
        try await ensureLoaded()
        return painMappings.values.filter {
            $0.bodyRegion == region || $0.referredAreas.contains(region)
        }
    }

    /// Get pain mapping by ID
    public func getPainMapping(id: String) async throws -> PainMapping {
        try await ensureLoaded()
        guard let mapping = painMappings[id] else {
            throw BackendError.contentNotFound(type: "PainMapping", id: id)
        }
        return mapping
    }

    /// Get exercises for a pain pattern
    public func getExercisesForPain(mappingId: String) async throws -> [Exercise] {
        let mapping = try await getPainMapping(id: mappingId)
        return try await getExercises(ids: mapping.suggestedExerciseIds)
    }

    /// Get all pain mappings
    public func getAllPainMappings() async throws -> [PainMapping] {
        try await ensureLoaded()
        return Array(painMappings.values)
    }

    // MARK: - User Management

    /// Get user by ID
    public func getUser(id: String) async throws -> User {
        // Try cache first
        if let cached: User = await cache.get("user_\(id)") {
            return cached
        }

        // Load from storage/API
        if let user = users[id] {
            await cache.set("user_\(id)", value: user)
            return user
        }

        throw BackendError.contentNotFound(type: "User", id: id)
    }

    /// Create or update user
    public func saveUser(_ user: User) async throws {
        users[user.id] = user
        await cache.set("user_\(user.id)", value: user)

        // Future: Persist to backend
        logger.info("Saved user: \(user.id)")
    }

    /// Delete user
    public func deleteUser(id: String) async throws {
        users.removeValue(forKey: id)
        await cache.remove("user_\(id)")
        entitlements.removeValue(forKey: id)

        logger.info("Deleted user: \(id)")
    }

    // MARK: - Subscription & Entitlement Operations

    /// Get user's subscription
    public func getSubscription(userId: String) async throws -> Subscription? {
        let user = try await getUser(id: userId)
        return user.subscription
    }

    /// Check if user has entitlement
    public func hasEntitlement(userId: String, type: EntitlementType, resourceId: String? = nil) async throws -> Bool {
        let user = try await getUser(id: userId)

        // Check subscription first
        if user.subscription?.isActive == true && type == .premium {
            return true
        }

        // Check specific entitlements
        return user.entitlements.contains { entitlement in
            entitlement.type == type &&
            entitlement.isValid &&
            (resourceId == nil || entitlement.resourceId == resourceId)
        }
    }

    /// Grant entitlement to user
    public func grantEntitlement(
        userId: String,
        type: EntitlementType,
        resourceId: String? = nil,
        expiresAt: Date? = nil,
        source: EntitlementSource
    ) async throws {
        var user = try await getUser(id: userId)

        let entitlement = Entitlement(
            id: "ent_\(UUID().uuidString.prefix(8))",
            type: type,
            resourceId: resourceId,
            grantedAt: Date(),
            expiresAt: expiresAt,
            source: source
        )

        user.entitlements.append(entitlement)
        try await saveUser(user)

        logger.info("Granted entitlement \(type.rawValue) to user \(userId)")
    }

    /// Revoke entitlement from user
    public func revokeEntitlement(userId: String, entitlementId: String) async throws {
        var user = try await getUser(id: userId)
        user.entitlements.removeAll { $0.id == entitlementId }
        try await saveUser(user)

        logger.info("Revoked entitlement \(entitlementId) from user \(userId)")
    }

    /// Get user's entitlements
    public func getEntitlements(userId: String) async throws -> [Entitlement] {
        let user = try await getUser(id: userId)
        return user.entitlements.filter { $0.isValid }
    }

    // MARK: - Content Access Control

    /// Check if user can access exercise
    public func canAccessExercise(userId: String?, exerciseId: String) async throws -> Bool {
        guard let userId = userId else {
            // Anonymous users: check if exercise is free
            let exercise = try await getExercise(id: exerciseId)
            return exercise.approvalStatus == .approved
        }

        return try await hasEntitlement(userId: userId, type: .premium) ||
               try await hasEntitlement(userId: userId, type: .unlimitedViews)
    }

    /// Check if user can access program
    public func canAccessProgram(userId: String, programId: String) async throws -> Bool {
        let program = try await getProgram(id: programId)

        // Free programs accessible to all
        if !program.isPremium { return true }

        // Check premium subscription
        if try await hasEntitlement(userId: userId, type: .premium) {
            return true
        }

        // Check specific program purchase
        return try await hasEntitlement(userId: userId, type: .program, resourceId: programId)
    }

    // MARK: - Analytics Data (for Admin)

    /// Get content statistics
    public func getContentStats() async throws -> ContentStats {
        try await ensureLoaded()

        let approvedExercises = exercises.values.filter { $0.approvalStatus == .approved }.count
        let publishedPrograms = programs.values.filter { $0.isPublished }.count

        return ContentStats(
            totalExercises: exercises.count,
            approvedExercises: approvedExercises,
            totalPrograms: programs.count,
            publishedPrograms: publishedPrograms,
            totalPainMappings: painMappings.count,
            totalUsers: users.count,
            lastUpdated: Date()
        )
    }

    // MARK: - CMS Write Operations (Admin)

    /// Update exercise (admin only)
    public func updateExercise(_ exercise: Exercise) async throws {
        exercises[exercise.id] = exercise
        await cache.remove("exercises_all")

        // Future: Persist to backend/file
        logger.info("Updated exercise: \(exercise.id)")
    }

    /// Update program (admin only)
    public func updateProgram(_ program: Program) async throws {
        programs[program.id] = program
        await cache.remove("programs_all")

        logger.info("Updated program: \(program.id)")
    }

    /// Update pain mapping (admin only)
    public func updatePainMapping(_ mapping: PainMapping) async throws {
        painMappings[mapping.id] = mapping

        logger.info("Updated pain mapping: \(mapping.id)")
    }

    // MARK: - Helper Methods

    private func ensureLoaded() async throws {
        if !isLoaded {
            try await loadContent()
        }
    }
}

// MARK: - CMS Response Models

/// Response model for exercises.json
struct CMSExercisesResponse: Codable {
    let version: String
    let lastUpdated: Date
    let exercises: [Exercise]
}

/// Response model for programs.json
struct CMSProgramsResponse: Codable {
    let version: String
    let lastUpdated: Date
    let programs: [Program]
}

/// Response model for pain_mappings.json
struct CMSPainMappingsResponse: Codable {
    let version: String
    let lastUpdated: Date
    let mappings: [PainMapping]
}

// MARK: - Pain Mapping Model (for CMS)

/// Pain mapping structure used in CMS
public struct PainMapping: Identifiable, Codable, Hashable {
    public let id: String
    public var name: String
    public var bodyRegion: BodyRegion
    public var referredAreas: [BodyRegion]
    public var commonCauses: [String]
    public var redFlags: [String]
    public var suggestedExerciseIds: [String]
    public var educationalContent: String
    public var disclaimer: String
    public var thumbnailURL: URL?
    public var severity: PainSeverity
    public var isActive: Bool

    public init(
        id: String,
        name: String,
        bodyRegion: BodyRegion,
        referredAreas: [BodyRegion],
        commonCauses: [String],
        redFlags: [String],
        suggestedExerciseIds: [String],
        educationalContent: String,
        disclaimer: String = PainPattern.defaultDisclaimer,
        thumbnailURL: URL? = nil,
        severity: PainSeverity = .moderate,
        isActive: Bool = true
    ) {
        self.id = id
        self.name = name
        self.bodyRegion = bodyRegion
        self.referredAreas = referredAreas
        self.commonCauses = commonCauses
        self.redFlags = redFlags
        self.suggestedExerciseIds = suggestedExerciseIds
        self.educationalContent = educationalContent
        self.disclaimer = disclaimer
        self.thumbnailURL = thumbnailURL
        self.severity = severity
        self.isActive = isActive
    }
}

/// Pain severity levels
public enum PainSeverity: String, Codable, CaseIterable, Hashable {
    case mild
    case moderate
    case severe

    public var displayName: String {
        rawValue.capitalized
    }
}

// MARK: - Content Stats

/// Statistics about CMS content
public struct ContentStats: Codable {
    public let totalExercises: Int
    public let approvedExercises: Int
    public let totalPrograms: Int
    public let publishedPrograms: Int
    public let totalPainMappings: Int
    public let totalUsers: Int
    public let lastUpdated: Date
}

// MARK: - Convenience Extensions

public extension BackendService {

    /// Get exercises suitable for a workout with given criteria
    func getExercisesForWorkout(
        goalType: WorkoutGoalType,
        location: WorkoutLocation,
        difficulty: DifficultyLevel,
        equipment: [Equipment]
    ) async throws -> [Exercise] {
        try await ensureLoaded()

        // Filter exercises based on criteria
        var filtered = exercises.values.filter { exercise in
            // Must be approved
            guard exercise.approvalStatus == .approved else { return false }

            // Match difficulty
            guard exercise.level == difficulty ||
                  (difficulty == .intermediate && exercise.level == .beginner) else {
                return false
            }

            // Check equipment availability
            let requiredEquipment = Set(exercise.equipment)
            let availableEquipment = Set(equipment + [.none])
            guard requiredEquipment.isSubset(of: availableEquipment) else {
                return false
            }

            return true
        }

        // Filter by goal type / body region
        switch goalType {
        case .upperBody:
            filtered = filtered.filter { [.shoulders, .chest, .upperBack, .arms].contains($0.bodyRegion) }
        case .lowerBody:
            filtered = filtered.filter { [.hips, .glutes, .quadriceps, .hamstrings, .calves, .ankles].contains($0.bodyRegion) }
        case .fullBody:
            // All exercises acceptable
            break
        case .cardio:
            filtered = filtered.filter { $0.category == .cardio }
        case .environmental:
            filtered = filtered.filter { $0.tags.contains("outdoor") || $0.tags.contains("swim") || $0.tags.contains("run") }
        }

        return Array(filtered)
    }

    /// Get the next workout in a program enrollment
    func getNextWorkout(programId: String, completedWorkoutIds: [String]) async throws -> (week: ProgramWeek, day: ProgramDay)? {
        let program = try await getProgram(id: programId)

        for week in program.weeks {
            for day in week.days {
                if !day.isRestDay && !completedWorkoutIds.contains(day.id) {
                    return (week, day)
                }
            }
        }

        return nil
    }
}
