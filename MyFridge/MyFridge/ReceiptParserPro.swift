//
//  ReceiptParserPro.swift
//  MyFridge
//
//  Enhanced receipt parser with improved accuracy, bilingual support, and better filtering
//

import Foundation

struct ReceiptParserPro {
    
    // MARK: - Configuration
    
    private static let minLineScore: Double = 3.5 // Slightly higher threshold for better accuracy
    private static let minItemNameLength = 2
    private static let maxItemNameLength = 60
    
    // MARK: - Main Parsing Function
    
    /// Parse receipt text with enhanced logic and accuracy
    static func parseReceipt(_ text: String) -> [ParsedItem] {
        
        var items: [ParsedItem] = []
        let lines = text.components(separatedBy: .newlines)
        
        print("📝 Parsing receipt with \(lines.count) lines...")
        
        // Pre-process: identify store headers and footers to skip
        let (headerLines, footerLines) = identifyHeaderAndFooter(lines)
        
        for (index, line) in lines.enumerated() {
            // Skip header and footer lines
            if index < headerLines || index >= lines.count - footerLines {
                continue
            }
            
            let cleanLine = line.trimmingCharacters(in: .whitespaces)
            guard !cleanLine.isEmpty else { continue }
            
            // Score the line
            let score = scoreLine(cleanLine, context: lines, index: index)
            
            if score < minLineScore {
                continue
            }
            
            // Try to extract item
            if let item = extractItem(from: cleanLine) {
                items.append(item)
                print("✅ Found: \(item.name) (qty: \(item.quantity)) - Category: \(item.estimatedCategory.rawValue)")
            }
        }
        
        // Post-processing: merge duplicates and validate
        items = mergeDuplicates(items)
        items = validateItems(items)
        
        print("🎉 Final result: \(items.count) items parsed")
        
        return items
    }
    
    // MARK: - Header/Footer Detection
    
    /// Identify how many lines at top/bottom are store info (not items)
    private static func identifyHeaderAndFooter(_ lines: [String]) -> (headerLines: Int, footerLines: Int) {
        
        var headerCount = 0
        var footerCount = 0
        
        let headerKeywords = [
            "store", "magasin", "location", "address", "adresse",
            "phone", "tel", "telephone", "www", ".com", "welcome",
            "bienvenue", "thank", "merci", "cashier", "caisse", "costco",
            "libre-service", "self-service", "membre", "member"
        ]
        
        let footerKeywords = [
            "total", "subtotal", "sous-total", "tax", "tps", "tvq", "gst", "hst",
            "balance", "payment", "paid", "payé", "card", "credit", "debit",
            "visa", "mastercard", "change", "monnaie", "thank", "merci",
            "interac", "compte", "solde"
        ]
        
        // Check first 8 lines for header
        for i in 0..<min(8, lines.count) {
            let line = lines[i].lowercased()
            if headerKeywords.contains(where: { line.contains($0) }) {
                headerCount = i + 1
            } else {
                break
            }
        }
        
        // Check last 15 lines for footer (receipts have lots of payment info at bottom)
        for i in (max(0, lines.count - 15)..<lines.count).reversed() {
            let line = lines[i].lowercased()
            if footerKeywords.contains(where: { line.contains($0) }) {
                footerCount = lines.count - i
            } else {
                break
            }
        }
        
        return (headerCount, footerCount)
    }
    
    // MARK: - Line Scoring with Context
    
