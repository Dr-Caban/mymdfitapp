//
//  APIClient.swift
//  MDfit
//
//  Production-ready HTTP client with authentication, retry logic,
//  and comprehensive error handling for the MD Fit platform.
//

import Foundation
import os.log

// MARK: - Configuration

/// API environment configuration for staging and production
enum APIEnvironment: String, CaseIterable {
    case development
    case staging
    case production

    var baseURL: URL {
        switch self {
        case .development:
            return URL(string: "http://localhost:8080/api/v1")!
        case .staging:
            return URL(string: "https://staging-api.mdfitsrq.com/api/v1")!
        case .production:
            return URL(string: "https://api.mdfitsrq.com/api/v1")!
        }
    }

    var isDebugLoggingEnabled: Bool {
        switch self {
        case .development, .staging:
            return true
        case .production:
            return false
        }
    }
}

/// Configuration for the API client
struct APIConfiguration {
    let environment: APIEnvironment
    let timeoutInterval: TimeInterval
    let maxRetryAttempts: Int
    let enableMockMode: Bool
    let additionalHeaders: [String: String]

    static let `default` = APIConfiguration(
        environment: .development,
        timeoutInterval: 30,
        maxRetryAttempts: 3,
        enableMockMode: false,
        additionalHeaders: [:]
    )

    static let mock = APIConfiguration(
        environment: .development,
        timeoutInterval: 30,
        maxRetryAttempts: 0,
        enableMockMode: true,
        additionalHeaders: [:]
    )

    init(
        environment: APIEnvironment,
        timeoutInterval: TimeInterval = 30,
        maxRetryAttempts: Int = 3,
        enableMockMode: Bool = false,
        additionalHeaders: [String: String] = [:]
    ) {
        self.environment = environment
        self.timeoutInterval = timeoutInterval
        self.maxRetryAttempts = maxRetryAttempts
        self.enableMockMode = enableMockMode
        self.additionalHeaders = additionalHeaders
    }
}

// MARK: - API Errors

/// Comprehensive error types for API operations
enum APIError: LocalizedError, Equatable {
    // Network errors
    case noConnection
    case timeout
    case cancelled

    // HTTP errors
    case badRequest(message: String?)
    case unauthorized
    case forbidden
    case notFound
    case conflict(message: String?)
    case tooManyRequests(retryAfter: TimeInterval?)
    case serverError(statusCode: Int, message: String?)

    // Data errors
    case invalidURL
    case invalidRequest
    case invalidResponse
    case decodingError(underlying: String)
    case encodingError(underlying: String)

    // Auth errors
    case tokenExpired
    case tokenRefreshFailed

    // Generic
    case unknown(underlying: String)

    var errorDescription: String? {
        switch self {
        case .noConnection:
            return "No internet connection. Please check your network settings."
        case .timeout:
            return "The request timed out. Please try again."
        case .cancelled:
            return "The request was cancelled."
        case .badRequest(let message):
            return message ?? "Invalid request. Please try again."
        case .unauthorized:
            return "Your session has expired. Please sign in again."
        case .forbidden:
            return "You don't have permission to access this resource."
        case .notFound:
            return "The requested resource was not found."
        case .conflict(let message):
            return message ?? "A conflict occurred. Please try again."
        case .tooManyRequests(let retryAfter):
            if let seconds = retryAfter {
                return "Too many requests. Please wait \(Int(seconds)) seconds."
            }
            return "Too many requests. Please try again later."
        case .serverError(let statusCode, let message):
            return message ?? "Server error (\(statusCode)). Please try again later."
        case .invalidURL:
            return "Invalid URL configuration."
        case .invalidRequest:
            return "Failed to create request."
        case .invalidResponse:
            return "Invalid response from server."
        case .decodingError(let underlying):
            return "Failed to process response: \(underlying)"
        case .encodingError(let underlying):
            return "Failed to encode request: \(underlying)"
        case .tokenExpired:
            return "Your session has expired. Please sign in again."
        case .tokenRefreshFailed:
            return "Failed to refresh session. Please sign in again."
        case .unknown(let underlying):
            return "An unexpected error occurred: \(underlying)"
        }
    }

