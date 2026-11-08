import Foundation
import StoreKit
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Product Identifiers

/// App Store product identifiers for MDfit subscriptions
enum MDfitProductID: String, CaseIterable {
    case premium = "com.mdfit.subscription.premium"                    // $20/mo
    case microMomentum = "com.mdfit.subscription.micromomentum"       // $9/mo x 3
    case betaGrandfathered = "com.mdfit.subscription.beta"            // $9.95/mo

    var tier: SubscriptionTier {
        switch self {
        case .premium: return .premium
        case .microMomentum: return .microMomentum
        case .betaGrandfathered: return .betaGrandfathered
        }
    }

    var displayName: String {
        tier.displayName
    }

    static var allProductIDs: Set<String> {
        Set(allCases.map(\.rawValue))
    }
}

// MARK: - Billing Service

@MainActor
class BillingService: ObservableObject {

    // MARK: - Published State

    @Published private(set) var products: [Product] = []
    @Published private(set) var purchasedProductIDs: Set<String> = []
    @Published private(set) var currentSubscription: Subscription?
    @Published private(set) var entitlements: [Entitlement] = []
    @Published private(set) var isLoading = false
    @Published private(set) var error: BillingError?
    @Published private(set) var purchaseState: PurchaseState = .idle

    // MARK: - Computed Properties

    /// Whether user has active premium access
    var isPremium: Bool {
        !purchasedProductIDs.isEmpty || currentSubscription?.isActive == true
    }

    /// Product for a specific tier
    func product(for tier: SubscriptionTier) -> Product? {
        let productID: String
        switch tier {
        case .premium:
            productID = MDfitProductID.premium.rawValue
        case .microMomentum:
            productID = MDfitProductID.microMomentum.rawValue
        case .betaGrandfathered:
            productID = MDfitProductID.betaGrandfathered.rawValue
        case .free:
            return nil
        }
        return products.first { $0.id == productID }
    }

    /// Sorted products by price (ascending)
    var sortedProducts: [Product] {
        products.sorted { ($0.price as NSDecimalNumber).doubleValue < ($1.price as NSDecimalNumber).doubleValue }
    }

    // MARK: - Private Properties

    private var transactionListener: Task<Void, Error>?
    private let userDefaults = UserDefaults.standard
    private let purchasedProductsKey = "mdfit_purchased_products"

    // MARK: - Initialization

    init() {
        loadCachedPurchases()
        startTransactionListener()

        Task {
            await fetchProducts()
            await refreshPurchasedProducts()
        }
    }

    deinit {
        transactionListener?.cancel()
    }

    // MARK: - Product Fetching

    /// Fetch all available subscription products from App Store
    func fetchProducts() async {
        isLoading = true
        error = nil

        defer { isLoading = false }

        do {
            let storeProducts = try await Product.products(for: MDfitProductID.allProductIDs)
            self.products = storeProducts

            #if DEBUG
            print("[BillingService] Fetched \(storeProducts.count) products")
            for product in storeProducts {
                print("  - \(product.id): \(product.displayName) @ \(product.displayPrice)")
            }
            #endif
        } catch {
            self.error = .productFetchFailed(error)
            #if DEBUG
            print("[BillingService] Failed to fetch products: \(error)")
            #endif
        }
    }

    // MARK: - Purchase Flow

    /// Purchase a subscription product
    /// - Parameter product: The StoreKit Product to purchase
    /// - Returns: The transaction if successful, nil otherwise
    @discardableResult
    func purchase(_ product: Product) async throws -> Transaction? {
        purchaseState = .purchasing
        error = nil

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)

                // Update local state
                await updatePurchasedProducts(transaction)

                // Finish the transaction
                await transaction.finish()

                purchaseState = .purchased

                #if DEBUG
                print("[BillingService] Purchase successful: \(product.id)")
                #endif

                return transaction

            case .userCancelled:
                purchaseState = .cancelled
                #if DEBUG
                print("[BillingService] Purchase cancelled by user")
                #endif
                return nil

            case .pending:
                purchaseState = .pending
                #if DEBUG
                print("[BillingService] Purchase pending (requires approval)")
                #endif
                return nil

