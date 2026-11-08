//
//  BackgroundTaskManager.swift
//  MDfit
//
//  Production-ready background task manager using BGTaskScheduler for
//  content sync, video downloads, and maintenance tasks.
//

import Foundation

// MARK: - Background Task Identifiers (Available without SwiftData)

/// Registered background task identifiers
enum BackgroundTaskIdentifier: String, CaseIterable {
    case contentSync = "com.mdfit.content-sync"
    case videoDownload = "com.mdfit.video-download"
    case cleanup = "com.mdfit.cleanup"
    case analytics = "com.mdfit.analytics"

    var isProcessingTask: Bool {
        switch self {
        case .videoDownload, .cleanup:
            return true
        case .contentSync, .analytics:
            return false
        }
    }
}

#if os(iOS)
import BackgroundTasks
import SwiftData
import os.log

// Note: BackgroundTaskIdentifier enum is defined above the #if block

// MARK: - Background Task Manager

/// Central manager for all background tasks in MD Fit
@MainActor
final class BackgroundTaskManager: ObservableObject {

    // MARK: - Singleton

    static let shared = BackgroundTaskManager()

    // MARK: - Published State

    @Published private(set) var isContentSyncScheduled: Bool = false
    @Published private(set) var isVideoDownloadScheduled: Bool = false
    @Published private(set) var lastContentSyncDate: Date?
    @Published private(set) var lastVideoDownloadDate: Date?
    @Published private(set) var backgroundTaskError: BackgroundTaskError?

    // MARK: - Constants

    private enum Constants {
        static let contentSyncInterval: TimeInterval = 60 * 60        // 1 hour
        static let videoDownloadInterval: TimeInterval = 4 * 60 * 60  // 4 hours
        static let cleanupInterval: TimeInterval = 24 * 60 * 60       // 24 hours
        static let analyticsInterval: TimeInterval = 6 * 60 * 60      // 6 hours
        static let minimumBatteryLevel: Float = 0.2                   // 20%
    }

    // MARK: - Private Properties

    private let logger = Logger(subsystem: "com.mdfit.background", category: "tasks")
    private var modelContainer: ModelContainer?
    private var registeredTasks: Set<BackgroundTaskIdentifier> = []

    // MARK: - Initialization

    private init() {
        loadScheduleState()
    }

    // MARK: - Configuration

    /// Configure the manager with dependencies
    func configure(with container: ModelContainer) {
        self.modelContainer = container
    }

    /// Register all background tasks - call from AppDelegate
    func registerBackgroundTasks() {
        for taskId in BackgroundTaskIdentifier.allCases {
            let success: Bool

            if taskId.isProcessingTask {
                success = BGTaskScheduler.shared.register(
                    forTaskWithIdentifier: taskId.rawValue,
                    using: nil
                ) { [weak self] task in
                    guard let processingTask = task as? BGProcessingTask else { return }
                    self?.handleProcessingTask(processingTask, identifier: taskId)
                }
            } else {
                success = BGTaskScheduler.shared.register(
                    forTaskWithIdentifier: taskId.rawValue,
                    using: nil
                ) { [weak self] task in
                    guard let refreshTask = task as? BGAppRefreshTask else { return }
                    self?.handleRefreshTask(refreshTask, identifier: taskId)
                }
            }

            if success {
                registeredTasks.insert(taskId)
                logger.info("Registered background task: \(taskId.rawValue)")
            } else {
                logger.error("Failed to register background task: \(taskId.rawValue)")
            }
        }
    }

    // MARK: - Scheduling

    /// Schedule content sync background task
    func scheduleContentSync(earliestBeginDate: Date? = nil) {
        let request = BGAppRefreshTaskRequest(
            identifier: BackgroundTaskIdentifier.contentSync.rawValue
        )

        request.earliestBeginDate = earliestBeginDate ?? Date(
            timeIntervalSinceNow: Constants.contentSyncInterval
        )

        do {
            try BGTaskScheduler.shared.submit(request)
            isContentSyncScheduled = true
            saveScheduleState()
            logger.info("Scheduled content sync for \(request.earliestBeginDate?.formatted() ?? "now")")
        } catch {
            logger.error("Failed to schedule content sync: \(error.localizedDescription)")
            backgroundTaskError = .schedulingFailed(error.localizedDescription)
        }
    }

