//
//  ReceiptParser.swift
//  MyFridge
//
//  Receipt parsing logic for scanning grocery receipts
//

import Foundation

struct ReceiptParser {
    
    // MARK: - Whitelist of Recognized Food Items
    // Only items in this list will be detected by the scanner!
    
    private static let recognizedFoods: [(name: String, category: ItemCategory, keywords: [String])] = [
        // DAIRY & EGGS
        ("Milk", .dairy, ["milk", "lait", "whole milk", "skim milk", "2%", "1%"]),
        ("Butter", .dairy, ["butter", "beurre"]),
        ("Cheese", .dairy, ["cheese", "fromage", "cheddar", "mozzarella", "parmesan", "swiss"]),
        ("Ice Cream", .dairy, ["ice cream", "crème glacée", "gelato"]),
        ("Eggs", .dairy, ["egg", "eggs", "oeuf", "oeufs"]),
        ("Yogurt", .dairy, ["yogurt", "yogourt", "yoghurt"]),
        ("Cream", .dairy, ["cream", "crème", "heavy cream", "whipping cream"]),
        
        // MEAT & FISH
        ("Chicken", .meat, ["chicken", "poulet"]),
        ("Beef", .meat, ["beef", "boeuf", "steak"]),
        ("Bacon", .meat, ["bacon"]),
        ("Pork", .meat, ["pork", "porc", "rib", "ribs"]),
        ("Fish", .meat, ["fish", "poisson"]),
        ("Salmon", .meat, ["salmon", "saumon"]),
        ("Tuna", .meat, ["tuna", "thon"]),
        ("Shrimp", .meat, ["shrimp", "prawn", "crevette"]),
        ("Turkey", .meat, ["turkey", "dinde"]),
        ("Ham", .meat, ["ham", "jambon"]),
        ("Sausage", .meat, ["sausage", "saucisse"]),
        
        // FRUITS
        ("Apple", .fruits, ["apple", "pomme"]),
        ("Banana", .fruits, ["banana", "banane"]),
        ("Strawberry", .fruits, ["strawberry", "strawberries", "fraise"]),
        ("Grape", .fruits, ["grape", "grapes", "raisin"]),
        ("Orange", .fruits, ["orange"]),
        ("Watermelon", .fruits, ["watermelon", "melon d'eau"]),
        ("Lemon", .fruits, ["lemon", "citron"]),
        ("Peach", .fruits, ["peach", "pêche"]),
        ("Cherry", .fruits, ["cherry", "cherries", "cerise"]),
        ("Pear", .fruits, ["pear", "poire"]),
        ("Pineapple", .fruits, ["pineapple", "ananas"]),
        ("Mango", .fruits, ["mango", "mangue"]),
        ("Kiwi", .fruits, ["kiwi"]),
        ("Avocado", .fruits, ["avocado", "avocat"]),
        ("Blueberry", .fruits, ["blueberry", "blueberries", "bleuet"]),
        ("Raspberry", .fruits, ["raspberry", "raspberries", "framboise"]),
        
        // VEGETABLES
        ("Carrot", .vegetables, ["carrot", "carrots", "carotte"]),
        ("Cucumber", .vegetables, ["cucumber", "concombre"]),
        ("Tomato", .vegetables, ["tomato", "tomatoes", "tomate"]),
        ("Lettuce", .vegetables, ["lettuce", "laitue", "salad", "salade"]),
        ("Corn", .vegetables, ["corn", "maïs"]),
        ("Broccoli", .vegetables, ["broccoli", "brocoli"]),
        ("Garlic", .vegetables, ["garlic", "ail"]),
        ("Onion", .vegetables, ["onion", "oignon"]),
        ("Potato", .vegetables, ["potato", "potatoes", "pomme de terre"]),
        ("Mushroom", .vegetables, ["mushroom", "champignon"]),
        ("Pepper", .vegetables, ["pepper", "peppers", "bell pepper", "poivron"]),
        ("Eggplant", .vegetables, ["eggplant", "aubergine"]),
        ("Spinach", .vegetables, ["spinach", "épinard"]),
        ("Celery", .vegetables, ["celery", "céleri"]),
        
        // BREAD & BAKERY
        ("Bread", .bakery, ["bread", "pain"]),
        ("Croissant", .bakery, ["croissant"]),
        ("Baguette", .bakery, ["baguette"]),
        ("Bagel", .bakery, ["bagel"]),
        ("Muffin", .bakery, ["muffin"]),
        ("Cookie", .bakery, ["cookie", "cookies", "biscuit"]),
        ("Cake", .bakery, ["cake", "gâteau"]),
        ("Donut", .bakery, ["donut", "doughnut", "beignet"]),
        ("Pretzel", .bakery, ["pretzel"]),
        ("Roll", .bakery, ["roll", "rolls"]),
        
        // PREPARED FOODS
        ("Pizza", .prepared, ["pizza"]),
        ("Burger", .prepared, ["burger", "hamburger"]),
        ("Sandwich", .prepared, ["sandwich"]),
        ("Hot Dog", .prepared, ["hot dog", "hotdog"]),
        ("Taco", .prepared, ["taco"]),
        ("Burrito", .prepared, ["burrito"]),
        ("Pasta", .prepared, ["pasta", "pâtes", "spaghetti"]),
        ("Curry", .prepared, ["curry"]),
        ("Sushi", .prepared, ["sushi"]),
        ("Ramen", .prepared, ["ramen", "noodle", "nouille"]),
        ("Rice", .prepared, ["rice", "riz"]),
        ("Wrap", .prepared, ["wrap"]),
        ("Soup", .prepared, ["soup", "soupe"]),
        
        // BEVERAGES
        ("Coffee", .beverages, ["coffee", "café"]),
        ("Latte", .beverages, ["latte"]),
        ("Cappuccino", .beverages, ["cappuccino", "cappu"]),
        ("Espresso", .beverages, ["espresso"]),
        ("Americano", .beverages, ["americano"]),
        ("Mocha", .beverages, ["mocha"]),
        ("Tea", .beverages, ["tea", "thé"]),
        ("Juice", .beverages, ["juice", "jus"]),
        ("Soda", .beverages, ["soda", "pop"]),
        ("Water", .beverages, ["water", "eau"]),
        ("Smoothie", .beverages, ["smoothie"]),
        ("Wine", .beverages, ["wine", "vin"]),
        ("Beer", .beverages, ["beer", "bière"]),
        
        // SNACKS & CONDIMENTS
        ("Chocolate", .snacks, ["chocolate", "chocolat"]),
        ("Chips", .snacks, ["chips", "croustilles"]),
        ("Crackers", .snacks, ["crackers"]),
        ("Popcorn", .snacks, ["popcorn", "maïs soufflé"]),
        ("Candy", .snacks, ["candy", "bonbon"]),
        ("Peanuts", .snacks, ["peanut", "peanuts", "arachide"]),
        ("Salt", .snacks, ["salt", "sel"]),
        ("Ketchup", .snacks, ["ketchup"]),
        ("Honey", .snacks, ["honey", "miel"]),
        
        // FROZEN FOODS
        ("Frozen Pizza", .frozen, ["frozen pizza"]),
        ("Ice", .frozen, ["ice", "glace"]),
        ("Dumpling", .frozen, ["dumpling", "dumplings"]),
    ]
    