    var isRetryable: Bool {
        switch self {
        case .timeout, .serverError, .noConnection:
            return true
        case .tooManyRequests:
            return true
        default:
            return false
        }
    }

    static func == (lhs: APIError, rhs: APIError) -> Bool {
        switch (lhs, rhs) {
        case (.noConnection, .noConnection),
             (.timeout, .timeout),
             (.cancelled, .cancelled),
             (.unauthorized, .unauthorized),
             (.forbidden, .forbidden),
             (.notFound, .notFound),
             (.invalidURL, .invalidURL),
             (.invalidRequest, .invalidRequest),
             (.invalidResponse, .invalidResponse),
             (.tokenExpired, .tokenExpired),
             (.tokenRefreshFailed, .tokenRefreshFailed):
            return true
        case (.badRequest(let lm), .badRequest(let rm)):
            return lm == rm
        case (.conflict(let lm), .conflict(let rm)):
            return lm == rm
        case (.tooManyRequests(let lr), .tooManyRequests(let rr)):
            return lr == rr
        case (.serverError(let lc, let lm), .serverError(let rc, let rm)):
            return lc == rc && lm == rm
        case (.decodingError(let lu), .decodingError(let ru)):
            return lu == ru
        case (.encodingError(let lu), .encodingError(let ru)):
            return lu == ru
        case (.unknown(let lu), .unknown(let ru)):
            return lu == ru
        default:
            return false
        }
    }
}

// MARK: - HTTP Methods

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

// MARK: - API Endpoints

/// Type-safe API endpoints for MD Fit platform
enum APIEndpoint {
    // Auth
    case login
    case register
    case refreshToken
    case logout
    case forgotPassword(email: String)
    case resetPassword

    // User
    case currentUser
    case updateProfile
    case updatePreferences
    case deleteAccount

    // Videos
    case videos
    case video(id: String)
    case videosByRegion(region: String)
    case videosByTag(tag: String)
    case searchVideos(query: String)

    // Pain Tool
    case bodyRegions
    case painPatterns(regionId: String)
    case exercisesForPain(patternId: String)

    // Programs
    case programs
    case program(id: String)
    case programEnrollment(programId: String)
    case programProgress(programId: String)

    // Workouts
    case generateWorkout
    case workouts
    case workout(id: String)
    case saveWorkout
    case workoutCompletion(workoutId: String)

    // Calendar & Events
    case events
    case event(id: String)
    case eventRegistration(eventId: String)
    case userCalendar(startDate: Date, endDate: Date)

    // Subscriptions
    case subscriptions
    case currentSubscription
    case cancelSubscription
    case purchaseHistory

    // Video Review (future)
    case submitReview
    case reviewStatus(submissionId: String)

    // Custom endpoint for flexibility
    case custom(path: String)

    var path: String {
        switch self {
        // Auth
        case .login:
            return "/auth/login"
        case .register:
            return "/auth/register"
        case .refreshToken:
            return "/auth/refresh"
        case .logout:
            return "/auth/logout"
        case .forgotPassword:
            return "/auth/forgot-password"
        case .resetPassword:
            return "/auth/reset-password"

        // User
        case .currentUser:
            return "/users/me"
        case .updateProfile:
            return "/users/me/profile"
        case .updatePreferences:
            return "/users/me/preferences"
        case .deleteAccount:
            return "/users/me"

        // Videos
        case .videos:
            return "/videos"
        case .video(let id):
            return "/videos/\(id)"
        case .videosByRegion(let region):
            return "/videos/region/\(region)"
        case .videosByTag(let tag):
            return "/videos/tag/\(tag)"
        case .searchVideos:
            return "/videos/search"

        // Pain Tool
        case .bodyRegions:
            return "/pain-tool/regions"
        case .painPatterns(let regionId):
            return "/pain-tool/regions/\(regionId)/patterns"
        case .exercisesForPain(let patternId):
            return "/pain-tool/patterns/\(patternId)/exercises"

        // Programs
        case .programs:
            return "/programs"
        case .program(let id):
            return "/programs/\(id)"
        case .programEnrollment(let programId):
            return "/programs/\(programId)/enroll"
        case .programProgress(let programId):
            return "/programs/\(programId)/progress"

        // Workouts
        case .generateWorkout:
            return "/workouts/generate"
        case .workouts:
            return "/workouts"
        case .workout(let id):
            return "/workouts/\(id)"
        case .saveWorkout:
            return "/workouts"
        case .workoutCompletion(let workoutId):
            return "/workouts/\(workoutId)/complete"

        // Calendar & Events
        case .events:
            return "/events"
        case .event(let id):
            return "/events/\(id)"
        case .eventRegistration(let eventId):
            return "/events/\(eventId)/register"
        case .userCalendar:
            return "/calendar"

        // Subscriptions
        case .subscriptions:
            return "/subscriptions"
        case .currentSubscription:
            return "/subscriptions/current"
        case .cancelSubscription:
            return "/subscriptions/cancel"
        case .purchaseHistory:
            return "/purchases"

        // Video Review
        case .submitReview:
            return "/reviews/submit"
        case .reviewStatus(let submissionId):
            return "/reviews/\(submissionId)"

        // Custom
        case .custom(let path):
            return path
        }
    }

