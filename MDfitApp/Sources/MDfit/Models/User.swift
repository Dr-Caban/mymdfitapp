import Foundation

struct User: Identifiable, Codable {
    let id: String
    var firstName: String
    var lastName: String
    var email: String
    var phone: String?
    var dateOfBirth: Date?
    var healthDataConsent: Bool
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
}

// MARK: - Sample Data

extension User {
    static let sample = User(
        id: "user_001",
        firstName: "John",
        lastName: "Doe",
        email: "john@example.com",
        phone: "941-555-0123",
        dateOfBirth: Calendar.current.date(byAdding: .year, value: -35, to: Date()),
        healthDataConsent: true,
        createdAt: Date(),
        updatedAt: Date()
    )
}
