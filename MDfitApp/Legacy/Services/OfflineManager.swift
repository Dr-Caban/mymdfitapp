//
//  OfflineManager.swift
//  MDfit
//
//  Production-ready offline manager that handles network state detection,
//  action queuing, and background synchronization for MD Fit.
//

import Foundation

#if os(iOS)
import SwiftUI
import SwiftData
import Network
import Combine
import os.log

// MARK: - Offline Manager

/// Central service for managing offline state, action queuing, and synchronization
@MainActor
final class OfflineManager: ObservableObject {

    // MARK: - Singleton

    static let shared = OfflineManager()

    // MARK: - Published State

    @Published private(set) var isOnline: Bool = true
    @Published private(set) var connectionType: ConnectionType = .unknown
    @Published private(set) var isSyncing: Bool = false
    @Published private(set) var pendingActionsCount: Int = 0
    @Published private(set) var lastSyncDate: Date?
    @Published private(set) var syncError: OfflineSyncError?

    // MARK: - Constants

    private enum Constants {
        static let syncDebounceSeconds: TimeInterval = 2.0
        static let maxConcurrentActions = 3
        static let retryDelayBase: TimeInterval = 1.0
        static let maxRetryDelay: TimeInterval = 60.0
        static let staleActionDays = 7
        static let syncBatchSize = 20
    }

    // MARK: - Private Properties