    /// Score line with surrounding context for better accuracy
    private static func scoreLine(_ line: String, context: [String], index: Int) -> Double {
        
        var score = 5.0
        let lowercaseLine = line.lowercased().folding(options: .diacriticInsensitive, locale: .current)
        
        // POSITIVE SIGNALS
        
        // Has price pattern
        if containsPrice(line) {
            score += 3.0
        }
        
        // Has quantity pattern
        if containsQuantityPattern(line) {
            score += 2.0
        }
        
        // Contains food-like words (enhanced with French and Canadian brands)
        let normalizedLine = normalizeLine(line)
        if containsFoodKeywords(normalizedLine) {
            score += 5.0
        }
        
        // Has item code at beginning (7-digit PLU or item ID)
        if hasItemCode(line) {
            score += 2.0
        }
        
        // Good length
        if line.count >= 5 && line.count <= 50 {
            score += 1.0
        }
        
        // Context bonus: lines above/below are also likely items
        if index > 0 && index < context.count - 1 {
            let prevLine = context[index - 1]
            let nextLine = context[index + 1]
            
            if containsPrice(prevLine) || containsPrice(nextLine) {
                score += 1.0
            }
        }
        
        // NEGATIVE SIGNALS
        
        // Too many digits (likely not an item name)
        let digitCount = line.filter { $0.isNumber }.count
        let letterCount = line.filter { $0.isLetter }.count
        if digitCount > letterCount && digitCount > 8 {
            score -= 6.0
        }
        
        // Skip keywords (STRONG negative) - ENHANCED WITH PAYMENT TERMS
        let skipKeywords = [
            "total", "subtotal", "sous-total", "tax", "tps", "tvq", "gst", "hst",
            "balance", "payment", "paid", "payé", "card", "carte", "credit", "debit",
            "visa", "mastercard", "cash", "argent", "change", "monnaie",
            "store", "magasin", "cashier", "caisse", "thank", "merci",
            "receipt", "reçu", "invoice", "facture", "date", "time", "heure",
            "customer", "client", "phone", "telephone", "address", "adresse",
            "save", "econom", "coupon", "rabais", "discount", "promo",
            "member", "membre", "points", "rewards", "récompense",
            // Payment/transaction info (NEW - filters out Interac, references, etc.)
            "interac", "compte:", "reference:", "autor", "authorization",
            "transaction", "achat", "vente", "solde", "approve", "approuvé",
            "numero", "number", "ref:", "auth:", "paiement"
        ]
        
        for keyword in skipKeywords {
            if lowercaseLine.contains(keyword) {
                score -= 15.0 // Heavy penalty
                break
            }
        }
        
        // Lines starting with # or special characters (likely IDs)
        if line.starts(with: "#") || line.starts(with: "*") || line.starts(with: "-") {
            score -= 10.0
        }
        
        // All caps with many spaces (likely header/separator)
        if line == line.uppercased() && line.filter({ $0 == " " }).count > 5 {
            score -= 5.0
        }
        
        // Too many special characters
        let symbolCount = line.filter { !$0.isLetter && !$0.isNumber && !$0.isWhitespace }.count
        if Double(symbolCount) / Double(line.count) > 0.5 {
            score -= 4.0
        }
        
        // Very short
        if line.count < 3 {
            score -= 10.0
        }
        
        return score
    }
    
    // MARK: - Item Extraction
    
    /// Extract grocery item from a line
    private static func extractItem(from line: String) -> ParsedItem? {
        
        // Remove item code if present (leading 7-8 digits)
        var cleanedLine = removeItemCode(line)
        
        // Remove price from end
        cleanedLine = removeTrailingPrice(cleanedLine)
        
        // Extract quantity
        let quantity = extractQuantity(from: line)
        
        // Remove quantity indicators from name
        cleanedLine = removeQuantityIndicators(cleanedLine)
        
        // Clean up name
        cleanedLine = cleanedLine.trimmingCharacters(in: .whitespaces)
        
        // Validate name length
        guard cleanedLine.count >= minItemNameLength && cleanedLine.count <= maxItemNameLength else {
            return nil
        }
        
        // Infer category using BOTH ReceiptParser AND enhanced logic
        let category = inferCategoryEnhanced(from: cleanedLine)
        
        return ParsedItem(
            name: cleanedLine.capitalized,
            quantity: quantity,
            isSelected: true,
            estimatedCategory: category
        )
    }
    
    // MARK: - Enhanced Category Inference (Bilingual)
    
