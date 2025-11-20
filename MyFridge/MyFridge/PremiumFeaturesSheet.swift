//
//  PremiumFeaturesSheet.swift
//  MyFridge
//
//  Bottom drawer showing premium features with purchase option
//

import SwiftUI
import StoreKit

struct PremiumFeaturesSheet: View {
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @Environment(\.dismiss) var dismiss
    
    let product: Product
    
    @State private var isPurchasing = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    private var isYearly: Bool {
        product.id.contains("yearly")
    }
    
    private var savings: String {
        if isYearly {
            return "Save $6 per year"
        }
        return ""
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                backgroundGradient
                
                ScrollView {
                    VStack(spacing: 32) {
                        headerSection
                        featuresGrid
                        pricingInfo
                        purchaseButton
                        termsSection
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 32)
                    .padding(.bottom, 40)
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    closeButton
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .alert("Purchase Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
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
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.yellow.opacity(0.3), .orange.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                
                Image(systemName: "crown.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.yellow, .orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            VStack(spacing: 8) {
                Text("Upgrade to Premium")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                
                Text(product.displayName)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.yellow)
                
                if !savings.isEmpty {
                    Text(savings)
                        .font(.system(size: 15))
                        .foregroundColor(.green.opacity(0.9))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color.green.opacity(0.2))
                        )
                }
            }
        }
    }
    
    private var featuresGrid: some View {
        VStack(spacing: 20) {
            PremiumFeatureCard(
                icon: "infinity",
                iconColor: .blue,
                title: "Unlimited Receipt Scans",
                description: "Scan as many receipts as you want, no limits"
            )
            
            PremiumFeatureCard(
                icon: "brain.head.profile",
                iconColor: .purple,
                title: "AI Cookbook",
                description: "Get smart recipe suggestions based on your ingredients"
            )
            
            PremiumFeatureCard(
                icon: "square.stack.3d.up.fill",
                iconColor: .orange,
                title: "Unlimited Storage",
                description: "Store unlimited items in your fridge with no restrictions"
            )
            
            PremiumFeatureCard(
                icon: "paintpalette.fill",
                iconColor: .pink,
                title: "Custom Fridge Themes",
                description: "Personalize your fridge with beautiful themes and colors"
            )
            
            PremiumFeatureCard(
                icon: "icloud.fill",
                iconColor: .cyan,
                title: "Cloud Sync",
                description: "Access your fridge from all your devices"
            )
        }
    }
    
    private var pricingInfo: some View {
        VStack(spacing: 12) {
            HStack {
                Text(product.displayPrice)
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.white)
                
                Text("/ \(product.formattedDuration)")
                    .font(.system(size: 20))
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.top, 8)
            }
            
            Text("7-day free trial included")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.green.opacity(0.9))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color.green.opacity(0.2))
                )
        }
        .padding(.vertical, 8)
    }
    
    private var purchaseButton: some View {
        Button(action: purchaseSubscription) {
            HStack {
                if isPurchasing {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("Start Free Trial")
                        .font(.system(size: 20, weight: .bold))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 1.0, green: 0.84, blue: 0.0), // Gold
                        Color(red: 0.85, green: 0.65, blue: 0.13) // Darker gold
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundColor(.white)
            .cornerRadius(16)
            .shadow(color: Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.5), radius: 10, y: 5)
        }
        .disabled(isPurchasing)
    }
    
    private var termsSection: some View {
        VStack(spacing: 8) {
            Text("After 7-day free trial: \(product.displayPrice) per \(product.formattedDuration)")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.6))
            
            Text("Auto-renews until cancelled. Cancel anytime.")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.6))
            
            Button(action: { }) {
                Text("Terms & Privacy Policy")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.8))
                    .underline()
            }
        }
        .multilineTextAlignment(.center)
    }
    
    private var closeButton: some View {
        Button(action: { dismiss() }) {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 28))
                .foregroundColor(.white.opacity(0.7))
        }
    }
    
    // MARK: - Actions
    
    private func purchaseSubscription() {
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
}

// MARK: - Premium Feature Card

struct PremiumFeatureCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(iconColor)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.7))
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding(16)
        .background(Color.white.opacity(0.1))
        .cornerRadius(16)
    }
}

// MARK: - Preview

// Preview disabled - requires actual StoreKit product
// To preview, run the app and navigate to the paywall