    var method: HTTPMethod {
        switch self {
        case .login, .register, .refreshToken, .logout, .forgotPassword, .resetPassword,
             .generateWorkout, .saveWorkout, .workoutCompletion,
             .programEnrollment, .eventRegistration, .submitReview:
            return .post
        case .updateProfile, .updatePreferences:
            return .put
        case .deleteAccount, .cancelSubscription:
            return .delete
        default:
            return .get
        }
    }

    var requiresAuth: Bool {
        switch self {
        case .login, .register, .forgotPassword, .resetPassword, .refreshToken:
            return false
        default:
            return true
        }
    }
}

// MARK: - API Request

/// Represents an API request with all necessary components
struct APIRequest<Response: Decodable> {
    let endpoint: APIEndpoint
    let method: HTTPMethod?
    let queryItems: [URLQueryItem]?
    let body: Encodable?
    let headers: [String: String]?
    let requiresAuth: Bool?

    init(
        endpoint: APIEndpoint,
        method: HTTPMethod? = nil,
        queryItems: [URLQueryItem]? = nil,
        body: Encodable? = nil,
        headers: [String: String]? = nil,
        requiresAuth: Bool? = nil
    ) {
        self.endpoint = endpoint
        self.method = method
        self.queryItems = queryItems
        self.body = body
        self.headers = headers
        self.requiresAuth = requiresAuth
    }
}

// MARK: - API Response

/// Wrapper for paginated API responses
struct PaginatedResponse<T: Decodable>: Decodable {
    let data: [T]
    let pagination: PaginationInfo

    struct PaginationInfo: Decodable {
        let page: Int
        let perPage: Int
        let totalPages: Int
        let totalItems: Int

        var hasNextPage: Bool {
            page < totalPages
        }
    }
}

/// Standard API response wrapper
struct APIResponse<T: Decodable>: Decodable {
    let success: Bool
    let data: T?
    let message: String?
    let errors: [String]?
}

/// Empty response for endpoints that return no data
struct EmptyResponse: Decodable {}

// MARK: - Token Manager

