//
//  ConsumeItemIntent.swift
//  MyFridge
//
//  App Intent for consuming/deleting items from widget (iOS 17+)
//

import AppIntents
import WidgetKit

@available(iOS 17.0, *)
struct ConsumeItemIntent: AppIntent {
    
    static var title: LocalizedStringResource = "Consume Item"
    static var description = IntentDescription("Mark an item as consumed and remove it from your fridge")
    
    @Parameter(title: "Item ID")
    var itemID: String
    
    @Parameter(title: "Item Name")
    var itemName: String
    
    init() {
        self.itemID = ""
        self.itemName = ""
    }
    
    init(itemID: String, itemName: String) {
        self.itemID = itemID
        self.itemName = itemName
    }
    
    func perform() async throws -> some IntentResult {
        // Delete from shared storage
        SharedDataManager.shared.consumeItem(withID: itemID)
        
        // Reload all widgets
        WidgetCenter.shared.reloadAllTimelines()
        
        print("✅ Consumed \(itemName) from widget")
        
        return .result(dialog: "\(itemName) removed from your fridge")
    }
}
