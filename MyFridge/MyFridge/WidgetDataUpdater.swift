//
//  WidgetDataUpdater.swift
//  MyFridge
//
//  Helper to update widget data when items change in main app
//

import Foundation
import SwiftData
import WidgetKit

class WidgetDataUpdater {
    
    /// Calculate days until expiration
    private static func daysUntilExpiration(for date: Date) -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let expirationDay = calendar.startOfDay(for: date)
        let components = calendar.dateComponents([.day], from: today, to: expirationDay)
        return components.day ?? 0
    }
    
    /// Call this whenever items change in the main app
    static func updateWidgetData(with items: [Item]) {
        // Filter to items expiring in next 7 days
        let expiringItems = items.filter { item in
            let days = daysUntilExpiration(for: item.expirationDate)
            return days <= 7
        }
        
        // Sort by expiration date
        let sortedItems = expiringItems.sorted { item1, item2 in
            daysUntilExpiration(for: item1.expirationDate) < daysUntilExpiration(for: item2.expirationDate)
        }
        
        // Convert to WidgetItems
        let widgetItems = sortedItems.map { item -> WidgetItem in
            WidgetItem(
                id: item.id.uuidString,
                name: item.name,
                quantity: item.quantity,
                expirationDate: item.expirationDate,
                category: item.category ?? "Other", // Provide default if nil
                daysUntilExpiration: daysUntilExpiration(for: item.expirationDate)
            )
        }
        
        // Save to shared storage
        SharedDataManager.shared.saveWidgetItems(widgetItems)
        
        // Reload all widgets
        WidgetCenter.shared.reloadAllTimelines()
        
        print("📱 Updated widget with \(widgetItems.count) expiring items")
    }
    
    /// Fetch items from SwiftData and update widget
    static func refreshWidget(modelContext: ModelContext) {
        let fetchDescriptor = FetchDescriptor<Item>(
            sortBy: [SortDescriptor(\.expirationDate)]
        )
        
        do {
            let allItems = try modelContext.fetch(fetchDescriptor)
            updateWidgetData(with: allItems)
        } catch {
            print("❌ Failed to fetch items for widget: \(error)")
        }
    }
    
    /// Handle item consumed from widget
    static func handleConsumedItem(itemID: String, modelContext: ModelContext) {
        // Find and delete the item from SwiftData
        let fetchDescriptor = FetchDescriptor<Item>()
        
        do {
            let allItems = try modelContext.fetch(fetchDescriptor)
            if let itemToDelete = allItems.first(where: { $0.id.uuidString == itemID }) {
                modelContext.delete(itemToDelete)
                try modelContext.save()
                
                print("✅ Deleted item \(itemID) from SwiftData after widget consumption")
                
                // Refresh widget with updated data
                refreshWidget(modelContext: modelContext)
            }
        } catch {
            print("❌ Failed to delete consumed item: \(error)")
        }
    }
}