/// Manages JWT authentication tokens
actor TokenManager {
    private var accessToken: String?
    private var refreshToken: String?
    private var tokenExpiresAt: Date?

    private let keychainService = "com.mdfit.api.tokens"
    private let accessTokenKey = "access_token"
    private let refreshTokenKey = "refresh_token"
    private let expiresAtKey = "token_expires_at"

    init() {
        loadTokensFromKeychain()
    }

    func setTokens(access: String, refresh: String?, expiresIn: TimeInterval) {
        self.accessToken = access
        self.refreshToken = refresh
        self.tokenExpiresAt = Date().addingTimeInterval(expiresIn)
        saveTokensToKeychain()
    }

    func getAccessToken() -> String? {
        accessToken
    }

    func getRefreshToken() -> String? {
        refreshToken
    }

    func isTokenExpired() -> Bool {
        guard let expiresAt = tokenExpiresAt else { return true }
        // Consider token expired 60 seconds before actual expiration
        return Date().addingTimeInterval(60) >= expiresAt
    }

    func clearTokens() {
        accessToken = nil
        refreshToken = nil
        tokenExpiresAt = nil
        deleteTokensFromKeychain()
    }

    func hasValidToken() -> Bool {
        accessToken != nil && !isTokenExpired()
    }

    // MARK: - Keychain Operations

    private func saveTokensToKeychain() {
        guard let accessToken = accessToken else { return }

        saveToKeychain(key: accessTokenKey, value: accessToken)
        if let refreshToken = refreshToken {
            saveToKeychain(key: refreshTokenKey, value: refreshToken)
        }
        if let expiresAt = tokenExpiresAt {
            saveToKeychain(key: expiresAtKey, value: String(expiresAt.timeIntervalSince1970))
        }
    }

    private func loadTokensFromKeychain() {
        accessToken = loadFromKeychain(key: accessTokenKey)
        refreshToken = loadFromKeychain(key: refreshTokenKey)
        if let expiresAtString = loadFromKeychain(key: expiresAtKey),
           let timestamp = Double(expiresAtString) {
            tokenExpiresAt = Date(timeIntervalSince1970: timestamp)
        }
    }

    private func deleteTokensFromKeychain() {
        deleteFromKeychain(key: accessTokenKey)
        deleteFromKeychain(key: refreshTokenKey)
        deleteFromKeychain(key: expiresAtKey)
    }

    private func saveToKeychain(key: String, value: String) {
        let data = Data(value.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]

        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    private func loadFromKeychain(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }

        return value
    }

    private func deleteFromKeychain(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
    }
}

// MARK: - Request Logger

/// Handles debug logging for API requests and responses
final class RequestLogger {
    private let logger = Logger(subsystem: "com.mdfit.api", category: "network")
    private let isEnabled: Bool

    init(isEnabled: Bool) {
        self.isEnabled = isEnabled
    }

    func logRequest(_ request: URLRequest) {
        guard isEnabled else { return }

        var log = "\n========== API REQUEST ==========\n"
        log += "\(request.httpMethod ?? "GET") \(request.url?.absoluteString ?? "Unknown URL")\n"

        if let headers = request.allHTTPHeaderFields, !headers.isEmpty {
            log += "Headers:\n"
            for (key, value) in headers {
                // Don't log full auth tokens
                if key.lowercased() == "authorization" {
                    log += "  \(key): Bearer ***\n"
                } else {
                    log += "  \(key): \(value)\n"
                }
            }
        }

        if let body = request.httpBody,
           let bodyString = String(data: body, encoding: .utf8) {
            // Truncate large bodies and redact sensitive fields
            let sanitized = sanitizeBody(bodyString)
            log += "Body: \(sanitized.prefix(1000))\n"
        }

        log += "=================================="
        logger.debug("\(log)")
    }

    func logResponse(_ response: HTTPURLResponse, data: Data?, duration: TimeInterval) {
        guard isEnabled else { return }

        var log = "\n========== API RESPONSE ==========\n"
        log += "Status: \(response.statusCode)\n"
        log += "Duration: \(String(format: "%.3f", duration))s\n"
        log += "URL: \(response.url?.absoluteString ?? "Unknown")\n"

        if let data = data,
           let bodyString = String(data: data, encoding: .utf8) {
            let truncated = String(bodyString.prefix(2000))
            log += "Body: \(truncated)\n"
        }

        log += "==================================="

        if response.statusCode >= 400 {
            logger.error("\(log)")
        } else {
            logger.debug("\(log)")
        }
    }

    func logError(_ error: Error, for request: URLRequest?) {
        guard isEnabled else { return }

        var log = "\n========== API ERROR ==========\n"
        log += "URL: \(request?.url?.absoluteString ?? "Unknown")\n"
        log += "Error: \(error.localizedDescription)\n"
        log += "================================"

        logger.error("\(log)")
    }

