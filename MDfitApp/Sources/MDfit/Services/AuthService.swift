import Foundation
import SwiftUI
import Security

// MARK: - Auth Request/Response Models

struct AuthLoginRequest: Encodable {   // AuthService-local shape; APIModels.LoginRequest is the backend contract
    let email: String
    let password: String
}

struct AuthRegisterRequest: Encodable {
    let firstName: String
    let lastName: String
    let email: String
    let password: String
}

struct AuthResponse: Decodable {
    let user: User
    let accessToken: String
    let refreshToken: String?
    let expiresIn: TimeInterval
}

struct ForgotPasswordRequest: Encodable {
    let email: String
}

struct ResetPasswordRequest: Encodable {
    let token: String
    let newPassword: String
}

// MARK: - Auth Service

@MainActor
class AuthService: ObservableObject, APIClientAuthDelegate {
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var error: AuthError?

    private let keychainService = "com.mdfit.auth"
    private let userDataKey = "current_user"

    static let shared = AuthService()

    init() {
        loadSavedUser()
        setupAuthDelegate()
    }

    private func setupAuthDelegate() {
        Task {
            await APIClient.shared.setAuthDelegate(self)
        }
    }

    // MARK: - APIClientAuthDelegate

    nonisolated func apiClientDidReceiveUnauthorized(_ client: APIClient) {
        Task { @MainActor in
            self.handleUnauthorized()
        }
    }

    nonisolated func apiClientDidRefreshToken(_ client: APIClient) {
        // Token refreshed successfully, no action needed
    }

    private func handleUnauthorized() {
        currentUser = nil
        isAuthenticated = false
        deleteUserFromKeychain()
        error = .sessionExpired
    }

    // MARK: - Authentication

    func signIn(email: String, password: String) async throws {
        isLoading = true
        error = nil

        defer { isLoading = false }

        // Validate input
        guard isValidEmail(email) else {
            throw AuthError.invalidEmail
        }

        guard !password.isEmpty else {
            throw AuthError.invalidCredentials
        }

        do {
            let request = AuthLoginRequest(email: email.lowercased().trimmingCharacters(in: .whitespaces), password: password)

            let response: AuthResponse = try await APIClient.shared.post(.login, body: request)

            // Store tokens securely
            await APIClient.shared.setAuthTokens(
                access: response.accessToken,
                refresh: response.refreshToken,
                expiresIn: response.expiresIn
            )

            // Update state
            self.currentUser = response.user
            self.isAuthenticated = true

            // Save user to Keychain
            saveUserToKeychain(response.user)

        } catch let apiError as APIError {
            throw mapAPIError(apiError)
        } catch {
            throw AuthError.networkError
        }
    }

    func signUp(firstName: String, lastName: String, email: String, password: String) async throws {
        isLoading = true
        error = nil

        defer { isLoading = false }

        // Validate input
        guard !firstName.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw AuthError.invalidName
        }