    private let logger = Logger(subsystem: "com.mdfit.offline", category: "sync")
    private let networkMonitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "com.mdfit.network-monitor")
    private var modelContainer: ModelContainer?
    private var syncTask: Task<Void, Never>?
    private var syncDebounceTask: Task<Void, Never>?
    private var actionQueue = OperationQueue()
    private var cancellables = Set<AnyCancellable>()
    private var sequenceCounter: Int = 0

    // MARK: - Initialization

    private init() {
        setupActionQueue()
        setupNetworkMonitor()
    }

    // MARK: - Setup

    /// Configure the offline manager with a model container
    func configure(with container: ModelContainer) {
        self.modelContainer = container
        loadPendingActionsCount()
        loadLastSyncDate()
    }

    private func setupActionQueue() {
        actionQueue.maxConcurrentOperationCount = Constants.maxConcurrentActions
        actionQueue.qualityOfService = .userInitiated
    }

    private func setupNetworkMonitor() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor [weak self] in
                self?.handleNetworkChange(path)
            }
        }
        networkMonitor.start(queue: monitorQueue)
    }

    private func handleNetworkChange(_ path: NWPath) {
        let wasOnline = isOnline
        isOnline = path.status == .satisfied

        // Determine connection type
        if path.usesInterfaceType(.wifi) {
            connectionType = .wifi
        } else if path.usesInterfaceType(.cellular) {
            connectionType = .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            connectionType = .wired
        } else {
            connectionType = .unknown
        }

        logger.info("Network state changed: online=\(self.isOnline), type=\(self.connectionType.rawValue)")

        // Trigger sync when coming back online
        if !wasOnline && isOnline {
            logger.info("Device came online, triggering sync...")
            scheduleSyncDebounced()
        }
    }

    // MARK: - Public API: Action Queuing

    /// Queue an action for execution (immediate if online, deferred if offline)
    func queueAction(
        type: OfflineActionType,
        entityType: String,
        entityId: String,
        payload: Encodable? = nil,
        requestPath: String? = nil,
        httpMethod: String? = nil,
        priority: Int = 0,
        dependsOn: String? = nil
    ) async throws {
        guard let container = modelContainer else {
            throw OfflineSyncError.notConfigured
        }

        let context = ModelContext(container)
        sequenceCounter += 1

        let action = OfflineAction(
            actionType: type,
            entityType: entityType,
            entityId: entityId,
            payload: payload,
            requestPath: requestPath,
            httpMethod: httpMethod,
            priority: priority,
            sequenceNumber: sequenceCounter,
            dependsOnActionId: dependsOn
        )

        context.insert(action)
        try context.save()

        pendingActionsCount += 1
        logger.debug("Queued offline action: \(type.rawValue) for \(entityType)/\(entityId)")

        // Try to execute immediately if online
        if isOnline {
            scheduleSyncDebounced()
        }
    }

    /// Queue a workout completion action
    func queueWorkoutCompletion(workoutId: String, completedAt: Date = Date()) async throws {
        struct CompletionPayload: Codable {
            let workoutId: String
            let completedAt: Date
        }

        try await queueAction(
            type: .completeWorkout,
            entityType: "workout",
            entityId: workoutId,
            payload: CompletionPayload(workoutId: workoutId, completedAt: completedAt),
            requestPath: "/workouts/\(workoutId)/complete",
            httpMethod: "POST",
            priority: 10  // High priority
        )
    }

    /// Queue an exercise completion action
    func queueExerciseCompletion(
        exerciseId: String,
        workoutId: String,
        completedAt: Date = Date()
    ) async throws {
        struct ExerciseCompletionPayload: Codable {
            let exerciseId: String
            let workoutId: String
            let completedAt: Date
        }

        try await queueAction(
            type: .completeExercise,
            entityType: "exercise",
            entityId: exerciseId,
            payload: ExerciseCompletionPayload(
                exerciseId: exerciseId,
                workoutId: workoutId,
                completedAt: completedAt
            ),
            requestPath: "/workouts/\(workoutId)/exercises/\(exerciseId)/complete",
            httpMethod: "POST",
            priority: 8
        )
    }

    /// Queue a workout creation action
    func queueWorkoutCreation(workout: Workout) async throws {
        try await queueAction(
            type: .createWorkout,
            entityType: "workout",
            entityId: workout.id,
            payload: workout,
            requestPath: "/workouts",
            httpMethod: "POST",
            priority: 5
        )
    }

    /// Queue a program enrollment action
    func queueProgramEnrollment(programId: String, startDate: Date = Date()) async throws {
        struct EnrollmentPayload: Codable {
            let programId: String
            let startDate: Date
        }

        try await queueAction(
            type: .enrollProgram,
            entityType: "program",
            entityId: programId,
            payload: EnrollmentPayload(programId: programId, startDate: startDate),
            requestPath: "/programs/\(programId)/enroll",
            httpMethod: "POST",
            priority: 7
        )
    }

    // MARK: - Public API: Synchronization

    /// Trigger a manual sync
    func syncNow() async throws {
        guard isOnline else {
            throw OfflineSyncError.offline
        }
        await performSync()
    }

    /// Cancel any ongoing sync
    func cancelSync() {
        syncTask?.cancel()
        syncTask = nil
        isSyncing = false
    }

    /// Get pending actions
    func getPendingActions() async throws -> [OfflineAction] {
        guard let container = modelContainer else {
            throw OfflineSyncError.notConfigured
        }

        let context = ModelContext(container)
        let descriptor = FetchDescriptor<OfflineAction>(
            predicate: #Predicate { action in
                action.statusRaw == "pending" || action.statusRaw == "failed"
            },
            sortBy: [
                SortDescriptor(\.priority, order: .reverse),
                SortDescriptor(\.sequenceNumber)
            ]
        )

        return try context.fetch(descriptor)
    }

    /// Clear completed actions
    func clearCompletedActions() async throws {
        guard let container = modelContainer else {
            throw OfflineSyncError.notConfigured
        }

        let context = ModelContext(container)
        let descriptor = FetchDescriptor<OfflineAction>(
            predicate: #Predicate { action in
                action.statusRaw == "completed"
            }
        )

        let actions = try context.fetch(descriptor)
        for action in actions {
            context.delete(action)
        }
        try context.save()

        logger.info("Cleared \(actions.count) completed actions")
    }

    /// Clear stale failed actions
    func clearStaleActions() async throws {
        guard let container = modelContainer else {
            throw OfflineSyncError.notConfigured
        }

        let context = ModelContext(container)
        let staleDate = Date().addingTimeInterval(-Double(Constants.staleActionDays) * 24 * 60 * 60)

        let descriptor = FetchDescriptor<OfflineAction>(
            predicate: #Predicate { action in
                action.createdAt < staleDate
            }
        )

        let actions = try context.fetch(descriptor)
        for action in actions {
            context.delete(action)
        }
        try context.save()

        pendingActionsCount = try await getPendingActionsCount()
        logger.info("Cleared \(actions.count) stale actions")
    }

    // MARK: - Public API: Caching

    /// Cache exercises for offline use
    func cacheExercises(_ exercises: [Exercise]) async throws {
        guard let container = modelContainer else {
            throw OfflineSyncError.notConfigured
        }

        let context = ModelContext(container)

        for exercise in exercises {
            // Check if already cached
            let targetExerciseId = exercise.id   // #Predicate can only compare against plain local values
            let descriptor = FetchDescriptor<CachedExercise>(
                predicate: #Predicate { cached in
                    cached.exerciseId == targetExerciseId
                }
            )

            if let existing = try context.fetch(descriptor).first {
                existing.update(from: exercise)
            } else {
                let cached = CachedExercise.from(exercise)
                context.insert(cached)
            }
        }

        try context.save()
        logger.debug("Cached \(exercises.count) exercises")
    }

    /// Cache workouts for offline use
    func cacheWorkouts(_ workouts: [Workout]) async throws {
        guard let container = modelContainer else {
            throw OfflineSyncError.notConfigured
        }

        let context = ModelContext(container)

        for workout in workouts {
            let targetWorkoutId = workout.id   // #Predicate can only compare against plain local values
            let descriptor = FetchDescriptor<CachedWorkout>(
                predicate: #Predicate { cached in
                    cached.workoutId == targetWorkoutId
                }
            )

            if let existing = try context.fetch(descriptor).first {
                existing.update(from: workout)
            } else {
                let cached = CachedWorkout.from(workout)
                context.insert(cached)
            }
        }

        try context.save()
        logger.debug("Cached \(workouts.count) workouts")
    }

    /// Cache programs for offline use
    func cachePrograms(_ programs: [Program]) async throws {
        guard let container = modelContainer else {
            throw OfflineSyncError.notConfigured
        }

        let context = ModelContext(container)

        for program in programs {
            let targetProgramId = program.id   // #Predicate can only compare against plain local values
            let descriptor = FetchDescriptor<CachedProgram>(
                predicate: #Predicate { cached in
                    cached.programId == targetProgramId
                }
            )

            if let existing = try context.fetch(descriptor).first {
                existing.update(from: program)
            } else {
                let cached = CachedProgram.from(program)
                context.insert(cached)
            }
        }

        try context.save()
        logger.debug("Cached \(programs.count) programs")
    }

    /// Get cached exercises
    func getCachedExercises(
        bodyRegion: BodyRegion? = nil,
        category: ExerciseCategory? = nil
    ) async throws -> [Exercise] {
        guard let container = modelContainer else {
            throw OfflineSyncError.notConfigured
        }

        let context = ModelContext(container)
        var descriptor = FetchDescriptor<CachedExercise>(
            sortBy: [SortDescriptor(\.name)]
        )

        // Build predicate based on filters
        if let region = bodyRegion, let cat = category {
            let regionRaw = region.rawValue
            let catRaw = cat.rawValue
            descriptor.predicate = #Predicate { cached in
                cached.bodyRegionRaw == regionRaw && cached.categoryRaw == catRaw
            }
        } else if let region = bodyRegion {
            let regionRaw = region.rawValue
            descriptor.predicate = #Predicate { cached in
                cached.bodyRegionRaw == regionRaw
            }
        } else if let cat = category {
            let catRaw = cat.rawValue
            descriptor.predicate = #Predicate { cached in
                cached.categoryRaw == catRaw
            }
        }

        let cached = try context.fetch(descriptor)
        return cached.map { $0.toExercise() }
    }

    /// Get cached workouts
    func getCachedWorkouts(
        scheduledFrom: Date? = nil,
        scheduledTo: Date? = nil,
        completed: Bool? = nil
    ) async throws -> [Workout] {
        guard let container = modelContainer else {
            throw OfflineSyncError.notConfigured
        }

        let context = ModelContext(container)
        var descriptor = FetchDescriptor<CachedWorkout>(
            sortBy: [SortDescriptor(\.scheduledDate, order: .reverse)]
        )

        // Apply filters
        if let completed = completed {
            if completed {
                descriptor.predicate = #Predicate { cached in
                    cached.completedAt != nil
                }
            } else {
                descriptor.predicate = #Predicate { cached in
                    cached.completedAt == nil
                }
            }
        }

        var workouts = try context.fetch(descriptor).map { $0.toWorkout() }

        // Filter by date range in memory (SwiftData predicate limitations)
        if let from = scheduledFrom {
            workouts = workouts.filter { $0.scheduledDate ?? Date.distantPast >= from }
        }
        if let to = scheduledTo {
            workouts = workouts.filter { $0.scheduledDate ?? Date.distantFuture <= to }
        }

        return workouts
    }

    /// Get cached programs
    func getCachedPrograms(enrolledOnly: Bool = false) async throws -> [Program] {
        guard let container = modelContainer else {
            throw OfflineSyncError.notConfigured
        }

        let context = ModelContext(container)
        var descriptor = FetchDescriptor<CachedProgram>(
            sortBy: [SortDescriptor(\.name)]
        )

        if enrolledOnly {
            descriptor.predicate = #Predicate { cached in
                cached.isEnrolled == true
            }
        }

        let cached = try context.fetch(descriptor)
        return cached.map { $0.toProgram() }
    }

    // MARK: - Private: Sync Implementation

    private func scheduleSyncDebounced() {
        syncDebounceTask?.cancel()
        syncDebounceTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(Constants.syncDebounceSeconds * 1_000_000_000))
            guard !Task.isCancelled else { return }
            await self?.performSync()
        }
    }

    private func performSync() async {
        guard !isSyncing else {
            logger.debug("Sync already in progress, skipping")
            return
        }

        guard isOnline else {
            logger.debug("Offline, skipping sync")
            return
        }

        isSyncing = true
        syncError = nil

        logger.info("Starting offline sync...")

        syncTask = Task { [weak self] in
            guard let self = self else { return }

            do {
                // Process pending actions in batches
                var processedCount = 0
                var hasMore = true

                while hasMore && !Task.isCancelled {
                    let actions = try await self.fetchNextBatch()
                    hasMore = actions.count >= Constants.syncBatchSize

                    for action in actions {
                        guard !Task.isCancelled else { break }
                        await self.processAction(action)
                        processedCount += 1
                    }
                }

                // Pull fresh data from server
                if !Task.isCancelled {
                    await self.pullServerUpdates()
                }

                await MainActor.run {
                    self.lastSyncDate = Date()
                    self.saveLastSyncDate()
                    self.logger.info("Sync completed, processed \(processedCount) actions")
                }

            } catch {
                await MainActor.run {
                    self.syncError = .syncFailed(error.localizedDescription)
                    self.logger.error("Sync failed: \(error.localizedDescription)")
                }
            }

            await MainActor.run {
                self.isSyncing = false
                self.loadPendingActionsCount()
            }
        }

        await syncTask?.value
    }

    private func fetchNextBatch() async throws -> [OfflineAction] {
        guard let container = modelContainer else {
            throw OfflineSyncError.notConfigured
        }

        let context = ModelContext(container)

        // Fetch pending actions that don't have unmet dependencies
        var descriptor = FetchDescriptor<OfflineAction>(
            predicate: #Predicate { action in
                action.statusRaw == "pending"
            },
            sortBy: [
                SortDescriptor(\.priority, order: .reverse),
                SortDescriptor(\.sequenceNumber)
            ]
        )
        descriptor.fetchLimit = Constants.syncBatchSize

        let allPending = try context.fetch(descriptor)

        // Filter out actions with unmet dependencies
        let completedIds = try context.fetch(
            FetchDescriptor<OfflineAction>(
                predicate: #Predicate { action in
                    action.statusRaw == "completed"
                }
            )
        ).map { $0.actionId }

        return allPending.filter { action in
            guard let dependsOn = action.dependsOnActionId else { return true }
            return completedIds.contains(dependsOn)
        }
    }

    private func processAction(_ action: OfflineAction) async {
        guard let container = modelContainer else { return }

        let context = ModelContext(container)

        // Refetch to get fresh state
        let targetActionId = action.actionId   // #Predicate can only compare against plain local values
        let descriptor = FetchDescriptor<OfflineAction>(
            predicate: #Predicate { a in
                a.actionId == targetActionId
            }
        )

        guard let freshAction = try? context.fetch(descriptor).first else { return }

        freshAction.markInProgress()
        try? context.save()

        do {
            try await executeAction(freshAction)
            freshAction.markCompleted()
            logger.debug("Action completed: \(freshAction.actionTypeRaw)")
        } catch {
            freshAction.markFailed(error: error.localizedDescription)
            logger.error("Action failed: \(freshAction.actionTypeRaw) - \(error.localizedDescription)")

            // Check if we should retry
            if freshAction.canRetry {
                freshAction.reset()
                logger.debug("Action will be retried: \(freshAction.actionTypeRaw)")
            }
        }

        try? context.save()
    }

    private func executeAction(_ action: OfflineAction) async throws {
        // Execute the action based on type
        switch action.actionType {
        case .completeWorkout:
            try await executeWorkoutCompletion(action)
        case .completeExercise:
            try await executeExerciseCompletion(action)
        case .createWorkout:
            try await executeWorkoutCreation(action)
        case .updateWorkout:
            try await executeWorkoutUpdate(action)
        case .deleteWorkout:
            try await executeWorkoutDeletion(action)
        case .enrollProgram:
            try await executeProgramEnrollment(action)
        case .updateProgress:
            try await executeProgressUpdate(action)
        case .logActivity:
            try await executeActivityLog(action)
        case .updatePreferences:
            try await executePreferencesUpdate(action)
        case .custom:
            try await executeCustomAction(action)
        }
    }

    private func executeWorkoutCompletion(_ action: OfflineAction) async throws {
        guard let path = action.requestPath else {
            throw OfflineSyncError.invalidAction("Missing request path")
        }

        let request = APIRequest<EmptyResponse>(
            endpoint: .custom(path: path),
            method: .post,
            body: action.payloadJSON.map(RawJSONBody.init)
        )

        try await APIClient.shared.execute(request)
    }

    private func executeExerciseCompletion(_ action: OfflineAction) async throws {
        guard let path = action.requestPath else {
            throw OfflineSyncError.invalidAction("Missing request path")
        }

        let request = APIRequest<EmptyResponse>(
            endpoint: .custom(path: path),
            method: .post,
            body: action.payloadJSON.map(RawJSONBody.init)
        )

        try await APIClient.shared.execute(request)
    }

    private func executeWorkoutCreation(_ action: OfflineAction) async throws {
        guard let payload = action.getPayload(as: Workout.self) else {
            throw OfflineSyncError.invalidAction("Invalid workout payload")
        }

        let _: Workout = try await APIClient.shared.post(.saveWorkout, body: payload)
    }

    private func executeWorkoutUpdate(_ action: OfflineAction) async throws {
        guard let payload = action.getPayload(as: Workout.self) else {
            throw OfflineSyncError.invalidAction("Invalid workout payload")
        }

        let _: Workout = try await APIClient.shared.put(.workout(id: action.entityId), body: payload)
    }

    private func executeWorkoutDeletion(_ action: OfflineAction) async throws {
        try await APIClient.shared.delete(.workout(id: action.entityId))
    }

    private func executeProgramEnrollment(_ action: OfflineAction) async throws {
        guard let path = action.requestPath else {
            throw OfflineSyncError.invalidAction("Missing request path")
        }

        let request = APIRequest<EmptyResponse>(
            endpoint: .custom(path: path),
            method: .post,
            body: action.payloadJSON.map(RawJSONBody.init)
        )

        try await APIClient.shared.execute(request)
    }

    private func executeProgressUpdate(_ action: OfflineAction) async throws {
        guard let path = action.requestPath else {
            throw OfflineSyncError.invalidAction("Missing request path")
        }

        let request = APIRequest<EmptyResponse>(
            endpoint: .custom(path: path),
            method: .post,
            body: action.payloadJSON.map(RawJSONBody.init)
        )

        try await APIClient.shared.execute(request)
    }

    private func executeActivityLog(_ action: OfflineAction) async throws {
        guard let path = action.requestPath else {
            throw OfflineSyncError.invalidAction("Missing request path")
        }

        let request = APIRequest<EmptyResponse>(
            endpoint: .custom(path: path),
            method: .post,
            body: action.payloadJSON.map(RawJSONBody.init)
        )

        try await APIClient.shared.execute(request)
    }

    private func executePreferencesUpdate(_ action: OfflineAction) async throws {
        guard let payload = action.getPayload(as: UserPreferences.self) else {
            throw OfflineSyncError.invalidAction("Invalid preferences payload")
        }

        let _: User = try await APIClient.shared.put(.updatePreferences, body: payload)
    }

    private func executeCustomAction(_ action: OfflineAction) async throws {
        guard let path = action.requestPath,
              let method = action.httpMethod else {
            throw OfflineSyncError.invalidAction("Missing request path or method")
        }

        let httpMethod = HTTPMethod(rawValue: method) ?? .post

        let request = APIRequest<EmptyResponse>(
            endpoint: .custom(path: path),
            method: httpMethod,
            body: action.payloadJSON.map(RawJSONBody.init)
        )

        try await APIClient.shared.execute(request)
    }

    private func pullServerUpdates() async {
        // Pull latest data from server and update cache
        // This would be customized based on app needs

        logger.debug("Pulling server updates...")

        // Example: Fetch recent workouts
        do {
            let workouts: [Workout] = try await APIClient.shared.get(.workouts)
            try await cacheWorkouts(workouts)
        } catch {
            logger.warning("Failed to pull workouts: \(error.localizedDescription)")
        }

        // Example: Fetch programs
        do {
            let programs: [Program] = try await APIClient.shared.get(.programs)
            try await cachePrograms(programs)
        } catch {
            logger.warning("Failed to pull programs: \(error.localizedDescription)")
        }
    }

    // MARK: - Private: Persistence Helpers

    private func loadPendingActionsCount() {
        Task {
            do {
                pendingActionsCount = try await getPendingActionsCount()
            } catch {
                logger.error("Failed to load pending actions count: \(error.localizedDescription)")
            }
        }
    }

    private func getPendingActionsCount() async throws -> Int {
        guard let container = modelContainer else { return 0 }

        let context = ModelContext(container)
        let descriptor = FetchDescriptor<OfflineAction>(
            predicate: #Predicate { action in
                action.statusRaw == "pending" || action.statusRaw == "failed"
            }
        )

        return try context.fetchCount(descriptor)
    }

    private func loadLastSyncDate() {
        lastSyncDate = UserDefaults.standard.object(forKey: "mdfit_last_sync") as? Date
    }

    private func saveLastSyncDate() {
        UserDefaults.standard.set(lastSyncDate, forKey: "mdfit_last_sync")
    }

    // MARK: - Cleanup

    deinit {
        networkMonitor.cancel()
    }
}

