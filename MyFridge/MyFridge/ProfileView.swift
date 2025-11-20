//
//  ProfileView.swift
//  MyFridge
//
//  Updated to include clickable subscription options
//

import SwiftUI
import SwiftData
import StoreKit

struct ProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @Query private var items: [Item]
    
    @State private var selectedProduct: Product?
    @State private var showingFeatures = false
    
    private var totalItemsAdded: Int {
        items.count
    }
    
    private var expiredItems: [Item] {
        items.filter { $0.isExpired }
    }
    
    private var freshItems: [Item] {
        items.filter { !$0.isExpired }
    }
    
    private var monthlyProduct: Product? {
        subscriptionManager.products.first { $0.id.contains("monthly") }
    }
    
    private var yearlyProduct: Product? {
        subscriptionManager.products.first { $0.id.contains("yearly") }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Header
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [.blue, .blue.opacity(0.7)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 100, height: 100)
                                .shadow(color: .blue.opacity(0.3), radius: 10, y: 5)
                            
                            Image(systemName: "person.fill")
                                .font(.system(size: 45))
                                .foregroundStyle(.white)
                        }
                        
                        Text("My Profile")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)
                    }
                    .padding(.top, 20)
                    
                    // Stats Cards
                    VStack(spacing: 16) {
                        HStack(spacing: 16) {
                            StatCard(
                                title: "Total Items",
                                value: "\(totalItemsAdded)",
                                icon: "refrigerator.fill",
                                color: .blue
                            )
                            
                            StatCard(
                                title: "Fresh Items",
                                value: "\(freshItems.count)",
                                icon: "checkmark.circle.fill",
                                color: .green
                            )
                        }
                        
                        HStack(spacing: 16) {
                            StatCard(
                                title: "Expired",
                                value: "\(expiredItems.count)",
                                icon: "xmark.circle.fill",
                                color: .red
                            )
                            
                            StatCard(
                                title: "Expiring Soon",
                                value: "\(items.filter { $0.isExpiringSoon }.count)",
                                icon: "exclamationmark.triangle.fill",
                                color: .orange
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Premium/Subscription Section
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(.yellow)
                            
                            Text("Premium")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundStyle(.primary)
                            
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        
                        VStack(spacing: 16) {
                            // Premium Card
                            VStack(spacing: 16) {
                                Image(systemName: "barcode.viewfinder")
                                    .font(.system(size: 50))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.yellow, .orange],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                
                                Text("Unlimited Receipt Scans")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundStyle(.primary)
                                
                                Text("Upgrade to Premium for unlimited access to our receipt scanner feature")
                                    .font(.system(size: 15))
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 20)
                                
                                if subscriptionManager.products.isEmpty {
                                    ProgressView()
                                        .padding()
                                } else {
                                    HStack(spacing: 20) {
                                        if let monthly = monthlyProduct {
                                            PricingOptionButton(
                                                title: "Monthly",
                                                price: monthly.displayPrice,
                                                period: "/month"
                                            ) {
                                                selectedProduct = monthly
                                            }
                                        }
                                        
                                        if let yearly = yearlyProduct {
                                            PricingOptionButton(
                                                title: "Yearly",
                                                price: yearly.displayPrice,
                                                period: "/year",
                                                badge: "Save $6"
                                            ) {
                                                selectedProduct = yearly
                                            }
                                        }
                                    }
                                    .padding(.top, 8)
                                    
                                    Text("✨ Tap to unlock premium features")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundStyle(.secondary)
                                        .padding(.top, 8)
                                }
                            }
                            .padding(.vertical, 24)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color(.systemBackground))
                                    .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
                            )
                            .padding(.horizontal, 20)
                        }
                    }
                    .padding(.top, 8)
                    
                    Spacer()
                        .frame(height: 40)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .sheet(item: $selectedProduct) { product in
                PremiumFeaturesSheet(product: product)
                    .environmentObject(subscriptionManager)
            }
        }
    }
}

// MARK: - Stat Card Component
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundStyle(color)
            
            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
            
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
        )
    }
}

// MARK: - Pricing Option Button Component
struct PricingOptionButton: View {
    let title: String
    let price: String
    let period: String
    var badge: String? = nil
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                // Fixed height container for badge area
                ZStack {
                    if let badge = badge {
                        Text(badge)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(.green)
                            )
                    }
                }
                .frame(height: 22)
                
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                
                HStack(alignment: .top, spacing: 2) {
                    Text(price)
                        .font(.system(size: 32, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                    
                    Text(period)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.9))
                        .offset(y: 6)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 140) // Fixed height for both buttons
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 1.0, green: 0.84, blue: 0.0), // Gold
                                Color(red: 0.85, green: 0.65, blue: 0.13) // Darker gold
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.5), radius: 10, y: 5)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color(red: 1.0, green: 0.95, blue: 0.6),
                                Color(red: 0.85, green: 0.65, blue: 0.13)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ProfileView()
        .modelContainer(for: Item.self, inMemory: true)
        .environmentObject(SubscriptionManager())
}
