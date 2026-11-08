import Foundation
#if canImport(UIKit)
import UIKit
import CoreHaptics
#endif

// MARK: - Haptic Types

enum MDFitHaptic: String, CaseIterable {
    // Workout Haptics
    case workoutStart
    case workoutComplete
    case exerciseComplete
    case setComplete
    case restStart
    case restEnd
    case countdownTick
    case countdownGo

    // Achievement Haptics
    case xpEarned
    case levelUp
    case achievementUnlocked
    case streakMilestone
    case personalRecord

    // Alert Haptics
    case streakWarning
    case success
    case failure

    // UI Haptics
    case buttonTap
    case toggle
    case selection
    case impact
}

// MARK: - Haptic Manager

@MainActor
final class HapticManager: ObservableObject {
    static let shared = HapticManager()

    @Published var isHapticEnabled: Bool {
        didSet { UserDefaults.standard.set(isHapticEnabled, forKey: "mdfit_haptic_enabled") }
    }

    @Published var hapticIntensity: Float {
        didSet { UserDefaults.standard.set(hapticIntensity, forKey: "mdfit_haptic_intensity") }
    }

    #if canImport(UIKit)
    private var engine: CHHapticEngine?
    private var supportsHaptics: Bool = false

    private let impactLight = UIImpactFeedbackGenerator(style: .light)
    private let impactMedium = UIImpactFeedbackGenerator(style: .medium)
    private let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
    private let impactSoft = UIImpactFeedbackGenerator(style: .soft)
    private let impactRigid = UIImpactFeedbackGenerator(style: .rigid)
    private let selectionFeedback = UISelectionFeedbackGenerator()
    private let notificationFeedback = UINotificationFeedbackGenerator()
    #endif

    private init() {
        isHapticEnabled = UserDefaults.standard.object(forKey: "mdfit_haptic_enabled") as? Bool ?? true
        hapticIntensity = UserDefaults.standard.object(forKey: "mdfit_haptic_intensity") as? Float ?? 1.0

        #if canImport(UIKit)
        prepareHaptics()
        #endif
    }

    #if canImport(UIKit)
    private func prepareHaptics() {
        supportsHaptics = CHHapticEngine.capabilitiesForHardware().supportsHaptics

        guard supportsHaptics else { return }

        do {
            engine = try CHHapticEngine()
            engine?.resetHandler = { [weak self] in
                do {
                    try self?.engine?.start()
                } catch {
                    print("[HapticManager] Failed to restart haptic engine: \(error)")
                }
            }
            engine?.stoppedHandler = { reason in
                print("[HapticManager] Engine stopped: \(reason.rawValue)")
            }
            try engine?.start()
        } catch {
            print("[HapticManager] Failed to create haptic engine: \(error)")
        }

        impactLight.prepare()
        impactMedium.prepare()
        impactHeavy.prepare()
        selectionFeedback.prepare()
        notificationFeedback.prepare()
    }
    #endif

    // MARK: - Play Haptic

    func play(_ haptic: MDFitHaptic) {
        guard isHapticEnabled else { return }

        #if canImport(UIKit)
        switch haptic {
        case .buttonTap:
            impactLight.impactOccurred(intensity: hapticIntensity * 0.6)
        case .toggle:
            impactMedium.impactOccurred(intensity: hapticIntensity * 0.7)
        case .selection:
            selectionFeedback.selectionChanged()
        case .impact:
            impactMedium.impactOccurred(intensity: hapticIntensity)

        case .success:
            notificationFeedback.notificationOccurred(.success)
        case .failure:
            notificationFeedback.notificationOccurred(.error)
        case .streakWarning:
            notificationFeedback.notificationOccurred(.warning)

        case .setComplete:
            playSetCompletePattern()
        case .exerciseComplete:
            playExerciseCompletePattern()
        case .restStart:
            impactSoft.impactOccurred(intensity: hapticIntensity * 0.5)
        case .restEnd:
            impactRigid.impactOccurred(intensity: hapticIntensity * 0.8)
        case .workoutStart:
            playWorkoutStartPattern()
        case .workoutComplete:
            playWorkoutCompletePattern()
        case .countdownTick:
            impactLight.impactOccurred(intensity: hapticIntensity * 0.4)
        case .countdownGo:
            playCountdownGoPattern()

        case .xpEarned:
            playXPEarnedPattern()
        case .levelUp:
            playLevelUpPattern()
        case .achievementUnlocked:
            playAchievementPattern()
        case .streakMilestone:
            playStreakMilestonePattern()
        case .personalRecord:
            playPersonalRecordPattern()
        }
        #endif
    }

    // MARK: - Custom Patterns