    /// Schedule video download processing task
    func scheduleVideoDownload(
        requiresExternalPower: Bool = false,
        requiresNetworkConnectivity: Bool = true
    ) {
        let request = BGProcessingTaskRequest(
            identifier: BackgroundTaskIdentifier.videoDownload.rawValue
        )

        request.earliestBeginDate = Date(timeIntervalSinceNow: Constants.videoDownloadInterval)
        request.requiresExternalPower = requiresExternalPower
        request.requiresNetworkConnectivity = requiresNetworkConnectivity

        do {
            try BGTaskScheduler.shared.submit(request)
            isVideoDownloadScheduled = true
            saveScheduleState()
            logger.info("Scheduled video download processing")
        } catch {
            logger.error("Failed to schedule video download: \(error.localizedDescription)")
            backgroundTaskError = .schedulingFailed(error.localizedDescription)
        }
    }

    /// Schedule cleanup processing task
    func scheduleCleanup() {
        let request = BGProcessingTaskRequest(
            identifier: BackgroundTaskIdentifier.cleanup.rawValue
        )

        request.earliestBeginDate = Date(timeIntervalSinceNow: Constants.cleanupInterval)
        request.requiresExternalPower = true  // Only when charging
        request.requiresNetworkConnectivity = false

        do {
            try BGTaskScheduler.shared.submit(request)
            logger.info("Scheduled cleanup task")
        } catch {
            logger.error("Failed to schedule cleanup: \(error.localizedDescription)")
        }
    }

    /// Schedule analytics sync task
    func scheduleAnalyticsSync() {
        let request = BGAppRefreshTaskRequest(
            identifier: BackgroundTaskIdentifier.analytics.rawValue
        )

        request.earliestBeginDate = Date(timeIntervalSinceNow: Constants.analyticsInterval)

        do {
            try BGTaskScheduler.shared.submit(request)
            logger.info("Scheduled analytics sync")
        } catch {
            logger.error("Failed to schedule analytics: \(error.localizedDescription)")
        }
    }

    /// Schedule all regular background tasks
    func scheduleAllTasks() {
        scheduleContentSync()
        scheduleVideoDownload()
        scheduleCleanup()
        scheduleAnalyticsSync()
    }

    /// Cancel a specific background task
    func cancelTask(_ identifier: BackgroundTaskIdentifier) {
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: identifier.rawValue)

        switch identifier {
        case .contentSync:
            isContentSyncScheduled = false
        case .videoDownload:
            isVideoDownloadScheduled = false
        default:
            break
        }

