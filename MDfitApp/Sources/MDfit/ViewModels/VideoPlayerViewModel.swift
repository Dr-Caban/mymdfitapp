//
//  VideoPlayerViewModel.swift
//  MDfit
//
//  Native video player state management with PiP support
//

import SwiftUI
import AVKit
import AVFoundation
import MediaPlayer
import Combine

// MARK: - Chapter Model
struct VideoChapter: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let startTime: TimeInterval
    let endTime: TimeInterval

    var duration: TimeInterval {
        endTime - startTime
    }
}

// MARK: - Playback Speed
enum PlaybackSpeed: Double, CaseIterable, Identifiable {
    case half = 0.5
    case normal = 1.0
    case oneAndHalf = 1.5
    case double = 2.0

    var id: Double { rawValue }

    var displayText: String {
        switch self {
        case .half: return "0.5x"
        case .normal: return "1x"
        case .oneAndHalf: return "1.5x"
        case .double: return "2x"
        }
    }
}

// MARK: - Player State
enum PlayerState: Equatable {
    case idle
    case loading
    case ready
    case playing
    case paused
    case buffering
    case ended
    case error(String)

    static func == (lhs: PlayerState, rhs: PlayerState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle),
             (.loading, .loading),
             (.ready, .ready),
             (.playing, .playing),
             (.paused, .paused),
             (.buffering, .buffering),
             (.ended, .ended):
            return true
        case (.error(let lhsMsg), .error(let rhsMsg)):
            return lhsMsg == rhsMsg
        default:
            return false
        }
    }
}

// MARK: - Video Player ViewModel
@MainActor
final class VideoPlayerViewModel: NSObject, ObservableObject {

    // MARK: - Published Properties
    @Published private(set) var player: AVPlayer?
    @Published private(set) var playerState: PlayerState = .idle
    @Published private(set) var currentTime: TimeInterval = 0
    @Published private(set) var duration: TimeInterval = 0
    @Published private(set) var bufferedTime: TimeInterval = 0
    @Published private(set) var currentChapter: VideoChapter?
    @Published var playbackSpeed: PlaybackSpeed = .normal {
        didSet {
            player?.rate = Float(playbackSpeed.rawValue)
            if playerState == .playing {
                player?.play()
            }
        }
    }
    @Published var isMuted: Bool = false {
        didSet {
            player?.isMuted = isMuted
        }
    }
    @Published var showControls: Bool = true
    @Published private(set) var isAirPlayActive: Bool = false
    @Published private(set) var isPictureInPictureActive: Bool = false
    @Published private(set) var isPictureInPicturePossible: Bool = false

    // MARK: - Video Info
    @Published var videoTitle: String = ""
    @Published var videoArtist: String = "MD Fit"
    @Published var videoArtwork: UIImage?
    @Published private(set) var chapters: [VideoChapter] = []

    // MARK: - PiP Controller
    private(set) var pipController: AVPictureInPictureController?
    private var playerLayer: AVPlayerLayer?

    // MARK: - Private Properties
    private var timeObserver: Any?
    private var cancellables = Set<AnyCancellable>()
    private var controlsHideTask: Task<Void, Never>?
    private var playerItemObservation: NSKeyValueObservation?
    private var statusObservation: NSKeyValueObservation?
    private var loadedTimeRangesObservation: NSKeyValueObservation?
    private var airPlayObservation: NSKeyValueObservation?

    // MARK: - State Restoration (for PiP)
    private var savedTime: TimeInterval = 0
    private var wasPlayingBeforePiP: Bool = false

    // MARK: - Initialization
    override init() {
        super.init()
        setupAudioSession()
        setupRemoteTransportControls()
        setupAirPlayObserver()
    }

    deinit {
        cleanupPlayer()
    }

