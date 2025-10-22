//
//  MyFridgeApp.swift
//  MyFridge
//
//  Fixed to show ContentView with fridge icon after login
//

import SwiftUI
import SwiftData

@main
struct MyFridgeApp: App {
    // MARK: - State Objects
    @StateObject private var authManager = AuthenticationManager()
    @StateObject private var subscriptionManager = SubscriptionManager()
    @StateObject private var notificationManager = NotificationManager.shared
    
    var body: some Scene {
        WindowGroup {
            // Show login screen if not authenticated, otherwise show main app
            if authManager.isAuthenticated {
                ContentView()
                    .environmentObject(authManager)
                    .environmentObject(subscriptionManager)
                    .environmentObject(notificationManager)
                    .modelContainer(for: Item.self)
            } else {
                LoginView()
                    .environmentObject(authManager)
            }
        }
    }
}
// MARK: - Main App View (Authenticated Users)
struct MainAppView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]
    
    @State private var showingPaywall = false
    @State private var showingSettings = false
    
    var body: some View {
        NavigationView {
            VStack {
                // Premium banner if not subscribed
                if !subscriptionManager.isPremium {
                    PremiumBanner {
                        showingPaywall = true
                    }
                }
                
                // Your existing MyFridge content here
                // (Your item list, add button, scanner, etc.)
                ItemListView(items: items)
                
                Spacer()
            }
            .navigationTitle("MyFridge")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    // Premium badge
                    if subscriptionManager.isPremium {
                        HStack(spacing: 4) {
                            Image(systemName: "crown.fill")
                                .font(.caption)
                            Text("Premium")
                                .font(.caption.bold())
                        }
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.yellow, .orange],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                    }
                }
            }
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
            .sheet(isPresented: $showingSettings) {
                CombinedSettingsView()
            }
        }
    }
}

// MARK: - Premium Banner
struct PremiumBanner: View {
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: "crown.fill")
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.yellow, .orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Try Premium Free")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("Unlimited scans & exclusive features")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }
}

// MARK: - Item List View (Placeholder - use your existing design)
struct ItemListView: View {
    let items: [Item]
    
    var body: some View {
        List(items) { item in
            VStack(alignment: .leading) {
                Text(item.name)
                    .font(.headline)
                Text("Expires: \(item.expirationDate, style: .date)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Combined Settings View (Account + Notifications)
struct CombinedSettingsView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @EnvironmentObject var notificationManager: NotificationManager
    @Environment(\.dismiss) var dismiss
    
    @State private var showingPaywall = false
    
    var body: some View {
        NavigationStack {
            List {
                // Account Section
                Section("Account") {
                    if let userName = authManager.userName {
                        HStack {
                            Text("Name")
                            Spacer()
                            Text(userName)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if let userEmail = authManager.userEmail {
                        HStack {
                            Text("Email")
                            Spacer()
                            Text(userEmail)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                }
                
                // Subscription Section
                Section("Subscription") {
                    if subscriptionManager.isPremium {
                        HStack {
                            Image(systemName: "crown.fill")
                                .foregroundColor(.yellow)
                            Text("Premium Active")
                                .foregroundColor(.green)
                        }
                        
                        Button("Manage Subscription") {
                            Task {
                                await subscriptionManager.showManageSubscriptions()
                            }
                        }
                    } else {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Free Tier")
                                    .font(.headline)
                                Text("\(subscriptionManager.remainingScans()) scan\(subscriptionManager.remainingScans() == 1 ? "" : "s") remaining this month")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        
                        Button("Upgrade to Premium") {
                            showingPaywall = true
                        }
                    }
                }
                
                // Notifications Settings Section
                Section("Notifications") {
                    NavigationLink {
                        SettingsView() // This is your existing notification settings
                    } label: {
                        HStack {
                            Image(systemName: "bell.fill")
                                .foregroundColor(.blue)
                            Text("Notification Preferences")
                        }
                    }
                }
                
                // Sign Out
                Section {
                    Button("Sign Out", role: .destructive) {
                        authManager.signOut()
                        dismiss()
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
        }
    }
}
