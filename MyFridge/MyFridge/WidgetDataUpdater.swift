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
    
    /// Full two-way sync with the widget. Call when the app becomes active, when it
    /// goes to the background, and whenever the set of items changes.
    ///  1. Deletes any items the user checked off ("consumed") from the widget
    ///  2. Pushes the current expiring items back to the widget
    @MainActor
    static func syncWithWidget(modelContext: ModelContext) {
        let consumedIDs = SharedDataManager.shared.takePendingConsumedIDs()

        if !consumedIDs.isEmpty {
            do {
                let allItems = try modelContext.fetch(FetchDescriptor<Item>())
                let consumedItems = allItems.filter { consumedIDs.contains($0.id.uuidString) }

                NotificationManager.shared.cleanupNotifications(itemIds: consumedItems.map { $0.id })
                for item in consumedItems {
                    modelContext.delete(item)
                }
                try modelContext.save()
                print("✅ Removed \(consumedItems.count) item(s) consumed from the widget")
            } catch {
                print("❌ Failed to apply widget consumption: \(error)")
            }
        }

        refreshWidget(modelContext: modelContext)
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