        guard !lastName.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw AuthError.invalidName
        }

        guard isValidEmail(email) else {
            throw AuthError.invalidEmail
        }

        guard isValidPassword(password) else {
            throw AuthError.weakPassword
        }

        do {
            let request = AuthRegisterRequest(
                firstName: firstName.trimmingCharacters(in: .whitespaces),
                lastName: lastName.trimmingCharacters(in: .whitespaces),
                email: email.lowercased().trimmingCharacters(in: .whitespaces),
                password: password
            )

            let response: AuthResponse = try await APIClient.shared.post(.register, body: request)

            // Store tokens securely
            await APIClient.shared.setAuthTokens(
                access: response.accessToken,
                refresh: response.refreshToken,
                expiresIn: response.expiresIn
            )

            // Update state
            self.currentUser = response.user
            self.isAuthenticated = true

            // Save user to Keychain
            saveUserToKeychain(response.user)

        } catch let apiError as APIError {
            throw mapAPIError(apiError)
        } catch {
            throw AuthError.networkError
        }
    }

    func signOut() async {
        isLoading = true

        do {
            // Call logout endpoint to invalidate server-side session
            try await APIClient.shared.execute(
                APIRequest<EmptyResponse>(endpoint: .logout, method: .post)
            )
        } catch {
            // Continue with local logout even if server call fails
            print("[AuthService] Logout API call failed: \(error)")
        }

        // Clear tokens
        await APIClient.shared.clearAuthTokens()

        // Clear local state
        currentUser = nil
        isAuthenticated = false
        deleteUserFromKeychain()

        isLoading = false
    }

    func continueAsGuest() {
        // Allow limited app access without account
        isAuthenticated = true
        currentUser = nil
    }

    // MARK: - Password Reset

    func forgotPassword(email: String) async throws {
        isLoading = true
        error = nil

        defer { isLoading = false }

        guard isValidEmail(email) else {
            throw AuthError.invalidEmail
        }

        do {
            let request = ForgotPasswordRequest(email: email.lowercased().trimmingCharacters(in: .whitespaces))
            try await APIClient.shared.execute(
                APIRequest<EmptyResponse>(endpoint: .forgotPassword(email: email), method: .post, body: request)
            )
        } catch let apiError as APIError {
            throw mapAPIError(apiError)
        } catch {
            throw AuthError.networkError
        }
    }

    func resetPassword(token: String, newPassword: String) async throws {
        isLoading = true
        error = nil

        defer { isLoading = false }

        guard isValidPassword(newPassword) else {
            throw AuthError.weakPassword
        }

        do {
            let request = ResetPasswordRequest(token: token, newPassword: newPassword)
            try await APIClient.shared.execute(
                APIRequest<EmptyResponse>(endpoint: .resetPassword, method: .post, body: request)
            )
        } catch let apiError as APIError {
            throw mapAPIError(apiError)
        } catch {
            throw AuthError.networkError
        }
    }

    // MARK: - User Profile

    func refreshCurrentUser() async throws {
        guard isAuthenticated else { return }

        do {
            let user: User = try await APIClient.shared.get(.currentUser)
            self.currentUser = user
            saveUserToKeychain(user)
        } catch let apiError as APIError {
            if case .unauthorized = apiError {
                handleUnauthorized()
            }
            throw mapAPIError(apiError)
        }
    }

    func updateProfile(firstName: String?, lastName: String?, phone: String?) async throws {
        isLoading = true

        defer { isLoading = false }

        struct UpdateProfileRequest: Encodable {
            let firstName: String?
            let lastName: String?
            let phone: String?
        }

        do {
            let request = UpdateProfileRequest(firstName: firstName, lastName: lastName, phone: phone)
            let user: User = try await APIClient.shared.put(.updateProfile, body: request)
            self.currentUser = user
            saveUserToKeychain(user)
        } catch let apiError as APIError {
            throw mapAPIError(apiError)
        }
    }

    func deleteAccount() async throws {
        isLoading = true

        defer { isLoading = false }

        do {
            try await APIClient.shared.delete(.deleteAccount)
            await signOut()
        } catch let apiError as APIError {
            throw mapAPIError(apiError)
        }
    }

    // MARK: - Session Validation

    func validateSession() async -> Bool {
        let hasValidToken = await APIClient.shared.isAuthenticated()

        if hasValidToken && currentUser != nil {
            return true
        }

        if hasValidToken {
            // Has token but no user - try to fetch user
            do {
                try await refreshCurrentUser()
                return true
            } catch {
                return false
            }
        }

        return false
    }

    // MARK: - Keychain Storage

    private func saveUserToKeychain(_ user: User) {
        guard let data = try? JSONEncoder().encode(user) else { return }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: userDataKey,
            kSecValueData as String: data
        ]

        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    private func loadSavedUser() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: userDataKey,
            kSecReturnData as String: true
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let user = try? JSONDecoder().decode(User.self, from: data) else {
            return
        }

        self.currentUser = user

        // Validate session in background
        Task {
            if await validateSession() {
                self.isAuthenticated = true
            } else {
                self.currentUser = nil
                deleteUserFromKeychain()
            }
        }
    }

    private func deleteUserFromKeychain() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: userDataKey
        ]
        SecItemDelete(query as CFDictionary)
    }

    // MARK: - Validation Helpers

    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }

    private func isValidPassword(_ password: String) -> Bool {
        // Minimum 8 characters
        return password.count >= 8
    }

    // MARK: - Error Mapping

    private func mapAPIError(_ error: APIError) -> AuthError {
        switch error {
        case .unauthorized:
            return .invalidCredentials
        case .conflict:
            return .emailAlreadyInUse
        case .badRequest(let message):
            if message?.lowercased().contains("password") == true {
                return .weakPassword
            }
            if message?.lowercased().contains("email") == true {
                return .invalidEmail
            }
            return .invalidCredentials
        case .noConnection:
            return .networkError
        case .timeout:
            return .networkError
        case .tokenExpired, .tokenRefreshFailed:
            return .sessionExpired
        default:
            return .unknown
        }
    }
}

// MARK: - Errors

enum AuthError: LocalizedError {
    case invalidCredentials
    case invalidEmail
    case invalidName
    case emailAlreadyInUse
    case weakPassword
    case networkError
    case sessionExpired
    case unknown

    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Invalid email or password"
        case .invalidEmail:
            return "Please enter a valid email address"
        case .invalidName:
            return "Please enter your name"
        case .emailAlreadyInUse:
            return "An account with this email already exists"
        case .weakPassword:
            return "Password must be at least 8 characters"
        case .networkError:
            return "Unable to connect. Please check your internet connection."
        case .sessionExpired:
            return "Your session has expired. Please sign in again."
        case .unknown:
            return "Something went wrong. Please try again."
        }
    }
}
