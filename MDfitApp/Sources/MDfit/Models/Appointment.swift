import Foundation

struct Appointment: Identifiable, Codable {
    let id: String
    let userId: String
    var date: Date
    var duration: Int // minutes
    var type: AppointmentType
    var status: AppointmentStatus
    var notes: String?
    var practitionerNotes: String?
    var createdAt: Date
    var updatedAt: Date

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    var formattedDuration: String {
        "\(duration) min"
    }
}

enum AppointmentType: String, Codable, CaseIterable {
    case initialConsult = "initial_consult"
    case followUp = "follow_up"
    case rehabilitation = "rehabilitation"
    case mobilityAssessment = "mobility_assessment"
    case activeRelease = "active_release"
    case sportsRecovery = "sports_recovery"

    var displayName: String {
        switch self {
        case .initialConsult: return "Initial Consultation"
        case .followUp: return "Follow-Up Session"
        case .rehabilitation: return "Physical Rehabilitation"
        case .mobilityAssessment: return "Mobility Assessment"
        case .activeRelease: return "Active Release Therapy"
        case .sportsRecovery: return "Sports Injury Recovery"
        }
    }

    var icon: String {
        switch self {
        case .initialConsult: return "person.badge.plus"
        case .followUp: return "arrow.clockwise"
        case .rehabilitation: return "figure.walk"
        case .mobilityAssessment: return "ruler"
        case .activeRelease: return "hand.raised"
        case .sportsRecovery: return "sportscourt"
        }
    }

    var defaultDuration: Int {
        switch self {
        case .initialConsult: return 60
        case .followUp: return 45
        case .rehabilitation: return 60
        case .mobilityAssessment: return 30
        case .activeRelease: return 45
        case .sportsRecovery: return 60
        }
    }
}

enum AppointmentStatus: String, Codable {
    case scheduled
    case confirmed
    case inProgress = "in_progress"
    case completed
    case cancelled
    case noShow = "no_show"

    var displayName: String {
        switch self {
        case .scheduled: return "Scheduled"
        case .confirmed: return "Confirmed"
        case .inProgress: return "In Progress"
        case .completed: return "Completed"
        case .cancelled: return "Cancelled"
        case .noShow: return "No Show"
        }
    }

    var color: String {
        switch self {
        case .scheduled: return "mdGray"
        case .confirmed: return "mdOrange"
        case .inProgress: return "mdOrange"
        case .completed: return "mdSuccess"
        case .cancelled: return "mdError"
        case .noShow: return "mdError"
        }
    }
}

// MARK: - Sample Data

extension Appointment {
    static let sample = Appointment(
        id: "apt_001",
        userId: "user_001",
        date: Calendar.current.date(byAdding: .day, value: 2, to: Date())!,
        duration: 60,
        type: .rehabilitation,
        status: .confirmed,
        notes: "Lower back pain, sitting too long at desk",
        practitionerNotes: nil,
        createdAt: Date(),
        updatedAt: Date()
    )

    static let samples: [Appointment] = [
        sample,
        Appointment(
            id: "apt_002",
            userId: "user_001",
            date: Calendar.current.date(byAdding: .day, value: 7, to: Date())!,
            duration: 45,
            type: .followUp,
            status: .scheduled,
            notes: nil,
            practitionerNotes: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
    ]
}
