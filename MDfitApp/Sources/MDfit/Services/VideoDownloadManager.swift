//
//  VideoDownloadManager.swift
//  MDfit
//
//  Production-ready video download manager for offline playback.
//  Handles background downloads, progress tracking, and storage management.
//

import Foundation

#if os(iOS)
import SwiftUI
import SwiftData
import Combine
import os.log

// MARK: - Video Download Manager

/// Manages video downloads for offline playback
@MainActor
final class VideoDownloadManager: ObservableObject {

    // MARK: - Singleton

    static let shared = VideoDownloadManager()

    // MARK: - Published State

    @Published private(set) var activeDownloads: [String: DownloadProgress] = [:]
    @Published private(set) var downloadQueue: [VideoDownloadTask] = []
    @Published private(set) var totalStorageUsed: Int64 = 0
    @Published private(set) var isDownloading: Bool = false
    @Published private(set) var downloadError: VideoDownloadError?

    // MARK: - Constants

    private enum Constants {
        static let maxConcurrentDownloads = 3
        static let maxStorageGB: Double = 5.0                        // 5 GB max
        static let maxStorageBytes: Int64 = 5 * 1024 * 1024 * 1024
        static let chunkSize = 1024 * 1024                           // 1 MB chunks
        static let downloadTimeout: TimeInterval = 60 * 10           // 10 minutes
        static let retryDelay: TimeInterval = 5.0
        static let maxRetries = 3
        static let videoDirectory = "OfflineVideos"
        static let thumbnailDirectory = "OfflineThumbnails"
        static let defaultExpirationDays = 30
    }

    // MARK: - Private Properties

    private let logger = Logger(subsystem: "com.mdfit.downloads", category: "video")
    private var modelContainer: ModelContainer?
    private var urlSession: URLSession!
    private var backgroundSession: URLSession!
    private var downloadTasks: [String: URLSessionDownloadTask] = [:]
    private var progressHandlers: [String: (Double) -> Void] = [:]
    private var completionHandlers: [String: (Result<URL, Error>) -> Void] = [:]
    private var cancellables = Set<AnyCancellable>()
    private let fileManager = FileManager.default
    private var downloadSemaphore = DispatchSemaphore(value: Constants.maxConcurrentDownloads)

    // MARK: - Directories

    private var videosDirectory: URL {
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let videosURL = documentsURL.appendingPathComponent(Constants.videoDirectory, isDirectory: true)

        if !fileManager.fileExists(atPath: videosURL.path) {
            try? fileManager.createDirectory(at: videosURL, withIntermediateDirectories: true)
        }

        return videosURL
    }

    private var thumbnailsDirectory: URL {
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let thumbnailsURL = documentsURL.appendingPathComponent(Constants.thumbnailDirectory, isDirectory: true)

        if !fileManager.fileExists(atPath: thumbnailsURL.path) {
            try? fileManager.createDirectory(at: thumbnailsURL, withIntermediateDirectories: true)
        }

        return thumbnailsURL
    }

    // MARK: - Initialization

    private init() {
        setupURLSessions()
        calculateStorageUsed()
    }

    private func setupURLSessions() {
        // Standard session for foreground downloads
        let standardConfig = URLSessionConfiguration.default
        standardConfig.timeoutIntervalForRequest = Constants.downloadTimeout
        standardConfig.timeoutIntervalForResource = Constants.downloadTimeout * 2
        standardConfig.httpMaximumConnectionsPerHost = Constants.maxConcurrentDownloads
        urlSession = URLSession(configuration: standardConfig)

        // Background session for background downloads
        let backgroundConfig = URLSessionConfiguration.background(
            withIdentifier: "com.mdfit.video-download"
        )
        backgroundConfig.isDiscretionary = true
        backgroundConfig.sessionSendsLaunchEvents = true
        backgroundConfig.allowsCellularAccess = UserDefaults.standard.bool(forKey: "mdfit_allow_cellular_download")
        backgroundSession = URLSession(configuration: backgroundConfig, delegate: nil, delegateQueue: nil)
    }