    private static func inferCategoryEnhanced(from itemName: String) -> ItemCategory {
        let normalized = itemName.lowercased().folding(options: .diacriticInsensitive, locale: .current)
        
        // DAIRY & EGGS (French + English)
        if normalized.contains("lait") || normalized.contains("milk") ||
           normalized.contains("beurre") || normalized.contains("butter") ||
           normalized.contains("fromage") || normalized.contains("cheese") ||
           normalized.contains("mozzarella") || normalized.contains("mozzafina") ||
           normalized.contains("cheddar") || normalized.contains("brie") ||
           normalized.contains("yogurt") || normalized.contains("yoghourt") ||
           normalized.contains("creme") || normalized.contains("cream") ||
           normalized.contains("oeuf") || normalized.contains("egg") {
            return .dairy
        }
        
        // MEAT & FISH (French + English)
        if normalized.contains("poulet") || normalized.contains("chicken") ||
           normalized.contains("boeuf") || normalized.contains("beef") ||
           normalized.contains("porc") || normalized.contains("pork") ||
           normalized.contains("bacon") || normalized.contains("saucisse") ||
           normalized.contains("sausage") || normalized.contains("steak") ||
           normalized.contains("viande") || normalized.contains("meat") ||
           normalized.contains("poisson") || normalized.contains("fish") ||
           normalized.contains("saumon") || normalized.contains("salmon") ||
           normalized.contains("thon") || normalized.contains("tuna") {
            return .meat
        }
        
        // FRUITS (French + English)
        if normalized.contains("pomme") || normalized.contains("apple") ||
           normalized.contains("banane") || normalized.contains("banana") ||
           normalized.contains("orange") || normalized.contains("citron") ||
           normalized.contains("lemon") || normalized.contains("raisin") ||
           normalized.contains("grape") || normalized.contains("fraise") ||
           normalized.contains("strawberr") || normalized.contains("melon") ||
           normalized.contains("peche") || normalized.contains("peach") ||
           normalized.contains("poire") || normalized.contains("pear") ||
           normalized.contains("cerise") || normalized.contains("cherr") {
            return .fruits
        }
        
        // VEGETABLES (French + English)
        if normalized.contains("carotte") || normalized.contains("carrot") ||
           normalized.contains("patate") || normalized.contains("potato") ||
           normalized.contains("pomme de terre") ||
           normalized.contains("tomate") || normalized.contains("tomato") ||
           normalized.contains("laitue") || normalized.contains("lettuce") ||
           normalized.contains("salade") || normalized.contains("salad") ||
           normalized.contains("oignon") || normalized.contains("onion") ||
           normalized.contains("concombre") || normalized.contains("cucumber") ||
           normalized.contains("brocoli") || normalized.contains("broccoli") ||
           normalized.contains("chou") || normalized.contains("cabbage") ||
           normalized.contains("celeri") || normalized.contains("celery") ||
           normalized.contains("poivron") || normalized.contains("pepper") {
            return .vegetables
        }
        
        // BREAD & BAKERY (French + English)
        if normalized.contains("pain") || normalized.contains("bread") ||
           normalized.contains("baguette") || normalized.contains("croissant") ||
           normalized.contains("gateau") || normalized.contains("cake") ||
           normalized.contains("muffin") || normalized.contains("bagel") ||
           normalized.contains("brioche") || normalized.contains("patisserie") {
            return .bakery
        }
        
        // BEVERAGES (French + English + Canadian brands)
        if normalized.contains("eau") || normalized.contains("water") ||
           normalized.contains("eska") || // Quebec water brand
           normalized.contains("pepsi") || normalized.contains("coca") ||
           normalized.contains("coke") || normalized.contains("soda") ||
           normalized.contains("jus") || normalized.contains("juice") ||
           normalized.contains("cafe") || normalized.contains("coffee") ||
           normalized.contains("the") || normalized.contains("tea") ||
           normalized.contains("lait") || normalized.contains("milk") ||
           normalized.contains("biere") || normalized.contains("beer") ||
           normalized.contains("vin") || normalized.contains("wine") ||
           normalized.contains("boisson") || normalized.contains("drink") ||
           normalized.contains("diete") || normalized.contains("diet") {
            return .beverages
        }
        
        // PREPARED FOODS (French + English)
        if normalized.contains("pizza") || normalized.contains("burger") ||
           normalized.contains("sandwich") || normalized.contains("pates") ||
           normalized.contains("pasta") || normalized.contains("spaghetti") ||
           normalized.contains("lasagne") || normalized.contains("lasagna") ||
           normalized.contains("soupe") || normalized.contains("soup") ||
           normalized.contains("plat") || normalized.contains("meal") ||
           normalized.contains("pret") || normalized.contains("ready") {
            return .prepared
        }
        
        // FROZEN (French + English)
        if normalized.contains("congele") || normalized.contains("frozen") ||
           normalized.contains("surgele") || normalized.contains("glace") ||
           normalized.contains("ice cream") || normalized.contains("sorbet") {
            return .frozen
        }
        
        // SNACKS & CONDIMENTS (default category)
        // Includes: chips, crackers, cookies, sauces, spices, condiments, etc.
        return .snacks
    }
    
