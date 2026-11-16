//
//  ReceiptParserPro.swift
//  MyFridge
//
//  Turns OCR text from a grocery receipt into a list of items.
//  Built for Canadian receipts (Quebec French + English): IGA, Metro, Maxi,
//  Super C, Provigo, Costco, Loblaws, No Frills, Walmart, ...
//
//  How it works (top to bottom):
//   1. Normalize lines, then CUT everything from "Sous-total / Subtotal / Total" down.
//   2. Skip noise lines: addresses, phones, postal codes, dates, taxes (TPS/TVQ/GST/HST),
//      payment, cashier, loyalty points, discounts, bags, deposits, non-food (toilet paper...).
//   3. A line is an ITEM when it ends with a price ("4.99", "4,99 $", "(5.55$) FP", "3.49 F").
//      Tax flags after the price (F, P, FP, A, Y, MRJ, HMRJ...) are ignored.
//   4. Quantities come ONLY from explicit forms ("2 x", "2 @ 1.79", "QTY 2", leading "2 Latte").
//      Sizes and weights (2L, 450G, 1.2 kg, 10LB) are NEVER quantities.
//   5. A name followed by a price-only line, or by a weighed line carrying the price,
//      is merged (Vision sometimes splits the columns of one row into two lines).
//   6. Category comes from ItemEmojiHelper (English + French rules), so the scanner and
//      the Add/Edit screens always agree.
//
//  The logic is covered by ReceiptParserProTests (real + synthetic receipts).
//

import Foundation

struct ReceiptParserPro {

    // MARK: - Public API

    /// Parse receipt text into grocery items (already merged and de-duplicated).
    static func parseReceipt(_ text: String) -> [ParsedItem] {

        // 1. Normalize and drop empty lines
        var lines = text.components(separatedBy: .newlines)
            .map { collapseSpaces($0) }
            .filter { !$0.isEmpty }

        // Cut everything from the first "total" line down (taxes, payment, footer)
        if let cut = lines.indices.first(where: { $0 > 0 && totalRx.test(fold(lines[$0])) }) {
            lines = Array(lines[..<cut])
        }

        var drafts: [Draft] = []
        var seenPrice = false
        var i = 0
        let count = lines.count

        while i < count {
            let raw = lines[i]
            let folded = fold(raw)

            // "2 x 3.99", "2 @ 1.79", "QTY 2" -> applies to the PREVIOUS item
            if let q = quantityLineValue(folded) {
                if let last = drafts.indices.last, drafts[last].quantity == 1 {
                    drafts[last].quantity = q
                }
                i += 1
                continue
            }

            // "1.856 kg @ 6.66/kg" detail lines are never items or quantities
            if weightRx.test(folded) {
                i += 1
                continue
            }

            if isNoise(raw) {
                i += 1
                continue
            }

            // Normal case: item name + price on the same line
            if let priced = splitPrice(raw) {
                if !priced.negative, let draft = makeItem(from: priced.name) {
                    drafts.append(draft)
                    seenPrice = true
                }
                i += 1
                continue
            }

            // No price on this line. Look at the next line.
            let next: String? = (i + 1 < count) ? lines[i + 1] : nil

            // (a) price printed alone on the next line (OCR split the row)
            if let next = next, priceOnlyRx.test(next), hasWord(raw) {
                if !next.contains("-"), let draft = makeItem(from: raw) {
                    drafts.append(draft)
                    seenPrice = true
                }
                i += 2
                continue
            }

            // (b) weighed item: name here, "1.2 kg @ 3.99/kg 4.79" on the next line
            if let next = next, weightRx.test(fold(next)), hasWord(raw),
               let weighed = splitPrice(next), !weighed.negative {
                if let draft = makeItem(from: raw) {
                    drafts.append(draft)
                    seenPrice = true
                }
                i += 2
                continue
            }

            // (c) no price at all: only accept obvious food, and only after the first priced item
            //     (so the store name in the header can never become an item)
            if seenPrice, ItemEmojiHelper.isKnownFood(raw), let draft = makeItem(from: raw) {
                drafts.append(draft)
            }
            i += 1
        }

        // Merge duplicates (same name -> add quantities), keep receipt order
        var order: [String] = []
        var merged: [String: Draft] = [:]
        for draft in drafts {
            let key = fold(draft.name)
            if var existing = merged[key] {
                existing.quantity += draft.quantity
                merged[key] = existing
            } else {
                merged[key] = draft
                order.append(key)
            }
        }

        return order.compactMap { merged[$0] }.map {
            ParsedItem(name: $0.name, quantity: $0.quantity, isSelected: true, estimatedCategory: $0.category)
        }
    }

