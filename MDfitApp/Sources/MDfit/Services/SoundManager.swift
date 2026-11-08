import Foundation
import Combine
import AVFoundation
#if canImport(UIKit)
import UIKit
#endif
import UserNotifications

// MARK: - Sound Types

enum MDFitSound: String, CaseIterable {
    // Workout Sounds
    case workoutStart = "workout_start"
    case workoutComplete = "workout_complete"
    case exerciseComplete = "exercise_complete"
    case setComplete = "set_complete"
    case restStart = "rest_start"
    case restEnd = "rest_end"
    case countdown3 = "countdown_3"
    case countdown2 = "countdown_2"
    case countdown1 = "countdown_1"
    case countdownGo = "countdown_go"

    // Achievement Sounds
    case xpEarned = "xp_earned"
    case levelUp = "level_up"
    case achievementUnlocked = "achievement_unlocked"
    case streakMilestone = "streak_milestone"
    case personalRecord = "personal_record"
    case gemEarned = "gem_earned"

    // Alert Sounds
    case notification = "notification"
    case reminder = "reminder"
    case streakWarning = "streak_warning"
    case error = "error"
    case success = "success"

    // UI Sounds
    case buttonTap = "button_tap"
    case toggle = "toggle"
    case swipe = "swipe"
    case pop = "pop"
    case whoosh = "whoosh"

    var category: SoundCategory {
        switch self {
        case .workoutStart, .workoutComplete, .exerciseComplete, .setComplete,
             .restStart, .restEnd, .countdown3, .countdown2, .countdown1, .countdownGo:
            return .workout
        case .xpEarned, .levelUp, .achievementUnlocked, .streakMilestone, .personalRecord, .gemEarned:
            return .achievement
        case .notification, .reminder, .streakWarning, .error, .success:
            return .alert
        case .buttonTap, .toggle, .swipe, .pop, .whoosh:
            return .ui
        }
    }

    var systemSoundFallback: SystemSoundID {
        switch self {
        case .workoutStart, .countdownGo:
            return 1025
        case .workoutComplete, .levelUp:
            return 1026
        case .exerciseComplete, .setComplete:
            return 1057
        case .restStart:
            return 1052
        case .restEnd:
            return 1054
        case .countdown3, .countdown2, .countdown1:
            return 1103
        case .xpEarned, .gemEarned:
            return 1075
        case .achievementUnlocked, .streakMilestone, .personalRecord:
            return 1025
        case .notification, .reminder:
            return 1007
        case .streakWarning:
            return 1006
        case .error:
            return 1073
        case .success:
            return 1075
        case .buttonTap:
            return 1104
        case .toggle:
            return 1105
        case .swipe:
            return 1100
        case .pop:
            return 1104
        case .whoosh:
            return 1110
        }
    }

    var notificationSound: UNNotificationSound {
        if let url = Bundle.main.url(forResource: rawValue, withExtension: "caf") {
            return UNNotificationSound(named: UNNotificationSoundName(rawValue: url.lastPathComponent))
        }
        return .default
    }
}

enum SoundCategory: String {
    case workout
    case achievement
    case alert
    case ui
}

// MARK: - Sound Manager

@MainActor
final class SoundManager: ObservableObject {
    static let shared = SoundManager()

    @Published var isSoundEnabled: Bool {
        didSet { UserDefaults.standard.set(isSoundEnabled, forKey: "mdfit_sound_enabled") }
    }

    @Published var masterVolume: Float {
        didSet { UserDefaults.standard.set(masterVolume, forKey: "mdfit_master_volume") }
    }

    @Published var workoutVolume: Float {
        didSet { UserDefaults.standard.set(workoutVolume, forKey: "mdfit_workout_volume") }
    }

    @Published var achievementVolume: Float {
        didSet { UserDefaults.standard.set(achievementVolume, forKey: "mdfit_achievement_volume") }
    }

    @Published var alertVolume: Float {
        didSet { UserDefaults.standard.set(alertVolume, forKey: "mdfit_alert_volume") }
    }

    @Published var uiVolume: Float {
        didSet { UserDefaults.standard.set(uiVolume, forKey: "mdfit_ui_volume") }
    }

    private var audioPlayers: [String: AVAudioPlayer] = [:]
    private var audioSession: AVAudioSession?
    private let preloadQueue = DispatchQueue(label: "com.mdfit.sound.preload", qos: .utility)