    // MARK: - Helper Functions
    
    private static func normalizeLine(_ line: String) -> String {
        return line.lowercased().folding(options: .diacriticInsensitive, locale: .current)
    }
    
    private static func containsFoodKeywords(_ normalizedLine: String) -> Bool {
        // Enhanced food keywords with French + Canadian brands
        let foodKeywords = [
            // Dairy & Eggs (French + English)
            "milk", "lait", "cheese", "fromage", "mozzarella", "mozzafina",
            "cheddar", "brie", "bread", "pain", "butter", "beurre",
            "chicken", "poulet", "beef", "boeuf", "egg", "oeuf",
            "yogurt", "yoghourt", "apple", "pomme", "banana", "banane",
            "orange", "carrot", "carotte", "tomato", "tomate",
            "potato", "patate", "rice", "riz", "pasta", "pates",
            "cereal", "cereale", "juice", "jus", "water", "eau",
            // Quebec/Canadian brands
            "eska", "agropur", "natrel", "lactantia",
            // Common French grocery terms
            "salade", "viande", "poisson", "legume", "fruit",
            "boisson", "sauce", "epice", "condiment"
        ]
        
        for keyword in foodKeywords {
            if normalizedLine.contains(keyword) {
                return true
            }
        }
        
        return false
    }
    
    private static func hasItemCode(_ line: String) -> Bool {
        // Match 5-8 digit codes at start
        let pattern = #"^\d{5,8}\s+"#
        return line.range(of: pattern, options: .regularExpression) != nil
    }
    
    private static func removeItemCode(_ line: String) -> String {
        let pattern = #"^\d{4,8}\s+"#
        return line.replacingOccurrences(of: pattern, with: "", options: .regularExpression)
    }
    
    private static func removeTrailingPrice(_ line: String) -> String {
        // Remove price patterns at end: $12.99, 12.99$, 12,99, FP, etc.
        let patterns = [
            #"\s*\$?\d+[.,]\d{2}\s*\$?\s*(FP|F)?\s*$"#,
            #"\s*\d+[.,]\d{2}\s*(CAD|USD|FP|F)?\s*$"#,
            #"\s*\d+\s\d{2}\s*(FP|F)?\s*$"#,
            #"\s*-\s*\d+[.,]\d{2}\s*$"#,
            #"\s*~\s*\d+[.,]\d{2}\s*$"#
        ]
        
        var result = line
        for pattern in patterns {
            result = result.replacingOccurrences(of: pattern, with: "", options: .regularExpression)
        }
        
        return result.trimmingCharacters(in: .whitespaces)
    }
    
    private static func removeQuantityIndicators(_ line: String) -> String {
        // Remove qty patterns: "2 X", "QTY: 3", "x2", etc.
        let patterns = [
            #"\d+\.?\d*\s*[xX]\s*"#,
            #"\s*[xX]\s*\d+\.?\d*"#,
            #"\bQTY\s*:?\s*\d+\.?\d*"#,
            #"\d+\.?\d*\s*(EA|DZ|DOZ|L|KG|LB|G)\b"#,
            #"\s*-\s*$"#  // Remove trailing dashes
        ]
        
        var result = line
        for pattern in patterns {
            result = result.replacingOccurrences(of: pattern, with: " ", options: [.regularExpression, .caseInsensitive])
        }
        
        return result.replacingOccurrences(of: "  ", with: " ").trimmingCharacters(in: .whitespaces)
    }
    
