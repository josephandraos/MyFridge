//
//  SharedDataManager.swift
//  MyFridge
//
//  Manages data sharing between main app and widget via App Groups
//

import Foundation

class SharedDataManager {
    
    static let shared = SharedDataManager()
    
    /// Must match the App Group enabled on BOTH the app and widget targets
    /// (see MyFridge.entitlements and MyFridgeWidget.entitlements).
    static let appGroupID = "group.johnmorchaw.MyFridge"
    private let expiringItemsKey = "expiringItems"
    private let pendingConsumedKey = "pendingConsumedItemIDs"
    
    private var userDefaults: UserDefaults? {
        return UserDefaults(suiteName: Self.appGroupID)
    }
    
    // MARK: - Save Items for Widget
    
    /// Save widget items to shared storage (called from main app via WidgetDataUpdater)
    func saveWidgetItems(_ widgetItems: [WidgetItem]) {
        if let encoded = try? JSONEncoder().encode(widgetItems) {
            userDefaults?.set(encoded, forKey: expiringItemsKey)
            print("✅ Saved \(widgetItems.count) items to widget storage")
        } else {
            print("❌ Failed to encode items for widget")
        }
    }
    
    // MARK: - Load Items for Widget
    
    /// Load expiring items from shared storage (used by widget)
    func loadExpiringItems() -> [WidgetItem] {
        guard let data = userDefaults?.data(forKey: expiringItemsKey),
              let items = try? JSONDecoder().decode([WidgetItem].self, from: data) else {
            print("⚠️ No items found in widget storage")
            return []
        }
        
        print("✅ Loaded \(items.count) items from widget storage")
        return items
    }
    
    // MARK: - Delete Item (from Widget)
    
    /// Mark item as consumed (called from the widget process).
    /// Removes it from the widget's list right away and queues the ID so the
    /// main app can delete it from SwiftData the next time it runs.
    /// (A NotificationCenter post can't cross from the widget extension to the
    /// app, so the queue lives in the shared App Group defaults instead.)
    func consumeItem(withID itemID: String) {
        var items = loadExpiringItems()
        items.removeAll { $0.id == itemID }

        // Save updated list
        if let encoded = try? JSONEncoder().encode(items) {
            userDefaults?.set(encoded, forKey: expiringItemsKey)
        }

        // Queue for the main app to delete from SwiftData
        var pending = userDefaults?.stringArray(forKey: pendingConsumedKey) ?? []
        if !pending.contains(itemID) {
            pending.append(itemID)
            userDefaults?.set(pending, forKey: pendingConsumedKey)
        }
        print("✅ Consumed item \(itemID) from widget (queued for app)")
    }

    /// Returns and clears the IDs consumed from the widget (called from the main app)
    func takePendingConsumedIDs() -> [String] {
        let pending = userDefaults?.stringArray(forKey: pendingConsumedKey) ?? []
        if !pending.isEmpty {
            userDefaults?.removeObject(forKey: pendingConsumedKey)
        }
        return pending
    }
}

// MARK: - Widget Item Model

struct WidgetItem: Codable, Identifiable {
    let id: String
    let name: String
    let quantity: Int
    let expirationDate: Date
    let category: String
    let daysUntilExpiration: Int
    
    var isExpired: Bool {
        return daysUntilExpiration < 0
    }
    
    var isExpiringSoon: Bool {
        return daysUntilExpiration >= 0 && daysUntilExpiration <= 3
    }
    
    var emoji: String {
        // Category strings are the app's ItemCategory raw values
        // ("Dairy & Eggs", "Meat & Fish", ...), so match by keyword.
        let c = category.lowercased()
        if c.contains("dairy") { return "🥛" }
        if c.contains("meat") { return "🥩" }
        if c.contains("vegetable") { return "🥬" }
        if c.contains("fruit") { return "🍎" }
        if c.contains("drink") || c.contains("beverage") { return "🥤" }
        if c.contains("snack") { return "🍿" }
        if c.contains("bread") || c.contains("bakery") { return "🍞" }
        if c.contains("frozen") { return "🧊" }
        if c.contains("prepared") { return "🍱" }
        return "🍽️"
    }
    
    var expirationText: String {
        if isExpired {
            let days = abs(daysUntilExpiration)
            return "Expired \(days)d ago"
        } else if daysUntilExpiration == 0 {
            return "Expires today!"
        } else if daysUntilExpiration == 1 {
            return "Expires tomorrow"
        } else {
            return "Expires in \(daysUntilExpiration)d"
        }
    }
    
    var expirationColor: String {
        if isExpired {
            return "red"
        } else if daysUntilExpiration <= 1 {
            return "orange"
        } else if daysUntilExpiration <= 3 {
            return "yellow"
        } else {
            return "green"
        }
    }
}