    // MARK: - Configuration

    /// Configure with model container
    func configure(with container: ModelContainer) {
        self.modelContainer = container
        loadDownloadRecords()
    }

    // MARK: - Public API: Download Management

    /// Start downloading a video for offline playback
    func downloadVideo(
        _ video: VideoAsset,
        resolution: VideoResolution = .hd,
        expiresIn: TimeInterval? = nil
    ) async throws -> URL {
        // Check if already downloaded
        if let localURL = try await getLocalURL(for: video.id) {
            logger.info("Video already downloaded: \(video.id)")
            return localURL
        }

        // Check storage
        guard hasStorageSpace(for: video.fileSize ?? 0) else {
            throw VideoDownloadError.insufficientStorage
        }

        // Check if already downloading
        if activeDownloads[video.id] != nil {
            throw VideoDownloadError.alreadyDownloading
        }

        // Get download URL
        guard let downloadURL = video.downloadURL ?? video.streamingURL else {
            throw VideoDownloadError.invalidURL
        }

        logger.info("Starting download: \(video.id)")

        // Create download task
        let task = VideoDownloadTask(
            videoId: video.id,
            exerciseId: video.exerciseId,
            remoteURL: downloadURL,
            fileName: video.filename,
            expectedSize: video.fileSize ?? 0,
            resolution: resolution,
            duration: video.duration,
            expiresAt: expiresIn.map { Date().addingTimeInterval($0) }
                ?? Date().addingTimeInterval(Double(Constants.defaultExpirationDays) * 24 * 60 * 60)
        )

        // Add to queue
        downloadQueue.append(task)

        // Start download
        return try await performDownload(task)
    }

    /// Download video for a specific exercise
    func downloadVideoForExercise(_ exercise: Exercise) async throws -> URL? {
        guard let videoAssetId = exercise.videoAssetId else { return nil }

        // Fetch video asset metadata
        let video = try await VideoService.shared.fetchVideoAsset(id: videoAssetId)
        return try await downloadVideo(video)
    }

    /// Download all videos for a program
    func downloadVideosForProgram(_ program: Program) async throws {
        var exerciseIds = Set<String>()

        // Collect all unique exercise IDs
        for week in program.weeks {
            for day in week.days {
                for exercise in day.exercises {
                    exerciseIds.insert(exercise.exerciseId)
                }
            }
        }

        logger.info("Downloading \(exerciseIds.count) videos for program: \(program.id)")

        // Download in batches
        for exerciseId in exerciseIds {
            do {
                let video = try await VideoService.shared.fetchVideoAsset(id: exerciseId)
                _ = try await downloadVideo(video)
            } catch {
                logger.warning("Failed to download video \(exerciseId): \(error.localizedDescription)")
                // Continue with other downloads
            }
        }
    }

    /// Download all videos for a workout
    func downloadVideosForWorkout(_ workout: Workout) async throws {
        for workoutExercise in workout.exercises {
            if let exercise = workoutExercise.exercise,
               let videoAssetId = exercise.videoAssetId {
                do {
                    let video = try await VideoService.shared.fetchVideoAsset(id: videoAssetId)
                    _ = try await downloadVideo(video)
                } catch {
                    logger.warning("Failed to download video for exercise \(workoutExercise.exerciseId)")
                }
            }
        }
    }

    /// Cancel a download
    func cancelDownload(videoId: String) {
        if let task = downloadTasks[videoId] {
            task.cancel()
            downloadTasks.removeValue(forKey: videoId)
        }

        activeDownloads.removeValue(forKey: videoId)
        downloadQueue.removeAll { $0.videoId == videoId }

        updateDownloadingState()
        logger.info("Cancelled download: \(videoId)")
    }

    /// Cancel all downloads
    func cancelAllDownloads() {
        for (videoId, task) in downloadTasks {
            task.cancel()
            logger.debug("Cancelled download: \(videoId)")
        }

        downloadTasks.removeAll()
        activeDownloads.removeAll()
        downloadQueue.removeAll()
        isDownloading = false
    }