        saveScheduleState()
        logger.info("Cancelled background task: \(identifier.rawValue)")
    }

    /// Cancel all background tasks
    func cancelAllTasks() {
        BGTaskScheduler.shared.cancelAllTaskRequests()
        isContentSyncScheduled = false
        isVideoDownloadScheduled = false
        saveScheduleState()
        logger.info("Cancelled all background tasks")
    }

    // MARK: - Task Handlers

    private func handleRefreshTask(_ task: BGAppRefreshTask, identifier: BackgroundTaskIdentifier) {
        logger.info("Handling refresh task: \(identifier.rawValue)")

        // Schedule next occurrence
        switch identifier {
        case .contentSync:
            Task { @MainActor in
                self.scheduleContentSync()
            }
        case .analytics:
            Task { @MainActor in
                self.scheduleAnalyticsSync()
            }
        default:
            break
        }

        // Create task operation
        let operation = Task { [weak self] in
            do {
                switch identifier {
                case .contentSync:
                    try await self?.performContentSync()
                case .analytics:
                    try await self?.performAnalyticsSync()
                default:
                    break
                }
                task.setTaskCompleted(success: true)
            } catch {
                self?.logger.error("Refresh task failed: \(error.localizedDescription)")
                task.setTaskCompleted(success: false)
            }
        }

        // Handle expiration
        task.expirationHandler = {
            operation.cancel()
        }
    }

    private func handleProcessingTask(_ task: BGProcessingTask, identifier: BackgroundTaskIdentifier) {
        logger.info("Handling processing task: \(identifier.rawValue)")

        // Schedule next occurrence
        switch identifier {
        case .videoDownload:
            Task { @MainActor in
                self.scheduleVideoDownload()
            }
        case .cleanup:
            Task { @MainActor in
                self.scheduleCleanup()
            }
        default:
            break
        }

        // Create task operation
        let operation = Task { [weak self] in
            do {
                switch identifier {
                case .videoDownload:
                    try await self?.performVideoDownloads()
                case .cleanup:
                    try await self?.performCleanup()
                default:
                    break
                }
                task.setTaskCompleted(success: true)
            } catch {
                self?.logger.error("Processing task failed: \(error.localizedDescription)")
                task.setTaskCompleted(success: false)
            }
        }

        // Handle expiration
        task.expirationHandler = {
            operation.cancel()
        }
    }

    // MARK: - Task Implementations

    private func performContentSync() async throws {
        logger.info("Performing content sync...")

        // Check battery level
        guard checkBatteryLevel() else {
            logger.warning("Battery too low for content sync")
            throw BackgroundTaskError.lowBattery
        }

        // Sync offline actions
        try await OfflineManager.shared.syncNow()

        // Pull fresh content
        try await syncExercises()
        try await syncWorkouts()
        try await syncPrograms()

        await MainActor.run {
            lastContentSyncDate = Date()
            saveLastSyncDates()
        }

        logger.info("Content sync completed")
    }

    private func syncExercises() async throws {
        guard let container = modelContainer else { return }

        // Get last sync date
        let context = ModelContext(container)
        let stateDescriptor = FetchDescriptor<SyncState>(
            predicate: #Predicate { state in
                state.id == "primary"
            }
        )

        let syncState = try context.fetch(stateDescriptor).first ?? SyncState()

        // Fetch updated exercises from server
        // In production, use sync version or last modified date
        let exercises: [Exercise] = try await APIClient.shared.get(
            .videos,
            queryItems: syncState.lastExerciseSync.map {
                [URLQueryItem(name: "updated_since", value: ISO8601DateFormatter().string(from: $0))]
            }
        )

        // Cache exercises
        try await OfflineManager.shared.cacheExercises(exercises)

        // Update sync state
        syncState.lastExerciseSync = Date()
        syncState.exerciseSyncVersion += 1

        if context.hasChanges {
            try context.save()
        }
    }

    private func syncWorkouts() async throws {
        guard let container = modelContainer else { return }

        let context = ModelContext(container)
        let stateDescriptor = FetchDescriptor<SyncState>(
            predicate: #Predicate { state in
                state.id == "primary"
            }
        )

        let syncState = try context.fetch(stateDescriptor).first ?? SyncState()

        // Fetch user's workouts
        let workouts: [Workout] = try await APIClient.shared.get(.workouts)

        // Cache workouts
        try await OfflineManager.shared.cacheWorkouts(workouts)

        // Update sync state
        syncState.lastWorkoutSync = Date()
        syncState.workoutSyncVersion += 1

        if context.hasChanges {
            try context.save()
        }
    }

    private func syncPrograms() async throws {
        guard let container = modelContainer else { return }

        let context = ModelContext(container)
        let stateDescriptor = FetchDescriptor<SyncState>(
            predicate: #Predicate { state in
                state.id == "primary"
            }
        )

        let syncState = try context.fetch(stateDescriptor).first ?? SyncState()

        // Fetch programs
        let programs: [Program] = try await APIClient.shared.get(.programs)

        // Cache programs
        try await OfflineManager.shared.cachePrograms(programs)

        // Update sync state
        syncState.lastProgramSync = Date()
        syncState.programSyncVersion += 1

        if context.hasChanges {
            try context.save()
        }
    }

    private func performVideoDownloads() async throws {
        logger.info("Performing video downloads...")

        // Check battery and storage
        guard checkBatteryLevel() else {
            logger.warning("Battery too low for video downloads")
            throw BackgroundTaskError.lowBattery
        }

        guard checkStorageAvailable() else {
            logger.warning("Insufficient storage for video downloads")
            throw BackgroundTaskError.insufficientStorage
        }

        // Get pending downloads from VideoDownloadManager
        let downloadManager = await VideoDownloadManager.shared
        try await downloadManager.resumePendingDownloads()

        await MainActor.run {
            lastVideoDownloadDate = Date()
            saveLastSyncDates()
        }

        logger.info("Video downloads completed")
    }

    private func performCleanup() async throws {
        logger.info("Performing cleanup...")

        guard let container = modelContainer else { return }

        // Clean expired video downloads
        let downloadManager = await VideoDownloadManager.shared
        try await downloadManager.cleanupExpiredDownloads()

        // Clean old completed actions
        try await OfflineManager.shared.clearCompletedActions()

        // Clean stale failed actions
        try await OfflineManager.shared.clearStaleActions()

        // Clean old cached data
        try await cleanOldCachedData(in: container)

        logger.info("Cleanup completed")
    }

    private func cleanOldCachedData(in container: ModelContainer) async throws {
        let context = ModelContext(container)
        let thirtyDaysAgo = Date().addingTimeInterval(-30 * 24 * 60 * 60)

        // Delete old completed workouts
        let oldWorkoutsDescriptor = FetchDescriptor<CachedWorkout>(
            predicate: #Predicate { workout in
                workout.completedAt != nil && workout.updatedAt < thirtyDaysAgo
            }
        )

        let oldWorkouts = try context.fetch(oldWorkoutsDescriptor)
        for workout in oldWorkouts {
            context.delete(workout)
        }

        if context.hasChanges {
            try context.save()
        }

        logger.debug("Cleaned \(oldWorkouts.count) old cached workouts")
    }

    private func performAnalyticsSync() async throws {
        logger.info("Performing analytics sync...")

        // This would sync local analytics events to server
        // Placeholder for analytics implementation

        logger.info("Analytics sync completed")
    }

    // MARK: - Utility

    private func checkBatteryLevel() -> Bool {
        UIDevice.current.isBatteryMonitoringEnabled = true
        let batteryLevel = UIDevice.current.batteryLevel
        UIDevice.current.isBatteryMonitoringEnabled = false

        // -1 means unknown, which we'll allow
        return batteryLevel < 0 || batteryLevel >= Constants.minimumBatteryLevel
    }

    private func checkStorageAvailable() -> Bool {
        do {
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let values = try documentsURL.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])

            if let available = values.volumeAvailableCapacityForImportantUsage {
                // Require at least 500MB
                return available > 500 * 1024 * 1024
            }
        } catch {
            logger.error("Failed to check storage: \(error.localizedDescription)")
        }
        return true
    }

    // MARK: - State Persistence

    private func loadScheduleState() {
        let defaults = UserDefaults.standard
        isContentSyncScheduled = defaults.bool(forKey: "mdfit_bg_content_sync_scheduled")
        isVideoDownloadScheduled = defaults.bool(forKey: "mdfit_bg_video_download_scheduled")
        lastContentSyncDate = defaults.object(forKey: "mdfit_bg_last_content_sync") as? Date
        lastVideoDownloadDate = defaults.object(forKey: "mdfit_bg_last_video_download") as? Date
    }

    private func saveScheduleState() {
        let defaults = UserDefaults.standard
        defaults.set(isContentSyncScheduled, forKey: "mdfit_bg_content_sync_scheduled")
        defaults.set(isVideoDownloadScheduled, forKey: "mdfit_bg_video_download_scheduled")
    }

    private func saveLastSyncDates() {
        let defaults = UserDefaults.standard
        defaults.set(lastContentSyncDate, forKey: "mdfit_bg_last_content_sync")
        defaults.set(lastVideoDownloadDate, forKey: "mdfit_bg_last_video_download")
    }

    // MARK: - Debug

    #if DEBUG
    /// Force run a background task for testing
    func debugRunTask(_ identifier: BackgroundTaskIdentifier) async throws {
        switch identifier {
        case .contentSync:
            try await performContentSync()
        case .videoDownload:
            try await performVideoDownloads()
        case .cleanup:
            try await performCleanup()
        case .analytics:
            try await performAnalyticsSync()
        }
    }

    /// Get all pending task requests
    func debugGetPendingTasks() async -> [BGTaskRequest] {
        await withCheckedContinuation { continuation in
            BGTaskScheduler.shared.getPendingTaskRequests { requests in
                continuation.resume(returning: requests)
            }
        }
    }
    #endif
}