            @unknown default:
                purchaseState = .failed
                throw BillingError.unknownPurchaseResult
            }
        } catch {
            purchaseState = .failed

            if let billingError = error as? BillingError {
                self.error = billingError
            } else {
                self.error = .purchaseFailed(error)
            }

            #if DEBUG
            print("[BillingService] Purchase failed: \(error)")
            #endif

            throw error
        }
    }

    /// Purchase a subscription by tier
    func purchase(tier: SubscriptionTier) async throws -> Transaction? {
        guard let product = product(for: tier) else {
            throw BillingError.productNotFound
        }
        return try await purchase(product)
    }

    // MARK: - Subscription Management

    /// Refresh purchased products and subscription status
    func refreshPurchasedProducts() async {
        var purchasedIDs: Set<String> = []
        var latestSubscription: Subscription?
        var activeEntitlements: [Entitlement] = []

        // Check for current entitlements
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }

            purchasedIDs.insert(transaction.productID)

            // Build subscription from transaction
            if let productID = MDfitProductID(rawValue: transaction.productID) {
                let subscription = buildSubscription(from: transaction, productID: productID)

                // Keep the most recent/active subscription
                if latestSubscription == nil || subscription.isActive {
                    latestSubscription = subscription
                }

                // Create entitlement
                let entitlement = buildEntitlement(from: transaction)
                activeEntitlements.append(entitlement)
            }
        }

        self.purchasedProductIDs = purchasedIDs
        self.currentSubscription = latestSubscription
        self.entitlements = activeEntitlements
        savePurchasedProducts()

        #if DEBUG
        print("[BillingService] Refreshed purchases: \(purchasedIDs)")
        if let sub = latestSubscription {
            print("[BillingService] Active subscription: \(sub.tier.displayName)")
        }
        #endif
    }

    /// Get subscription info for a specific product
    func subscriptionInfo(for productID: String) async -> Product.SubscriptionInfo? {
        guard let product = products.first(where: { $0.id == productID }) else {
            return nil
        }
        return product.subscription
    }

    /// Check if user is subscribed to a specific tier
    func isSubscribed(to tier: SubscriptionTier) -> Bool {
        currentSubscription?.tier == tier && currentSubscription?.isActive == true
    }

    /// Get subscription renewal info
    func renewalInfo(for productID: String) async -> Product.SubscriptionInfo.RenewalInfo? {
        guard let product = products.first(where: { $0.id == productID }),
              let subscription = product.subscription else {
            return nil
        }

        do {
            let status = try await subscription.status.first
            return try status?.renewalInfo.payloadValue
        } catch {
            #if DEBUG
            print("[BillingService] Failed to get renewal info: \(error)")
            #endif
            return nil
        }
    }

    // MARK: - Entitlement Verification

    /// Verify user has access to premium content
    func verifyPremiumAccess() async -> Bool {
        await refreshPurchasedProducts()
        return isPremium
    }

    /// Verify entitlement for specific content
    func verifyEntitlement(for type: EntitlementType) -> Bool {
        entitlements.contains { $0.type == type && $0.isValid }
    }

    /// Check if user has valid entitlement for a specific resource
    func hasEntitlement(for resourceId: String) -> Bool {
        entitlements.contains { $0.resourceId == resourceId && $0.isValid }
    }

    // MARK: - Transaction Listening

    /// Start listening for transaction updates
    private func startTransactionListener() {
        transactionListener = Task.detached { [weak self] in
            for await result in Transaction.updates {
                await self?.handleTransactionUpdate(result)
            }
        }
    }

    /// Handle incoming transaction updates
    private func handleTransactionUpdate(_ result: VerificationResult<Transaction>) async {
        do {
            let transaction = try checkVerified(result)
            await updatePurchasedProducts(transaction)
            await transaction.finish()

            #if DEBUG
            print("[BillingService] Transaction update processed: \(transaction.productID)")
            #endif
        } catch {
            #if DEBUG
            print("[BillingService] Transaction verification failed: \(error)")
            #endif
        }
    }

    /// Update purchased products after a transaction
    private func updatePurchasedProducts(_ transaction: Transaction) async {
        if transaction.revocationDate != nil {
            // Product was revoked (refund, family sharing removed, etc.)
            purchasedProductIDs.remove(transaction.productID)
        } else {
            purchasedProductIDs.insert(transaction.productID)
        }

        await refreshPurchasedProducts()
    }

    // MARK: - Restore Purchases

    /// Restore previous purchases
    func restorePurchases() async throws {
        isLoading = true
        error = nil

        defer { isLoading = false }

        do {
            // Sync with App Store
            try await AppStore.sync()

            // Refresh local state
            await refreshPurchasedProducts()

            if purchasedProductIDs.isEmpty {
                throw BillingError.noPurchasesToRestore
            }

            #if DEBUG
            print("[BillingService] Purchases restored successfully")
            #endif
        } catch {
            if let billingError = error as? BillingError {
                self.error = billingError
            } else {
                self.error = .restoreFailed(error)
            }
            throw error
        }
    }

    // MARK: - Receipt Validation (Server-Side Stub)

    /// Validate receipt with server
    /// - Note: This is a stub for server-side validation. Implement actual API call.
    func validateReceipt() async throws -> ReceiptValidationResult {
        // Get the app receipt URL
        guard let receiptURL = Bundle.main.appStoreReceiptURL,
              FileManager.default.fileExists(atPath: receiptURL.path) else {
            throw BillingError.receiptNotFound
        }

        // Read receipt data
        let receiptData: Data
        do {
            receiptData = try Data(contentsOf: receiptURL)
        } catch {
            throw BillingError.receiptReadFailed(error)
        }

        // Base64 encode for server transmission
        let receiptString = receiptData.base64EncodedString()

        // TODO: Send to your server for validation
        // Server should validate with Apple's verifyReceipt endpoint
        // For now, return a stub result

        #if DEBUG
        print("[BillingService] Receipt validation stub - receipt size: \(receiptData.count) bytes")
        #endif

        // Stub: Return success based on current entitlements
        return ReceiptValidationResult(
            isValid: !purchasedProductIDs.isEmpty,
            activeSubscriptions: Array(purchasedProductIDs),
            expirationDates: [:],
            originalPurchaseDate: nil,
            validatedAt: Date()
        )
    }

    /// Send receipt to server for validation
    /// - Parameter receiptData: Base64 encoded receipt
    /// - Returns: Server validation response
    /// - Note: Implement actual API call to your backend
    func validateReceiptWithServer(receiptData: String) async throws -> ReceiptValidationResult {
        // TODO: Replace with actual API endpoint
        let endpoint = "https://api.mdfit.com/v1/billing/validate-receipt"

        guard let url = URL(string: endpoint) else {
            throw BillingError.invalidServerURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "receipt_data": receiptData,
            "platform": "ios"
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        // For now, simulate server response
        // TODO: Uncomment when server endpoint is ready
        /*
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw BillingError.serverValidationFailed
        }

        return try JSONDecoder().decode(ReceiptValidationResult.self, from: data)
        */

        // Stub response
        return ReceiptValidationResult(
            isValid: true,
            activeSubscriptions: Array(purchasedProductIDs),
            expirationDates: [:],
            originalPurchaseDate: nil,
            validatedAt: Date()
        )
    }

    // MARK: - Manage Subscription (App Store)

    /// Open App Store subscription management
    func openSubscriptionManagement() async {
        #if canImport(UIKit)
        if let windowScene = await UIApplication.shared.connectedScenes.first as? UIWindowScene {
            do {
                try await AppStore.showManageSubscriptions(in: windowScene)
            } catch {
                #if DEBUG
                print("[BillingService] Failed to open subscription management: \(error)")
                #endif
            }
        }
        #endif
    }

    /// Request refund for a transaction
    func requestRefund(for transactionID: UInt64) async throws -> Transaction.RefundRequestStatus {
        #if canImport(UIKit)
        guard let windowScene = await UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            throw BillingError.windowSceneNotFound
        }

        return try await Transaction.beginRefundRequest(for: transactionID, in: windowScene)
        #else
        throw BillingError.windowSceneNotFound
        #endif
    }

    // MARK: - Helper Methods

    /// Verify a transaction result
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw BillingError.verificationFailed(error)
        case .verified(let safe):
            return safe
        }
    }

    /// Build Subscription model from transaction
    private func buildSubscription(from transaction: Transaction, productID: MDfitProductID) -> Subscription {
        let status: SubscriptionStatus
        if transaction.revocationDate != nil {
            status = .cancelled
        } else if let expirationDate = transaction.expirationDate, expirationDate < Date() {
            status = .expired
        } else {
            status = .active
        }

        return Subscription(
            id: String(transaction.id),
            tier: productID.tier,
            status: status,
            pricePerMonth: productID.tier.price,
            startDate: transaction.purchaseDate,
            currentPeriodEnd: transaction.expirationDate ?? Date().addingTimeInterval(30 * 24 * 60 * 60),
            cancelAtPeriodEnd: transaction.revocationDate != nil,
            paymentMethod: "Apple Pay"
        )
    }

    /// Build Entitlement model from transaction
    private func buildEntitlement(from transaction: Transaction) -> Entitlement {
        return Entitlement(
            id: String(transaction.id),
            type: .premium,
            resourceId: transaction.productID,
            grantedAt: transaction.purchaseDate,
            expiresAt: transaction.expirationDate,
            source: .subscription
        )
    }

    // MARK: - Persistence

    private func savePurchasedProducts() {
        let array = Array(purchasedProductIDs)
        userDefaults.set(array, forKey: purchasedProductsKey)
    }

    private func loadCachedPurchases() {
        if let array = userDefaults.stringArray(forKey: purchasedProductsKey) {
            purchasedProductIDs = Set(array)
        }
    }
}

