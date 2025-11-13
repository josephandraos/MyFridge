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
                print("✅ Found: \(item.name) (qty: \(item.quantity))")
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
            "bienvenue", "thank", "merci", "cashier", "caisse"
        ]
        
        let footerKeywords = [
            "total", "subtotal", "tax", "tps", "tvq", "gst", "hst",
            "balance", "payment", "paid", "card", "credit", "debit",
            "visa", "mastercard", "change", "monnaie", "thank", "merci"
        ]
        
        // Check first 5 lines for header
        for i in 0..<min(5, lines.count) {
            let line = lines[i].lowercased()
            if headerKeywords.contains(where: { line.contains($0) }) {
                headerCount = i + 1
            } else {
                break
            }
        }
        
        // Check last 10 lines for footer
        for i in (max(0, lines.count - 10)..<lines.count).reversed() {
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
        
        // Contains food-like words from your existing ReceiptParser
        // This uses your Canadian brand database
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
        if index > 0 {
            let prevScore = scoreLine(context[index - 1], context: context, index: index - 1)
            if prevScore >= minLineScore {
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
        
        // Skip keywords (STRONG negative)
        let skipKeywords = [
            "total", "subtotal", "sous-total", "tax", "tps", "tvq", "gst", "hst",
            "balance", "payment", "paid", "payé", "card", "carte", "credit", "debit",
            "visa", "mastercard", "cash", "argent", "change", "monnaie",
            "store", "magasin", "cashier", "caisse", "thank", "merci",
            "receipt", "reçu", "invoice", "facture", "date", "time", "heure",
            "customer", "client", "phone", "telephone", "address", "adresse",
            "save", "econom", "coupon", "rabais", "discount", "promo",
            "member", "membre", "points", "rewards", "récompense"
        ]
        
        for keyword in skipKeywords {
            if lowercaseLine.contains(keyword) {
                score -= 15.0 // Heavy penalty
                break
            }
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
        
        // Try to match using your existing ReceiptParser
        let category = ReceiptParser.inferCategory(from: cleanedLine)
        
        return ParsedItem(
            name: cleanedLine.capitalized,
            quantity: quantity,
            isSelected: true,
            estimatedCategory: category
        )
    }
    
    // MARK: - Helper Functions
    
    private static func normalizeLine(_ line: String) -> String {
        return line.lowercased().folding(options: .diacriticInsensitive, locale: .current)
    }
    
    private static func containsFoodKeywords(_ normalizedLine: String) -> Bool {
        // Common food keywords
        let foodKeywords = [
            "milk", "lait", "cheese", "fromage", "bread", "pain",
            "chicken", "poulet", "beef", "boeuf", "egg", "oeuf",
            "butter", "beurre", "yogurt", "apple", "pomme",
            "banana", "orange", "carrot", "tomato", "potato",
            "rice", "pasta", "cereal", "juice", "water"
        ]
        
        for keyword in foodKeywords {
            if normalizedLine.contains(keyword) {
                return true
            }
        }
        
        return false
    }
    
    private static func hasItemCode(_ line: String) -> Bool {
        // Match 7-8 digit codes at start
        let pattern = #"^\d{7,8}\s+"#
        return line.range(of: pattern, options: .regularExpression) != nil
    }
    
    private static func removeItemCode(_ line: String) -> String {
        let pattern = #"^\d{4,8}\s+"#
        return line.replacingOccurrences(of: pattern, with: "", options: .regularExpression)
    }
    
    private static func removeTrailingPrice(_ line: String) -> String {
        // Remove price patterns at end: $12.99, 12.99$, 12,99, etc.
        let patterns = [
            #"\s*\$?\d+[.,]\d{2}\s*\$?\s*$"#,
            #"\s*\d+[.,]\d{2}\s*(CAD|USD)?\s*$"#,
            #"\s*\d+\s\d{2}\s*$"#
        ]
        
        var result = line
        for pattern in patterns {
            result = result.replacingOccurrences(of: pattern, with: "", options: .regularExpression)
        }
        
        return result
    }
    
    private static func removeQuantityIndicators(_ line: String) -> String {
        // Remove qty patterns: "2 X", "QTY: 3", "x2", etc.
        let patterns = [
            #"\d+\.?\d*\s*[xX]\s*"#,
            #"\s*[xX]\s*\d+\.?\d*"#,
            #"\bQTY\s*:?\s*\d+\.?\d*"#,
            #"\d+\.?\d*\s*(EA|DZ|DOZ|L|KG|LB|G)\b"#
        ]
        
        var result = line
        for pattern in patterns {
            result = result.replacingOccurrences(of: pattern, with: " ", options: [.regularExpression, .caseInsensitive])
        }
        
        return result.replacingOccurrences(of: "  ", with: " ")
    }
    
    private static func containsPrice(_ text: String) -> Bool {
        let pricePatterns = [
            #"\$?\d+[.,]\d{2}"#,
            #"\d+[.,]\d{2}\s*\$"#,
            #"\d+\s\d{2}\b"#
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
            
            return true
        }
    }
}
