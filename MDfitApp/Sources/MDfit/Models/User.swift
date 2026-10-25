import Foundation

// MARK: - User

struct User: Identifiable, Codable, Hashable {
    let id: String
    var email: String
    var firstName: String
    var lastName: String
    var phone: String?
    var avatarURL: URL?
    var dateOfBirth: Date?
    var subscription: Subscription?
    var entitlements: [Entitlement]
    var preferences: UserPreferences
    var isAdmin: Bool
    var createdAt: Date
    var updatedAt: Date

    var fullName: String {
        "\(firstName) \(lastName)"
    }

    var initials: String {
        let first = firstName.first.map(String.init) ?? ""
        let last = lastName.first.map(String.init) ?? ""
        return "\(first)\(last)"
    }

    var isPremium: Bool {
        subscription?.isActive == true || entitlements.contains { $0.type == .premium && $0.isValid }
    }

    var freeViewsRemaining: Int {
        guard !isPremium else { return .max }
        // TODO: Track daily views
        return 3
    }
}

// MARK: - Subscription

struct Subscription: Codable, Hashable {
    var id: String
    var tier: SubscriptionTier
    var status: SubscriptionStatus
    var pricePerMonth: Decimal
    var startDate: Date
    var currentPeriodEnd: Date
    var cancelAtPeriodEnd: Bool
    var paymentMethod: String?          // "Apple Pay", etc.

    var isActive: Bool {
        status == .active && currentPeriodEnd > Date()
    }

    var formattedPrice: String {
        "$\(pricePerMonth)/mo"
    }
}

enum SubscriptionTier: String, Codable, Hashable {
    case free
    case microMomentum = "micro_momentum"   // $9/mo × 3
    case premium                             // $20/mo
    case betaGrandfathered = "beta"         // $9.95/mo lifetime

    var displayName: String {
        switch self {
        case .free: return "Free"
        case .microMomentum: return "90-Day Micro Momentum"
        case .premium: return "Premium"
        case .betaGrandfathered: return "Beta Member"
        }
    }

    var price: Decimal {
        switch self {
        case .free: return 0
        case .microMomentum: return 9
        case .premium: return 20
        case .betaGrandfathered: return 9.95
        }
    }
}

enum SubscriptionStatus: String, Codable, Hashable {
    case active
    case pastDue = "past_due"
    case cancelled
    case expired
    case trialing
}

// MARK: - Entitlement

struct Entitlement: Identifiable, Codable, Hashable {
    let id: String
    var type: EntitlementType
    var resourceId: String?             // specific program ID, etc.
    var grantedAt: Date
    var expiresAt: Date?
    var source: EntitlementSource

    var isValid: Bool {
        guard let expiresAt = expiresAt else { return true }
        return expiresAt > Date()
    }
}

enum EntitlementType: String, Codable, Hashable {
    case premium                        // full access
    case program                        // specific program
    case videoReview                    // paid review submission
    case unlimitedViews = "unlimited_views"
}

enum EntitlementSource: String, Codable, Hashable {
    case subscription
    case purchase
    case promo
    case admin                          // manually granted
    case beta
}

// MARK: - User Preferences

struct UserPreferences: Codable, Hashable {
    var defaultLocation: WorkoutLocation = .home
    var defaultDifficulty: DifficultyLevel = .intermediate
    var availableEquipment: [Equipment] = []
    var excludedMovements: [String] = []
    var notificationsEnabled: Bool = true
    var workoutReminders: Bool = true
    var reminderTime: Date?             // preferred reminder time
    var calendarSync: Bool = true
}

// MARK: - Purchase

struct Purchase: Identifiable, Codable, Hashable {
    let id: String
    var userId: String
    var productType: PurchaseProductType
    var productId: String               // program ID, etc.
    var amount: Decimal
    var currency: String
    var status: PurchaseStatus
    var appleTransactionId: String?
    var createdAt: Date

    var formattedAmount: String {
        "$\(amount)"
    }
}

enum PurchaseProductType: String, Codable, Hashable {
    case subscription
    case program
    case videoReview = "video_review"
}

enum PurchaseStatus: String, Codable, Hashable {
    case pending
    case completed
    case failed
    case refunded
}

// MARK: - Video Review Submission

struct ReviewSubmission: Identifiable, Codable, Hashable {
    let id: String
    var userId: String
    var videoURL: URL
    var exerciseId: String?
    var notes: String?
    var status: ReviewStatus
    var feedback: String?               // Dr. Jared's response
    var feedbackVideoURL: URL?
    var submittedAt: Date
    var reviewedAt: Date?
}

enum ReviewStatus: String, Codable, Hashable {
    case pending
    case inReview = "in_review"
    case completed
    case needsResubmission = "needs_resubmission"
}

// MARK: - Sample Data

extension User {
    static let sample = User(
        id: "user_001",
        email: "john@example.com",
        firstName: "John",
        lastName: "Doe",
        phone: "941-555-0123",
        avatarURL: nil,
        dateOfBirth: Calendar.current.date(byAdding: .year, value: -35, to: Date()),
        subscription: Subscription(
            id: "sub_001",
            tier: .premium,
            status: .active,
            pricePerMonth: 20,
            startDate: Calendar.current.date(byAdding: .month, value: -2, to: Date())!,
            currentPeriodEnd: Calendar.current.date(byAdding: .month, value: 1, to: Date())!,
            cancelAtPeriodEnd: false,
            paymentMethod: "Apple Pay"
        ),
        entitlements: [],
        preferences: UserPreferences(),
        isAdmin: false,
        createdAt: Date(),
        updatedAt: Date()
    )

    static let guest = User(
        id: "guest",
        email: "",
        firstName: "Guest",
        lastName: "",
        phone: nil,
        avatarURL: nil,
        dateOfBirth: nil,
        subscription: nil,
        entitlements: [],
        preferences: UserPreferences(),
        isAdmin: false,
        createdAt: Date(),
        updatedAt: Date()
    )
}
