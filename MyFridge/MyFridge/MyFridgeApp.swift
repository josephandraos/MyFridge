//
//  MyFridgeApp.swift
//  MyFridge
//
//  Created by Joe Andraos on 2025-10-03.
//

import SwiftUI
import SwiftData
import UserNotifications

@main
struct MyFridgeApp: App {
    // MARK: - SwiftData Model Container
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    // MARK: - Notification Manager
    @StateObject private var notificationManager = NotificationManager.shared
    
    // MARK: - App Delegate
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    // MARK: - Scene Phase
    @Environment(\.scenePhase) private var scenePhase

    // MARK: - App Initialization
    init() {
        // Setup notification categories with actions
        NotificationManager.shared.setupNotificationCategories()
        
        // Configure app appearance
        configureAppearance()
    }

    // MARK: - Scene Definition
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(notificationManager)
                .onAppear {
                    performMaintenanceTasks()
                }
        }
        .modelContainer(sharedModelContainer)
        .onChange(of: scenePhase) { oldPhase, newPhase in
            handleScenePhaseChange(from: oldPhase, to: newPhase)
        }
    }
    
    // MARK: - Appearance Configuration
    
    private func configureAppearance() {
        // Customize navigation bar appearance if needed
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }
    
    // MARK: - Scene Phase Handling
    
    private func handleScenePhaseChange(from oldPhase: ScenePhase, to newPhase: ScenePhase) {
        switch newPhase {
        case .active:
            // App became active
            print("📱 App became active")
            // Refresh notification permission status
            Task {
                await notificationManager.checkAuthorizationStatus()
            }
            
        case .inactive:
            // App became inactive
            print("📱 App became inactive")
            
        case .background:
            // App moved to background
            print("📱 App moved to background")
            // Update app badge count
            updateBadgeCount()
            
        @unknown default:
            break
        }
    }
    
    // MARK: - Maintenance Tasks
    
    /// Perform cleanup and rescheduling on app launch
    private func performMaintenanceTasks() {
        Task { @MainActor in
            print("🔧 Starting maintenance tasks...")
            
            // Check notification permission status
            await notificationManager.checkAuthorizationStatus()
            
            // Clean up expired items and reschedule notifications
            let context = sharedModelContainer.mainContext
            let descriptor = FetchDescriptor<Item>()
            
            do {
                let items = try context.fetch(descriptor)
                print("📊 Found \(items.count) items in database")
                
                // Find expired items to clean up notifications
                let expiredItems = items.filter { $0.isExpired }
                if !expiredItems.isEmpty {
                    print("🗑️ Cleaning up \(expiredItems.count) expired items")
                    let expiredItemIds = expiredItems.map { $0.id }
                    notificationManager.cleanupNotifications(itemIds: expiredItemIds)
                }
                
                // Reschedule notifications for active items if permission is granted
                if notificationManager.notificationPermissionGranted {
                    let activeItems = items.filter { !$0.isExpired && $0.notificationScheduled }
                    print("🔔 Rescheduling notifications for \(activeItems.count) active items")
                    
                    for item in activeItems {
                        await notificationManager.scheduleNotification(
                            for: item,
                            leadTimeDays: item.customLeadTimeDays
                        )
                    }
                }
                
                // Log pending notification count
                let pendingCount = await notificationManager.getPendingNotificationCount()
                print("📊 Active notifications: \(pendingCount)")
                
                // Update badge count
                updateBadgeCount()
                
                print("✅ Maintenance tasks completed")
            } catch {
                print("❌ Error during maintenance: \(error.localizedDescription)")
            }
        }
    }
    
    /// Updates the app badge count based on expiring items
    private func updateBadgeCount() {
        Task { @MainActor in
            let context = sharedModelContainer.mainContext
            let descriptor = FetchDescriptor<Item>()
            
            do {
                let items = try context.fetch(descriptor)
                let expiringOrExpiredCount = items.filter { item in
                    item.isExpired || item.isExpiringSoon
                }.count
                
                // Update badge
                UNUserNotificationCenter.current().setBadgeCount(expiringOrExpiredCount)
                print("🔢 Updated badge count to: \(expiringOrExpiredCount)")
            } catch {
                print("❌ Error updating badge: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - App Delegate for Notification Handling
class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    // MARK: - App Launch
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        // Set the notification delegate
        UNUserNotificationCenter.current().delegate = self
        
        print("🚀 MyFridge app launched")
        return true
    }
    
    // MARK: - Notification Presentation (Foreground)
    
    /// Handle notification when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        print("🔔 Received notification while app is in foreground")
        
        // Show notification even when app is open
        if #available(iOS 14.0, *) {
            completionHandler([.banner, .sound, .badge, .list])
        } else {
            completionHandler([.alert, .sound, .badge])
        }
    }
    
    // MARK: - Notification Response Handling
    
    /// Handle notification tap and actions
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        
        print("📱 User interacted with notification - Action: \(response.actionIdentifier)")
        
        switch response.actionIdentifier {
        case "SNOOZE_ACTION":
            handleSnoozeAction(userInfo: userInfo)
            
        case "MARK_USED_ACTION":
            handleMarkUsedAction(userInfo: userInfo)
            
        case UNNotificationDefaultActionIdentifier:
            // User tapped the notification body
            handleNotificationTap(userInfo: userInfo)
            
        case UNNotificationDismissActionIdentifier:
            // User dismissed the notification
            print("🚫 Notification dismissed")
            
        default:
            print("⚠️ Unknown action identifier: \(response.actionIdentifier)")
        }
        
        completionHandler()
    }
    
    // MARK: - Action Handlers
    
    /// Handle tapping the notification
    private func handleNotificationTap(userInfo: [AnyHashable: Any]) {
        guard let itemIdString = userInfo["itemId"] as? String,
              let itemId = UUID(uuidString: itemIdString) else {
            print("⚠️ Invalid item ID in notification")
            return
        }
        
        print("📱 User tapped notification for item: \(itemId)")
        
        // Post notification to open items list
        NotificationCenter.default.post(
            name: NSNotification.Name("OpenItemsList"),
            object: nil,
            userInfo: ["itemId": itemId]
        )
    }
    
    /// Handle snooze action - reschedule for 1 day later
    private func handleSnoozeAction(userInfo: [AnyHashable: Any]) {
        guard let itemIdString = userInfo["itemId"] as? String,
              let itemId = UUID(uuidString: itemIdString) else {
            print("⚠️ Invalid item ID in snooze action")
            return
        }
        
        print("⏰ Snoozing notification for item: \(itemId)")
        
        Task { @MainActor in
            // Get model context
            guard let container = try? ModelContainer(
                for: Item.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: false)
            ) else {
                print("❌ Could not access model container")
                return
            }
            
            let context = container.mainContext
            let descriptor = FetchDescriptor<Item>(
                predicate: #Predicate { $0.id == itemId }
            )
            
            do {
                if let item = try context.fetch(descriptor).first {
                    // Reschedule notification for 1 day later
                    let calendar = Calendar.current
                    if let newNotificationDate = calendar.date(byAdding: .day, value: 1, to: Date()) {
                        await NotificationManager.shared.scheduleNotification(
                            for: item,
                            customDate: newNotificationDate
                        )
                        print("✅ Notification snoozed for 1 day")
                    }
                } else {
                    print("⚠️ Item not found for snooze action")
                }
            } catch {
                print("❌ Error handling snooze: \(error.localizedDescription)")
            }
        }
    }
    
    /// Handle mark as used action - delete the item
    private func handleMarkUsedAction(userInfo: [AnyHashable: Any]) {
        guard let itemIdString = userInfo["itemId"] as? String,
              let itemId = UUID(uuidString: itemIdString) else {
            print("⚠️ Invalid item ID in mark used action")
            return
        }
        
        print("✅ Marking item as used: \(itemId)")
        
        Task { @MainActor in
            // Get model context
            guard let container = try? ModelContainer(
                for: Item.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: false)
            ) else {
                print("❌ Could not access model container")
                return
            }
            
            let context = container.mainContext
            let descriptor = FetchDescriptor<Item>(
                predicate: #Predicate { $0.id == itemId }
            )
            
            do {
                if let item = try context.fetch(descriptor).first {
                    // Cancel notification
                    await NotificationManager.shared.cancelNotification(for: item)
                    
                    // Delete item
                    context.delete(item)
                    try context.save()
                    
                    print("✅ Item marked as used and deleted")
                    
                    // Show local notification confirming deletion
                    showConfirmationNotification(itemName: item.name)
                } else {
                    print("⚠️ Item not found for mark used action")
                }
            } catch {
                print("❌ Error handling mark used: \(error.localizedDescription)")
            }
        }
    }
    
    /// Show a confirmation notification
    private func showConfirmationNotification(itemName: String) {
        let content = UNMutableNotificationContent()
        content.title = "Item Used"
        content.body = "\(itemName) has been removed from your fridge"
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: "confirmation-\(UUID().uuidString)",
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Error showing confirmation: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Background Refresh
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        print("📱 App entered background")
        // Any cleanup or state saving can go here
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        print("📱 App will enter foreground")
        // Refresh data if needed
    }
}