// MARK: - Connection Type

enum ConnectionType: String {
    case wifi = "wifi"
    case cellular = "cellular"
    case wired = "wired"
    case unknown = "unknown"

    var isExpensive: Bool {
        self == .cellular
    }

    var displayName: String {
        switch self {
        case .wifi: return "Wi-Fi"
        case .cellular: return "Cellular"
        case .wired: return "Ethernet"
        case .unknown: return "Unknown"
        }
    }
}

// MARK: - Offline Sync Error

enum OfflineSyncError: LocalizedError {
    case notConfigured
    case offline
    case syncFailed(String)
    case invalidAction(String)
    case actionNotFound
    case dependencyNotMet

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Offline manager not configured with model container"
        case .offline:
            return "Device is offline. Actions will sync when connection is restored."
        case .syncFailed(let message):
            return "Sync failed: \(message)"
        case .invalidAction(let message):
            return "Invalid action: \(message)"
        case .actionNotFound:
            return "Action not found"
        case .dependencyNotMet:
            return "Action dependency not yet completed"
        }
    }
}

// MARK: - Sync State Observer

/// SwiftUI view modifier for observing offline state
struct OfflineStateModifier: ViewModifier {
    @ObservedObject private var offlineManager = OfflineManager.shared

    let onOnlineChange: (Bool) -> Void

