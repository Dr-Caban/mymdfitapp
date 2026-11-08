import Foundation

// MARK: - Membership System

/// Three tiers: Accountability ($19.95), Premium ($200), Premium Plus ($349)
/// Access levels: 0 (free), 1 (member), 2 (premium with 1-on-1s)

// MARK: - Membership Tier

enum MembershipTier: String, CaseIterable, Codable {
    case member           // $19.95/mo, 0 meetings
    case premium          // $200/mo, 2 × 30 min
    case premiumPlus = "premium-plus"  // $349/mo, 4 × 30 min

    var displayName: String {
        switch self {
        case .member: return "Accountability Membership"
        case .premium: return "Premium 1-on-1"
        case .premiumPlus: return "Premium Plus"
        }
    }

    var price: Decimal {
        switch self {
        case .member: return 19.95
        case .premium: return 200
        case .premiumPlus: return 349
        }
    }

    var meetingsIncluded: Int {
        switch self {
        case .member: return 0
        case .premium: return 2
        case .premiumPlus: return 4
        }
    }

    var meetingDuration: Int {  // minutes
        30
    }

    var accessLevel: AccessLevel {
        switch self {
        case .member: return .member
        case .premium, .premiumPlus: return .premium
        }
    }

    var features: [String] {
        switch self {
        case .member:
            return [
                "Unlimited video library access",
                "All 23 programs",
                "Workout generator",
                "Pain tool with tracks",
                "Progress tracking",
                "Leaderboard & challenges",
                "Message Dr. Jared"
            ]
        case .premium:
            return [
                "Everything in Accountability",
                "2 × 30-min 1-on-1 sessions",
                "Priority messaging",
                "Personalized program"
            ]
        case .premiumPlus:
            return [
                "Everything in Premium",
                "4 × 30-min 1-on-1 sessions",
                "Direct scheduling access",
                "Extended session options"
            ]
        }
    }
}

// MARK: - Access Level

enum AccessLevel: Int, Codable {
    case free = 0      // Limited daily views, pain tool free
    case member = 1    // Any tier active
    case premium = 2   // Tier with meetings > 0
}

// MARK: - Membership

struct Membership: Codable {
    let tier: MembershipTier
    let since: Date
    let until: Date
    let stripeSubscriptionId: String?
    let status: MembershipStatus
    let cancelAtPeriodEnd: Bool
    let via: String?  // "stripe", "referral-reward", "admin"

    var isActive: Bool {
        status == .active && until > Date()
    }
}

enum MembershipStatus: String, Codable {
    case active
    case pastDue = "past_due"
    case cancelled
    case trialing
}

// MARK: - Protocol Packages

/// Gold: -20% paid in full
/// Silver: 3 monthly payments
/// Platinum: 12/24 payments (+5/10%)
/// Bronze: pay as you go

enum ProtocolPlan: String, CaseIterable, Codable {
    case gold
    case silver
    case ext12
    case ext24
    case payg

    var displayName: String {
        switch self {
        case .gold: return "Gold, paid in full (20% off)"
        case .silver: return "Silver, 3 monthly payments"
        case .ext12: return "Platinum, 12 monthly payments (+5%)"
        case .ext24: return "Platinum, 24 monthly payments (+10%)"
        case .payg: return "Bronze, pay as you go"
        }
    }

    var paymentCount: Int {
        switch self {
        case .gold, .payg: return 1
        case .silver: return 3
        case .ext12: return 12
        case .ext24: return 24
        }
    }

    var discountPercent: Double {
        switch self {
        case .gold: return -0.20  // 20% off
        case .silver: return 0
        case .ext12: return 0.05  // 5% more
        case .ext24: return 0.10  // 10% more
        case .payg: return 0
        }
    }

    func calculateTotal(base: Decimal) -> Decimal {
        let multiplier = 1.0 + Decimal(discountPercent)
        return base * multiplier
    }
}

struct Protocol: Identifiable, Codable {
    let id: String
    let serviceId: String
    let serviceName: String
    let sessions: Int
    let plan: ProtocolPlan
    let total: Decimal
    let paid: Int
    let remaining: Int
    let status: ProtocolStatus
    let paidAt: Date?
    let subscriptionId: String?
}

enum ProtocolStatus: String, Codable {
    case pending
    case active
    case paid
    case ended
    case failed
}

// MARK: - Accountability Credit

/// For $19.95 membership: $1 off per active day (workout or pain log)
/// 20 active days = free month

struct AccountabilityCredit: Codable {
    let activeDays: Int
    let threshold: Int  // 20
    let price: Decimal  // 19.95
    let credit: Decimal
    let owed: Decimal
    let free: Bool
    let month: String

    var formattedCredit: String {
        "$\(credit)"
    }

    var formattedOwed: String {
        "$\(owed)"
    }
}

// MARK: - Referral System

/// Referrer gets +30 days per referee (up to FREE_MONTHS = 3)
/// Referee currently gets nothing (drift in system)

struct ReferralInfo: Codable {
    let code: String
    let referrals: Int
    let freeMonths: Int  // Reported as 3 but not applied
    let creditedDays: Int

    var shareMessage: String {
        "Join me on MD Fit! Use my code \(code) to get started."
    }
}

// MARK: - Review Reward

/// Any on-site review mints MDFIT-XXXXXX
/// 30% off first month
/// Single use

struct ReviewReward: Codable {
    let code: String
    let discountPercent: Int  // 30
    let used: Bool
    let usedAt: Date?
}

// MARK: - Payments Response

struct PaymentsResponse: Codable {
    let enabled: Bool
    let protocols: [Protocol]
    let membership: Membership?
    let hasBilling: Bool
}

// MARK: - Service (for protocol purchases)

struct Service: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let rate: Decimal
    let evalRate: Decimal?
    let duration: Int  // minutes
    let requiresEval: Bool
}

// MARK: - Package Sizes

struct PackageOptions {
    static let sizes = [6, 12, 24]
    static let guaranteeMin = 12
}