    /// Pause a download
    func pauseDownload(videoId: String) async throws {
        guard let task = downloadTasks[videoId] else {
            throw VideoDownloadError.downloadNotFound
        }

        task.cancel(byProducingResumeData: { [weak self] data in
            // Store resume data for later
            if let data = data {
                self?.saveResumeData(data, for: videoId)
            }
        })

        downloadTasks.removeValue(forKey: videoId)

        if var progress = activeDownloads[videoId] {
            progress.status = .paused
            activeDownloads[videoId] = progress
        }

        updateDownloadingState()
        logger.info("Paused download: \(videoId)")
    }

    /// Resume a paused download
    func resumeDownload(videoId: String) async throws -> URL {
        guard let task = downloadQueue.first(where: { $0.videoId == videoId }) else {
            throw VideoDownloadError.downloadNotFound
        }

        // Check for resume data
        if let resumeData = loadResumeData(for: videoId) {
            return try await resumeDownload(task: task, resumeData: resumeData)
        } else {
            // Start fresh
            return try await performDownload(task)
        }
    }

    /// Resume all pending downloads
    func resumePendingDownloads() async throws {
        for task in downloadQueue where activeDownloads[task.videoId]?.status == .paused {
            do {
                _ = try await resumeDownload(videoId: task.videoId)
            } catch {
                logger.warning("Failed to resume download \(task.videoId): \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Public API: Storage Management

    /// Get local URL for downloaded video
    func getLocalURL(for videoId: String) async throws -> URL? {
        guard let container = modelContainer else { return nil }

        let context = ModelContext(container)
        let descriptor = FetchDescriptor<VideoDownloadRecord>(
            predicate: #Predicate { record in
                record.videoId == videoId && record.isComplete
            }
        )

        guard let record = try context.fetch(descriptor).first else { return nil }

        // Check if file still exists
        guard let localURL = record.localURL,
              fileManager.fileExists(atPath: localURL.path) else {
            // Clean up stale record
            context.delete(record)
            try context.save()
            return nil
        }

        // Check expiration
        if record.isExpired {
            try await deleteDownload(videoId: videoId)
            return nil
        }

        // Record access
        record.recordAccess()
        try context.save()

        return localURL
    }

    /// Check if video is downloaded
    func isDownloaded(videoId: String) async -> Bool {
        do {
            return try await getLocalURL(for: videoId) != nil
        } catch {
            return false
        }
    }

    /// Delete a downloaded video
    func deleteDownload(videoId: String) async throws {
        guard let container = modelContainer else { return }

        let context = ModelContext(container)
        let descriptor = FetchDescriptor<VideoDownloadRecord>(
            predicate: #Predicate { record in
                record.videoId == videoId
            }
        )

        guard let record = try context.fetch(descriptor).first else { return }

        // Delete file
        if let localURL = record.localURL {
            try? fileManager.removeItem(at: localURL)
        }

        // Delete record
        context.delete(record)
        try context.save()

        calculateStorageUsed()
        logger.info("Deleted download: \(videoId)")
    }

    /// Delete all downloaded videos
    func deleteAllDownloads() async throws {
        guard let container = modelContainer else { return }

        // Delete all files
        try? fileManager.removeItem(at: videosDirectory)
        try? fileManager.createDirectory(at: videosDirectory, withIntermediateDirectories: true)

        // Delete all records
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<VideoDownloadRecord>()
        let records = try context.fetch(descriptor)

        for record in records {
            context.delete(record)
        }

        try context.save()
        totalStorageUsed = 0

        logger.info("Deleted all downloads")
    }

    /// Delete expired downloads
    func cleanupExpiredDownloads() async throws {
        guard let container = modelContainer else { return }

        let context = ModelContext(container)
        let now = Date()

        let descriptor = FetchDescriptor<VideoDownloadRecord>(
            predicate: #Predicate { record in
                record.expiresAt != nil
            }
        )

        let records = try context.fetch(descriptor)
        var deletedCount = 0

        for record in records {
            if let expiresAt = record.expiresAt, now > expiresAt {
                if let localURL = record.localURL {
                    try? fileManager.removeItem(at: localURL)
                }
                context.delete(record)
                deletedCount += 1
            }
        }

        if context.hasChanges {
            try context.save()
        }

        calculateStorageUsed()
        logger.info("Cleaned up \(deletedCount) expired downloads")
    }

    /// Delete least recently used videos to free space
    func cleanupToFreeSpace(_ bytesNeeded: Int64) async throws {
        guard let container = modelContainer else { return }

        let context = ModelContext(container)
        let descriptor = FetchDescriptor<VideoDownloadRecord>(
            sortBy: [SortDescriptor(\.lastAccessedAt)]
        )

        let records = try context.fetch(descriptor)
        var freedBytes: Int64 = 0

        for record in records {
            guard freedBytes < bytesNeeded else { break }

            if let localURL = record.localURL {
                try? fileManager.removeItem(at: localURL)
            }

            freedBytes += record.fileSize
            context.delete(record)
        }

        try context.save()
        calculateStorageUsed()

        logger.info("Freed \(ByteCountFormatter.string(fromByteCount: freedBytes, countStyle: .file))")
    }

    /// Get all downloaded videos
    func getDownloadedVideos() async throws -> [VideoDownloadRecord] {
        guard let container = modelContainer else { return [] }

        let context = ModelContext(container)
        let descriptor = FetchDescriptor<VideoDownloadRecord>(
            predicate: #Predicate { record in
                record.isComplete
            },
            sortBy: [SortDescriptor(\.downloadedAt, order: .reverse)]
        )

        return try context.fetch(descriptor)
    }

