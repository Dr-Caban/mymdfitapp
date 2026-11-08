import Foundation
import SwiftUI
import AVFoundation
import Combine

// MARK: - Video Asset Model

/// Represents a video asset with metadata for exercise demonstrations
struct VideoAsset: Identifiable, Codable, Hashable {
    let id: String
    var exerciseId: String
    var filename: String
    var title: String
    var description: String?
    var duration: TimeInterval                  // seconds
    var thumbnailURL: URL?
    var streamingURL: URL?
    var downloadURL: URL?
    var resolution: VideoResolution
    var fileSize: Int64?                        // bytes
    var bodyRegion: BodyRegion
    var category: ExerciseCategory
    var level: DifficultyLevel
    var isPremiumOnly: Bool
    var tags: [String]
    var uploadedAt: Date
    var updatedAt: Date

    /// Computed filename based on MD Fit naming convention
    /// Format: REGION_CATEGORY_MOVEMENT_SUBTYPE.mp4
    var conventionFilename: String {
        "\(bodyRegion.rawValue.uppercased())_\(category.rawValue.uppercased())_\(title.replacingOccurrences(of: " ", with: "_").uppercased()).mp4"
    }

    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        if minutes > 0 {
            return String(format: "%d:%02d", minutes, seconds)
        }
        return "\(seconds)s"
    }

    var formattedFileSize: String? {
        guard let size = fileSize else { return nil }
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }
}

enum VideoResolution: String, Codable, Hashable {
    case sd = "480p"
    case hd = "720p"
    case fullHD = "1080p"
    case uhd = "4K"

    var displayName: String { rawValue }

    var preferredBitrate: Int {
        switch self {
        case .sd: return 1_500_000
        case .hd: return 3_000_000
        case .fullHD: return 6_000_000
        case .uhd: return 15_000_000
        }
    }
}

// MARK: - Video Playback State

/// Tracks the current state of video playback
struct VideoPlaybackState: Codable, Hashable {
    var videoId: String
    var currentTime: TimeInterval
    var duration: TimeInterval
    var isPlaying: Bool
    var playbackRate: Float
    var isMuted: Bool
    var volume: Float
    var lastUpdated: Date

    var progress: Double {
        guard duration > 0 else { return 0 }
        return min(currentTime / duration, 1.0)
    }

    var remainingTime: TimeInterval {
        max(duration - currentTime, 0)
    }

    var formattedCurrentTime: String {
        formatTime(currentTime)
    }

    var formattedRemainingTime: String {
        "-\(formatTime(remainingTime))"
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    static func initial(videoId: String, duration: TimeInterval = 0) -> VideoPlaybackState {
        VideoPlaybackState(
            videoId: videoId,
            currentTime: 0,
            duration: duration,
            isPlaying: false,
            playbackRate: 1.0,
            isMuted: false,
            volume: 1.0,
            lastUpdated: Date()
        )
    }
}

// MARK: - Video Progress (Resume Tracking)

/// Persisted progress for resuming video playback
struct VideoProgress: Identifiable, Codable, Hashable {
    var id: String { videoId }
    var videoId: String
    var userId: String
    var watchedSeconds: TimeInterval
    var totalDuration: TimeInterval
    var completedAt: Date?
    var lastWatchedAt: Date
    var watchCount: Int

    var percentComplete: Double {
        guard totalDuration > 0 else { return 0 }
        return min(watchedSeconds / totalDuration, 1.0)
    }

    var isCompleted: Bool {
        completedAt != nil || percentComplete >= 0.95
    }

    var resumeTime: TimeInterval {
        // Don't resume if essentially complete or at very beginning
        guard !isCompleted, watchedSeconds > 5 else { return 0 }
        // Back up 3 seconds for context
        return max(watchedSeconds - 3, 0)
    }
}

// MARK: - Daily View Tracking

/// Tracks daily video views for free tier limits
struct DailyViewRecord: Codable {
    var date: Date
    var videoIds: [String]

    var viewCount: Int { videoIds.count }

    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }

    static func today() -> DailyViewRecord {
        DailyViewRecord(date: Date(), videoIds: [])
    }
}

