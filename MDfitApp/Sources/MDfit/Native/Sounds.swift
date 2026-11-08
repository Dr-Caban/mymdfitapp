import AVFoundation

/// Short reward chimes (new gem, badge unlocked, daily goal). They respect the ring/silent switch and mix with
/// whatever music the member has playing, like a game's sound effects.
@MainActor
enum Sounds {
    private static var players: [String: AVAudioPlayer] = [:]
    private static var sessionReady = false

    /// `name` is one of the files in Resources/Sounds: gem, badge, goal, xp, notify.
    static func play(_ name: String) {
        guard ["gem", "badge", "goal", "xp", "notify"].contains(name) else { return }
        if !sessionReady {
            try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try? AVAudioSession.sharedInstance().setActive(true)
            sessionReady = true
        }
        if players[name] == nil,
           let url = Bundle.main.url(forResource: name, withExtension: "wav", subdirectory: "Sounds")
            ?? Bundle.main.url(forResource: name, withExtension: "wav"),
           let player = try? AVAudioPlayer(contentsOf: url) {
            player.prepareToPlay()
            players[name] = player
        }
        guard let player = players[name] else { return }
        player.currentTime = 0
        player.volume = 0.9
        player.play()
    }
}