    // MARK: - Types

    private struct Draft {
        var name: String
        var quantity: Int
        var category: ItemCategory
    }

    /// Small wrapper so a bad pattern can never crash the app (it just never matches)
    private struct Rx {
        let regex: NSRegularExpression?

        init(_ pattern: String, ignoreCase: Bool = false) {
            regex = try? NSRegularExpression(pattern: pattern, options: ignoreCase ? [.caseInsensitive] : [])
        }

        func firstMatch(in s: String) -> NSTextCheckingResult? {
            regex?.firstMatch(in: s, range: NSRange(s.startIndex..., in: s))
        }

        func test(_ s: String) -> Bool {
            firstMatch(in: s) != nil
        }

        func replace(in s: String, with template: String = " ") -> String {
            guard let regex = regex else { return s }
            return regex.stringByReplacingMatches(in: s, range: NSRange(s.startIndex..., in: s), withTemplate: template)
        }

        func group(_ m: NSTextCheckingResult, _ index: Int, in s: String) -> String? {
            let r = m.range(at: index)
            guard r.location != NSNotFound, let range = Range(r, in: s) else { return nil }
            return String(s[range])
        }

        /// Returns `s` with the whole match removed (replaced by a space)
        func removing(_ m: NSTextCheckingResult, from s: String) -> String {
            guard let range = Range(m.range, in: s) else { return s }
            return String(s[..<range.lowerBound]) + " " + String(s[range.upperBound...])
        }
    }

    // MARK: - Patterns

    private static let noiseWords: [String] = [
        "total", "sous total", "subtotal", "tax", "taxes", "taxe", "tps", "tvq", "tvh", "gst", "hst", "pst", "qst",
        "balance", "solde", "payment", "paiement", "paye", "paid", "card", "carte", "credit", "debit",
        "visa", "mastercard", "master card", "amex", "interac", "cash", "comptant", "monnaie", "change", "rendu",
        "thank", "thanks", "merci", "receipt", "recu", "facture", "invoice",
        "cashier", "caissier", "caissiere", "caisse", "terminal", "transaction", "commande", "order",
        "client", "customer", "member", "membre", "points", "rewards", "optimum", "scene", "aeroplan",
        "rabais", "discount", "coupon", "economie", "economies", "econ", "promo", "promotion",
        "approuve", "approved", "autorisation", "authorization", "auth", "reference",
        "tel", "telephone", "fax", "courriel", "email", "adresse", "address",
        "bienvenue", "welcome", "visitez", "visit", "retour", "echange", "exchange",
        "magasin", "store", "succursale", "merchant", "marchand", "date", "heure", "time",
        "consigne", "deposit", "depot", "ecofrais", "enviro", "loterie", "lottery", "employe", "employee",
        "donation", "sondage", "survey", "wholesale", "supercentre",
    ]

    /// Bags, deposits and non-food items that commonly appear on grocery receipts
    private static let noisePhrases: [String] = [
        "sac\\s+(?:reutilisable|plastique|papier)", "(?:reusable|plastic|paper)\\s+bags?", "frais\\s+de\\s+sacs?", "bag\\s+fee",
        "papier\\s+toilette", "toilet\\s+paper", "essuie\\s?tout", "paper\\s+towels?", "savon", "\\bsoap\\b", "detergent",
        "shampo", "dentifrice", "toothpaste", "deodorant", "kleenex", "couches?", "diapers?", "ampoule", "light\\s+bulb",
        "piles?\\b", "batter(?:y|ies)\\b",
    ]

