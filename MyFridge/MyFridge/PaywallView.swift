//
//  PaywallView.swift
//  MyFridge
//
//  Premium subscription paywall - Shows subscription options and opens feature drawer
//

import SwiftUI
import StoreKit

struct PaywallView: View {
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedProduct: Product?
    @State private var showingFeatures = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                backgroundGradient
                
                ScrollView {
                    VStack(spacing: 32) {
                        headerSection
                        quickFeaturesSection
                        pricingSection
                        restoreButton
                    }
                    .padding(.bottom, 40)
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    closeButton
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(item: $selectedProduct) { product in
            PremiumFeaturesSheet(product: product)
                .environmentObject(subscriptionManager)
        }
    }
    
    // MARK: - View Components
    
    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color(red: 0.1, green: 0.2, blue: 0.45),
                Color(red: 0.2, green: 0.3, blue: 0.6)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            crownIcon
            
            Text("Upgrade to Premium")
                .font(.system(size: 34, weight: .bold))
                .foregroundColor(.white)
            
            Text("Scan as many receipts as you like")
                .font(.system(size: 17))
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(.top, 40)
    }
    
    private var crownIcon: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [.yellow.opacity(0.3), .orange.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 100, height: 100)
            
            Image(systemName: "crown.fill")
                .font(.system(size: 50))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.yellow, .orange],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
    }
    
    private var quickFeaturesSection: some View {
        VStack(spacing: 12) {
            QuickFeatureRow(icon: "infinity", title: "Unlimited Receipt Scans")
        }
        .padding(.horizontal, 24)
    }
    
    private var pricingSection: some View {
        VStack(spacing: 16) {
            Text("Choose Your Plan")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
            
            if subscriptionManager.products.isEmpty {
                ProgressView()
                    .tint(.white)
                    .padding()
            } else {
                ForEach(subscriptionManager.products.sorted(by: { $0.price < $1.price })) { product in
                    PricingCard(
                        product: product,
                        onTap: { selectedProduct = product }
                    )
                }
            }
            
            Text("Tap a plan to see details")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.6))
                .padding(.top, 8)
        }
        .padding(.horizontal)
    }
    
    private var restoreButton: some View {
        Button(action: restorePurchases) {
            Text("Restore Purchases")
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.7))
        }
        .padding(.top, 8)
    }
    
    private var closeButton: some View {
        Button(action: { dismiss() }) {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 28))
                .foregroundColor(.white.opacity(0.7))
        }
    }
    
    // MARK: - Actions
    
    private func restorePurchases() {
        Task {
            await subscriptionManager.restorePurchases()
            
            if subscriptionManager.isPremium {
                dismiss()
            }
        }
    }
}

// MARK: - Quick Feature Row

struct QuickFeatureRow: View {
    let icon: String
    let title: LocalizedStringKey
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.yellow, .orange],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 24)
            
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
            
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 20))
                .foregroundColor(.green)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Pricing Card

struct PricingCard: View {
    let product: Product
    let onTap: () -> Void
    
    private var isYearly: Bool {
        product.id.contains("yearly")
    }
    
    private var savings: LocalizedStringKey? {
        if isYearly {
            return "Save 16%"
        }
        return nil
    }
    
    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .topTrailing) {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(product.displayName)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("\(product.displayPrice) / \(product.formattedDuration)")
                            .font(.system(size: 15))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    Spacer()
                    
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.yellow)
                }
                .padding(20)
                .frame(height: 90)
                .frame(maxWidth: .infinity)
                .background(cardBackground)
                
                if let savings = savings {
                    savingsBadge(savings)
                        .offset(x: -8, y: -8)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func savingsBadge(_ text: LocalizedStringKey) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(LinearGradient(
                        colors: [.green, .green.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
            )
    }
    
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.white.opacity(0.15))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(
                            colors: [.yellow.opacity(0.5), .orange.opacity(0.5)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
            )
    }
}

// MARK: - Preview

#Preview {
    PaywallView()
        .environmentObject(SubscriptionManager())
}
