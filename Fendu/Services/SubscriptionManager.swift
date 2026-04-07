import StoreKit
import UIKit

@MainActor @Observable
final class SubscriptionManager {

    // MARK: - State

    private(set) var isPro: Bool = false
    private(set) var products: [Product] = []
    private(set) var purchaseState: PurchaseState = .idle
    private(set) var currentSubscription: StoreKit.Transaction?

    enum PurchaseState: Equatable {
        case idle, purchasing, purchased, failed(String), cancelled
    }

    // MARK: - Product IDs

    static let monthlyID = "com.jordanbardwell.fendu.pro.monthly"
    static let yearlyID  = "com.jordanbardwell.fendu.pro.yearly"
    private static let productIDs: Set<String> = [monthlyID, yearlyID]

    // MARK: - Listener

    private var updateListenerTask: Task<Void, Never>?

    init() {
        updateListenerTask = Task { [weak self] in
            for await result in StoreKit.Transaction.updates {
                guard let self else { return }
                if let transaction = try? result.payloadValue {
                    await transaction.finish()
                    await self.checkSubscriptionStatus()
                }
            }
        }
    }

    nonisolated func cleanup() {
        // Called if needed; Task will be cancelled when the object is deallocated
    }

    // MARK: - Load Products

    func loadProducts() async {
        print("[SubscriptionManager] Loading products for IDs: \(Self.productIDs)")
        do {
            let storeProducts = try await Product.products(for: Self.productIDs)
            print("[SubscriptionManager] Loaded \(storeProducts.count) products: \(storeProducts.map { "\($0.id) - \($0.displayName) - \($0.displayPrice)" })")
            products = storeProducts.sorted { ($0.subscription?.subscriptionPeriod.value ?? 0) < ($1.subscription?.subscriptionPeriod.value ?? 0) }
            #if DEBUG
            if storeProducts.isEmpty {
                print("[SubscriptionManager] ⚠️ 0 products returned. Verify:")
                print("  - Xcode: Edit Scheme → Run → Options → StoreKit Configuration = FenduPro.storekit")
                print("  - TestFlight: Ensure products are 'Ready to Submit' in App Store Connect")
                print("  - Check Paid Apps agreement is active in App Store Connect → Business")
            }
            #endif
        } catch {
            print("[SubscriptionManager] ❌ Failed to load products: \(error)")
        }
    }

    // MARK: - Check Status

    func checkSubscriptionStatus() async {
        var foundActive = false
        for await result in StoreKit.Transaction.currentEntitlements {
            if let transaction = try? result.payloadValue {
                if transaction.revocationDate == nil {
                    foundActive = true
                    currentSubscription = transaction
                }
            }
        }
        isPro = foundActive
        if !foundActive {
            currentSubscription = nil
        }
    }

    // MARK: - Purchase

    func purchase(_ product: Product) async {
        purchaseState = .purchasing
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if let transaction = try? verification.payloadValue {
                    await transaction.finish()
                    isPro = true
                    currentSubscription = transaction
                    purchaseState = .purchased
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    print("[SubscriptionManager] Purchase successful — isPro = true")
                } else {
                    purchaseState = .failed("Verification failed")
                    print("[SubscriptionManager] Purchase verification failed")
                }
            case .userCancelled:
                purchaseState = .cancelled
            case .pending:
                purchaseState = .idle
            @unknown default:
                purchaseState = .failed("Unknown error")
            }
        } catch {
            purchaseState = .failed(error.localizedDescription)
        }
    }

    // MARK: - Restore

    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await checkSubscriptionStatus()
        } catch {
            print("Restore failed: \(error)")
        }
    }

    // MARK: - Free Tier Limits

    static let freeAccountLimit = 2
    static let freeCheckingLimit = 1
    static let freeSavingsLimit = 1
    static let freeBillLimit = 2

    // MARK: - Convenience Gates

    func canCreateAccount(currentCount: Int) -> Bool {
        isPro || currentCount < Self.freeAccountLimit
    }

    func canCreateChecking(currentCount: Int) -> Bool {
        isPro || currentCount < Self.freeCheckingLimit
    }

    func canCreateSavings(currentCount: Int) -> Bool {
        isPro || currentCount < Self.freeSavingsLimit
    }

    func canCreateBill(currentCount: Int) -> Bool {
        isPro || currentCount < Self.freeBillLimit
    }

    func canSplitDeposits(depositCount: Int) -> Bool {
        isPro || depositCount <= 2
    }

    func canTrackIncome() -> Bool {
        isPro
    }

    func canSendChatMessage() -> Bool {
        ChatMessageTracker.canSendMessage(isPro: isPro)
    }

    // MARK: - Helpers

    var monthlyProduct: Product? {
        products.first { $0.id == Self.monthlyID }
    }

    var yearlyProduct: Product? {
        products.first { $0.id == Self.yearlyID }
    }

    var currentPlanName: String? {
        guard let transaction = currentSubscription else { return nil }
        if transaction.productID == Self.yearlyID { return "Yearly" }
        if transaction.productID == Self.monthlyID { return "Monthly" }
        return nil
    }
}