    /// Get storage usage info
    func getStorageInfo() -> StorageInfo {
        StorageInfo(
            used: totalStorageUsed,
            limit: Constants.maxStorageBytes,
            available: max(0, Constants.maxStorageBytes - totalStorageUsed)
        )
    }

    // MARK: - Private: Download Implementation

    private func performDownload(_ task: VideoDownloadTask) async throws -> URL {
        // Update state
        activeDownloads[task.videoId] = DownloadProgress(
            videoId: task.videoId,
            progress: 0,
            bytesDownloaded: 0,
            totalBytes: task.expectedSize,
            status: .downloading
        )
        updateDownloadingState()

        return try await withCheckedThrowingContinuation { continuation in
            let downloadTask = urlSession.downloadTask(with: task.remoteURL) { [weak self] tempURL, response, error in
                Task { @MainActor [weak self] in
                    guard let self = self else {
                        continuation.resume(throwing: VideoDownloadError.cancelled)
                        return
                    }

                    // Handle error
                    if let error = error {
                        self.activeDownloads[task.videoId]?.status = .failed
                        self.downloadTasks.removeValue(forKey: task.videoId)
                        self.updateDownloadingState()

                        continuation.resume(throwing: VideoDownloadError.networkError(error.localizedDescription))
                        return
                    }

                    // Handle success
                    guard let tempURL = tempURL else {
                        self.activeDownloads[task.videoId]?.status = .failed
                        self.downloadTasks.removeValue(forKey: task.videoId)
                        self.updateDownloadingState()

                        continuation.resume(throwing: VideoDownloadError.downloadFailed)
                        return
                    }

                    do {
                        let localURL = try self.moveToLocalStorage(
                            tempURL: tempURL,
                            task: task
                        )

                        // Save record
                        try await self.saveDownloadRecord(task: task, localPath: localURL.path)

                        // Update state
                        self.activeDownloads[task.videoId]?.status = .completed
                        self.activeDownloads[task.videoId]?.progress = 1.0
                        self.downloadTasks.removeValue(forKey: task.videoId)
                        self.downloadQueue.removeAll { $0.videoId == task.videoId }
                        self.calculateStorageUsed()
                        self.updateDownloadingState()

                        self.logger.info("Download completed: \(task.videoId)")
                        continuation.resume(returning: localURL)

                    } catch {
                        self.activeDownloads[task.videoId]?.status = .failed
                        self.downloadTasks.removeValue(forKey: task.videoId)
                        self.updateDownloadingState()

                        continuation.resume(throwing: error)
                    }
                }
            }

            // Track progress
            downloadTask.progress.publisher(for: \.fractionCompleted)
                .receive(on: DispatchQueue.main)
                .sink { [weak self] progress in
                    if var download = self?.activeDownloads[task.videoId] {
                        download.progress = progress
                        download.bytesDownloaded = Int64(Double(task.expectedSize) * progress)
                        self?.activeDownloads[task.videoId] = download
                    }
                }
                .store(in: &cancellables)

            downloadTasks[task.videoId] = downloadTask
            downloadTask.resume()
        }
    }