// MARK: - Purchase State

enum PurchaseState: Equatable {
    case idle
    case purchasing
    case purchased
    case pending
    case cancelled
    case failed

    var isProcessing: Bool {
        self == .purchasing
    }

    var displayMessage: String? {
        switch self {
        case .idle: return nil
        case .purchasing: return "Processing purchase..."
        case .purchased: return "Purchase successful!"
        case .pending: return "Purchase pending approval"
        case .cancelled: return "Purchase cancelled"
        case .failed: return "Purchase failed"
        }
    }
}

// MARK: - Receipt Validation Result

struct ReceiptValidationResult: Codable {
    let isValid: Bool
    let activeSubscriptions: [String]
    let expirationDates: [String: Date]
    let originalPurchaseDate: Date?
    let validatedAt: Date
}

// MARK: - Billing Error

enum BillingError: LocalizedError {
    case productFetchFailed(Error)
    case productNotFound
    case purchaseFailed(Error)
    case verificationFailed(Error)
    case unknownPurchaseResult
    case restoreFailed(Error)
    case noPurchasesToRestore
    case receiptNotFound
    case receiptReadFailed(Error)
    case invalidServerURL
    case serverValidationFailed
    case windowSceneNotFound
    case notEntitled
    case subscriptionExpired

    var errorDescription: String? {
        switch self {
        case .productFetchFailed(let error):
            return "Failed to load products: \(error.localizedDescription)"
        case .productNotFound:
            return "Product not found"
        case .purchaseFailed(let error):
            return "Purchase failed: \(error.localizedDescription)"
        case .verificationFailed:
            return "Unable to verify purchase"
        case .unknownPurchaseResult:
            return "Unknown purchase result"
        case .restoreFailed(let error):
            return "Failed to restore purchases: \(error.localizedDescription)"
        case .noPurchasesToRestore:
            return "No previous purchases found"
        case .receiptNotFound:
            return "Receipt not found"
        case .receiptReadFailed:
            return "Failed to read receipt"
        case .invalidServerURL:
            return "Invalid server configuration"
        case .serverValidationFailed:
            return "Server validation failed"
        case .windowSceneNotFound:
            return "Unable to present App Store interface"
        case .notEntitled:
            return "Premium subscription required"
        case .subscriptionExpired:
            return "Your subscription has expired"
        }
    }
}