    private static let noiseRx: Rx = {
        let alternatives = noiseWords.map {
            NSRegularExpression.escapedPattern(for: $0).replacingOccurrences(of: " ", with: "\\s+")
        }
        return Rx("(?<![a-z0-9])(?:" + alternatives.joined(separator: "|") + ")(?![a-z0-9])")
    }()
    private static let noisePhraseRx = Rx(noisePhrases.joined(separator: "|"))
    private static let phoneRx = Rx("\\(?\\b\\d{3}\\)?[\\s.\\-]?\\d{3}[\\s.\\-]?\\d{4}\\b")
    private static let postalRx = Rx("\\b[a-z]\\d[a-z]\\s?\\d[a-z]\\d\\b")
    private static let dateRx = Rx("\\b(?:20\\d{2}|\\d{1,2})[-/.]\\d{1,2}[-/.](?:20\\d{2}|\\d{2})\\b")
    private static let timeRx = Rx("\\b\\d{1,2}:\\d{2}(?::\\d{2})?\\b")
    private static let urlRx = Rx("www\\.|https?:|\\w@\\w+\\.\\w+|\\.com\\b|\\.ca\\b")
    private static let addressRx = Rx("^(?:\\d{1,5}[,\\s]+)?(?:av|ave|avenue|rue|boul|boulevard|blvd|chemin|rte|route|street|st|road|rd|drive|dr|rang)\\b\\.?(?:\\s|$)")
    private static let totalRx = Rx("^\\W*(?:sous\\W?total|sub\\W?total|total|montant\\s+total|amount\\s+due)(?![a-z])")
    private static let onlySymbolsRx = Rx("^[\\W_\\d]+$")
    private static let priceInTextRx = Rx("\\d+[.,]\\d{2}")

    // Price at the END of a line. Groups: 1 "-", 2 "-", 3 amount, 4 "-"/"cr", 5 tax flag
    private static let priceTailRx = Rx("(-)?\\s*\\(?\\s*(-)?\\s*\\$?\\s*(\\d{1,4}[.,]\\d{2})\\s*\\$?\\s*\\)?\\s*(-|cr)?\\s*([A-Za-z]{1,4})?\\s*$")
    // "LAIT 2 99" (OCR read the decimal point as a space). Groups: 1 dollars, 2 cents
    private static let priceSpacedRx = Rx("\\s(\\d{1,3})\\s(\\d{2})\\s*[A-Z]{0,4}\\s*$")
    private static let priceOnlyRx = Rx("^\\W*-?\\s*\\$?\\s*\\d{1,4}[.,]\\d{2}\\s*\\$?\\s*[A-Za-z]{0,4}\\s*$")

    private static let weightRx = Rx("^\\s*\\d+[.,]\\d+\\s*(?:kg|lb|lbs|g)\\b|@\\s*\\$?\\d+[.,]\\d{2}\\s*/\\s*(?:kg|lb|g|100g)|/\\s*(?:kg|lb)\\b")
    private static let qtyLineRx = Rx("^\\s*(\\d{1,3})\\s*[x@×]\\s*\\$?\\s*\\d+[.,]\\d{2}")
    private static let qtyWordLineRx = Rx("^\\s*(?:qty|qte|quantite)\\s*:?\\s*(\\d{1,3})\\b")
    private static let inlineQtyRx = Rx("(\\d{1,3})\\s*[x@×]\\s*\\$?\\s*\\d+[.,]\\d{2}")
    private static let inlineQtyWordRx = Rx("\\b(?:qty|qte)\\s*:?\\s*(\\d{1,3})\\b", ignoreCase: true)
    private static let inlineQtyXRx = Rx("\\b(\\d{1,2})\\s*[x×](?![a-z0-9])", ignoreCase: true)
    private static let leadQtyRx = Rx("^(\\d{1,2})\\s+(?=\\p{L})")

