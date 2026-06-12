import Foundation
import StoreKit

/// Подписка Tennis Score Pro: загрузка продукта, покупка, восстановление,
/// актуальное состояние entitlement (StoreKit 2).
@Observable
@MainActor
final class StoreManager {
    static let monthlyProductID = "com.efremov.tennisscore.pro.monthly"

    /// Подписка активна.
    private(set) var isSubscribed = false
    /// Продукт из App Store (nil, пока грузится или при ошибке сети).
    private(set) var monthlyProduct: Product?
    /// Текст последней ошибки для показа в UI.
    var lastError: String?
    /// Покупка в процессе.
    private(set) var isPurchasing = false

    /// Живёт всё время работы приложения (менеджер создаётся один раз в корне).
    private var updatesTask: Task<Void, Never>?

    /// autoload=false — для demo-режимов: без сетевых запросов и ошибок в UI.
    init(autoload: Bool = true) {
        guard autoload else { return }
        updatesTask = Task { [weak self] in
            for await update in Transaction.updates {
                guard let self else { break }
                if case .verified(let transaction) = update {
                    await transaction.finish()
                }
                await self.refreshEntitlement()
            }
        }
        Task { [weak self] in
            await self?.loadProduct()
            await self?.refreshEntitlement()
        }
    }

    func loadProduct() async {
        do {
            let products = try await Product.products(for: [Self.monthlyProductID])
            monthlyProduct = products.first
        } catch {
            lastError = "Unable to load the subscription. Check your connection."
        }
    }

    func refreshEntitlement() async {
        var active = false
        for await entitlement in Transaction.currentEntitlements {
            if case .verified(let transaction) = entitlement,
               transaction.productID == Self.monthlyProductID,
               transaction.revocationDate == nil {
                active = true
            }
        }
        isSubscribed = active
    }

    /// Покупка подписки. Возвращает true при успехе.
    @discardableResult
    func purchase() async -> Bool {
        guard let product = monthlyProduct else {
            await loadProduct()
            guard monthlyProduct != nil else { return false }
            return await purchase()
        }
        isPurchasing = true
        defer { isPurchasing = false }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if case .verified(let transaction) = verification {
                    await transaction.finish()
                }
                await refreshEntitlement()
                return isSubscribed
            case .userCancelled, .pending:
                return false
            @unknown default:
                return false
            }
        } catch {
            lastError = "Purchase failed. Please try again."
            return false
        }
    }

    /// Восстановление покупок (повторная синхронизация с App Store).
    func restore() async {
        do {
            try await AppStore.sync()
        } catch {
            lastError = "Restore failed. Please try again."
        }
        await refreshEntitlement()
    }

    /// Цена для пейволла, например «$2.99».
    var priceText: String {
        monthlyProduct?.displayPrice ?? "$2.99"
    }
}