    private func sanitizeBody(_ body: String) -> String {
        // Redact common sensitive fields
        var sanitized = body
        let sensitivePatterns = [
            "\"password\"\\s*:\\s*\"[^\"]*\"",
            "\"token\"\\s*:\\s*\"[^\"]*\"",
            "\"access_token\"\\s*:\\s*\"[^\"]*\"",
            "\"refresh_token\"\\s*:\\s*\"[^\"]*\""
        ]

        for pattern in sensitivePatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(sanitized.startIndex..., in: sanitized)
                sanitized = regex.stringByReplacingMatches(
                    in: sanitized,
                    options: [],
                    range: range,
                    withTemplate: "\"***REDACTED***\""
                )
            }
        }

        return sanitized
    }
}

// MARK: - Mock Response Provider

/// Protocol for providing mock responses during development
protocol MockResponseProvider {
    func mockResponse<T: Decodable>(for endpoint: APIEndpoint) async throws -> T
}

/// Default mock provider with sample responses
struct DefaultMockProvider: MockResponseProvider {
    init() {}

    func mockResponse<T: Decodable>(for endpoint: APIEndpoint) async throws -> T {
        // Simulate network delay
        try await Task.sleep(nanoseconds: UInt64.random(in: 200_000_000...800_000_000))

        // Return mock data based on endpoint
        // This should be extended with actual mock data for each endpoint
        throw APIError.notFound
    }
}

// MARK: - API Client