    private func resumeDownload(task: VideoDownloadTask, resumeData: Data) async throws -> URL {
        activeDownloads[task.videoId]?.status = .downloading
        updateDownloadingState()

        return try await withCheckedThrowingContinuation { continuation in
            let downloadTask = urlSession.downloadTask(withResumeData: resumeData) { [weak self] tempURL, response, error in
                Task { @MainActor [weak self] in
                    guard let self = self else {
                        continuation.resume(throwing: VideoDownloadError.cancelled)
                        return
                    }

                    if let error = error {
                        self.activeDownloads[task.videoId]?.status = .failed
                        continuation.resume(throwing: VideoDownloadError.networkError(error.localizedDescription))
                        return
                    }

                    guard let tempURL = tempURL else {
                        self.activeDownloads[task.videoId]?.status = .failed
                        continuation.resume(throwing: VideoDownloadError.downloadFailed)
                        return
                    }

                    do {
                        let localURL = try self.moveToLocalStorage(tempURL: tempURL, task: task)
                        try await self.saveDownloadRecord(task: task, localPath: localURL.path)

                        self.activeDownloads[task.videoId]?.status = .completed
                        self.downloadTasks.removeValue(forKey: task.videoId)
                        self.deleteResumeData(for: task.videoId)
                        self.calculateStorageUsed()
                        self.updateDownloadingState()

                        continuation.resume(returning: localURL)
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            }

            downloadTasks[task.videoId] = downloadTask
            downloadTask.resume()
        }
    }

    private func moveToLocalStorage(tempURL: URL, task: VideoDownloadTask) throws -> URL {
        let localURL = videosDirectory.appendingPathComponent(task.fileName)

        // Remove existing file if any
        if fileManager.fileExists(atPath: localURL.path) {
            try fileManager.removeItem(at: localURL)
        }

        try fileManager.moveItem(at: tempURL, to: localURL)
        return localURL
    }

    private func saveDownloadRecord(task: VideoDownloadTask, localPath: String) async throws {
        guard let container = modelContainer else { return }

        let context = ModelContext(container)

        // Check for existing record
        let descriptor = FetchDescriptor<VideoDownloadRecord>(
            predicate: #Predicate { record in
                record.videoId == task.videoId
            }
        )

        if let existing = try context.fetch(descriptor).first {
            existing.localPath = localPath
            existing.isComplete = true
            existing.downloadProgress = 1.0
            existing.bytesDownloaded = task.expectedSize
        } else {
            let record = VideoDownloadRecord(
                videoId: task.videoId,
                exerciseId: task.exerciseId,
                remoteURL: task.remoteURL.absoluteString,
                localPath: localPath,
                fileName: task.fileName,
                fileSize: task.expectedSize,
                resolution: task.resolution.rawValue,
                duration: task.duration,
                expiresAt: task.expiresAt
            )
            record.isComplete = true
            record.downloadProgress = 1.0
            record.bytesDownloaded = task.expectedSize
            context.insert(record)
        }

        try context.save()
    }

    // MARK: - Private: Resume Data

    private func saveResumeData(_ data: Data, for videoId: String) {
        let url = videosDirectory.appendingPathComponent("\(videoId).resume")
        try? data.write(to: url)
    }

    private func loadResumeData(for videoId: String) -> Data? {
        let url = videosDirectory.appendingPathComponent("\(videoId).resume")
        return try? Data(contentsOf: url)
    }

    private func deleteResumeData(for videoId: String) {
        let url = videosDirectory.appendingPathComponent("\(videoId).resume")
        try? fileManager.removeItem(at: url)
    }

    // MARK: - Private: Storage Helpers

    private func hasStorageSpace(for bytes: Int64) -> Bool {
        totalStorageUsed + bytes <= Constants.maxStorageBytes
    }

    private func calculateStorageUsed() {
        var total: Int64 = 0

        if let enumerator = fileManager.enumerator(
            at: videosDirectory,
            includingPropertiesForKeys: [.fileSizeKey],
            options: [.skipsHiddenFiles]
        ) {
            for case let fileURL as URL in enumerator {
                if let attributes = try? fileManager.attributesOfItem(atPath: fileURL.path),
                   let size = attributes[.size] as? Int64 {
                    total += size
                }
            }
        }

        totalStorageUsed = total
    }

    private func loadDownloadRecords() {
        guard let container = modelContainer else { return }

        Task {
            let context = ModelContext(container)
            let descriptor = FetchDescriptor<VideoDownloadRecord>(
                predicate: #Predicate { record in
                    !record.isComplete
                }
            )

            if let records = try? context.fetch(descriptor) {
                for record in records {
                    let task = VideoDownloadTask(
                        videoId: record.videoId,
                        exerciseId: record.exerciseId,
                        remoteURL: URL(string: record.remoteURL)!,
                        fileName: record.fileName,
                        expectedSize: record.fileSize,
                        resolution: VideoResolution(rawValue: record.resolution) ?? .hd,
                        duration: record.duration,
                        expiresAt: record.expiresAt
                    )
                    downloadQueue.append(task)

                    activeDownloads[record.videoId] = DownloadProgress(
                        videoId: record.videoId,
                        progress: record.downloadProgress,
                        bytesDownloaded: record.bytesDownloaded,
                        totalBytes: record.fileSize,
                        status: .paused
                    )
                }
            }
        }
    }