    // MARK: - Audio Session Setup
    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .moviePlayback, options: [.allowAirPlay])
            try audioSession.setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }

    // MARK: - Load Video
    func loadVideo(url: URL, title: String, chapters: [VideoChapter] = []) {
        cleanupPlayer()

        playerState = .loading
        videoTitle = title
        self.chapters = chapters

        let playerItem = AVPlayerItem(url: url)
        let newPlayer = AVPlayer(playerItem: playerItem)
        newPlayer.allowsExternalPlayback = true
        newPlayer.usesExternalPlaybackWhileExternalScreenIsActive = true

        self.player = newPlayer

        setupPlayerObservers()
        setupTimeObserver()
        setupNowPlayingInfo()
    }

    // MARK: - Player Observers
    private func setupPlayerObservers() {
        guard let player = player, let playerItem = player.currentItem else { return }

        // Status observation
        statusObservation = playerItem.observe(\.status, options: [.new]) { [weak self] item, _ in
            Task { @MainActor in
                self?.handleStatusChange(item.status)
            }
        }

        // Buffering observation
        loadedTimeRangesObservation = playerItem.observe(\.loadedTimeRanges, options: [.new]) { [weak self] item, _ in
            Task { @MainActor in
                self?.updateBufferedTime(item.loadedTimeRanges)
            }
        }

        // Playback ended notification
        NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime, object: playerItem)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.handlePlaybackEnded()
            }
            .store(in: &cancellables)

        // Playback stalled notification
        NotificationCenter.default.publisher(for: .AVPlayerItemPlaybackStalled, object: playerItem)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.playerState = .buffering
            }
            .store(in: &cancellables)
    }

    private func handleStatusChange(_ status: AVPlayerItem.Status) {
        switch status {
        case .readyToPlay:
            if let duration = player?.currentItem?.duration.seconds, duration.isFinite {
                self.duration = duration
            }
            playerState = .ready
        case .failed:
            let errorMessage = player?.currentItem?.error?.localizedDescription ?? "Unknown error"
            playerState = .error(errorMessage)
        case .unknown:
            break
        @unknown default:
            break
        }
    }

    private func updateBufferedTime(_ loadedTimeRanges: [NSValue]) {
        guard let timeRange = loadedTimeRanges.first?.timeRangeValue else { return }
        let start = CMTimeGetSeconds(timeRange.start)
        let duration = CMTimeGetSeconds(timeRange.duration)
        bufferedTime = start + duration
    }

    private func handlePlaybackEnded() {
        playerState = .ended
        showControls = true
    }

    // MARK: - Time Observer
    private func setupTimeObserver() {
        let interval = CMTime(seconds: 0.1, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self = self else { return }
            Task { @MainActor in
                self.currentTime = time.seconds
                self.updateCurrentChapter()
                self.updateNowPlayingTime()
            }
        }
    }

    private func updateCurrentChapter() {
        guard !chapters.isEmpty else { return }
        currentChapter = chapters.first { chapter in
            currentTime >= chapter.startTime && currentTime < chapter.endTime
        }
    }

    // MARK: - AirPlay Observer
    private func setupAirPlayObserver() {
        airPlayObservation = AVAudioSession.sharedInstance().observe(\.currentRoute, options: [.new]) { [weak self] session, _ in
            Task { @MainActor in
                let hasAirPlayOutput = session.currentRoute.outputs.contains { output in
                    output.portType == .airPlay
                }
                self?.isAirPlayActive = hasAirPlayOutput
            }
        }
    }

    // MARK: - Playback Controls
    func play() {
        player?.rate = Float(playbackSpeed.rawValue)
        player?.play()
        playerState = .playing
        scheduleControlsHide()
    }

    func pause() {
        player?.pause()
        playerState = .paused
        showControls = true
    }

    func togglePlayPause() {
        if playerState == .playing {
            pause()
        } else {
            play()
        }
    }

    func seek(to time: TimeInterval) {
        let cmTime = CMTime(seconds: time, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        player?.seek(to: cmTime, toleranceBefore: .zero, toleranceAfter: .zero)
    }

    func seekForward(by seconds: TimeInterval = 10) {
        let newTime = min(currentTime + seconds, duration)
        seek(to: newTime)
    }

    func seekBackward(by seconds: TimeInterval = 10) {
        let newTime = max(currentTime - seconds, 0)
        seek(to: newTime)
    }

    func seekToChapter(_ chapter: VideoChapter) {
        seek(to: chapter.startTime)
        if playerState != .playing {
            play()
        }
    }

    func restart() {
        seek(to: 0)
        play()
    }

    // MARK: - Controls Visibility
    func toggleControls() {
        showControls.toggle()
        if showControls && playerState == .playing {
            scheduleControlsHide()
        }
    }

    func userInteracted() {
        showControls = true
        if playerState == .playing {
            scheduleControlsHide()
        }
    }

    private func scheduleControlsHide() {
        controlsHideTask?.cancel()
        controlsHideTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            if !Task.isCancelled && playerState == .playing {
                withAnimation(.easeOut(duration: 0.3)) {
                    showControls = false
                }
            }
        }
    }

    // MARK: - Picture in Picture
    func setupPictureInPicture(playerLayer: AVPlayerLayer) {
        guard AVPictureInPictureController.isPictureInPictureSupported() else {
            print("Picture in Picture is not supported on this device")
            return
        }

        self.playerLayer = playerLayer
        pipController = AVPictureInPictureController(playerLayer: playerLayer)
        pipController?.delegate = self

        isPictureInPicturePossible = pipController?.isPictureInPicturePossible ?? false
    }

    func togglePictureInPicture() {
        guard let pipController = pipController else { return }

        if pipController.isPictureInPictureActive {
            pipController.stopPictureInPicture()
        } else {
            pipController.startPictureInPicture()
        }
    }

    // MARK: - Now Playing Info
    private func setupNowPlayingInfo() {
        updateNowPlayingInfo()
    }

    private func updateNowPlayingInfo() {
        var nowPlayingInfo = [String: Any]()

        nowPlayingInfo[MPMediaItemPropertyTitle] = videoTitle
        nowPlayingInfo[MPMediaItemPropertyArtist] = videoArtist
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = duration
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = playerState == .playing ? playbackSpeed.rawValue : 0
        nowPlayingInfo[MPNowPlayingInfoPropertyMediaType] = MPNowPlayingInfoMediaType.video.rawValue

        if let artwork = videoArtwork {
            nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: artwork.size) { _ in artwork }
        }

        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }

    private func updateNowPlayingTime() {
        guard var nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo else { return }
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }

    // MARK: - Remote Transport Controls
    private func setupRemoteTransportControls() {
        let commandCenter = MPRemoteCommandCenter.shared()

        commandCenter.playCommand.addTarget { [weak self] _ in
            self?.play()
            return .success
        }

        commandCenter.pauseCommand.addTarget { [weak self] _ in
            self?.pause()
            return .success
        }

        commandCenter.togglePlayPauseCommand.addTarget { [weak self] _ in
            self?.togglePlayPause()
            return .success
        }

        commandCenter.skipForwardCommand.preferredIntervals = [10]
        commandCenter.skipForwardCommand.addTarget { [weak self] _ in
            self?.seekForward()
            return .success
        }

        commandCenter.skipBackwardCommand.preferredIntervals = [10]
        commandCenter.skipBackwardCommand.addTarget { [weak self] _ in
            self?.seekBackward()
            return .success
        }

        commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let positionEvent = event as? MPChangePlaybackPositionCommandEvent else {
                return .commandFailed
            }
            self?.seek(to: positionEvent.positionTime)
            return .success
        }
    }

    // MARK: - Cleanup
    private func cleanupPlayer() {
        if let timeObserver = timeObserver {
            player?.removeTimeObserver(timeObserver)
            self.timeObserver = nil
        }

        statusObservation?.invalidate()
        loadedTimeRangesObservation?.invalidate()
        playerItemObservation?.invalidate()
        airPlayObservation?.invalidate()

        cancellables.removeAll()
        controlsHideTask?.cancel()

        player?.pause()
        player = nil
        pipController = nil
        playerLayer = nil

        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }

    // MARK: - Progress Calculation
    var progress: Double {
        guard duration > 0 else { return 0 }
        return currentTime / duration
    }

    var bufferedProgress: Double {
        guard duration > 0 else { return 0 }
        return bufferedTime / duration
    }

    // MARK: - Time Formatting
    func formatTime(_ time: TimeInterval) -> String {
        guard time.isFinite else { return "0:00" }
        let totalSeconds = Int(time)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
}

// MARK: - AVPictureInPictureControllerDelegate
extension VideoPlayerViewModel: AVPictureInPictureControllerDelegate {

    nonisolated func pictureInPictureControllerWillStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        Task { @MainActor in
            wasPlayingBeforePiP = playerState == .playing
            savedTime = currentTime
            isPictureInPictureActive = true
        }
    }

    nonisolated func pictureInPictureControllerDidStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        Task { @MainActor in
            isPictureInPictureActive = true
        }
    }

    nonisolated func pictureInPictureControllerWillStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        Task { @MainActor in
            isPictureInPictureActive = false
        }
    }

    nonisolated func pictureInPictureControllerDidStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        Task { @MainActor in
            isPictureInPictureActive = false
        }
    }

    nonisolated func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void) {
        Task { @MainActor in
            // Restore playback state
            if wasPlayingBeforePiP {
                play()
            }
            completionHandler(true)
        }
    }

    nonisolated func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, failedToStartPictureInPictureWithError error: Error) {
        Task { @MainActor in
            print("Failed to start PiP: \(error.localizedDescription)")
            isPictureInPictureActive = false
        }
    }
}