    private static let codePrefixRx = Rx("^(?:[A-Za-z]\\s+)?\\d{4,14}\\s+")
    private static let brandPrefixRx = Rx("^(?:ks|kirkland)\\s+", ignoreCase: true)
    private static let sizeRx = Rx("\\b\\d+(?:[.,]\\d+)?\\s*(?:x\\s*\\d+(?:[.,]\\d+)?\\s*)?(?:ml|cl|l|g|kg|lb|lbs|oz|un|ea|pk|pqt|ct)\\b", ignoreCase: true)
    private static let packRx = Rx("\\b\\d{1,2}\\s*[x×]\\s*\\d+", ignoreCase: true)
    private static let symbolsRx = Rx("[\\(\\)\\[\\]{}$*#=_|]+")
    private static let multiSpaceRx = Rx("\\s+")
    private static let trailingNumberRx = Rx("\\s+\\d{1,3}$")
    private static let wordRx = Rx("\\p{L}{2,}")
    private static let numericWordRx = Rx("^[\\d%.,]+$")

    private static let genericNames: Set<String> = [
        "item", "items", "product", "produit", "article", "articles", "divers", "misc", "dept", "grocery", "epicerie",
    ]

    private static let punctuation = CharacterSet(charactersIn: " -./,:;")

    // MARK: - Line classification

    /// True for lines that can never be a grocery item (address, tax, payment, date, ...)
    private static func isNoise(_ line: String) -> Bool {
        let f = fold(line)
        guard let first = f.first else { return true }
        if "#*=_~|".contains(first) { return true }

        let letters = f.filter { $0.isLetter }.count
        let digits = f.filter { $0.isNumber }.count
        let hasPrice = priceInTextRx.test(f)

        if first == "-" && !wordRx.test(f) { return true }
        if onlySymbolsRx.test(f) && !hasPrice { return true }
        if digits >= 8 && letters < 4 && !hasPrice { return true }

        return noiseRx.test(f) || noisePhraseRx.test(f) || phoneRx.test(f) || postalRx.test(f)
            || dateRx.test(f) || timeRx.test(f) || urlRx.test(f) || addressRx.test(f)
    }

    private static func hasWord(_ s: String) -> Bool {
        wordRx.test(s)
    }

    private static func quantityLineValue(_ folded: String) -> Int? {
        if let m = qtyLineRx.firstMatch(in: folded), let n = qtyLineRx.group(m, 1, in: folded) { return Int(n) }
        if let m = qtyWordLineRx.firstMatch(in: folded), let n = qtyWordLineRx.group(m, 1, in: folded) { return Int(n) }
        return nil
    }

    // MARK: - Price handling

    private struct PricedLine {
        let name: String
        let amount: Double
        let negative: Bool
    }

    /// Splits "LAIT 2% 2L 4.99 F" into ("LAIT 2% 2L", 4.99). Returns nil if there is no price at the end.
    private static func splitPrice(_ line: String) -> PricedLine? {
        let s = line.trimmingCharacters(in: .whitespaces)

        if let m = priceTailRx.firstMatch(in: s) {
            let flag = priceTailRx.group(m, 5, in: s) ?? ""
            // A trailing word is a tax flag only if it is ALL CAPS ("F", "FP", "MRJ"); otherwise it's part of the name
            let flagIsValid = flag.isEmpty || flag == flag.uppercased()
            if flagIsValid, let amountText = priceTailRx.group(m, 3, in: s),
               let amount = Double(amountText.replacingOccurrences(of: ",", with: ".")),
               let range = Range(m.range, in: s) {
                let name = String(s[..<range.lowerBound]).trimmingCharacters(in: .whitespaces)
                let negative = priceTailRx.group(m, 1, in: s) != nil
                    || priceTailRx.group(m, 2, in: s) != nil
                    || priceTailRx.group(m, 4, in: s) != nil
                return PricedLine(name: name, amount: amount, negative: negative)
            }
        }

        if let m = priceSpacedRx.firstMatch(in: s), let range = Range(m.range, in: s) {
            let name = String(s[..<range.lowerBound]).trimmingCharacters(in: .whitespaces)
            if name.filter({ $0.isLetter }).count >= 3,
               let dollars = Double(priceSpacedRx.group(m, 1, in: s) ?? ""),
               let cents = Double(priceSpacedRx.group(m, 2, in: s) ?? "") {
                return PricedLine(name: name, amount: dollars + cents / 100.0, negative: false)
            }
        }

        return nil
    }