/// Main API client for MD Fit platform
actor APIClient {
    // MARK: - Properties

    private let configuration: APIConfiguration
    private let session: URLSession
    private let tokenManager: TokenManager
    private let logger: RequestLogger
    private let jsonEncoder: JSONEncoder
    private let jsonDecoder: JSONDecoder
    private var mockProvider: MockResponseProvider?

    // Delegate for handling auth events
    private weak var _authDelegate: APIClientAuthDelegate?

    /// Set the auth delegate for handling authentication events
    func setAuthDelegate(_ delegate: APIClientAuthDelegate?) {
        self._authDelegate = delegate
    }

    /// Get the current auth delegate
    var authDelegate: APIClientAuthDelegate? {
        _authDelegate
    }

    // MARK: - Singleton

    static let shared = APIClient()

    // MARK: - Initialization

    init(
        configuration: APIConfiguration = .default,
        session: URLSession? = nil,
        mockProvider: MockResponseProvider? = nil
    ) {
        self.configuration = configuration
        self.tokenManager = TokenManager()
        self.logger = RequestLogger(isEnabled: configuration.environment.isDebugLoggingEnabled)
        self.mockProvider = mockProvider

        // Configure JSON encoder
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601
        self.jsonEncoder = encoder

        // Configure JSON decoder
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        self.jsonDecoder = decoder

        // Configure URLSession
        if let session = session {
            self.session = session
        } else {
            let sessionConfig = URLSessionConfiguration.default
            sessionConfig.timeoutIntervalForRequest = configuration.timeoutInterval
            sessionConfig.timeoutIntervalForResource = configuration.timeoutInterval * 2
            sessionConfig.waitsForConnectivity = true
            sessionConfig.httpAdditionalHeaders = [
                "Accept": "application/json",
                "Content-Type": "application/json"
            ]
            self.session = URLSession(configuration: sessionConfig)
        }
    }

    // MARK: - Public API

    /// Execute an API request and return decoded response
    func execute<T: Decodable>(_ request: APIRequest<T>) async throws -> T {
        // Use mock if enabled
        if configuration.enableMockMode, let provider = mockProvider {
            return try await provider.mockResponse(for: request.endpoint)
        }

        // Build and execute the request
        let urlRequest = try await buildURLRequest(for: request)
        return try await executeWithRetry(urlRequest, request: request)
    }

    /// Execute request without expecting a response body
    func execute(_ request: APIRequest<EmptyResponse>) async throws {
        if configuration.enableMockMode {
            try await Task.sleep(nanoseconds: 300_000_000)
            return
        }

        let urlRequest = try await buildURLRequest(for: request)
        let _: EmptyResponse = try await executeWithRetry(urlRequest, request: request)
    }

    /// Convenience method for GET requests
    func get<T: Decodable>(
        _ endpoint: APIEndpoint,
        queryItems: [URLQueryItem]? = nil
    ) async throws -> T {
        let request = APIRequest<T>(
            endpoint: endpoint,
            method: .get,
            queryItems: queryItems
        )
        return try await execute(request)
    }

    /// Convenience method for POST requests
    func post<T: Decodable, Body: Encodable>(
        _ endpoint: APIEndpoint,
        body: Body
    ) async throws -> T {
        let request = APIRequest<T>(
            endpoint: endpoint,
            method: .post,
            body: body
        )
        return try await execute(request)
    }

    /// Convenience method for PUT requests
    func put<T: Decodable, Body: Encodable>(
        _ endpoint: APIEndpoint,
        body: Body
    ) async throws -> T {
        let request = APIRequest<T>(
            endpoint: endpoint,
            method: .put,
            body: body
        )
        return try await execute(request)
    }

    /// Convenience method for DELETE requests
    func delete(_ endpoint: APIEndpoint) async throws {
        let request = APIRequest<EmptyResponse>(
            endpoint: endpoint,
            method: .delete
        )
        try await execute(request)
    }

    // MARK: - Token Management

    /// Set authentication tokens after login
    func setAuthTokens(access: String, refresh: String?, expiresIn: TimeInterval) async {
        await tokenManager.setTokens(access: access, refresh: refresh, expiresIn: expiresIn)
    }

    /// Clear authentication tokens on logout
    func clearAuthTokens() async {
        await tokenManager.clearTokens()
    }

    /// Check if user has valid authentication
    func isAuthenticated() async -> Bool {
        await tokenManager.hasValidToken()
    }

    // MARK: - Mock Mode

    /// Set mock provider for testing
    func setMockProvider(_ provider: MockResponseProvider?) {
        self.mockProvider = provider
    }

    // MARK: - Private Methods

    private func buildURLRequest<T>(for request: APIRequest<T>) async throws -> URLRequest {
        // Build URL with path and query items
        var components = URLComponents(
            url: configuration.environment.baseURL.appendingPathComponent(request.endpoint.path),
            resolvingAgainstBaseURL: true
        )

        // Add query items
        if let queryItems = request.queryItems, !queryItems.isEmpty {
            components?.queryItems = queryItems
        }

        guard let url = components?.url else {
            throw APIError.invalidURL
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = (request.method ?? request.endpoint.method).rawValue
        urlRequest.timeoutInterval = configuration.timeoutInterval

        // Add default headers
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        urlRequest.setValue("MDfit-iOS/1.0", forHTTPHeaderField: "User-Agent")

        // Add configuration headers
        for (key, value) in configuration.additionalHeaders {
            urlRequest.setValue(value, forHTTPHeaderField: key)
        }

        // Add custom headers
        if let headers = request.headers {
            for (key, value) in headers {
                urlRequest.setValue(value, forHTTPHeaderField: key)
            }
        }

        // Add auth token if required
        let requiresAuth = request.requiresAuth ?? request.endpoint.requiresAuth
        if requiresAuth {
            // Check if token needs refresh
            if await tokenManager.isTokenExpired() {
                try await refreshTokenIfNeeded()
            }

            if let token = await tokenManager.getAccessToken() {
                urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }
        }

        // Encode body
        if let body = request.body {
            do {
                urlRequest.httpBody = try jsonEncoder.encode(AnyEncodable(body))
            } catch {
                throw APIError.encodingError(underlying: error.localizedDescription)
            }
        }

        return urlRequest
    }

    private func executeWithRetry<T: Decodable>(
        _ urlRequest: URLRequest,
        request: APIRequest<T>,
        attempt: Int = 0
    ) async throws -> T {
        let startTime = Date()

        logger.logRequest(urlRequest)

        do {
            let (data, response) = try await session.data(for: urlRequest)

            let duration = Date().timeIntervalSince(startTime)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }

            logger.logResponse(httpResponse, data: data, duration: duration)

            // Handle response based on status code
            switch httpResponse.statusCode {
            case 200...299:
                // Success - decode response
                do {
                    // Handle empty responses
                    if data.isEmpty || T.self == EmptyResponse.self {
                        return EmptyResponse() as! T
                    }
                    return try jsonDecoder.decode(T.self, from: data)
                } catch {
                    throw APIError.decodingError(underlying: error.localizedDescription)
                }

            case 401:
                // Unauthorized - try token refresh
                if request.endpoint.requiresAuth && attempt == 0 {
                    do {
                        try await refreshTokenIfNeeded()
                        // Rebuild request with new token and retry
                        let newRequest = try await buildURLRequest(for: request)
                        return try await executeWithRetry(newRequest, request: request, attempt: attempt + 1)
                    } catch {
                        await tokenManager.clearTokens()
                        await _authDelegate?.apiClientDidReceiveUnauthorized(self)
                        throw APIError.unauthorized
                    }
                }
                throw APIError.unauthorized

            case 400:
                let message = extractErrorMessage(from: data)
                throw APIError.badRequest(message: message)

            case 403:
                throw APIError.forbidden

            case 404:
                throw APIError.notFound

            case 409:
                let message = extractErrorMessage(from: data)
                throw APIError.conflict(message: message)

            case 429:
                let retryAfter = httpResponse.value(forHTTPHeaderField: "Retry-After")
                    .flatMap { Double($0) }
                throw APIError.tooManyRequests(retryAfter: retryAfter)

            case 500...599:
                let message = extractErrorMessage(from: data)
                throw APIError.serverError(statusCode: httpResponse.statusCode, message: message)

            default:
                throw APIError.serverError(statusCode: httpResponse.statusCode, message: nil)
            }

        } catch let error as APIError {
            // Check if we should retry
            if error.isRetryable && attempt < configuration.maxRetryAttempts {
                let delay = calculateRetryDelay(for: attempt, error: error)
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                return try await executeWithRetry(urlRequest, request: request, attempt: attempt + 1)
            }
            throw error

        } catch let error as URLError {
            logger.logError(error, for: urlRequest)

            let apiError: APIError
            switch error.code {
            case .notConnectedToInternet, .networkConnectionLost:
                apiError = .noConnection
            case .timedOut:
                apiError = .timeout
            case .cancelled:
                apiError = .cancelled
            default:
                apiError = .unknown(underlying: error.localizedDescription)
            }

            // Retry network errors
            if apiError.isRetryable && attempt < configuration.maxRetryAttempts {
                let delay = calculateRetryDelay(for: attempt, error: apiError)
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                return try await executeWithRetry(urlRequest, request: request, attempt: attempt + 1)
            }

            throw apiError

        } catch {
            logger.logError(error, for: urlRequest)
            throw APIError.unknown(underlying: error.localizedDescription)
        }
    }

    private func refreshTokenIfNeeded() async throws {
        guard let refreshToken = await tokenManager.getRefreshToken() else {
            throw APIError.tokenRefreshFailed
        }

        // Build refresh request
        var components = URLComponents(
            url: configuration.environment.baseURL.appendingPathComponent("/auth/refresh"),
            resolvingAgainstBaseURL: true
        )

        guard let url = components?.url else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ["refresh_token": refreshToken]
        request.httpBody = try jsonEncoder.encode(body)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.tokenRefreshFailed
        }

        struct TokenResponse: Decodable {
            let accessToken: String
            let refreshToken: String?
            let expiresIn: TimeInterval
        }

        let tokenResponse = try jsonDecoder.decode(TokenResponse.self, from: data)
        await tokenManager.setTokens(
            access: tokenResponse.accessToken,
            refresh: tokenResponse.refreshToken ?? refreshToken,
            expiresIn: tokenResponse.expiresIn
        )
    }

    private func calculateRetryDelay(for attempt: Int, error: APIError) -> TimeInterval {
        // Exponential backoff: 1s, 2s, 4s, 8s...
        let baseDelay: TimeInterval = 1.0
        let maxDelay: TimeInterval = 30.0

        // For rate limiting, use server-provided retry-after
        if case .tooManyRequests(let retryAfter) = error, let delay = retryAfter {
            return min(delay, maxDelay)
        }

        // Exponential backoff with jitter
        let exponentialDelay = baseDelay * pow(2.0, Double(attempt))
        let jitter = Double.random(in: 0...0.3) * exponentialDelay
        return min(exponentialDelay + jitter, maxDelay)
    }

    private func extractErrorMessage(from data: Data) -> String? {
        struct ErrorResponse: Decodable {
            let message: String?
            let error: String?
            let errors: [String]?
        }

        guard let errorResponse = try? jsonDecoder.decode(ErrorResponse.self, from: data) else {
            return nil
        }

        return errorResponse.message ?? errorResponse.error ?? errorResponse.errors?.first
    }
}

