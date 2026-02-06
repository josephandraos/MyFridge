//
//  SharedDataManager.swift
//  MyFridge
//
//  Manages data sharing between main app and widget via App Groups
//

import Foundation

class SharedDataManager {
    
    static let shared = SharedDataManager()
    
    private let appGroupID = "group.com.yourname.MyFridge"
    private let expiringItemsKey = "expiringItems"
    
    private var userDefaults: UserDefaults? {
        return UserDefaults(suiteName: appGroupID)
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
    
    /// Mark item as consumed (called from widget)
    func consumeItem(withID itemID: String) {
        var items = loadExpiringItems()
        items.removeAll { $0.id == itemID }
        
        // Save updated list
        if let encoded = try? JSONEncoder().encode(items) {
            userDefaults?.set(encoded, forKey: expiringItemsKey)
            print("✅ Consumed item \(itemID) from widget")
        }
        
        // Notify app to sync (app will delete from SwiftData)
        NotificationCenter.default.post(
            name: NSNotification.Name("ItemConsumedFromWidget"),
            object: nil,
            userInfo: ["itemID": itemID]
        )
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
        // Map categories to emojis
        switch category.lowercased() {
        case "dairy": return "🥛"
        case "meat": return "🥩"
        case "vegetables": return "🥬"
        case "fruits": return "🍎"
        case "beverages": return "🥤"
        case "snacks": return "🍿"
        case "bakery": return "🍞"
        case "frozen": return "🧊"
        case "prepared": return "🍱"
        default: return "🍽️"
        }
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