    // MARK: - Main Parsing Function
    
    /// Parse scanned receipt text into grocery items
    static func parseReceipt(_ text: String) -> [ParsedItem] {
        var items: [ParsedItem] = []
        let lines = text.components(separatedBy: .newlines)
        
        for line in lines {
            // Clean up the line
            let cleanLine = line.trimmingCharacters(in: .whitespaces)
            guard !cleanLine.isEmpty else { continue }
            
            // Skip obvious non-item lines first (performance optimization)
            if shouldSkipLine(cleanLine) {
                continue
            }
            
            // Try to match against our whitelist
            if let item = matchRecognizedFood(from: cleanLine) {
                items.append(item)
            }
        }
        
        // Remove duplicates and merge quantities
        items = mergeDuplicates(items)
        
        return items
    }
    
    // MARK: - Whitelist Matching
    
    private static func matchRecognizedFood(from line: String) -> ParsedItem? {
        let lowercaseLine = line.lowercased()
        
        // Try to match against each recognized food item
        for food in recognizedFoods {
            // Check if any of the keywords match
            for keyword in food.keywords {
                if lowercaseLine.contains(keyword) {
                    // Found a match! Extract quantity and clean up the name
                    let quantity = extractQuantity(from: line)
                    
                    return ParsedItem(
                        name: food.name,
                        quantity: quantity,
                        isSelected: true,
                        estimatedCategory: food.category
                    )
                }
            }
        }
        
        return nil
    }
    
    // MARK: - Helper Functions
    