// MARK: - Auth Delegate

/// Delegate protocol for handling authentication events
@MainActor
protocol APIClientAuthDelegate: AnyObject {
    func apiClientDidReceiveUnauthorized(_ client: APIClient)
    func apiClientDidRefreshToken(_ client: APIClient)
}

// MARK: - Type Erasure Helper

/// Type-erased Encodable wrapper
private struct AnyEncodable: Encodable {
    private let _encode: (Encoder) throws -> Void

    init<T: Encodable>(_ wrapped: T) {
        _encode = wrapped.encode
    }

    func encode(to encoder: Encoder) throws {
        try _encode(encoder)
    }
}

// MARK: - Convenience Extensions

extension APIClient {
    /// Upload file data with multipart form
    func upload<T: Decodable>(
        to endpoint: APIEndpoint,
        fileData: Data,
        fileName: String,
        mimeType: String,
        additionalFields: [String: String]? = nil
    ) async throws -> T {
        let boundary = UUID().uuidString

        var components = URLComponents(
            url: configuration.environment.baseURL.appendingPathComponent(endpoint.path),
            resolvingAgainstBaseURL: true
        )

        guard let url = components?.url else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        if await tokenManager.hasValidToken(),
           let token = await tokenManager.getAccessToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        var body = Data()

        // Add additional fields
        if let fields = additionalFields {
            for (key, value) in fields {
                body.append("--\(boundary)\r\n".data(using: .utf8)!)
                body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
                body.append("\(value)\r\n".data(using: .utf8)!)
            }
        }

        // Add file data
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(fileData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw APIError.invalidResponse
        }

        return try jsonDecoder.decode(T.self, from: data)
    }

