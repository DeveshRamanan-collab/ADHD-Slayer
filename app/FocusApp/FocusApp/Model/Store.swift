import Foundation
import Observation
import StoreKit

/// Focus Plus, sold only through Apple: StoreKit 2 products, Apple's own purchase sheet, Apple's trial,
/// Apple's receipts. No other payment path exists in the app or on the web.
///
/// Free plan: everything, with up to 3 day types and 5 activity categories.
/// Plus: unlimited day types and categories. First month free for anyone Apple says is eligible.
@MainActor @Observable
final class Store {
    static let productIDs = ["au.adhdslayer.focus.plus.monthly", "au.adhdslayer.focus.plus.yearly"]
    static let freeDayTypes = 3
    static let freeCategories = 5

    enum Status: Equatable { case free, trial(until: Date?), plus(renews: Date?), lapsed }

    private(set) var products: [StoreKit.Product] = []
    private(set) var status: Status = .free
    private(set) var trialEligible = true
    private(set) var loading = false
    private(set) var loadFailed = false
    /// Set from a launch argument for demos and UI tests only.
    private let forcedPlus: Bool

    var isPlus: Bool {
        if forcedPlus { return true }
        switch status {
        case .trial, .plus: return true
        case .free, .lapsed: return false
        }
    }

    var monthly: StoreKit.Product? { products.first { $0.id == Self.productIDs[0] } }
    var yearly: StoreKit.Product? { products.first { $0.id == Self.productIDs[1] } }

    init(arguments: [String] = ProcessInfo.processInfo.arguments) {
        forcedPlus = arguments.contains("-plus")
    }

    func canAddDayType(existing: Int) -> Bool { isPlus || existing < Self.freeDayTypes }
    func canAddCategory(existing: Int) -> Bool { isPlus || existing < Self.freeCategories }

    /// Starts listening for renewals, refunds and purchases made on other devices, then loads.
    func start() {
        Task { [weak self] in
            for await update in Transaction.updates {
                if case .verified(let transaction) = update { await transaction.finish() }
                await self?.refresh()
            }
        }
        Task { await refresh() }
    }

    func refresh() async {
        loading = true
        defer { loading = false }
        do {
            products = try await StoreKit.Product.products(for: Self.productIDs).sorted { $0.price < $1.price }
            loadFailed = products.isEmpty
        } catch {
            loadFailed = true
        }
        if let subscription = products.first?.subscription {
            trialEligible = await subscription.isEligibleForIntroOffer
        }
        var newStatus: Status = .free
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result, Self.productIDs.contains(transaction.productID),
                  transaction.revocationDate == nil else { continue }
            let isTrial = transaction.offer?.paymentMode == .freeTrial
            newStatus = isTrial ? .trial(until: transaction.expirationDate) : .plus(renews: transaction.expirationDate)
        }
        if newStatus == .free, case .plus = status { newStatus = .lapsed }
        status = newStatus
    }

    enum PurchaseOutcome { case purchased, pending, cancelled, failed(String) }

    /// Buys through Apple's sheet. The account's id rides along as `appAccountToken`, so the server
    /// can match App Store notifications to the right account without seeing any card details.
    func purchase(_ product: StoreKit.Product, account: UUID?) async -> PurchaseOutcome {
        do {
            var options: Set<StoreKit.Product.PurchaseOption> = []
            if let account { options.insert(.appAccountToken(account)) }
            switch try await product.purchase(options: options) {
            case .success(let verification):
                guard case .verified(let transaction) = verification else { return .failed("Apple couldn’t verify that purchase.") }
                await transaction.finish()
                await refresh()
                return .purchased
            case .pending: return .pending
            case .userCancelled: return .cancelled
            @unknown default: return .cancelled
            }
        } catch {
            return .failed("That didn’t go through. Nothing was charged.")
        }
    }

    func restore() async {
        try? await AppStore.sync()
        await refresh()
    }

    /// "1 month", "1 week": straight from Apple, so the copy can never promise the wrong trial length.
    var trialLength: String? {
        guard let offer = (monthly ?? yearly)?.subscription?.introductoryOffer, offer.paymentMode == .freeTrial else { return nil }
        let p = offer.period
        let unit = switch p.unit {
        case .day: p.value == 1 ? "day" : "days"
        case .week: p.value == 1 ? "week" : "weeks"
        case .month: p.value == 1 ? "month" : "months"
        case .year: p.value == 1 ? "year" : "years"
        @unknown default: "period"
        }
        return "\(p.value) \(unit)"
    }
}