    func body(content: Content) -> some View {
        content
            .onChange(of: offlineManager.isOnline) { _, newValue in
                onOnlineChange(newValue)
            }
    }
}

extension View {
    /// Observe online/offline state changes
    func onOnlineStateChange(_ action: @escaping (Bool) -> Void) -> some View {
        modifier(OfflineStateModifier(onOnlineChange: action))
    }
}

// MARK: - Offline Banner View

/// A banner view showing offline status
struct OfflineBannerView: View {
    @ObservedObject private var offlineManager = OfflineManager.shared

    var body: some View {
        if !offlineManager.isOnline {
            HStack(spacing: 8) {
                Image(systemName: "wifi.slash")
                    .font(.subheadline)

                Text("You're offline")
                    .font(.subheadline.weight(.medium))

                if offlineManager.pendingActionsCount > 0 {
                    Text("(\(offlineManager.pendingActionsCount) pending)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.orange)
        }
    }
}

// MARK: - Sync Status View

/// A view showing sync status and pending actions
struct SyncStatusView: View {
    @ObservedObject private var offlineManager = OfflineManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle()
                    .fill(offlineManager.isOnline ? Color.green : Color.orange)
                    .frame(width: 8, height: 8)

                Text(offlineManager.isOnline ? "Online" : "Offline")
                    .font(.subheadline.weight(.medium))

                if offlineManager.isOnline {
                    Text("(\(offlineManager.connectionType.displayName))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if offlineManager.isSyncing {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }

            if offlineManager.pendingActionsCount > 0 {
                HStack {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.caption)
                    Text("\(offlineManager.pendingActionsCount) actions pending")
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
            }

            if let lastSync = offlineManager.lastSyncDate {
                Text("Last synced: \(lastSync.formatted(.relative(presentation: .named)))")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            if let error = offlineManager.syncError {
                Text(error.localizedDescription)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
    }
}

#endif // os(iOS)


// MARK: - Replaying stored JSON

/// Re-sends a queued action's JSON payload exactly as it was stored. APIRequest.body must be Encodable, and a
/// `[String: Any]` from JSONSerialization isn't, so this walks the parsed JSON and encodes it value by value.
private struct RawJSONBody: Encodable {
    let data: Data

    func encode(to encoder: Encoder) throws {
        let object = try JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
        try RawJSONBody.encode(object, to: encoder)
    }

    private static func encode(_ value: Any, to encoder: Encoder) throws {
        var single = encoder.singleValueContainer()
        switch value {
        case is NSNull: try single.encodeNil()
        case let v as String: try single.encode(v)
        case let v as Bool where CFGetTypeID(v as CFTypeRef) == CFBooleanGetTypeID(): try single.encode(v)
        case let v as Int: try single.encode(v)
        case let v as Double: try single.encode(v)
        case let v as [Any]:
            var c = encoder.unkeyedContainer()
            for item in v { try encode(item, to: c.superEncoder()) }
        case let v as [String: Any]:
            var c = encoder.container(keyedBy: JSONKey.self)
            for (k, item) in v { try encode(item, to: c.superEncoder(forKey: JSONKey(k))) }
        default:
            throw EncodingError.invalidValue(value, .init(codingPath: encoder.codingPath, debugDescription: "Unsupported JSON value"))
        }
    }

    private struct JSONKey: CodingKey {
        var stringValue: String; var intValue: Int? { nil }
        init(_ s: String) { stringValue = s }
        init?(stringValue: String) { self.stringValue = stringValue }
        init?(intValue: Int) { nil }
    }
}