    /// Download file from URL
    func download(from url: URL, to destination: URL) async throws {
        let (tempURL, response) = try await session.download(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw APIError.invalidResponse
        }

        try FileManager.default.moveItem(at: tempURL, to: destination)
    }
}

// MARK: - Request Builder DSL

/// Fluent builder for constructing API requests
class APIRequestBuilder<Response: Decodable> {
    private var endpoint: APIEndpoint
    private var method: HTTPMethod?
    private var queryItems: [URLQueryItem] = []
    private var body: Encodable?
    private var headers: [String: String] = [:]
    private var requiresAuth: Bool?

    init(endpoint: APIEndpoint) {
        self.endpoint = endpoint
    }

    func method(_ method: HTTPMethod) -> Self {
        self.method = method
        return self
    }

    func query(_ name: String, value: String?) -> Self {
        if let value = value {
            queryItems.append(URLQueryItem(name: name, value: value))
        }
        return self
    }

    func queries(_ items: [String: String?]) -> Self {
        for (name, value) in items {
            if let value = value {
                queryItems.append(URLQueryItem(name: name, value: value))
            }
        }
        return self
    }

    func body<T: Encodable>(_ body: T) -> Self {
        self.body = body
        return self
    }

    func header(_ name: String, value: String) -> Self {
        headers[name] = value
        return self
    }

    func requiresAuth(_ requires: Bool) -> Self {
        self.requiresAuth = requires
        return self
    }

    func build() -> APIRequest<Response> {
        APIRequest(
            endpoint: endpoint,
            method: method,
            queryItems: queryItems.isEmpty ? nil : queryItems,
            body: body,
            headers: headers.isEmpty ? nil : headers,
            requiresAuth: requiresAuth
        )
    }

    func execute(with client: APIClient = .shared) async throws -> Response {
        try await client.execute(build())
    }
}

// MARK: - Endpoint Builder Extension

extension APIEndpoint {
    func request<T: Decodable>() -> APIRequestBuilder<T> {
        APIRequestBuilder(endpoint: self)
    }
}