    // MARK: - Building an item

    private static func makeItem(from namePart: String) -> Draft? {
        var s = namePart.trimmingCharacters(in: .whitespaces)
        var quantity = 1

        s = codePrefixRx.replace(in: s, with: "")      // "E 1234567 " (Costco), "0012345 "
        s = brandPrefixRx.replace(in: s, with: "")     // "KS " (Kirkland Signature)

        // Explicit quantity forms
        if let m = inlineQtyRx.firstMatch(in: s), let n = inlineQtyRx.group(m, 1, in: s), let q = Int(n) {
            quantity = q
            s = inlineQtyRx.removing(m, from: s)
        } else if let m = inlineQtyWordRx.firstMatch(in: s), let n = inlineQtyWordRx.group(m, 1, in: s), let q = Int(n) {
            quantity = q
            s = inlineQtyWordRx.removing(m, from: s)
        } else if let m = inlineQtyXRx.firstMatch(in: s), let n = inlineQtyXRx.group(m, 1, in: s), let q = Int(n) {
            quantity = q
            s = inlineQtyXRx.removing(m, from: s)
        }

        // Leading count, e.g. "2 Latte" (cafes, restaurants)
        if quantity == 1, let m = leadQtyRx.firstMatch(in: s),
           let n = leadQtyRx.group(m, 1, in: s), let q = Int(n), (1...20).contains(q) {
            quantity = q
            s = leadQtyRx.removing(m, from: s)
        }

        // Sizes and weights are NOT quantities: drop "2L", "450G", "10LB", "12X355ML"
        s = sizeRx.replace(in: s)
        s = packRx.replace(in: s)
        s = symbolsRx.replace(in: s)
        s = multiSpaceRx.replace(in: s).trimmingCharacters(in: punctuation)
        s = trailingNumberRx.replace(in: s, with: "").trimmingCharacters(in: punctuation)   // "OEUFS GROS 12" -> "OEUFS GROS"

        guard s.count >= 2, s.count <= 60 else { return nil }
        let letters = s.filter { $0.isLetter }.count
        let digits = s.filter { $0.isNumber }.count
        guard letters >= 2, digits <= letters, wordRx.test(s) else { return nil }
        guard !genericNames.contains(fold(s)) else { return nil }

        let name = titleCase(s)
        return Draft(name: name, quantity: quantity, category: ItemEmojiHelper.detectCategory(for: name))
    }

    private static func titleCase(_ s: String) -> String {
        s.split(separator: " ").map { word -> String in
            let w = String(word)
            if numericWordRx.test(w) { return w }
            return w.prefix(1).uppercased() + w.dropFirst().lowercased()
        }.joined(separator: " ")
    }

    // MARK: - Text helpers

    private static func collapseSpaces(_ s: String) -> String {
        s.replacingOccurrences(of: "[ \\t\\u00A0]+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// lower-case, no accents, apostrophes become spaces (same normalisation as ItemEmojiHelper)
    private static func fold(_ s: String) -> String {
        var t = s.lowercased()
        t = t.replacingOccurrences(of: "œ", with: "oe")
        t = t.replacingOccurrences(of: "’", with: " ")
        t = t.replacingOccurrences(of: "'", with: " ")
        t = t.folding(options: .diacriticInsensitive, locale: Locale(identifier: "en_US"))
        return t.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
