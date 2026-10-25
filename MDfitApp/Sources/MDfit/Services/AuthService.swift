import Foundation
import SwiftUI

@MainActor
class AuthService: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var error: AuthError?

    private let userDefaultsKey = "mdfit_current_user"

    init() {
        loadSavedUser()
    }

    // MARK: - Authentication

    func signIn(email: String, password: String) async throws {
        isLoading = true
        error = nil

        defer { isLoading = false }

        // TODO: Replace with actual API call
        try await Task.sleep(nanoseconds: 1_000_000_000) // Simulate network delay

        // Mock authentication
        if email.lowercased() == "demo@mdfit.com" && password == "demo123" {
            let user = User(
                id: "user_demo",
                firstName: "Demo",
                lastName: "User",
                email: email,
                phone: nil,
                dateOfBirth: nil,
                healthDataConsent: false,
                createdAt: Date(),
                updatedAt: Date()
            )
            self.currentUser = user
            self.isAuthenticated = true
            saveUser(user)
        } else {
            throw AuthError.invalidCredentials
        }
    }

    func signUp(firstName: String, lastName: String, email: String, password: String) async throws {
        isLoading = true
        error = nil

        defer { isLoading = false }

        // TODO: Replace with actual API call
        try await Task.sleep(nanoseconds: 1_500_000_000)

        let user = User(
            id: UUID().uuidString,
            firstName: firstName,
            lastName: lastName,
            email: email,
            phone: nil,
            dateOfBirth: nil,
            healthDataConsent: false,
            createdAt: Date(),
            updatedAt: Date()
        )

        self.currentUser = user
        self.isAuthenticated = true
        saveUser(user)
    }

    func signOut() {
        currentUser = nil
        isAuthenticated = false
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
    }

    func continueAsGuest() {
        // Allow limited app access without account
        isAuthenticated = true
        currentUser = nil
    }

    // MARK: - Persistence

    private func saveUser(_ user: User) {
        if let data = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        }
    }

    private func loadSavedUser() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let user = try? JSONDecoder().decode(User.self, from: data) else {
            return
        }
        self.currentUser = user
        self.isAuthenticated = true
    }
}

// MARK: - Errors

enum AuthError: LocalizedError {
    case invalidCredentials
    case emailAlreadyInUse
    case weakPassword
    case networkError
    case unknown

    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Invalid email or password"
        case .emailAlreadyInUse:
            return "An account with this email already exists"
        case .weakPassword:
            return "Password must be at least 8 characters"
        case .networkError:
            return "Unable to connect. Please check your internet connection."
        case .unknown:
            return "Something went wrong. Please try again."
        }
    }
}
