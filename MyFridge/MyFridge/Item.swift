//
//  Item.swift
//  MyFridge
//
//  Created by Joe Andraos on 2025-10-03.
//

import Foundation
import SwiftData

@Model
final class Item {
    // MARK: - Core Properties
    var id: UUID
    var name: String
    var expirationDate: Date
    var addedDate: Date
    
    // MARK: - Optional Properties
    var quantity: Int
    var category: String?
    var notes: String?
    
    // MARK: - Notification Properties
    var notificationScheduled: Bool = false
    var customLeadTimeDays: Int? = nil // Optional per-item override
    var lastNotificationDate: Date? = nil // Track when last notification was sent
    
    // MARK: - Metadata
    var modifiedDate: Date
    
    // MARK: - Initializer
    init(
        name: String,
        quantity: Int = 1,
        expirationDate: Date,
        category: String? = nil,
        notes: String? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.quantity = quantity
        self.expirationDate = expirationDate
        self.addedDate = Date()
        self.modifiedDate = Date()
        self.category = category
        self.notes = notes
        self.notificationScheduled = false
        self.customLeadTimeDays = nil
        self.lastNotificationDate = nil
    }
    
    // MARK: - Computed Properties
    
    /// Returns the number of days until expiration (negative if expired)
    var daysUntilExpiry: Int {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        let startOfExpiryDate = calendar.startOfDay(for: expirationDate)
        let components = calendar.dateComponents([.day], from: startOfToday, to: startOfExpiryDate)
        return components.day ?? 0
    }
    
    /// Returns true if the item has expired
    var isExpired: Bool {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        let startOfExpiryDate = calendar.startOfDay(for: expirationDate)
        return startOfExpiryDate < startOfToday
    }
    
    /// Returns true if the item expires within 7 days (customizable)
    var isExpiringSoon: Bool {
        let days = daysUntilExpiry
        return days >= 0 && days <= 7
    }
    
    /// Returns true if the item expires today
    var isExpiringToday: Bool {
        return daysUntilExpiry == 0
    }
    
    /// Returns the expiration status as a string
    var expirationStatus: String {
        let days = daysUntilExpiry
        
        if isExpired {
            let daysExpired = abs(days)
            if daysExpired == 0 {
                return "Expired today"
            } else if daysExpired == 1 {
                return "Expired yesterday"
            } else {
                return "Expired \(daysExpired) days ago"
            }
        } else if days == 0 {
            return "Expires today"
        } else if days == 1 {
            return "Expires tomorrow"
        } else if isExpiringSoon {
            return "Expires in \(days) days"
        } else if days <= 14 {
            return "Expires in \(days) days"
        } else if days <= 30 {
            let weeks = days / 7
            return "Expires in \(weeks) week\(weeks == 1 ? "" : "s")"
        } else {
            let months = days / 30
            return "Expires in \(months) month\(months == 1 ? "" : "s")"
        }
    }
    
    /// Returns a short expiration status for compact views
    var shortExpirationStatus: String {
        let days = daysUntilExpiry
        
        if isExpired {
            return "Expired"
        } else if days == 0 {
            return "Today"
        } else if days == 1 {
            return "Tomorrow"
        } else if days <= 7 {
            return "\(days)d"
        } else {
            return "Fresh"
        }
    }
    
    /// Returns the category as ItemCategory enum
    var itemCategory: ItemCategory {
        guard let category = category else { return .snacks }
        return ItemCategory(rawValue: category) ?? .snacks
    }
    