// MARK: - Video Service Errors

enum VideoServiceError: LocalizedError {
    case videoNotFound(String)
    case streamingURLUnavailable
    case thumbnailLoadFailed
    case dailyLimitReached(remaining: Int)
    case premiumRequired
    case networkError(Error)
    case cacheError(Error)
    case invalidVideoState

    var errorDescription: String? {
        switch self {
        case .videoNotFound(let id):
            return "Video not found: \(id)"
        case .streamingURLUnavailable:
            return "Video is temporarily unavailable for streaming"
        case .thumbnailLoadFailed:
            return "Failed to load video thumbnail"
        case .dailyLimitReached(let remaining):
            return "Daily view limit reached. \(remaining) views remaining. Upgrade to Premium for unlimited access."
        case .premiumRequired:
            return "This video requires a Premium subscription"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .cacheError(let error):
            return "Cache error: \(error.localizedDescription)"
        case .invalidVideoState:
            return "Invalid video playback state"
        }
    }
}

// MARK: - Video Service

/// Production-ready service for video management, streaming, and playback tracking
@MainActor
final class VideoService: ObservableObject {

    // MARK: - Singleton

    static let shared = VideoService()

    // MARK: - Published Properties

    @Published private(set) var currentVideo: VideoAsset?
    @Published private(set) var playbackState: VideoPlaybackState?
    @Published private(set) var isLoading = false
    @Published private(set) var error: VideoServiceError?
    @Published private(set) var cachedThumbnails: [String: UIImage] = [:]
    @Published private(set) var dailyViewsRemaining: Int = 3
    @Published private(set) var videoProgress: [String: VideoProgress] = [:]

    // MARK: - Constants

    private enum Constants {
        static let freeTierDailyLimit = 3
        static let thumbnailCacheLimit = 100
        static let progressSaveDebounceSeconds: TimeInterval = 5
        static let minimumWatchTimeForProgress: TimeInterval = 3
        static let completionThreshold: Double = 0.95
        static let baseStreamingURL = "https://cdn.mdfitsrq.com/videos"
        static let baseThumbnailURL = "https://cdn.mdfitsrq.com/thumbnails"
    }

    // MARK: - Private Properties

    private let userDefaults = UserDefaults.standard
    private let progressKey = "mdfit_video_progress"
    private let dailyViewsKey = "mdfit_daily_views"
    private var thumbnailCache = NSCache<NSString, UIImage>()
    private var progressSaveTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    private init() {
        setupThumbnailCache()
        loadPersistedProgress()
        loadDailyViews()
    }

    private func setupThumbnailCache() {
        thumbnailCache.countLimit = Constants.thumbnailCacheLimit
        thumbnailCache.totalCostLimit = 50 * 1024 * 1024 // 50 MB
    }

    // MARK: - Video Metadata

    /// Fetches video asset metadata by ID
    func fetchVideoAsset(id: String) async throws -> VideoAsset {
        isLoading = true
        error = nil

        defer { isLoading = false }

        // TODO: Replace with actual API call
        try await Task.sleep(nanoseconds: 500_000_000) // Simulate network

        // Check sample videos first
        if let sample = VideoAsset.samples.first(where: { $0.id == id }) {
            currentVideo = sample
            return sample
        }

        throw VideoServiceError.videoNotFound(id)
    }

    /// Fetches video asset for an exercise
    func fetchVideoAsset(for exercise: Exercise) async throws -> VideoAsset? {
        guard let videoAssetId = exercise.videoAssetId else { return nil }
        return try await fetchVideoAsset(id: videoAssetId)
    }

