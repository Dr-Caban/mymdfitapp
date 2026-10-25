import Foundation

// MARK: - Event (Admin-created, shows on user calendars)

struct Event: Identifiable, Codable, Hashable {
    let id: String
    var title: String
    var description: String?
    var type: EventType
    var startDate: Date
    var endDate: Date
    var location: EventLocation
    var capacity: Int?
    var enrolledCount: Int
    var price: Decimal?                 // nil = free or included
    var isRecurring: Bool
    var recurrenceRule: RecurrenceRule?
    var requiresRegistration: Bool
    var registrationDeadline: Date?
    var imageURL: URL?
    var createdBy: String               // admin user ID
    var createdAt: Date
    var updatedAt: Date

    var isFull: Bool {
        guard let capacity = capacity else { return false }
        return enrolledCount >= capacity
    }

    var spotsRemaining: Int? {
        guard let capacity = capacity else { return nil }
        return max(0, capacity - enrolledCount)
    }

    var formattedDateTime: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: startDate)
    }

    var formattedTimeRange: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        let start = formatter.string(from: startDate)
        let end = formatter.string(from: endDate)
        return "\(start) - \(end)"
    }

    var durationMinutes: Int {
        Int(endDate.timeIntervalSince(startDate) / 60)
    }
}

// MARK: - Event Type

enum EventType: String, Codable, CaseIterable, Hashable {
    case groupClass = "group_class"
    case workshop
    case seminar
    case mobilitySession = "mobility_session"
    case oneOnOne = "one_on_one"
    case openGym = "open_gym"
    case special

    var displayName: String {
        switch self {
        case .groupClass: return "Group Class"
        case .workshop: return "Workshop"
        case .seminar: return "Seminar"
        case .mobilitySession: return "Mobility Session"
        case .oneOnOne: return "1-on-1 Session"
        case .openGym: return "Open Gym"
        case .special: return "Special Event"
        }
    }

    var icon: String {
        switch self {
        case .groupClass: return "person.3.fill"
        case .workshop: return "wrench.and.screwdriver.fill"
        case .seminar: return "person.wave.2.fill"
        case .mobilitySession: return "figure.flexibility"
        case .oneOnOne: return "person.fill"
        case .openGym: return "dumbbell.fill"
        case .special: return "star.fill"
        }
    }
}

// MARK: - Event Location

struct EventLocation: Codable, Hashable {
    var type: LocationType
    var name: String?                   // "MD Fit Studio"
    var address: String?                // "3214 Clark Road, Sarasota, FL"
    var virtualLink: URL?               // Zoom/Meet link
    var notes: String?

    enum LocationType: String, Codable, Hashable {
        case inPerson = "in_person"
        case virtual
        case hybrid
    }

    static let clinic = EventLocation(
        type: .inPerson,
        name: "MD Fit",
        address: "3214 Clark Road, Sarasota, FL 34231",
        virtualLink: nil,
        notes: nil
    )
}

// MARK: - Recurrence Rule

struct RecurrenceRule: Codable, Hashable {
    var frequency: RecurrenceFrequency
    var interval: Int                   // every X weeks/days
    var daysOfWeek: [DayOfWeek]?       // for weekly
    var endDate: Date?
    var occurrences: Int?               // or end after X times
}

enum RecurrenceFrequency: String, Codable, Hashable {
    case daily
    case weekly
    case biweekly
    case monthly
}

// MARK: - Event Registration

struct EventRegistration: Identifiable, Codable, Hashable {
    let id: String
    var userId: String
    var eventId: String
    var status: RegistrationStatus
    var registeredAt: Date
    var checkedInAt: Date?
    var cancelledAt: Date?
    var waitlistPosition: Int?
}

enum RegistrationStatus: String, Codable, Hashable {
    case registered
    case waitlisted
    case checkedIn = "checked_in"
    case noShow = "no_show"
    case cancelled
}

// MARK: - Sample Data

extension Event {
    static let sample = Event(
        id: "evt_001",
        title: "Morning Mobility Class",
        description: "Start your day with guided mobility work. All levels welcome.",
        type: .groupClass,
        startDate: Calendar.current.date(byAdding: .day, value: 1, to: Date())!,
        endDate: Calendar.current.date(byAdding: .hour, value: 1, to: Calendar.current.date(byAdding: .day, value: 1, to: Date())!)!,
        location: .clinic,
        capacity: 12,
        enrolledCount: 8,
        price: nil,
        isRecurring: true,
        recurrenceRule: RecurrenceRule(
            frequency: .weekly,
            interval: 1,
            daysOfWeek: [.monday, .wednesday, .friday],
            endDate: nil,
            occurrences: nil
        ),
        requiresRegistration: true,
        registrationDeadline: nil,
        imageURL: nil,
        createdBy: "admin_001",
        createdAt: Date(),
        updatedAt: Date()
    )
}
