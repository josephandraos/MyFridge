//
//  MyFridgeWidget.swift
//  MyFridgeWidget
//
//  Interactive widget showing expiring items with swipe-to-consume
//

import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Timeline Provider

struct ExpiringItemsProvider: TimelineProvider {
    
    func placeholder(in context: Context) -> ExpiringItemsEntry {
        ExpiringItemsEntry(date: Date(), items: sampleItems())
    }
    
    func getSnapshot(in context: Context, completion: @escaping (ExpiringItemsEntry) -> Void) {
        let items = context.isPreview ? sampleItems() : SharedDataManager.shared.loadExpiringItems()
        let entry = ExpiringItemsEntry(date: Date(), items: items)
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<ExpiringItemsEntry>) -> Void) {
        // Load items from shared storage
        let items = SharedDataManager.shared.loadExpiringItems()
        
        // Create entry
        let entry = ExpiringItemsEntry(date: Date(), items: items)
        
        // Refresh every hour
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        
        completion(timeline)
    }
    
    // Sample data for preview
    private func sampleItems() -> [WidgetItem] {
        return [
            WidgetItem(id: "1", name: "Milk", quantity: 1, expirationDate: Date().addingTimeInterval(86400), category: "Dairy", daysUntilExpiration: 1),
            WidgetItem(id: "2", name: "Chicken Breast", quantity: 2, expirationDate: Date().addingTimeInterval(172800), category: "Meat", daysUntilExpiration: 2),
            WidgetItem(id: "3", name: "Lettuce", quantity: 1, expirationDate: Date(), category: "Vegetables", daysUntilExpiration: 0)
        ]
    }
}

// MARK: - Timeline Entry

struct ExpiringItemsEntry: TimelineEntry {
    let date: Date
    let items: [WidgetItem]
    
    var expiringItems: [WidgetItem] {
        // Show items expiring in next 3 days, sorted by expiration
        return items
            .filter { $0.daysUntilExpiration <= 3 }
            .sorted { $0.daysUntilExpiration < $1.daysUntilExpiration }
    }
}

// MARK: - Widget Entry View

struct MyFridgeWidgetEntryView: View {
    var entry: ExpiringItemsProvider.Entry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(items: entry.expiringItems)
        case .systemMedium:
            MediumWidgetView(items: entry.expiringItems)
        case .systemLarge:
            LargeWidgetView(items: entry.expiringItems)
        default:
            SmallWidgetView(items: entry.expiringItems)
        }
    }
}

// MARK: - Small Widget (1-2 items)

struct SmallWidgetView: View {
    let items: [WidgetItem]
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            VStack(alignment: .leading, spacing: 8) {
                // Header
                HStack {
                    Image(systemName: "refrigerator.fill")
                        .font(.title3)
                    Text("MyFridge")
                        .font(.headline)
                        .fontWeight(.bold)
                }
                .foregroundStyle(.white)
                
                Spacer()
                
                if items.isEmpty {
                    Text("All good! 🎉")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                } else {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(items.prefix(2)) { item in
                            HStack(spacing: 6) {
                                Text(item.emoji)
                                    .font(.title2)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.name)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .lineLimit(1)
                                    
                                    Text(item.expirationText)
                                        .font(.caption2)
                                        .foregroundStyle(.white.opacity(0.8))
                                }
                                .foregroundStyle(.white)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                
                if items.count > 2 {
                    Text("+\(items.count - 2) more")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            .padding()
        }
    }
}

// MARK: - Medium Widget (3-4 items with actions)

struct MediumWidgetView: View {
    let items: [WidgetItem]
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    Image(systemName: "refrigerator.fill")
                        .font(.title3)
                    Text("Expiring Soon")
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    Text("\(items.count)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                }
                .foregroundStyle(.white)
                
                if items.isEmpty {
                    Spacer()
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            Text("🎉")
                                .font(.system(size: 48))
                            Text("Nothing expiring soon!")
                                .font(.subheadline)
                                .foregroundStyle(.white)
                        }
                        Spacer()
                    }
                    Spacer()
                } else {
                    VStack(spacing: 6) {
                        ForEach(items.prefix(3)) { item in
                            WidgetItemRow(item: item)
                        }
                    }
                    
                    if items.count > 3 {
                        Text("+ \(items.count - 3) more items")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                            .padding(.top, 4)
                    }
                }
            }
            .padding()
        }
    }
}

// MARK: - Large Widget (full list with actions)

struct LargeWidgetView: View {
    let items: [WidgetItem]
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    Image(systemName: "refrigerator.fill")
                        .font(.title2)
                    Text("Expiring Soon")
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    if !items.isEmpty {
                        Text("\(items.count)")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                    }
                }
                .foregroundStyle(.white)
                
                if items.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Text("🎉")
                            .font(.system(size: 64))
                        Text("Nothing expiring soon!")
                            .font(.title3)
                            .fontWeight(.semibold)
                        Text("Your fridge is well stocked")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(items.prefix(8)) { item in
                                WidgetItemRow(item: item)
                            }
                        }
                    }
                    
                    if items.count > 8 {
                        Text("+ \(items.count - 8) more items")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
            }
            .padding()
        }
    }
}

// MARK: - Widget Item Row with Button

struct WidgetItemRow: View {
    let item: WidgetItem
    
    var body: some View {
        HStack(spacing: 10) {
            // Emoji
            Text(item.emoji)
                .font(.title2)
            
            // Item details
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                    .foregroundStyle(.white)
                
                HStack(spacing: 4) {
                    Text(item.expirationText)
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.8))
                    
                    if item.quantity > 1 {
                        Text("• Qty: \(item.quantity)")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }
            }
            
            Spacer()
            
            // Consume button
            if #available(iOS 17.0, *) {
                Button(intent: ConsumeItemIntent(itemID: item.id, itemName: item.name)) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.white)
                        .opacity(0.8)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(.white.opacity(0.15))
        )
    }
}

// MARK: - Widget Configuration

@main
struct MyFridgeWidget: Widget {
    let kind: String = "MyFridgeWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ExpiringItemsProvider()) { entry in
            MyFridgeWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("MyFridge")
        .description("Quick view of items expiring soon")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Preview

#Preview(as: .systemMedium) {
    MyFridgeWidget()
} timeline: {
    ExpiringItemsEntry(
        date: .now,
        items: [
            WidgetItem(id: "1", name: "Milk", quantity: 1, expirationDate: Date().addingTimeInterval(86400), category: "Dairy", daysUntilExpiration: 1),
            WidgetItem(id: "2", name: "Chicken", quantity: 2, expirationDate: Date().addingTimeInterval(172800), category: "Meat", daysUntilExpiration: 2),
            WidgetItem(id: "3", name: "Lettuce", quantity: 1, expirationDate: Date(), category: "Vegetables", daysUntilExpiration: 0)
        ]
    )
}