    /// Searches videos by criteria
    func searchVideos(
        query: String? = nil,
        bodyRegion: BodyRegion? = nil,
        category: ExerciseCategory? = nil,
        level: DifficultyLevel? = nil,
        tags: [String]? = nil,
        limit: Int = 20,
        offset: Int = 0
    ) async throws -> [VideoAsset] {
        isLoading = true
        error = nil

        defer { isLoading = false }

        // TODO: Replace with actual API call
        try await Task.sleep(nanoseconds: 300_000_000)

        var results = VideoAsset.samples

        // Apply filters
        if let query = query?.lowercased(), !query.isEmpty {
            results = results.filter {
                $0.title.lowercased().contains(query) ||
                $0.description?.lowercased().contains(query) == true ||
                $0.tags.contains { $0.lowercased().contains(query) }
            }
        }

        if let region = bodyRegion {
            results = results.filter { $0.bodyRegion == region }
        }

        if let cat = category {
            results = results.filter { $0.category == cat }
        }

        if let lvl = level {
            results = results.filter { $0.level == lvl }
        }

        if let searchTags = tags, !searchTags.isEmpty {
            results = results.filter { video in
                searchTags.allSatisfy { tag in
                    video.tags.contains { $0.lowercased() == tag.lowercased() }
                }
            }
        }

        // Apply pagination
        let startIndex = min(offset, results.count)
        let endIndex = min(offset + limit, results.count)
        return Array(results[startIndex..<endIndex])
    }

    // MARK: - Streaming URL Generation

