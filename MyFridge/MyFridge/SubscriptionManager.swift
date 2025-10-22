//
//  SubscriptionManager.swift
//  MyFridge
//
//  Handles StoreKit 2 subscriptions and premium features + scan tracking
//  FIXED: Transaction ambiguity and missing await
//

import Foundation
import StoreKit
import SwiftUI

// MARK: - Subscription Product IDs
enum SubscriptionProduct: String, CaseIterable {
    case monthly = "myfridge.premium.monthly"
    case yearly = "myfridge.premium.yearly"
    
    var displayName: String {
        switch self {
        case .monthly: return "Monthly"
        case .yearly: return "Yearly"
        }
    }
}

// MARK: - Premium Features
enum PremiumFeature: String {
    case unlimitedScans = "unlimited_scans"
    case advancedNotifications = "advanced_notifications"
    case recipesSuggestions = "recipes_suggestions"
    case cloudSync = "cloud_sync"
    case customCategories = "custom_categories"
}

@MainActor
class SubscriptionManager: ObservableObject {
    // MARK: - Published Properties
    @Published var products: [Product] = []
    @Published var purchasedSubscriptions: [Product] = []
    @Published var isPremium = false
    @Published var errorMessage: String?
    
    // MARK: - Scan Tracking (Free Tier)
    @Published var scansThisMonth: Int = 0
    @Published var canScanReceipt: Bool = true
    
    private let maxFreeScans = 1 // Free users get 1 scan per month
    
    // UserDefaults keys for scan tracking
    private let scansCountKey = "scans_count"
    private let lastResetDateKey = "last_reset_date"
    
    // MARK: - Private Properties
    private var updateListenerTask: Task<Void, Error>?
    
    init() {
        // Load scan count
        loadScanCount()
        
        // Check if we need to reset monthly scans
        checkAndResetMonthlyScans()
        
        // Start transaction listener
        updateListenerTask = listenForTransactions()
        
        // Load products and check subscription status
        Task {
            await loadProducts()
            await updateSubscriptionStatus()
            updateCanScan()
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    // MARK: - Scan Management
    
    /// Check if user can scan a receipt
    func canUserScan() -> Bool {
        if isPremium {
            return true // Premium users have unlimited scans
        }
        
        return scansThisMonth < maxFreeScans
    }
    
    /// Increment scan count when user scans a receipt
    func incrementScanCount() {
        guard !isPremium else { return } // Don't track for premium users
        
        scansThisMonth += 1
        UserDefaults.standard.set(scansThisMonth, forKey: scansCountKey)
        updateCanScan()
        
        print("📊 Scan count: \(scansThisMonth)/\(maxFreeScans)")
    }
    
    /// Get remaining scans for free tier users
    func remainingScans() -> Int {
        if isPremium {
            return Int.max // Unlimited
        }
        
        return max(0, maxFreeScans - scansThisMonth)
    }
    
    /// Load scan count from UserDefaults
    private func loadScanCount() {
        scansThisMonth = UserDefaults.standard.integer(forKey: scansCountKey)
    }
    
    /// Reset scan count monthly
    private func checkAndResetMonthlyScans() {
        let lastResetTimestamp = UserDefaults.standard.double(forKey: lastResetDateKey)
        let lastResetDate = Date(timeIntervalSince1970: lastResetTimestamp)
        
        let calendar = Calendar.current
        let now = Date()
        
        // Check if we're in a new month
        if !calendar.isDate(lastResetDate, equalTo: now, toGranularity: .month) {
            // Reset scans
            scansThisMonth = 0
            UserDefaults.standard.set(scansThisMonth, forKey: scansCountKey)
            UserDefaults.standard.set(now.timeIntervalSince1970, forKey: lastResetDateKey)
            
            print("🔄 Monthly scans reset!")
        }
    }
    
    /// Update canScan based on current status
    private func updateCanScan() {
        canScanReceipt = canUserScan()
    }
    
    // MARK: - Load Products
    func loadProducts() async {
        do {
            let productIDs = SubscriptionProduct.allCases.map { $0.rawValue }
            products = try await Product.products(for: productIDs)
            print("✅ Loaded \(products.count) subscription products")
        } catch {
            errorMessage = "Failed to load products: \(error.localizedDescription)"
            print("❌ Error loading products: \(error)")
        }
    }
    
    // MARK: - Purchase Subscription
    func purchase(_ product: Product) async throws -> StoreKit.Transaction? {
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            // Verify the transaction
            let transaction = try checkVerified(verification)
            
            // Update subscription status
            await updateSubscriptionStatus()
            
            // Finish the transaction
            await transaction.finish()
            
            return transaction
            
        case .userCancelled:
            print("⚠️ User cancelled purchase")
            return nil
            
        case .pending:
            print("⏳ Purchase pending (Ask to Buy)")
            return nil
            
        @unknown default:
            return nil
        }
    }
    
    // MARK: - Restore Purchases
    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await updateSubscriptionStatus()
            print("✅ Purchases restored")
        } catch {
            errorMessage = "Failed to restore purchases: \(error.localizedDescription)"
            print("❌ Error restoring purchases: \(error)")
        }
    }
    
    // MARK: - Update Subscription Status
    func updateSubscriptionStatus() async {
        var activeSubscriptions: [Product] = []
        
        // FIX: Use StoreKit.Transaction to avoid ambiguity
        for await result in StoreKit.Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                
                // Find the product for this transaction
                if let product = products.first(where: { $0.id == transaction.productID }) {
                    activeSubscriptions.append(product)
                }
            } catch {
                print("❌ Failed to verify transaction: \(error)")
            }
        }
        
        self.purchasedSubscriptions = activeSubscriptions
        self.isPremium = !activeSubscriptions.isEmpty
        
        // Update scan availability
        updateCanScan()
        
        print(isPremium ? "✨ Premium active" : "📦 Free tier")
    }
    
    // MARK: - Check Premium Feature Access
    func hasAccess(to feature: PremiumFeature) -> Bool {
        return isPremium
    }
    
    // MARK: - Transaction Verification
    nonisolated private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
    
    // MARK: - Listen for Transactions
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            // FIX: Use StoreKit.Transaction to avoid ambiguity
            for await result in StoreKit.Transaction.updates {
                do {
                    let transaction = try self.checkVerified(result)
                    await self.updateSubscriptionStatus()
                    // FIX: Added await for transaction.finish()
                    await transaction.finish()
                } catch {
                    print("❌ Transaction verification failed: \(error)")
                }
            }
        }
    }
    
    // MARK: - Show Manage Subscriptions
    func showManageSubscriptions() async {
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            do {
                try await AppStore.showManageSubscriptions(in: scene)
            } catch {
                errorMessage = "Failed to show subscriptions: \(error.localizedDescription)"
            }
        }
    }
}

// MARK: - Store Error
enum StoreError: Error {
    case failedVerification
}

// MARK: - Product Extensions
extension Product {
    var formattedDuration: String {
        guard let subscription = subscription else { return "" }
        let unit = subscription.subscriptionPeriod.unit
        let value = subscription.subscriptionPeriod.value
        
        switch unit {
        case .day:
            return value == 1 ? "day" : "\(value) days"
        case .week:
            return value == 1 ? "week" : "\(value) weeks"
        case .month:
            return value == 1 ? "month" : "\(value) months"
        case .year:
            return value == 1 ? "year" : "\(value) years"
        @unknown default:
            return ""
        }
    }
}
