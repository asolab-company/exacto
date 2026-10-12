import Combine
import Foundation
import StoreKit

@MainActor
final class IAPManager: ObservableObject {
    static let shared = IAPManager()

    enum PurchaseOutcome: Equatable {
        case purchased, cancelled, pending
    }

    enum PurchaseError: LocalizedError {
        case productUnavailable, paymentsNotAllowed

        var errorDescription: String? {
            switch self {
            case .productUnavailable:
                return "Products are not loaded yet. Please try again."
            case .paymentsNotAllowed:
                return "In-App Purchases are disabled on this device."
            }
        }
    }

    @Published private(set) var products: [Product] = []
    @Published private(set) var purchasedProductIDs: Set<String> = []
    @Published private(set) var isSubscribed = false
    @Published private(set) var hasLoadedEntitlements = false
    @Published private(set) var isLoadingProducts = false

    private let productIDs: Set<String> = [Constants.weekly, Constants.yearly]
    private var transactionUpdatesTask: Task<Void, Never>?
    private var expirationTask: Task<Void, Never>?
    private var refreshGeneration = 0

    init() {
        observeTransactionUpdates()
        Task {
            await refreshEntitlements()
        }
        Task { await fetchProducts() }
    }

    deinit {
        transactionUpdatesTask?.cancel()
        expirationTask?.cancel()
    }

    func fetchProducts() async {
        guard !isLoadingProducts else { return }
        isLoadingProducts = true
        defer { isLoadingProducts = false }
        do {
            products = try await Product.products(for: productIDs)
                .sorted { $0.price < $1.price }
        } catch {}
    }

    func purchase(product: Product) async throws -> PurchaseOutcome {
        guard productIDs.contains(product.id) else {
            throw PurchaseError.productUnavailable
        }
        guard AppStore.canMakePayments else {
            throw PurchaseError.paymentsNotAllowed
        }
        switch try await product.purchase() {
        case .success(.verified(let transaction)):
            await refreshEntitlements()
            await transaction.finish()
            return .purchased
        case .success(.unverified(_, let error)):
            throw error
        case .userCancelled:
            return .cancelled
        case .pending:
            return .pending
        @unknown default:
            return .pending
        }
    }

    @discardableResult
    func restore() async throws -> Bool {
        try await AppStore.sync()
        await refreshEntitlements()
        return isSubscribed
    }

    func refreshEntitlements() async {
        refreshGeneration += 1
        let generation = refreshGeneration
        let snapshot = await Self.subscriptionSnapshot(productIDs: productIDs)

        guard generation == refreshGeneration else { return }
        purchasedProductIDs = snapshot.productIDs
        isSubscribed = !snapshot.productIDs.isEmpty
        hasLoadedEntitlements = true
        scheduleExpirationRefresh(at: snapshot.expiration)
    }

    private nonisolated struct SubscriptionSnapshot: Sendable {
        let productIDs: Set<String>
        let expiration: Date?
    }

    @concurrent
    private static func subscriptionSnapshot(productIDs: Set<String>) async -> SubscriptionSnapshot {
        var owned = Set<String>()
        var nextExpiration: Date?

        for productID in productIDs {
            guard let result = await Transaction.latest(for: productID),
                  case .verified(let latest) = result,
                  latest.revocationDate == nil,
                  !latest.isUpgraded,
                  let status = await latest.subscriptionStatus,
                  status.state == .subscribed || status.state == .inGracePeriod,
                  case .verified(let transaction) = status.transaction,
                  case .verified(let renewal) = status.renewalInfo,
                  productIDs.contains(transaction.productID),
                  transaction.productType == .autoRenewable,
                  transaction.revocationDate == nil,
                  !transaction.isUpgraded
            else { continue }

            let expiration = status.state == .inGracePeriod
                ? renewal.gracePeriodExpirationDate ?? transaction.expirationDate
                : transaction.expirationDate
            if status.state == .subscribed {
                guard let expiration, expiration > Date() else { continue }
            } else if let graceExpiration = renewal.gracePeriodExpirationDate,
                      graceExpiration <= Date() {
                continue
            }
            owned.insert(transaction.productID)
            if let expiration {
                nextExpiration = min(nextExpiration ?? expiration, expiration)
            }
        }

        return SubscriptionSnapshot(productIDs: owned, expiration: nextExpiration)
    }

    private func observeTransactionUpdates() {
        transactionUpdatesTask = Task { [weak self] in
            for await result in Transaction.updates {
                guard !Task.isCancelled, let self else { return }
                guard case .verified(let transaction) = result,
                      self.productIDs.contains(transaction.productID)
                else { continue }
                await self.refreshEntitlements()
                await transaction.finish()
            }
        }
    }

    private func scheduleExpirationRefresh(at date: Date?) {
        expirationTask?.cancel()
        expirationTask = nil
        guard let date else { return }

        let delay = date > Date() ? date.timeIntervalSinceNow + 1 : 60
        expirationTask = Task { [weak self] in
            do {
                try await Task.sleep(for: .seconds(max(1, delay)))
                guard !Task.isCancelled else { return }
                await self?.refreshEntitlements()
            } catch {
            }
        }
    }
}