// MARK: - Background Task Error

enum BackgroundTaskError: LocalizedError {
    case notRegistered
    case schedulingFailed(String)
    case lowBattery
    case insufficientStorage
    case networkUnavailable
    case taskExpired
    case syncFailed(String)

    var errorDescription: String? {
        switch self {
        case .notRegistered:
            return "Background task not registered"
        case .schedulingFailed(let reason):
            return "Failed to schedule task: \(reason)"
        case .lowBattery:
            return "Battery level too low for background task"
        case .insufficientStorage:
            return "Insufficient storage available"
        case .networkUnavailable:
            return "Network connection unavailable"
        case .taskExpired:
            return "Background task time expired"
        case .syncFailed(let reason):
            return "Sync failed: \(reason)"
        }
    }
}

// MARK: - App Delegate Integration

/// Extension to integrate with AppDelegate
extension BackgroundTaskManager {

    /// Call from application(_:didFinishLaunchingWithOptions:)
    func applicationDidFinishLaunching() {
        registerBackgroundTasks()
    }

    /// Call when app enters background
    func applicationDidEnterBackground() {
        scheduleContentSync()
        scheduleVideoDownload()
    }

    /// Call when app becomes active to refresh state
    func applicationDidBecomeActive() {
        loadScheduleState()
    }
}

