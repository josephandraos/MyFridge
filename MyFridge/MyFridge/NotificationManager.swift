//
//  NotificationManager.swift
//  MyFridge
//
//  Created for MyFridge notification system
//

import Foundation
import UserNotifications
import SwiftData
import UIKit

@MainActor
class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    // MARK: - Published Properties
    @Published var notificationPermissionGranted = false
    @Published var defaultLeadTimeDays = 3
    @Published var useDailyDigest = false
    @Published var digestTime = DateComponents(hour: 9, minute: 0) // 9:00 AM
    @Published var notificationStatus: UNAuthorizationStatus = .notDetermined
    
    // MARK: - Private Properties
    private let center = UNUserNotificationCenter.current()
    private let dailyDigestIdentifier = "daily-digest-notification"
    
    // UserDefaults keys
    private let permissionAskedKey = "notificationPermissionAsked"
    private let leadTimeDaysKey = "defaultLeadTimeDays"
    private let useDailyDigestKey = "useDailyDigest"
    private let digestHourKey = "digestHour"
    private let digestMinuteKey = "digestMinute"
    
    // MARK: - Initialization
    private init() {
        loadSettings()
        // Check auth status on next run loop to avoid async in init
        Task { @MainActor in
            await self.checkAuthorizationStatus()
        }
    }
    
    // MARK: - Permission Management
    
    /// Check if we've already asked for permission
    var hasAskedForPermission: Bool {
        UserDefaults.standard.bool(forKey: permissionAskedKey)
    }
    
    /// Request notification permission with proper explanation
    func requestPermission(completion: @escaping (Bool) -> Void) {
        center.requestAuthorization(options: [.alert, .badge, .sound, .criticalAlert]) { [weak self] granted, error in
            Task { @MainActor in
                guard let self = self else { return }
                
                self.notificationPermissionGranted = granted
                UserDefaults.standard.set(true, forKey: self.permissionAskedKey)
                
                if granted {
                    print("✅ Notification permission granted")
                    await self.checkAuthorizationStatus()
                } else if let error = error {
                    print("❌ Notification permission error: \(error.localizedDescription)")
                } else {
                    print("⚠️ Notification permission denied by user")
                }
                
                completion(granted)
            }
        }
    }
    
    /// Check current authorization status
    func checkAuthorizationStatus() async {
        let settings = await center.notificationSettings()
        notificationStatus = settings.authorizationStatus
        notificationPermissionGranted = settings.authorizationStatus == .authorized
        
        print("🔔 Notification status: \(settings.authorizationStatus.description)")
    }
    
    /// Open iOS Settings app to notification settings
    func openNotificationSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else { return }
        
        if UIApplication.shared.canOpenURL(settingsUrl) {
            UIApplication.shared.open(settingsUrl)
        }
    }
    
    // MARK: - Settings Management
    
    private func loadSettings() {
        // Load lead time days
        let savedLeadTime = UserDefaults.standard.integer(forKey: leadTimeDaysKey)
        defaultLeadTimeDays = savedLeadTime > 0 ? savedLeadTime : 3
        
        // Load daily digest preference
        useDailyDigest = UserDefaults.standard.bool(forKey: useDailyDigestKey)
        
        // Load digest time
        let hour = UserDefaults.standard.integer(forKey: digestHourKey)
        let minute = UserDefaults.standard.integer(forKey: digestMinuteKey)
        if hour > 0 || minute > 0 {
            digestTime = DateComponents(hour: hour, minute: minute)
        }
    }
    
    func saveSettings() {
        UserDefaults.standard.set(defaultLeadTimeDays, forKey: leadTimeDaysKey)
        UserDefaults.standard.set(useDailyDigest, forKey: useDailyDigestKey)
        UserDefaults.standard.set(digestTime.hour ?? 9, forKey: digestHourKey)
        UserDefaults.standard.set(digestTime.minute ?? 0, forKey: digestMinuteKey)
        
        print("💾 Settings saved - Lead time: \(defaultLeadTimeDays) days, Digest: \(useDailyDigest)")
        
        // Reschedule notifications with new settings
        Task {
            await rescheduleAllNotifications()
        }
    }
    
    // MARK: - Notification Scheduling
    
    /// Schedule notification for a single item
    func scheduleNotification(
        for item: Item,
        leadTimeDays: Int? = nil,
        customDate: Date? = nil
    ) async {
        guard notificationPermissionGranted else {
            print("⚠️ Cannot schedule notification - permission not granted")
            return
        }
        
        // Cancel existing notification if any
        await cancelNotification(for: item)
        
        // Don't schedule if already expired
        guard !item.isExpired else {
            print("⚠️ Item \(item.name) is already expired - skipping notification")
            return
        }
        
        // Use custom date if provided, otherwise calculate from lead time
        let notificationDate: Date
        if let customDate = customDate {
            notificationDate = customDate
        } else {
            let lead = leadTimeDays ?? item.customLeadTimeDays ?? defaultLeadTimeDays
            
            guard let calculatedDate = Calendar.current.date(
                byAdding: .day,
                value: -lead,
                to: Calendar.current.startOfDay(for: item.expirationDate)
            ) else {
                print("❌ Could not calculate notification date for \(item.name)")
                return
            }
            
            // Set notification time to digest time (default 9:00 AM)
            var components = Calendar.current.dateComponents([.year, .month, .day], from: calculatedDate)
            components.hour = digestTime.hour ?? 9
            components.minute = digestTime.minute ?? 0
            
            guard let finalDate = Calendar.current.date(from: components) else {
                print("❌ Could not create final notification date for \(item.name)")
                return
            }
            
            notificationDate = finalDate
        }
        
        // Don't schedule if notification date is in the past
        guard notificationDate > Date() else {
            print("⚠️ Notification date is in the past for \(item.name) - skipping")
            return
        }
        
        if useDailyDigest {
            // Daily digest will handle individual item notifications
            await scheduleDailyDigest()
            print("📊 Using daily digest for \(item.name)")
        } else {
            // Schedule individual notification
            let lead = leadTimeDays ?? item.customLeadTimeDays ?? defaultLeadTimeDays
            let daysText = lead == 1 ? "day" : "days"
            
            let content = UNMutableNotificationContent()
            content.title = "🍽️ Item Expiring Soon"
            content.body = "\(item.name) expires in \(lead) \(daysText)"
            content.sound = .default
            // Removed: content.badge = NSNumber(value: 1)
            content.categoryIdentifier = "EXPIRY_REMINDER"
            content.userInfo = [
                "itemId": item.id.uuidString,
                "itemName": item.name,
                "expirationDate": item.expirationDate.timeIntervalSince1970
            ]
            
            // Add thread identifier for grouping
            content.threadIdentifier = "expiry-reminders"
            
            // Add subtitle with category if available
            if let category = item.category {
                content.subtitle = category
            }
            
            let components = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: notificationDate
            )
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            
            let identifier = "item-\(item.id.uuidString)"
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            
            do {
                try await center.add(request)
                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .medium
                dateFormatter.timeStyle = .short
                print("✅ Scheduled notification for \(item.name) at \(dateFormatter.string(from: notificationDate))")
            } catch {
                print("❌ Error scheduling notification for \(item.name): \(error.localizedDescription)")
            }
        }
    }
    
    /// Cancel notification for a specific item
    func cancelNotification(for item: Item) async {
        let identifier = "item-\(item.id.uuidString)"
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        print("🗑️ Cancelled notification for \(item.name)")
    }
    
    /// Schedule daily digest notification
    func scheduleDailyDigest() async {
        guard notificationPermissionGranted else {
            print("⚠️ Cannot schedule daily digest - permission not granted")
            return
        }
        
        // Cancel existing digest
        center.removePendingNotificationRequests(withIdentifiers: [dailyDigestIdentifier])
        
        let content = UNMutableNotificationContent()
        content.title = "🍽️ MyFridge Daily Digest"
        content.body = "Check your fridge for items expiring soon"
        content.sound = .default
        // Removed: content.badge = NSNumber(value: 1)
        content.categoryIdentifier = "DAILY_DIGEST"
        content.threadIdentifier = "daily-digest"
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: digestTime, repeats: true)
        let request = UNNotificationRequest(identifier: dailyDigestIdentifier, content: content, trigger: trigger)
        
        do {
            try await center.add(request)
            let hour = digestTime.hour ?? 9
            let minute = digestTime.minute ?? 0
            print("✅ Scheduled daily digest at \(String(format: "%02d:%02d", hour, minute))")
        } catch {
            print("❌ Error scheduling daily digest: \(error.localizedDescription)")
        }
    }
    
    /// Cancel daily digest notification
    func cancelDailyDigest() async {
        center.removePendingNotificationRequests(withIdentifiers: [dailyDigestIdentifier])
        print("🗑️ Cancelled daily digest")
    }
    
    /// Reschedule all notifications (call after settings change)
    func rescheduleAllNotifications() async {
        center.removeAllPendingNotificationRequests()
        print("♻️ Cleared all pending notifications - ready to reschedule")
        
        if useDailyDigest {
            await scheduleDailyDigest()
        }
    }
    
    // MARK: - Notification Actions & Categories
    
    /// Setup notification categories with actions
    func setupNotificationCategories() {
        let snoozeAction = UNNotificationAction(
            identifier: "SNOOZE_ACTION",
            title: "Snooze 1 Day",
            options: []
        )
        
        let markUsedAction = UNNotificationAction(
            identifier: "MARK_USED_ACTION",
            title: "Mark as Used",
            options: [.destructive, .authenticationRequired]
        )
        
        let expiryCategory = UNNotificationCategory(
            identifier: "EXPIRY_REMINDER",
            actions: [snoozeAction, markUsedAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        
        let digestCategory = UNNotificationCategory(
            identifier: "DAILY_DIGEST",
            actions: [],
            intentIdentifiers: [],
            options: []
        )
        
        center.setNotificationCategories([expiryCategory, digestCategory])
        print("✅ Notification categories configured")
    }
    
    // MARK: - Cleanup & Utilities
    
    /// Remove notifications for deleted/used items
    func cleanupNotifications(itemIds: [UUID]) {
        let identifiers = itemIds.map { "item-\($0.uuidString)" }
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
        print("🧹 Cleaned up \(identifiers.count) notification(s)")
    }
    
    /// Remove all pending notifications
    func removeAllNotifications() async {
        center.removeAllPendingNotificationRequests()
        print("🗑️ Removed all pending notifications")
    }
    
    /// Get count of pending notifications
    func getPendingNotificationCount() async -> Int {
        let requests = await center.pendingNotificationRequests()
        return requests.count
    }
    
    /// Get all pending notification requests (for debugging)
    func getPendingNotifications() async -> [UNNotificationRequest] {
        return await center.pendingNotificationRequests()
    }
    
    /// Get detailed info about pending notifications
    func logPendingNotifications() async {
        let requests = await center.pendingNotificationRequests()
        print("📋 Pending Notifications (\(requests.count)):")
        
        for request in requests {
            print("  - \(request.identifier)")
            if let trigger = request.trigger as? UNCalendarNotificationTrigger,
               let nextTriggerDate = trigger.nextTriggerDate() {
                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .medium
                dateFormatter.timeStyle = .short
                print("    Scheduled for: \(dateFormatter.string(from: nextTriggerDate))")
            }
        }
    }
    
    /// Reset all notification settings (useful for debugging)
    func resetNotificationSettings() {
        UserDefaults.standard.removeObject(forKey: permissionAskedKey)
        UserDefaults.standard.removeObject(forKey: leadTimeDaysKey)
        UserDefaults.standard.removeObject(forKey: useDailyDigestKey)
        UserDefaults.standard.removeObject(forKey: digestHourKey)
        UserDefaults.standard.removeObject(forKey: digestMinuteKey)
        
        defaultLeadTimeDays = 3
        useDailyDigest = false
        digestTime = DateComponents(hour: 9, minute: 0)
        
        Task {
            await removeAllNotifications()
        }
        
        print("🔄 Reset all notification settings to defaults")
    }
    
    // MARK: - Badge Management
    
    /// Update app badge count
    func updateBadgeCount(_ count: Int) {
        center.setBadgeCount(count) { error in
            if let error = error {
                print("❌ Error updating badge: \(error.localizedDescription)")
            } else {
                print("🔢 Badge count updated to: \(count)")
            }
        }
    }
    
    /// Clear app badge
    func clearBadge() {
        updateBadgeCount(0)
    }
}

// MARK: - UNAuthorizationStatus Extension

extension UNAuthorizationStatus {
    var description: String {
        switch self {
        case .notDetermined:
            return "Not Determined"
        case .denied:
            return "Denied"
        case .authorized:
            return "Authorized"
        case .provisional:
            return "Provisional"
        case .ephemeral:
            return "Ephemeral"
        @unknown default:
            return "Unknown"
        }
    }
    
    var isAuthorized: Bool {
        return self == .authorized || self == .provisional
    }
}

// MARK: - Notification Helper Extensions

extension NotificationManager {
    /// Schedule notifications for multiple items
    func scheduleNotifications(for items: [Item]) async {
        print("📅 Scheduling notifications for \(items.count) items...")
        
        var successCount = 0
        
        for item in items {
            guard !item.isExpired else {
                print("⏭️ Skipping expired item: \(item.name)")
                continue
            }
            
            await scheduleNotification(for: item)
            successCount += 1
        }
        
        let pendingCount = await getPendingNotificationCount()
        print("✅ Scheduled \(successCount) notifications. Total pending: \(pendingCount)")
    }
    
    /// Cancel notifications for multiple items
    func cancelNotifications(for items: [Item]) async {
        print("🗑️ Cancelling notifications for \(items.count) items...")
        
        for item in items {
            await cancelNotification(for: item)
        }
        
        let pendingCount = await getPendingNotificationCount()
        print("✅ Cancelled notifications. Remaining pending: \(pendingCount)")
    }
    
    /// Test notification (for debugging)
    func sendTestNotification() async {
        let content = UNMutableNotificationContent()
        content.title = "🧪 Test Notification"
        content.body = "MyFridge notifications are working!"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(
            identifier: "test-notification-\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        
        do {
            try await center.add(request)
            print("✅ Test notification scheduled (will appear in 5 seconds)")
        } catch {
            print("❌ Error sending test notification: \(error.localizedDescription)")
        }
    }
}