    #if canImport(UIKit)
    private func playSetCompletePattern() {
        guard supportsHaptics, let engine = engine else {
            impactMedium.impactOccurred(intensity: hapticIntensity)
            return
        }

        do {
            let pattern = try CHHapticPattern(events: [
                CHHapticEvent(eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.6 * hapticIntensity),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
                    ], relativeTime: 0),
                CHHapticEvent(eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8 * hapticIntensity),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.7)
                    ], relativeTime: 0.1)
            ], parameters: [])

            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            impactMedium.impactOccurred(intensity: hapticIntensity)
        }
    }

    private func playExerciseCompletePattern() {
        guard supportsHaptics, let engine = engine else {
            impactHeavy.impactOccurred(intensity: hapticIntensity)
            return
        }

        do {
            let pattern = try CHHapticPattern(events: [
                CHHapticEvent(eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.7 * hapticIntensity),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
                    ], relativeTime: 0),
                CHHapticEvent(eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.9 * hapticIntensity),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.8)
                    ], relativeTime: 0.12)
            ], parameters: [])

            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            impactHeavy.impactOccurred(intensity: hapticIntensity)
        }
    }

    private func playWorkoutStartPattern() {
        guard supportsHaptics, let engine = engine else {
            notificationFeedback.notificationOccurred(.success)
            return
        }

        do {
            var events: [CHHapticEvent] = []

            for i in 0..<3 {
                let intensity = (0.5 + Float(i) * 0.2) * hapticIntensity
                events.append(CHHapticEvent(eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.6)
                    ], relativeTime: Double(i) * 0.15))
            }

            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            notificationFeedback.notificationOccurred(.success)
        }
    }

    private func playWorkoutCompletePattern() {
        guard supportsHaptics, let engine = engine else {
            notificationFeedback.notificationOccurred(.success)
            return
        }

        do {
            var events: [CHHapticEvent] = []

            for i in 0..<4 {
                let intensity = (0.6 + Float(i) * 0.1) * hapticIntensity
                events.append(CHHapticEvent(eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.7)
                    ], relativeTime: Double(i) * 0.12))
            }

            events.append(CHHapticEvent(eventType: .hapticContinuous,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0 * hapticIntensity),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
                ], relativeTime: 0.5, duration: 0.3))

            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            notificationFeedback.notificationOccurred(.success)
        }
    }

    private func playCountdownGoPattern() {
        guard supportsHaptics, let engine = engine else {
            impactHeavy.impactOccurred(intensity: hapticIntensity)
            return
        }

        do {
            let pattern = try CHHapticPattern(events: [
                CHHapticEvent(eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0 * hapticIntensity),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 1.0)
                    ], relativeTime: 0),
                CHHapticEvent(eventType: .hapticContinuous,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.6 * hapticIntensity),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.4)
                    ], relativeTime: 0.05, duration: 0.25)
            ], parameters: [])

            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            impactHeavy.impactOccurred(intensity: hapticIntensity)
        }
    }

    private func playXPEarnedPattern() {
        guard supportsHaptics, let engine = engine else {
            impactLight.impactOccurred(intensity: hapticIntensity * 0.7)
            return
        }

        do {
            let pattern = try CHHapticPattern(events: [
                CHHapticEvent(eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.5 * hapticIntensity),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.8)
                    ], relativeTime: 0),
                CHHapticEvent(eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.3 * hapticIntensity),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.9)
                    ], relativeTime: 0.08)
            ], parameters: [])

            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            impactLight.impactOccurred(intensity: hapticIntensity * 0.7)
        }
    }

    private func playLevelUpPattern() {
        guard supportsHaptics, let engine = engine else {
            notificationFeedback.notificationOccurred(.success)
            return
        }

        do {
            var events: [CHHapticEvent] = []

            for i in 0..<5 {
                let intensity = (0.4 + Float(i) * 0.15) * hapticIntensity
                let sharpness = 0.3 + Float(i) * 0.15

                events.append(CHHapticEvent(eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
                    ], relativeTime: Double(i) * 0.1))
            }

            events.append(CHHapticEvent(eventType: .hapticContinuous,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0 * hapticIntensity),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.8)
                ], relativeTime: 0.5, duration: 0.4))

            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            notificationFeedback.notificationOccurred(.success)
        }
    }

    private func playAchievementPattern() {
        guard supportsHaptics, let engine = engine else {
            notificationFeedback.notificationOccurred(.success)
            return
        }

        do {
            var events: [CHHapticEvent] = []

            events.append(CHHapticEvent(eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8 * hapticIntensity),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.6)
                ], relativeTime: 0))

            for i in 0..<4 {
                events.append(CHHapticEvent(eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.4 * hapticIntensity),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.9)
                    ], relativeTime: 0.15 + Double(i) * 0.08))
            }

            events.append(CHHapticEvent(eventType: .hapticContinuous,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.7 * hapticIntensity),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
                ], relativeTime: 0.5, duration: 0.3))

            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            notificationFeedback.notificationOccurred(.success)
        }
    }

    private func playStreakMilestonePattern() {
        guard supportsHaptics, let engine = engine else {
            notificationFeedback.notificationOccurred(.success)
            return
        }

        do {
            var events: [CHHapticEvent] = []

            events.append(CHHapticEvent(eventType: .hapticContinuous,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.3 * hapticIntensity),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
                ], relativeTime: 0, duration: 0.2))

            events.append(CHHapticEvent(eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0 * hapticIntensity),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.7)
                ], relativeTime: 0.2))

            events.append(CHHapticEvent(eventType: .hapticContinuous,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.6 * hapticIntensity),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.4)
                ], relativeTime: 0.25, duration: 0.35))

            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            notificationFeedback.notificationOccurred(.success)
        }
    }

    private func playPersonalRecordPattern() {
        guard supportsHaptics, let engine = engine else {
            notificationFeedback.notificationOccurred(.success)
            return
        }

        do {
            var events: [CHHapticEvent] = []

            events.append(CHHapticEvent(eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0 * hapticIntensity),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 1.0)
                ], relativeTime: 0))

            events.append(CHHapticEvent(eventType: .hapticContinuous,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8 * hapticIntensity),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.6)
                ], relativeTime: 0.05, duration: 0.3))

            for i in 0..<4 {
                let delay = 0.4 + Double(i) * 0.12
                let intensity = (0.9 - Float(i) * 0.1) * hapticIntensity

                events.append(CHHapticEvent(eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.8)
                    ], relativeTime: delay))
            }

            events.append(CHHapticEvent(eventType: .hapticContinuous,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.5 * hapticIntensity),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
                ], relativeTime: 0.9, duration: 0.2))

            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            notificationFeedback.notificationOccurred(.success)
        }
    }
    #endif

    func playCountdownSequence() async {
        guard isHapticEnabled else { return }

        play(.countdownTick)
        try? await Task.sleep(nanoseconds: 1_000_000_000)

        play(.countdownTick)
        try? await Task.sleep(nanoseconds: 1_000_000_000)

        play(.countdownTick)
        try? await Task.sleep(nanoseconds: 1_000_000_000)

        play(.countdownGo)
    }

    func cleanup() {
        #if canImport(UIKit)
        engine?.stop()
        engine = nil
        #endif
    }
}

