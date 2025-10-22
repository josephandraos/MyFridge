//
//  PaywallView.swift
//  MyFridge
//
//  Premium subscription paywall - FIXED for compiler
//

import SwiftUI
import StoreKit

struct PaywallView: View {
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedProduct: Product?
    @State private var isPurchasing = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                backgroundGradient
                
                ScrollView {
                    VStack(spacing: 32) {
                        headerSection
                        featuresSection
                        pricingSection
                        purchaseButtonSection
                        fineprint
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    closeButton
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .alert("Purchase Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            selectDefaultProduct()
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
            
            Text("Unlimited scans & exclusive features")
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
    
    private var featuresSection: some View {
        VStack(spacing: 16) {
            FeatureRow(
                icon: "infinity",
                title: "Unlimited Receipt Scans",
                description: "Scan as many receipts as you want"
            )
            
            FeatureRow(
                icon: "book.fill",
                title: "Smart Cookbook (Coming Soon)",
                description: "Get recipe suggestions based on your ingredients"
            )
            
            FeatureRow(
                icon: "bell.badge.fill",
                title: "Advanced Notifications",
                description: "Custom alerts for each item type"
            )
            
            FeatureRow(
                icon: "icloud.fill",
                title: "Cloud Sync (Coming Soon)",
                description: "Access your fridge from all devices"
            )
        }
        .padding(.horizontal)
    }
    
    private var pricingSection: some View {
        VStack(spacing: 16) {
            if subscriptionManager.products.isEmpty {
                ProgressView()
                    .tint(.white)
                    .padding()
            } else {
                ForEach(subscriptionManager.products.sorted(by: { $0.price < $1.price })) { product in
                    PricingCard(
                        product: product,
                        isSelected: selectedProduct?.id == product.id,
                        onTap: { selectedProduct = product }
                    )
                }
            }
        }
        .padding(.horizontal)
    }
    
    private var purchaseButtonSection: some View {
        VStack(spacing: 12) {
            Button(action: purchaseSelected) {
                purchaseButtonContent
            }
            .disabled(selectedProduct == nil || isPurchasing)
            
            Button(action: restorePurchases) {
                Text("Restore Purchases")
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.7))
            }
            .disabled(isPurchasing)
        }
        .padding(.horizontal)
    }
    
    private var purchaseButtonContent: some View {
        HStack {
            if isPurchasing {
                ProgressView()
                    .tint(.white)
            } else {
                Text(selectedProduct == nil ? "Select a Plan" : "Start Free Trial")
                    .font(.system(size: 18, weight: .bold))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(purchaseButtonBackground)
        .foregroundColor(selectedProduct == nil ? .white.opacity(0.5) : .white)
        .cornerRadius(16)
    }
    
    private var purchaseButtonBackground: some ShapeStyle {
        if selectedProduct == nil {
            return AnyShapeStyle(Color.white.opacity(0.3))
        } else {
            return AnyShapeStyle(LinearGradient(
                colors: [.yellow, .orange],
                startPoint: .leading,
                endPoint: .trailing
            ))
        }
    }
    
    private var fineprint: some View {
        VStack(spacing: 8) {
            Text("7-day free trial, then \(selectedProduct?.displayPrice ?? "$0.00") per \(selectedProduct?.formattedDuration ?? "month")")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.6))
            
            Text("Cancel anytime. Auto-renews until cancelled.")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.6))
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal)
        .padding(.bottom, 40)
    }
    
    private var closeButton: some View {
        Button(action: { dismiss() }) {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 28))
                .foregroundColor(.white.opacity(0.7))
        }
    }
    
    // MARK: - Helper Functions
    
    private func selectDefaultProduct() {
        if selectedProduct == nil, let monthlyProduct = subscriptionManager.products.first {
            selectedProduct = monthlyProduct
        }
    }
    
    private func purchaseSelected() {
        guard let product = selectedProduct else { return }
        
        isPurchasing = true
        
        Task {
            do {
                let transaction = try await subscriptionManager.purchase(product)
                
                if transaction != nil {
                    await MainActor.run {
                        dismiss()
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showingError = true
                }
            }
            
            await MainActor.run {
                isPurchasing = false
            }
        }
    }
    
    private func restorePurchases() {
        isPurchasing = true
        
        Task {
            await subscriptionManager.restorePurchases()
            
            await MainActor.run {
                isPurchasing = false
                
                if subscriptionManager.isPremium {
                    dismiss()
                } else {
                    errorMessage = "No previous purchases found"
                    showingError = true
                }
            }
        }
    }
}

// MARK: - Feature Row

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.yellow, .orange],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
        }
        .padding(16)
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Pricing Card

struct PricingCard: View {
    let product: Product
    let isSelected: Bool
    let onTap: () -> Void
    
    private var isYearly: Bool {
        product.id.contains("yearly")
    }
    
    private var savings: String? {
        if isYearly {
            return "Save 40%"
        }
        return nil
    }
    
    var body: some View {
        Button(action: onTap) {
            cardContent
        }
    }
    
    private var cardContent: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(product.displayName)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    
                    if let savings = savings {
                        savingsBadge(savings)
                    }
                }
                
                Text("\(product.displayPrice) / \(product.formattedDuration)")
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Spacer()
            
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 28))
                .foregroundColor(isSelected ? .yellow : .white.opacity(0.3))
        }
        .padding(20)
        .background(cardBackground)
    }
    
    private func savingsBadge(_ text: String) -> some View {
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
            .fill(isSelected ? Color.white.opacity(0.2) : Color.white.opacity(0.1))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(cardBorderGradient, lineWidth: isSelected ? 2 : 0)
            )
    }
    
    private var cardBorderGradient: LinearGradient {
        if isSelected {
            return LinearGradient(
                colors: [.yellow, .orange],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                colors: [.clear],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

// MARK: - Preview

#Preview {
    PaywallView()
        .environmentObject(SubscriptionManager())
}