    private func updateDownloadingState() {
        isDownloading = !activeDownloads.filter { $0.value.status == .downloading }.isEmpty
    }
}

// MARK: - Supporting Types

/// Download task configuration
struct VideoDownloadTask {
    let videoId: String
    let exerciseId: String?
    let remoteURL: URL
    let fileName: String
    let expectedSize: Int64
    let resolution: VideoResolution
    let duration: TimeInterval
    let expiresAt: Date?
}

/// Download progress tracking
struct DownloadProgress {
    let videoId: String
    var progress: Double
    var bytesDownloaded: Int64
    var totalBytes: Int64
    var status: DownloadStatus

    var formattedProgress: String {
        "\(Int(progress * 100))%"
    }

    var formattedSize: String {
        let downloaded = ByteCountFormatter.string(fromByteCount: bytesDownloaded, countStyle: .file)
        let total = ByteCountFormatter.string(fromByteCount: totalBytes, countStyle: .file)
        return "\(downloaded) / \(total)"
    }
}

/// Download status
enum DownloadStatus {
    case pending
    case downloading
    case paused
    case completed
    case failed
}

/// Storage info
struct StorageInfo {
    let used: Int64
    let limit: Int64
    let available: Int64

    var usedPercentage: Double {
        guard limit > 0 else { return 0 }
        return Double(used) / Double(limit)
    }

    var formattedUsed: String {
        ByteCountFormatter.string(fromByteCount: used, countStyle: .file)
    }

    var formattedLimit: String {
        ByteCountFormatter.string(fromByteCount: limit, countStyle: .file)
    }

    var formattedAvailable: String {
        ByteCountFormatter.string(fromByteCount: available, countStyle: .file)
    }
}

// MARK: - Video Download Error

enum VideoDownloadError: LocalizedError {
    case invalidURL
    case alreadyDownloading
    case downloadNotFound
    case downloadFailed
    case insufficientStorage
    case networkError(String)
    case fileSystemError(String)
    case cancelled

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid video URL"
        case .alreadyDownloading:
            return "Video is already downloading"
        case .downloadNotFound:
            return "Download not found"
        case .downloadFailed:
            return "Download failed"
        case .insufficientStorage:
            return "Insufficient storage space. Delete some videos to free up space."
        case .networkError(let message):
            return "Network error: \(message)"
        case .fileSystemError(let message):
            return "File system error: \(message)"
        case .cancelled:
            return "Download was cancelled"
        }
    }
}