    private init() {
        isSoundEnabled = UserDefaults.standard.object(forKey: "mdfit_sound_enabled") as? Bool ?? true
        masterVolume = UserDefaults.standard.object(forKey: "mdfit_master_volume") as? Float ?? 0.8
        workoutVolume = UserDefaults.standard.object(forKey: "mdfit_workout_volume") as? Float ?? 1.0
        achievementVolume = UserDefaults.standard.object(forKey: "mdfit_achievement_volume") as? Float ?? 1.0
        alertVolume = UserDefaults.standard.object(forKey: "mdfit_alert_volume") as? Float ?? 0.8
        uiVolume = UserDefaults.standard.object(forKey: "mdfit_ui_volume") as? Float ?? 0.5

        setupAudioSession()
        preloadFrequentSounds()
    }

    // MARK: - Audio Session

    private func setupAudioSession() {
        #if canImport(UIKit)
        do {
            audioSession = AVAudioSession.sharedInstance()
            try audioSession?.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try audioSession?.setActive(true)
        } catch {
            print("[SoundManager] Failed to setup audio session: \(error)")
        }
        #endif
    }

    func configureForWorkout() {
        #if canImport(UIKit)
        do {
            try audioSession?.setCategory(.playback, mode: .default, options: [.duckOthers])
            try audioSession?.setActive(true)
        } catch {
            print("[SoundManager] Failed to configure for workout: \(error)")
        }
        #endif
    }

    func configureForBackground() {
        #if canImport(UIKit)
        do {
            try audioSession?.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
        } catch {
            print("[SoundManager] Failed to configure for background: \(error)")
        }
        #endif
    }

    // MARK: - Preloading

    private func preloadFrequentSounds() {
        let frequentSounds: [MDFitSound] = [
            .buttonTap, .setComplete, .exerciseComplete, .countdown3, .countdown2, .countdown1, .countdownGo
        ]

        preloadQueue.async { [weak self] in
            for sound in frequentSounds {
                self?.preloadSound(sound)
            }
        }
    }

    private func preloadSound(_ sound: MDFitSound) {
        guard let url = Bundle.main.url(forResource: sound.rawValue, withExtension: "caf") ??
                        Bundle.main.url(forResource: sound.rawValue, withExtension: "mp3") ??
                        Bundle.main.url(forResource: sound.rawValue, withExtension: "wav") else {
            return
        }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            DispatchQueue.main.async { [weak self] in
                self?.audioPlayers[sound.rawValue] = player
            }
        } catch {
            print("[SoundManager] Failed to preload \(sound.rawValue): \(error)")
        }
    }

    // MARK: - Playback

    func play(_ sound: MDFitSound) {
        guard isSoundEnabled else { return }

        let volume = calculateVolume(for: sound)
        guard volume > 0 else { return }

        if let player = audioPlayers[sound.rawValue] {
            player.volume = volume
            player.currentTime = 0
            player.play()
        } else if let url = Bundle.main.url(forResource: sound.rawValue, withExtension: "caf") ??
                          Bundle.main.url(forResource: sound.rawValue, withExtension: "mp3") ??
                          Bundle.main.url(forResource: sound.rawValue, withExtension: "wav") {
            do {
                let player = try AVAudioPlayer(contentsOf: url)
                player.volume = volume
                player.prepareToPlay()
                player.play()
                audioPlayers[sound.rawValue] = player
            } catch {
                playSystemSound(sound)
            }
        } else {
            playSystemSound(sound)
        }
    }

    private func playSystemSound(_ sound: MDFitSound) {
        #if canImport(UIKit)
        AudioServicesPlaySystemSound(sound.systemSoundFallback)
        #endif
    }

    private func calculateVolume(for sound: MDFitSound) -> Float {
        let categoryVolume: Float
        switch sound.category {
        case .workout:
            categoryVolume = workoutVolume
        case .achievement:
            categoryVolume = achievementVolume
        case .alert:
            categoryVolume = alertVolume
        case .ui:
            categoryVolume = uiVolume
        }

        return masterVolume * categoryVolume
    }

    // MARK: - Countdown Sequence

    func playCountdownSequence() async {
        guard isSoundEnabled else { return }

        configureForWorkout()

        play(.countdown3)
        try? await Task.sleep(nanoseconds: 1_000_000_000)

        play(.countdown2)
        try? await Task.sleep(nanoseconds: 1_000_000_000)

        play(.countdown1)
        try? await Task.sleep(nanoseconds: 1_000_000_000)

        play(.countdownGo)
    }

    func stopAllSounds() {
        for player in audioPlayers.values {
            player.stop()
        }
    }

    func cleanup() {
        stopAllSounds()
        audioPlayers.removeAll()
    }
}