// MARK: - SwiftUI Integration

/// View modifier for automatic background task scheduling
struct BackgroundTaskModifier: ViewModifier {
    @Environment(\.scenePhase) private var scenePhase

    func body(content: Content) -> some View {
        content
            .onChange(of: scenePhase) { _, newPhase in
                switch newPhase {
                case .background:
                    BackgroundTaskManager.shared.applicationDidEnterBackground()
                case .active:
                    BackgroundTaskManager.shared.applicationDidBecomeActive()
                default:
                    break
                }
            }
    }
}

extension View {
    /// Enable automatic background task management
    func withBackgroundTasks() -> some View {
        modifier(BackgroundTaskModifier())
    }
}

// MARK: - Background Task Status View

/// Debug view for background task status
struct BackgroundTaskStatusView: View {
    @ObservedObject private var manager = BackgroundTaskManager.shared

    var body: some View {
        List {
            Section("Scheduled Tasks") {
                HStack {
                    Text("Content Sync")
                    Spacer()
                    Image(systemName: manager.isContentSyncScheduled ? "checkmark.circle.fill" : "xmark.circle")
                        .foregroundStyle(manager.isContentSyncScheduled ? .green : .secondary)
                }

                HStack {
                    Text("Video Download")
                    Spacer()
                    Image(systemName: manager.isVideoDownloadScheduled ? "checkmark.circle.fill" : "xmark.circle")
                        .foregroundStyle(manager.isVideoDownloadScheduled ? .green : .secondary)
                }
            }

            Section("Last Run") {
                if let date = manager.lastContentSyncDate {
                    LabeledContent("Content Sync", value: date.formatted(.relative(presentation: .named)))
                } else {
                    LabeledContent("Content Sync", value: "Never")
                }

                if let date = manager.lastVideoDownloadDate {
                    LabeledContent("Video Download", value: date.formatted(.relative(presentation: .named)))
                } else {
                    LabeledContent("Video Download", value: "Never")
                }
            }

            if let error = manager.backgroundTaskError {
                Section("Error") {
                    Text(error.localizedDescription)
                        .foregroundStyle(.red)
                }
            }

            Section {
                Button("Schedule All Tasks") {
                    manager.scheduleAllTasks()
                }

                Button("Cancel All Tasks", role: .destructive) {
                    manager.cancelAllTasks()
                }
            }
        }
        .navigationTitle("Background Tasks")
    }
}

#endif // os(iOS)