// MARK: - SwiftUI Views

/// View showing download progress
struct DownloadProgressView: View {
    let progress: DownloadProgress

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                statusIcon
                Text(statusText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(progress.formattedProgress)
                    .font(.caption.monospacedDigit())
            }

            ProgressView(value: progress.progress)
                .tint(progressColor)

            Text(progress.formattedSize)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
    }

    @ViewBuilder
    private var statusIcon: some View {
        switch progress.status {
        case .downloading:
            Image(systemName: "arrow.down.circle")
                .foregroundStyle(.blue)
        case .paused:
            Image(systemName: "pause.circle")
                .foregroundStyle(.orange)
        case .completed:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
        case .failed:
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundStyle(.red)
        case .pending:
            Image(systemName: "clock")
                .foregroundStyle(.secondary)
        }
    }

    private var statusText: String {
        switch progress.status {
        case .downloading: return "Downloading..."
        case .paused: return "Paused"
        case .completed: return "Complete"
        case .failed: return "Failed"
        case .pending: return "Waiting..."
        }
    }

    private var progressColor: Color {
        switch progress.status {
        case .downloading: return .blue
        case .paused: return .orange
        case .completed: return .green
        case .failed: return .red
        case .pending: return .secondary
        }
    }
}

/// View for storage management
struct StorageManagementView: View {
    @ObservedObject private var downloadManager = VideoDownloadManager.shared
    @State private var downloads: [VideoDownloadRecord] = []
    @State private var showDeleteAllAlert = false

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    let info = downloadManager.getStorageInfo()

                    HStack {
                        Text("Offline Videos")
                            .font(.headline)
                        Spacer()
                        Text(info.formattedUsed)
                            .foregroundStyle(.secondary)
                    }

                    ProgressView(value: info.usedPercentage)
                        .tint(info.usedPercentage > 0.9 ? .red : .blue)

                    HStack {
                        Text("\(info.formattedAvailable) available")
                            .font(.caption)
                        Spacer()
                        Text("Limit: \(info.formattedLimit)")
                            .font(.caption)
                    }
                    .foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)
            }

            Section("Downloaded Videos") {
                if downloads.isEmpty {
                    Text("No videos downloaded")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(downloads, id: \.videoId) { record in
                        DownloadedVideoRow(record: record) {
                            Task {
                                try? await downloadManager.deleteDownload(videoId: record.videoId)
                                await loadDownloads()
                            }
                        }
                    }
                }
            }

            if !downloads.isEmpty {
                Section {
                    Button("Delete All Downloads", role: .destructive) {
                        showDeleteAllAlert = true
                    }
                }
            }
        }
        .navigationTitle("Storage")
        .task {
            await loadDownloads()
        }
        .alert("Delete All Downloads?", isPresented: $showDeleteAllAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete All", role: .destructive) {
                Task {
                    try? await downloadManager.deleteAllDownloads()
                    await loadDownloads()
                }
            }
        } message: {
            Text("This will delete all offline videos. You can download them again anytime.")
        }
    }

    private func loadDownloads() async {
        downloads = (try? await downloadManager.getDownloadedVideos()) ?? []
    }
}

/// Row for downloaded video
struct DownloadedVideoRow: View {
    let record: VideoDownloadRecord
    let onDelete: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(record.fileName)
                    .lineLimit(1)

                HStack {
                    Text(ByteCountFormatter.string(fromByteCount: record.fileSize, countStyle: .file))
                    Text(record.resolution)
                    if let expires = record.expiresAt {
                        Text("Expires: \(expires.formatted(.relative(presentation: .named)))")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            Button(role: .destructive) {
                onDelete()
            } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(.borderless)
        }
    }
}

#endif // os(iOS)
