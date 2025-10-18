//
//  ProfileView.swift
//  MyFridge
//
//  Created by Joe Andraos on 2025-10-03.
//

import SwiftUI
import SwiftData

struct ProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var items: [Item]
    
    private var totalItemsAdded: Int {
        items.count
    }
    
    private var expiredItems: [Item] {
        items.filter { $0.isExpired }
    }
    
    private var freshItems: [Item] {
        items.filter { !$0.isExpired }
    }
    
    private var sortedItemsByDate: [Item] {
        items.sorted { $0.addedDate > $1.addedDate }
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
                    
                    // History Section
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(.blue)
                            
                            Text("History")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundStyle(.primary)
                            
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        
                        if sortedItemsByDate.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "tray")
                                    .font(.system(size: 50))
                                    .foregroundStyle(.secondary)
                                
                                Text("No items yet")
                                    .font(.system(size: 17, weight: .medium))
                                    .foregroundStyle(.secondary)
                                
                                Text("Start adding items to see your history")
                                    .font(.system(size: 14))
                                    .foregroundStyle(.tertiary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                        } else {
                            VStack(spacing: 12) {
                                ForEach(sortedItemsByDate.prefix(10)) { item in
                                    HistoryItemRow(item: item)
                                }
                            }
                            .padding(.horizontal, 20)
                            
                            if sortedItemsByDate.count > 10 {
                                Text("Showing 10 most recent items")
                                    .font(.system(size: 13))
                                    .foregroundStyle(.secondary)
                                    .padding(.top, 8)
                            }
                        }
                    }
                    .padding(.top, 8)
                    
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
                                
                                HStack(spacing: 20) {
                                    PricingOption(
                                        title: "Monthly",
                                        price: "$3",
                                        period: "/month"
                                    )
                                    
                                    PricingOption(
                                        title: "Yearly",
                                        price: "$30",
                                        period: "/year",
                                        badge: "Save $6"
                                    )
                                }
                                .padding(.top, 8)
                                
                                Button(action: {
                                    // TODO: Implement subscription flow
                                }) {
                                    Text("Coming Soon")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundStyle(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 16)
                                        .background(
                                            LinearGradient(
                                                colors: [.gray, .gray.opacity(0.8)],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .cornerRadius(12)
                                }
                                .disabled(true)
                                .padding(.horizontal, 20)
                                .padding(.top, 8)
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

// MARK: - History Item Row
struct HistoryItemRow: View {
    let item: Item
    
    var body: some View {
        HStack(spacing: 12) {
            Text(ItemEmojiHelper.emoji(for: item.name))
                .font(.system(size: 28))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.primary)
                
                Text("Added \(item.addedDate, format: .dateTime.month().day().year())")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Status badge
            HStack(spacing: 4) {
                Circle()
                    .fill(item.isExpired ? .red : .green)
                    .frame(width: 6, height: 6)
                
                Text(item.isExpired ? "Expired" : "Fresh")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(item.isExpired ? .red : .green)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill((item.isExpired ? Color.red : Color.green).opacity(0.12))
            )
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        )
    }
}

// MARK: - Pricing Option Component
struct PricingOption: View {
    let title: String
    let price: String
    let period: String
    var badge: String? = nil
    
    var body: some View {
        VStack(spacing: 8) {
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
            
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.secondary)
            
            HStack(alignment: .top, spacing: 0) {
                Text(price)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                
                Text(period)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
                    .offset(y: 4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
}

#Preview {
    ProfileView()
        .modelContainer(for: Item.self, inMemory: true)
}