    /// Returns the number of days the item has been stored
    var daysStored: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: addedDate, to: Date())
        return max(0, components.day ?? 0)
    }
    
    // MARK: - Helper Methods
    
    /// Updates the modified date to current date
    func updateModifiedDate() {
        self.modifiedDate = Date()
    }
    
    /// Returns true if notification should be scheduled for this item
    func shouldScheduleNotification(leadTimeDays: Int) -> Bool {
        guard !isExpired else { return false }
        let daysUntil = daysUntilExpiry
        return daysUntil >= 0 && daysUntil <= leadTimeDays + 1
    }
    
    /// Returns the date when notification should be triggered
    func notificationDate(leadTimeDays: Int) -> Date? {
        guard !isExpired else { return nil }
        
        let effectiveLeadTime = customLeadTimeDays ?? leadTimeDays
        let calendar = Calendar.current
        
        guard let notificationDate = calendar.date(
            byAdding: .day,
            value: -effectiveLeadTime,
            to: calendar.startOfDay(for: expirationDate)
        ) else {
            return nil
        }
        
        // Set notification time to 9:00 AM
        var components = calendar.dateComponents([.year, .month, .day], from: notificationDate)
        components.hour = 9
        components.minute = 0
        
        return calendar.date(from: components)
    }
}

// MARK: - Category Options (NO MORE .other!)
enum ItemCategory: String, CaseIterable, Codable {
    case dairy = "Dairy & Eggs"
    case vegetables = "Vegetables"
    case fruits = "Fruits"
    case meat = "Meat & Fish"
    case bakery = "Bread & Bakery"
    case prepared = "Prepared Foods"
    case beverages = "Drinks & Beverages"
    case snacks = "Snacks & Condiments"
    case frozen = "Frozen Foods"
    
    /// Returns an emoji representation of the category
    var emoji: String {
        switch self {
        case .dairy: return "🥛"
        case .vegetables: return "🥕"
        case .fruits: return "🍎"
        case .meat: return "🍖"
        case .bakery: return "🍞"
        case .prepared: return "🍱"
        case .beverages: return "🥤"
        case .snacks: return "🍿"
        case .frozen: return "🧊"
        }
    }
    
    /// Returns a color associated with the category
    var colorName: String {
        switch self {
        case .dairy: return "blue"
        case .vegetables: return "green"
        case .fruits: return "red"
        case .meat: return "brown"
        case .bakery: return "orange"
        case .prepared: return "purple"
        case .beverages: return "cyan"
        case .snacks: return "yellow"
        case .frozen: return "indigo"
        }
    }
}

// MARK: - Item Extensions for Sorting and Filtering

extension Item {
    /// Sorting options for items
    enum SortOption: String, CaseIterable {
        case expirationDateAscending = "Expiring Soon"
        case expirationDateDescending = "Expiring Last"
        case nameAscending = "Name A-Z"
        case nameDescending = "Name Z-A"
        case addedDateNewest = "Recently Added"
        case addedDateOldest = "Oldest First"
        case quantityAscending = "Quantity Low-High"
        case quantityDescending = "Quantity High-Low"
        
        var systemImage: String {
            switch self {
            case .expirationDateAscending: return "calendar.badge.exclamationmark"
            case .expirationDateDescending: return "calendar"
            case .nameAscending: return "textformat.abc"
            case .nameDescending: return "textformat.abc"
            case .addedDateNewest: return "clock.arrow.circlepath"
            case .addedDateOldest: return "clock"
            case .quantityAscending: return "number"
            case .quantityDescending: return "number"
            }
        }
    }
    
    /// Filter options for items
    enum FilterOption: String, CaseIterable {
        case all = "All Items"
        case expiringSoon = "Expiring Soon"
        case expired = "Expired"
        case fresh = "Fresh"
        
        var systemImage: String {
            switch self {
            case .all: return "refrigerator"
            case .expiringSoon: return "exclamationmark.triangle"
            case .expired: return "xmark.circle"
            case .fresh: return "checkmark.circle"
            }
        }
        
        func matches(item: Item) -> Bool {
            switch self {
            case .all: return true
            case .expiringSoon: return item.isExpiringSoon && !item.isExpired
            case .expired: return item.isExpired
            case .fresh: return !item.isExpiringSoon && !item.isExpired
            }
        }
    }
}