    /// Generates a signed streaming URL for the video
    func generateStreamingURL(
        for video: VideoAsset,
        resolution: VideoResolution = .hd,
        user: User?
    ) async throws -> URL {
        // Check access permissions
        try checkVideoAccess(video: video, user: user)

        // Track view for free tier
        if user?.isPremium != true {
            try await recordVideoView(videoId: video.id)
        }

        // Generate signed URL (in production, this would call the backend)
        // TODO: Replace with actual signed URL generation
        let baseURL = video.streamingURL ?? URL(string: "\(Constants.baseStreamingURL)/\(video.filename)")!

        // Add resolution and token parameters
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "resolution", value: resolution.rawValue),
            URLQueryItem(name: "token", value: generateTemporaryToken()),
            URLQueryItem(name: "expires", value: String(Int(Date().addingTimeInterval(3600).timeIntervalSince1970)))
        ]

        guard let streamingURL = components?.url else {
            throw VideoServiceError.streamingURLUnavailable
        }

        return streamingURL
    }

    /// Generates HLS streaming URL with adaptive bitrate
    func generateAdaptiveStreamingURL(
        for video: VideoAsset,
        user: User?
    ) async throws -> URL {
        try checkVideoAccess(video: video, user: user)

        if user?.isPremium != true {
            try await recordVideoView(videoId: video.id)
        }

        // Generate HLS manifest URL
        let hlsFilename = video.filename.replacingOccurrences(of: ".mp4", with: ".m3u8")
        let baseURL = URL(string: "\(Constants.baseStreamingURL)/hls/\(hlsFilename)")!

        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "token", value: generateTemporaryToken()),
            URLQueryItem(name: "expires", value: String(Int(Date().addingTimeInterval(3600).timeIntervalSince1970)))
        ]

        guard let hlsURL = components?.url else {
            throw VideoServiceError.streamingURLUnavailable
        }

        return hlsURL
    }

    private func generateTemporaryToken() -> String {
        // In production, this would be a signed JWT or similar
        let timestamp = Int(Date().timeIntervalSince1970)
        return "tk_\(timestamp)_\(UUID().uuidString.prefix(8))"
    }

    // MARK: - Access Control

    /// Checks if user has access to view the video
    func checkVideoAccess(video: VideoAsset, user: User?) throws {
        // Premium videos require subscription
        if video.isPremiumOnly {
            guard user?.isPremium == true else {
                throw VideoServiceError.premiumRequired
            }
        }

        // Free tier daily limit check
        if user?.isPremium != true {
            let viewsUsed = getTodayViewCount()
            if viewsUsed >= Constants.freeTierDailyLimit {
                throw VideoServiceError.dailyLimitReached(remaining: 0)
            }
        }
    }

    /// Checks if user can view video (returns bool instead of throwing)
    func canViewVideo(video: VideoAsset, user: User?) -> Bool {
        do {
            try checkVideoAccess(video: video, user: user)
            return true
        } catch {
            return false
        }
    }

    /// Returns true if user has premium access
    func hasPremiumAccess(user: User?) -> Bool {
        user?.isPremium == true
    }

    // MARK: - Daily View Limits (Free Tier)

    /// Records a video view for daily limit tracking
    func recordVideoView(videoId: String) async throws {
        var dailyViews = loadDailyViewRecord()

        // Reset if new day
        if !dailyViews.isToday {
            dailyViews = DailyViewRecord.today()
        }

        // Check if already viewed today (don't count duplicate views)
        if dailyViews.videoIds.contains(videoId) {
            return
        }

        // Check limit
        if dailyViews.viewCount >= Constants.freeTierDailyLimit {
            throw VideoServiceError.dailyLimitReached(remaining: 0)
        }

        // Record view
        dailyViews.videoIds.append(videoId)
        saveDailyViewRecord(dailyViews)
        updateDailyViewsRemaining()
    }

    /// Gets remaining free views for today
    func getRemainingFreeViews() -> Int {
        let viewsUsed = getTodayViewCount()
        return max(Constants.freeTierDailyLimit - viewsUsed, 0)
    }

    private func getTodayViewCount() -> Int {
        let record = loadDailyViewRecord()
        return record.isToday ? record.viewCount : 0
    }

    private func loadDailyViewRecord() -> DailyViewRecord {
        guard let data = userDefaults.data(forKey: dailyViewsKey),
              let record = try? JSONDecoder().decode(DailyViewRecord.self, from: data) else {
            return DailyViewRecord.today()
        }
        return record
    }

    private func saveDailyViewRecord(_ record: DailyViewRecord) {
        if let data = try? JSONEncoder().encode(record) {
            userDefaults.set(data, forKey: dailyViewsKey)
        }
    }

    private func loadDailyViews() {
        updateDailyViewsRemaining()
    }

    private func updateDailyViewsRemaining() {
        dailyViewsRemaining = getRemainingFreeViews()
    }

    // MARK: - Playback State Management

    /// Starts tracking playback for a video
    func startPlayback(video: VideoAsset) {
        let existingProgress = videoProgress[video.id]
        let resumeTime = existingProgress?.resumeTime ?? 0

        playbackState = VideoPlaybackState(
            videoId: video.id,
            currentTime: resumeTime,
            duration: video.duration,
            isPlaying: true,
            playbackRate: 1.0,
            isMuted: false,
            volume: 1.0,
            lastUpdated: Date()
        )

        currentVideo = video
    }

    /// Updates playback state with current time
    func updatePlaybackTime(_ time: TimeInterval) {
        guard var state = playbackState else { return }
        state.currentTime = time
        state.lastUpdated = Date()
        playbackState = state

        // Debounced progress save
        scheduleProgressSave()
    }

    /// Updates play/pause state
    func setPlaying(_ isPlaying: Bool) {
        guard var state = playbackState else { return }
        state.isPlaying = isPlaying
        state.lastUpdated = Date()
        playbackState = state
    }

    /// Updates playback rate
    func setPlaybackRate(_ rate: Float) {
        guard var state = playbackState else { return }
        state.playbackRate = rate
        state.lastUpdated = Date()
        playbackState = state
    }

    /// Updates mute state
    func setMuted(_ muted: Bool) {
        guard var state = playbackState else { return }
        state.isMuted = muted
        state.lastUpdated = Date()
        playbackState = state
    }

    /// Updates volume
    func setVolume(_ volume: Float) {
        guard var state = playbackState else { return }
        state.volume = max(0, min(1, volume))
        state.lastUpdated = Date()
        playbackState = state
    }

    /// Seeks to specific time
    func seekTo(_ time: TimeInterval) {
        guard var state = playbackState else { return }
        state.currentTime = max(0, min(time, state.duration))
        state.lastUpdated = Date()
        playbackState = state
        scheduleProgressSave()
    }

    /// Stops playback and saves progress
    func stopPlayback() {
        saveCurrentProgress()
        playbackState = nil
        currentVideo = nil
    }

    // MARK: - Video Progress / Resume

    /// Gets progress for a specific video
    func getProgress(for videoId: String) -> VideoProgress? {
        videoProgress[videoId]
    }

    /// Gets resume time for a video (returns 0 if should start from beginning)
    func getResumeTime(for videoId: String) -> TimeInterval {
        videoProgress[videoId]?.resumeTime ?? 0
    }

    /// Checks if video has been started but not completed
    func hasUnfinishedProgress(for videoId: String) -> Bool {
        guard let progress = videoProgress[videoId] else { return false }
        return progress.watchedSeconds > Constants.minimumWatchTimeForProgress && !progress.isCompleted
    }

    /// Marks a video as completed
    func markAsCompleted(videoId: String, userId: String) {
        if var progress = videoProgress[videoId] {
            progress.completedAt = Date()
            progress.watchCount += 1
            progress.lastWatchedAt = Date()
            videoProgress[videoId] = progress
        } else if let video = currentVideo, video.id == videoId {
            videoProgress[videoId] = VideoProgress(
                videoId: videoId,
                userId: userId,
                watchedSeconds: video.duration,
                totalDuration: video.duration,
                completedAt: Date(),
                lastWatchedAt: Date(),
                watchCount: 1
            )
        }
        persistProgress()
    }

    /// Resets progress for a video
    func resetProgress(for videoId: String) {
        videoProgress.removeValue(forKey: videoId)
        persistProgress()
    }

    /// Gets all videos in progress (started but not completed)
    func getVideosInProgress() -> [VideoProgress] {
        videoProgress.values
            .filter { !$0.isCompleted && $0.watchedSeconds > Constants.minimumWatchTimeForProgress }
            .sorted { $0.lastWatchedAt > $1.lastWatchedAt }
    }

    /// Gets all completed videos
    func getCompletedVideos() -> [VideoProgress] {
        videoProgress.values
            .filter { $0.isCompleted }
            .sorted { ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast) }
    }

    private func scheduleProgressSave() {
        progressSaveTask?.cancel()
        progressSaveTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(Constants.progressSaveDebounceSeconds * 1_000_000_000))
            guard !Task.isCancelled else { return }
            await self?.saveCurrentProgress()
        }
    }

    private func saveCurrentProgress() {
        guard let state = playbackState,
              let video = currentVideo,
              state.currentTime > Constants.minimumWatchTimeForProgress else { return }

        let userId = "current_user" // TODO: Get from AuthService

        var progress = videoProgress[video.id] ?? VideoProgress(
            videoId: video.id,
            userId: userId,
            watchedSeconds: 0,
            totalDuration: video.duration,
            completedAt: nil,
            lastWatchedAt: Date(),
            watchCount: 0
        )

        progress.watchedSeconds = max(progress.watchedSeconds, state.currentTime)
        progress.totalDuration = state.duration
        progress.lastWatchedAt = Date()

        // Mark completed if threshold reached
        if progress.percentComplete >= Constants.completionThreshold && progress.completedAt == nil {
            progress.completedAt = Date()
            progress.watchCount += 1
        }

        videoProgress[video.id] = progress
        persistProgress()
    }

    private func persistProgress() {
        let progressArray = Array(videoProgress.values)
        if let data = try? JSONEncoder().encode(progressArray) {
            userDefaults.set(data, forKey: progressKey)
        }
    }

    private func loadPersistedProgress() {
        guard let data = userDefaults.data(forKey: progressKey),
              let progressArray = try? JSONDecoder().decode([VideoProgress].self, from: data) else {
            return
        }
        videoProgress = Dictionary(uniqueKeysWithValues: progressArray.map { ($0.videoId, $0) })
    }

    // MARK: - Thumbnail Loading & Caching

    /// Loads and caches thumbnail for a video
    func loadThumbnail(for video: VideoAsset) async throws -> UIImage {
        // Check memory cache
        if let cached = thumbnailCache.object(forKey: video.id as NSString) {
            return cached
        }

        // Check published cache (for SwiftUI reactivity)
        if let cached = cachedThumbnails[video.id] {
            return cached
        }

        // Load from network
        let thumbnailURL = video.thumbnailURL ?? generateThumbnailURL(for: video)

        do {
            let (data, response) = try await URLSession.shared.data(from: thumbnailURL)

            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw VideoServiceError.thumbnailLoadFailed
            }

            guard let image = UIImage(data: data) else {
                throw VideoServiceError.thumbnailLoadFailed
            }

            // Cache in memory
            thumbnailCache.setObject(image, forKey: video.id as NSString)
            cachedThumbnails[video.id] = image

            return image
        } catch let networkError as URLError {
            throw VideoServiceError.networkError(networkError)
        } catch let serviceError as VideoServiceError {
            throw serviceError
        } catch {
            throw VideoServiceError.thumbnailLoadFailed
        }
    }

    /// Preloads thumbnails for multiple videos
    func preloadThumbnails(for videos: [VideoAsset]) async {
        await withTaskGroup(of: Void.self) { group in
            for video in videos {
                group.addTask { [weak self] in
                    try? await self?.loadThumbnail(for: video)
                }
            }
        }
    }

    /// Clears thumbnail cache
    func clearThumbnailCache() {
        thumbnailCache.removeAllObjects()
        cachedThumbnails.removeAll()
    }

    /// Gets cached thumbnail if available
    func getCachedThumbnail(for videoId: String) -> UIImage? {
        thumbnailCache.object(forKey: videoId as NSString) ?? cachedThumbnails[videoId]
    }

    private func generateThumbnailURL(for video: VideoAsset) -> URL {
        let thumbnailFilename = video.filename.replacingOccurrences(of: ".mp4", with: "_thumb.jpg")
        return URL(string: "\(Constants.baseThumbnailURL)/\(thumbnailFilename)")!
    }

    // MARK: - Video Extraction (for local files)

    /// Generates thumbnail from video at URL
    func generateThumbnail(from videoURL: URL, at time: TimeInterval = 1.0) async throws -> UIImage {
        let asset = AVURLAsset(url: videoURL)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: 640, height: 360)

        let cmTime = CMTime(seconds: time, preferredTimescale: 600)

        return try await withCheckedThrowingContinuation { continuation in
            generator.generateCGImagesAsynchronously(forTimes: [NSValue(time: cmTime)]) { _, cgImage, _, _, error in
                if let error = error {
                    continuation.resume(throwing: VideoServiceError.cacheError(error))
                    return
                }

                guard let cgImage = cgImage else {
                    continuation.resume(throwing: VideoServiceError.thumbnailLoadFailed)
                    return
                }

                let image = UIImage(cgImage: cgImage)
                continuation.resume(returning: image)
            }
        }
    }

    // MARK: - Error Handling

    func clearError() {
        error = nil
    }
}