    private static func shouldSkipLine(_ line: String) -> Bool {
        let lowercaseLine = line.lowercased()
        
        // Skip lines with store/receipt keywords
        let skipKeywords = [
            // Store info
            "store", "shop", "market", "restaurant", "address", "avenue", "street", "blvd", "road",
            "phone", "tel:", "fax:", "email", "website", "www", ".com",
            
            // Receipt structure
            "receipt", "invoice", "bill", "order", "commande", "transaction", "command",
            
            // Employee/register
            "cashier", "caissier", "employee", "employé", "register", "terminal",
            
            // Payment
            "payment", "paiement", "card", "carte", "credit", "debit", "cash", "change", "monnaie",
            "master", "visa", "amex", "interac", "mastercard",
            
            // Totals and taxes
            "subtotal", "sous-total", "total", "tax", "tps", "tvq", "balance", "amount", "montant",
            
            // Other receipt elements
            "thank", "merci", "visit", "date", "time", "code", "qr", "barcode",
            
            // Common separators
            "***", "---", "===", "______", "......",
            
            // Location/administrative
            "québec", "quebec", "laval", "montreal", "canada", "centropolis"
        ]
        
        for keyword in skipKeywords {
            if lowercaseLine.contains(keyword) {
                return true
            }
        }
        
        // Skip lines that are mostly numbers (transaction IDs, phone numbers, etc.)
        let digitCount = line.filter { $0.isNumber }.count
        let letterCount = line.filter { $0.isLetter }.count
        
        if digitCount > letterCount && digitCount > 4 {
            return true
        }
        
        // Skip very short lines (codes, abbreviations)
        if line.count < 3 {
            return true
        }
        
        // Skip lines with too many symbols
        let symbolCount = line.filter { !$0.isLetter && !$0.isNumber && !$0.isWhitespace }.count
        if Double(symbolCount) / Double(line.count) > 0.4 {
            return true
        }
        
        return false
    }
    
    private static func extractQuantity(from text: String) -> Int {
        // Look for patterns like "2x", "x2", "qty 2", "2 ea"
        let patterns = [
            #"^(\d+)\s*x"#,         // "2x Item"
            #"x\s*(\d+)"#,          // "x2 Item"
            #"qty\s*:?\s*(\d+)"#,   // "qty: 2" or "qty 2"
            #"(\d+)\s*ea"#,         // "2 ea"
            #"^(\d+)\s+[a-zA-Z]"#   // "2 Apples"
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
               let range = Range(match.range(at: 1), in: text),
               let quantity = Int(text[range]) {
                return quantity
            }
        }
        
        return 1 // Default quantity
    }
    
    private static func mergeDuplicates(_ items: [ParsedItem]) -> [ParsedItem] {
        var merged: [String: ParsedItem] = [:]
        
        for item in items {
            let key = item.name.lowercased()
            if var existingItem = merged[key] {
                existingItem.quantity += item.quantity
                merged[key] = existingItem
            } else {
                merged[key] = item
            }
        }
        
        return Array(merged.values)
    }
    
    // MARK: - Category Inference (now just returns the category from whitelist)
    
    static func inferCategory(from name: String) -> ItemCategory {
        let lowercaseName = name.lowercased()
        
        // Find matching food in whitelist
        for food in recognizedFoods {
            if food.name.lowercased() == lowercaseName {
                return food.category
            }
        }
        
        // Default fallback
        return .snacks
    }
    
    // MARK: - Expiration Date Estimation
    
    static func estimateExpirationDate(for name: String, category: ItemCategory) -> Date {
        let calendar = Calendar.current
        let today = Date()
        
        // Base days until expiration by category
        let daysToAdd: Int
        
        switch category {
        case .dairy:
            daysToAdd = 7  // 1 week
        case .vegetables:
            daysToAdd = 5  // 5 days
        case .fruits:
            daysToAdd = 7  // 1 week
        case .meat:
            daysToAdd = 3  // 3 days (fresh meat)
        case .bakery:
            daysToAdd = 5  // 5 days
        case .prepared:
            daysToAdd = 3  // 3 days
        case .beverages:
            daysToAdd = 30 // 1 month
        case .snacks:
            daysToAdd = 60 // 2 months
        case .frozen:
            daysToAdd = 90 // 3 months
        }
        
        // Adjust based on specific keywords
        let lowercaseName = name.lowercased()
        var adjustedDays = daysToAdd
        
        if lowercaseName.contains("fresh") || lowercaseName.contains("frais") {
            adjustedDays = max(3, adjustedDays - 2)
        }
        if lowercaseName.contains("organic") || lowercaseName.contains("bio") {
            adjustedDays = max(3, adjustedDays - 1)
        }
        if lowercaseName.contains("frozen") || lowercaseName.contains("congelé") {
            adjustedDays = 90
        }
        
        return calendar.date(byAdding: .day, value: adjustedDays, to: today) ?? today
    }
}
