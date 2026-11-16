//
//  MyFridgeApp.swift
//  MyFridge
//
//  App entry: Login screen until signed in, then ContentView
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