// MARK: - VideoAsset Sample Data

extension VideoAsset {
    static let samples: [VideoAsset] = [
        VideoAsset(
            id: "vid_001",
            exerciseId: "ex_001",
            filename: "LOWER_BACK_MOBILITY_CAT_COW.mp4",
            title: "Cat Cow",
            description: "A gentle spinal mobility exercise that warms up the entire spine.",
            duration: 45,
            thumbnailURL: URL(string: "https://cdn.mdfitsrq.com/thumbnails/cat_cow_thumb.jpg"),
            streamingURL: URL(string: "https://cdn.mdfitsrq.com/videos/LOWER_BACK_MOBILITY_CAT_COW.mp4"),
            downloadURL: nil,
            resolution: .fullHD,
            fileSize: 12_500_000,
            bodyRegion: .lowerBack,
            category: .mobility,
            level: .beginner,
            isPremiumOnly: false,
            tags: ["spine", "warmup", "mobility", "beginner"],
            uploadedAt: Date().addingTimeInterval(-86400 * 30),
            updatedAt: Date().addingTimeInterval(-86400 * 7)
        ),
        VideoAsset(
            id: "AN_CO_ECCENTRIC_CALF_DROPS_RHB",
            exerciseId: "AN_CO_ECCENTRIC_CALF_DROPS_RHB",
            filename: "CALVES_REHAB_ECCENTRIC_CALF_DROPS.mp4",
            title: "Eccentric Calf Drops",
            description: "Rehabilitation exercise for calf and Achilles tendon strengthening.",
            duration: 90,
            thumbnailURL: URL(string: "https://cdn.mdfitsrq.com/thumbnails/calf_drops_thumb.jpg"),
            streamingURL: URL(string: "https://cdn.mdfitsrq.com/videos/CALVES_REHAB_ECCENTRIC_CALF_DROPS.mp4"),
            downloadURL: nil,
            resolution: .fullHD,
            fileSize: 25_000_000,
            bodyRegion: .calves,
            category: .rehab,
            level: .beginner,
            isPremiumOnly: false,
            tags: ["calf", "eccentric", "rehab", "plantar"],
            uploadedAt: Date().addingTimeInterval(-86400 * 45),
            updatedAt: Date().addingTimeInterval(-86400 * 10)
        ),
        VideoAsset(
            id: "SP_RT_THREAD_THE_NEEDLE_MOB",
            exerciseId: "SP_RT_THREAD_THE_NEEDLE_MOB",
            filename: "UPPER_BACK_MOBILITY_THREAD_THE_NEEDLE.mp4",
            title: "Thread the Needle",
            description: "Thoracic rotation mobility drill for upper back flexibility.",
            duration: 60,
            thumbnailURL: URL(string: "https://cdn.mdfitsrq.com/thumbnails/thread_needle_thumb.jpg"),
            streamingURL: URL(string: "https://cdn.mdfitsrq.com/videos/UPPER_BACK_MOBILITY_THREAD_THE_NEEDLE.mp4"),
            downloadURL: nil,
            resolution: .fullHD,
            fileSize: 18_000_000,
            bodyRegion: .upperBack,
            category: .mobility,
            level: .beginner,
            isPremiumOnly: false,
            tags: ["thoracic", "rotation", "mobility"],
            uploadedAt: Date().addingTimeInterval(-86400 * 60),
            updatedAt: Date().addingTimeInterval(-86400 * 5)
        ),
        VideoAsset(
            id: "HP_RT_9090_HIP_SWITCH_MOB",
            exerciseId: "HP_RT_9090_HIP_SWITCH_MOB",
            filename: "HIPS_MOBILITY_9090_HIP_SWITCH.mp4",
            title: "90/90 Hip Switch",
            description: "Hip mobility exercise targeting internal and external rotation.",
            duration: 75,
            thumbnailURL: URL(string: "https://cdn.mdfitsrq.com/thumbnails/hip_switch_thumb.jpg"),
            streamingURL: URL(string: "https://cdn.mdfitsrq.com/videos/HIPS_MOBILITY_9090_HIP_SWITCH.mp4"),
            downloadURL: nil,
            resolution: .fullHD,
            fileSize: 22_000_000,
            bodyRegion: .hips,
            category: .mobility,
            level: .beginner,
            isPremiumOnly: true,
            tags: ["hip", "rotation", "mobility"],
            uploadedAt: Date().addingTimeInterval(-86400 * 20),
            updatedAt: Date().addingTimeInterval(-86400 * 3)
        ),
        VideoAsset(
            id: "GLUTES_STRENGTHENING_SINGLE_LEG_GLUTE_BRIDGE",
            exerciseId: "glute_bridge_001",
            filename: "GLUTES_STRENGTHENING_SINGLE_LEG_GLUTE_BRIDGE.mp4",
            title: "Single Leg Glute Bridge",
            description: "Advanced glute strengthening exercise for stability and power.",
            duration: 120,
            thumbnailURL: URL(string: "https://cdn.mdfitsrq.com/thumbnails/glute_bridge_thumb.jpg"),
            streamingURL: URL(string: "https://cdn.mdfitsrq.com/videos/GLUTES_STRENGTHENING_SINGLE_LEG_GLUTE_BRIDGE.mp4"),
            downloadURL: nil,
            resolution: .fullHD,
            fileSize: 35_000_000,
            bodyRegion: .glutes,
            category: .strengthening,
            level: .intermediate,
            isPremiumOnly: true,
            tags: ["glutes", "strength", "single-leg", "stability"],
            uploadedAt: Date().addingTimeInterval(-86400 * 15),
            updatedAt: Date().addingTimeInterval(-86400 * 1)
        )
    ]

    static let sample = samples[0]
}