    private static func containsPrice(_ text: String) -> Bool {
        let pricePatterns = [
            #"\$?\d+[.,]\d{2}"#,
            #"\d+[.,]\d{2}\s*\$"#,
            #"\d+\s\d{2}\s*(FP|F)?\b"#
        ]
        
        for pattern in pricePatterns {
            if text.range(of: pattern, options: .regularExpression) != nil {
                return true
            }
        }
        
        return false
    }
    
    private static func containsQuantityPattern(_ text: String) -> Bool {
        let qtyPatterns = [
            #"\d+\s*[xX]\b"#,
            #"\b[xX]\s*\d+"#,
            #"\bQTY\s*:?\s*\d+"#,
            #"\d+\s*(EA|DZ|L|KG|LB)\b"#
        ]
        
        for pattern in qtyPatterns {
            if text.range(of: pattern, options: [.regularExpression, .caseInsensitive]) != nil {
                return true
            }
        }
        
        return false
    }
    
    private static func extractQuantity(from text: String) -> Int {
        // Skip leading item IDs
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        
        var workingText = trimmed
        if let regex = try? NSRegularExpression(pattern: #"^\d{4,8}\s+"#),
           let match = regex.firstMatch(in: trimmed, range: NSRange(trimmed.startIndex..., in: trimmed)),
           let range = Range(match.range, in: trimmed) {
            workingText = String(trimmed[range.upperBound...])
        }
        
        // Quantity patterns
        let patterns = [
            (#"(\d+\.?\d*)\s*(DZ|DOZ|DOZEN)"#, 12.0),  // Dozen = 12
            (#"(\d+\.?\d*)\s*L\b"#, 1.0),
            (#"(\d+\.?\d*)\s*KG"#, 1.0),
            (#"(\d+\.?\d*)\s*LB"#, 1.0),
            (#"\bQTY\s*:?\s*(\d+)"#, 1.0),
            (#"\b(\d+)\s*[xX]\b"#, 1.0),
            (#"\b[xX]\s*(\d+)\b"#, 1.0),
            (#"\b(\d+)\s*EA\b"#, 1.0),
        ]
        
        for (pattern, multiplier) in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: workingText, range: NSRange(workingText.startIndex..., in: workingText)),
               let range = Range(match.range(at: 1), in: workingText) {
                
                let quantityStr = String(workingText[range])
                
                if let quantityDouble = Double(quantityStr) {
                    return Int(ceil(quantityDouble * multiplier))
                }
            }
        }
        
        return 1
    }
    
    // MARK: - Duplicate Merging
    
    private static func mergeDuplicates(_ items: [ParsedItem]) -> [ParsedItem] {
        var merged: [String: ParsedItem] = [:]
        
        for item in items {
            let key = item.name.lowercased().folding(options: .diacriticInsensitive, locale: .current)
            
            if var existingItem = merged[key] {
                existingItem.quantity += item.quantity
                merged[key] = existingItem
            } else {
                merged[key] = item
            }
        }
        
        return Array(merged.values)
    }
    
    // MARK: - Validation
    
    /// Remove items that don't make sense
    private static func validateItems(_ items: [ParsedItem]) -> [ParsedItem] {
        
        return items.filter { item in
            // Name must have at least one letter
            guard item.name.contains(where: { $0.isLetter }) else {
                return false
            }
            
            // Name shouldn't be all numbers
            let digitCount = item.name.filter { $0.isNumber }.count
            let letterCount = item.name.filter { $0.isLetter }.count
            
            if digitCount > letterCount && digitCount > 5 {
                return false
            }
            
            // Name shouldn't be too generic
            let genericNames = ["item", "product", "article", "produit"]
            if genericNames.contains(item.name.lowercased()) {
                return false
            }
            
            // Filter out lines that start with special characters
            if item.name.starts(with: "#") || item.name.starts(with: "*") {
                return false
            }
            
            return true
        }
    }
}