// MARK: - Combined Sound + Haptic

@MainActor
final class FeedbackManager {
    static let shared = FeedbackManager()

    private let soundManager = SoundManager.shared
    private let hapticManager = HapticManager.shared

    private init() {}

    func play(sound: MDFitSound, haptic: MDFitHaptic) {
        soundManager.play(sound)
        hapticManager.play(haptic)
    }

    func workoutStart() { play(sound: .workoutStart, haptic: .workoutStart) }
    func workoutComplete() { play(sound: .workoutComplete, haptic: .workoutComplete) }
    func exerciseComplete() { play(sound: .exerciseComplete, haptic: .exerciseComplete) }
    func setComplete() { play(sound: .setComplete, haptic: .setComplete) }
    func restStart() { play(sound: .restStart, haptic: .restStart) }
    func restEnd() { play(sound: .restEnd, haptic: .restEnd) }
    func xpEarned() { play(sound: .xpEarned, haptic: .xpEarned) }
    func levelUp() { play(sound: .levelUp, haptic: .levelUp) }
    func achievementUnlocked() { play(sound: .achievementUnlocked, haptic: .achievementUnlocked) }
    func streakMilestone() { play(sound: .streakMilestone, haptic: .streakMilestone) }
    func personalRecord() { play(sound: .personalRecord, haptic: .personalRecord) }
    func streakWarning() { play(sound: .streakWarning, haptic: .streakWarning) }
    func buttonTap() { play(sound: .buttonTap, haptic: .buttonTap) }
    func success() { play(sound: .success, haptic: .success) }
    func error() { play(sound: .error, haptic: .failure) }

    func playCountdownSequence() async {
        guard soundManager.isSoundEnabled || hapticManager.isHapticEnabled else { return }

        soundManager.configureForWorkout()

        soundManager.play(.countdown3)
        hapticManager.play(.countdownTick)
        try? await Task.sleep(nanoseconds: 1_000_000_000)

        soundManager.play(.countdown2)
        hapticManager.play(.countdownTick)
        try? await Task.sleep(nanoseconds: 1_000_000_000)

        soundManager.play(.countdown1)
        hapticManager.play(.countdownTick)
        try? await Task.sleep(nanoseconds: 1_000_000_000)

        soundManager.play(.countdownGo)
        hapticManager.play(.countdownGo)
    }
}