// MARK: - Product Extensions

extension Product {
    /// Formatted subscription period (e.g., "per month")
    var subscriptionPeriodText: String? {
        guard let subscription = subscription else { return nil }

        let unit = subscription.subscriptionPeriod.unit
        let value = subscription.subscriptionPeriod.value

        switch unit {
        case .day:
            return value == 1 ? "per day" : "every \(value) days"
        case .week:
            return value == 1 ? "per week" : "every \(value) weeks"
        case .month:
            return value == 1 ? "per month" : "every \(value) months"
        case .year:
            return value == 1 ? "per year" : "every \(value) years"
        @unknown default:
            return nil
        }
    }

    /// Whether this product offers a free trial
    var hasFreeTrial: Bool {
        subscription?.introductoryOffer?.paymentMode == .freeTrial
    }

    /// Free trial duration text
    var freeTrialText: String? {
        guard let offer = subscription?.introductoryOffer,
              offer.paymentMode == .freeTrial else {
            return nil
        }

        let period = offer.period
        let value = period.value

        switch period.unit {
        case .day:
            return "\(value)-day free trial"
        case .week:
            return "\(value)-week free trial"
        case .month:
            return "\(value)-month free trial"
        case .year:
            return "\(value)-year free trial"
        @unknown default:
            return "Free trial"
        }
    }
}

// MARK: - Preview Helpers

#if DEBUG
extension BillingService {
    /// Create a mock service for previews
    static var preview: BillingService {
        let service = BillingService()
        service.currentSubscription = Subscription(
            id: "preview_sub",
            tier: .premium,
            status: .active,
            pricePerMonth: 20,
            startDate: Date().addingTimeInterval(-30 * 24 * 60 * 60),
            currentPeriodEnd: Date().addingTimeInterval(30 * 24 * 60 * 60),
            cancelAtPeriodEnd: false,
            paymentMethod: "Apple Pay"
        )
        return service
    }

    /// Create a mock free user service for previews
    static var previewFree: BillingService {
        BillingService()
    }
}
#endif
