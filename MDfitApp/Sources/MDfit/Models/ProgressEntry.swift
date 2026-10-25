import Foundation

struct ProgressEntry: Identifiable, Codable {
    let id: String
    let userId: String
    var date: Date
    var painLevel: Int // 0-10 scale
    var painLocation: TargetArea?
    var mobilityScore: Int? // 0-100
    var notes: String?
    var mood: Mood?
    var sleepQuality: Int? // 1-5
    var exercisesCompleted: Int
    var appointmentId: String? // linked to session
    var createdAt: Date

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    var painLevelDescription: String {
        switch painLevel {
        case 0: return "No pain"
        case 1...3: return "Mild"
        case 4...6: return "Moderate"
        case 7...9: return "Severe"
        case 10: return "Worst possible"
        default: return "Unknown"
        }
    }
}

enum Mood: String, Codable, CaseIterable {
    case great
    case good
    case okay
    case poor
    case bad

    var emoji: String {
        switch self {
        case .great: return "😄"
        case .good: return "🙂"
        case .okay: return "😐"
        case .poor: return "😕"
        case .bad: return "😣"
        }
    }

    var displayName: String {
        rawValue.capitalized
    }
}

// MARK: - Sample Data

extension ProgressEntry {
    static let sample = ProgressEntry(
        id: "prog_001",
        userId: "user_001",
        date: Date(),
        painLevel: 4,
        painLocation: .lowerBack,
        mobilityScore: 72,
        notes: "Feeling better after yesterday's session",
        mood: .good,
        sleepQuality: 4,
        exercisesCompleted: 3,
        appointmentId: nil,
        createdAt: Date()
    )

    static let samples: [ProgressEntry] = [
        sample,
        ProgressEntry(
            id: "prog_002",
            userId: "user_001",
            date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!,
            painLevel: 6,
            painLocation: .lowerBack,
            mobilityScore: 65,
            notes: "Stiff from sitting all day",
            mood: .okay,
            sleepQuality: 3,
            exercisesCompleted: 2,
            appointmentId: nil,
            createdAt: Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        ),
        ProgressEntry(
            id: "prog_003",
            userId: "user_001",
            date: Calendar.current.date(byAdding: .day, value: -3, to: Date())!,
            painLevel: 7,
            painLocation: .lowerBack,
            mobilityScore: 58,
            notes: nil,
            mood: .poor,
            sleepQuality: 2,
            exercisesCompleted: 0,
            appointmentId: nil,
            createdAt: Calendar.current.date(byAdding: .day, value: -3, to: Date())!
        )
    ]
}
