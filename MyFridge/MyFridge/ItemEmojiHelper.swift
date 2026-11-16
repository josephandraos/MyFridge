//
//  ItemEmojiHelper.swift
//  MyFridge
//
//  Picks an emoji and a category from an item name.
//  Understands English AND French (including Quebec terms such as
//  "yogourt", "beigne", "pinotte", "poutine", "lardons").
//
//  How matching works:
//   • The name is lower-cased and accents are removed ("Crème" -> "creme").
//   • Rules are checked top to bottom and the FIRST rule that matches wins,
//     so more specific rules must come before general ones
//     (e.g. "peanut butter" before "butter", "laitue" before "lait").
//   • `starts` keywords match at the START of a word ("lait" matches "lait 2%"
//     but not "ballast"). `words` keywords must match a whole word ("the", "vin").
//

import Foundation

struct ItemEmojiHelper {

    // MARK: - Public API

    static func emoji(for itemName: String) -> String {
        return rule(for: itemName)?.emoji ?? defaultEmoji
    }

    static func detectCategory(for itemName: String) -> ItemCategory {
        return rule(for: itemName)?.category ?? .snacks
    }

    // MARK: - Matching

    private static let defaultEmoji = "🍿"

    private struct Rule {
        let emoji: String
        let category: ItemCategory
        let regex: NSRegularExpression?

        init(_ emoji: String, _ category: ItemCategory, starts: [String], words: [String] = []) {
            self.emoji = emoji
            self.category = category

            var alternatives: [String] = []
            for keyword in starts {
                alternatives.append(NSRegularExpression.escapedPattern(for: keyword))
            }
            for keyword in words {
                alternatives.append(NSRegularExpression.escapedPattern(for: keyword) + "(?![a-z0-9])")
            }
            let pattern = "(?<![a-z0-9])(?:" + alternatives.joined(separator: "|") + ")"
            self.regex = try? NSRegularExpression(pattern: pattern)
        }

        func matches(_ text: String) -> Bool {
            guard let regex = regex else { return false }
            let range = NSRange(text.startIndex..., in: text)
            return regex.firstMatch(in: text, range: range) != nil
        }
    }

    private static func rule(for itemName: String) -> Rule? {
        let text = normalize(itemName)
        guard !text.isEmpty else { return nil }
        return rules.first { $0.matches(text) }
    }

    /// lower-case, no accents, apostrophes become spaces ("d'arachide" -> "d arachide")
    private static func normalize(_ name: String) -> String {
        var text = name.lowercased()
        text = text.replacingOccurrences(of: "œ", with: "oe")
        text = text.replacingOccurrences(of: "’", with: " ")
        text = text.replacingOccurrences(of: "'", with: " ")
        text = text.folding(options: .diacriticInsensitive, locale: Locale(identifier: "en_US"))
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Rules (first match wins)

    private static let rules: [Rule] = [

        // --- Ice cream and frozen (must come first) ---
        Rule("🍦", .dairy, starts: ["ice cream", "icecream", "creme glace", "gelato", "sorbet"]),
        Rule("🧊", .frozen, starts: ["frozen", "congele", "surgele", "glacon"], words: ["ice"]),
        Rule("🥟", .frozen, starts: ["dumpling", "gyoza", "raviolis chinois"]),

        // --- Specific vegetables that other rules would swallow ---
        Rule("🥦", .vegetables, starts: ["broccoli", "brocoli", "cauliflower", "chou fleur", "chou-fleur"]),
        Rule("🥬", .vegetables, starts: ["laitue", "lettuce", "salad", "salade", "spinach", "epinard", "celery", "celeri", "kale", "chou", "cabbage"]),
        Rule("🍆", .vegetables, starts: ["eggplant", "aubergine"]),
        Rule("🎃", .vegetables, starts: ["butternut", "courge", "squash", "citrouille", "pumpkin"]),

        // --- Nuts and nut butters (before butter / nut-like words) ---
        Rule("🥜", .snacks, starts: ["peanut", "arachide", "pinotte", "beurre d arachide", "nut", "noix", "noisette", "hazelnut", "amande", "almond", "cashew", "pistach"]),

        // --- Prepared / fast food that contains meat words ---
        Rule("🍔", .prepared, starts: ["burger", "hamburger"]),
        Rule("🌭", .prepared, starts: ["hot dog", "hotdog", "chien chaud"]),
        Rule("🍟", .prepared, starts: ["poutine", "frite", "fries", "french fries"]),
        Rule("🍲", .prepared, starts: ["pate chinois"]),
        Rule("🥧", .prepared, starts: ["tourtiere", "quiche", "pot pie"]),

        // --- Snacks that contain other words ---
        Rule("🍟", .snacks, starts: ["chips", "croustille"]),
        Rule("🍿", .snacks, starts: ["popcorn", "mais souffle", "mais a eclater"]),
        Rule("🥔", .vegetables, starts: ["pomme de terre", "pommes de terre", "potato", "patate"]),

        // --- Sauces and condiments (before tomato / pasta etc.) ---
        Rule("🍅", .snacks, starts: ["ketchup"]),
        Rule("🫙", .snacks, starts: ["sauce", "salsa", "mayo", "moutarde", "mustard", "vinaigr", "vinegar", "dressing", "hummus", "relish", "confiture", "pickle", "cornichon", "marinade"], words: ["jam"]),

        // --- Juice (before fruit names like "orange") ---
        Rule("🧃", .beverages, starts: ["juice", "jus"]),

        // --- Dairy & eggs ---
        Rule("🍶", .dairy, starts: ["yogurt", "yoghurt", "yogourt", "yaourt"]),
        Rule("🧈", .dairy, starts: ["butter", "beurre"]),
        Rule("🧀", .dairy, starts: ["cheese", "fromage", "cheddar", "mozzarella", "parmesan", "feta", "brie", "ricotta", "cottage", "gouda", "swiss", "emmental"]),
        Rule("🥚", .dairy, starts: ["egg", "oeuf"]),
        Rule("🥛", .dairy, starts: ["milk", "lait", "cream", "creme"]),

        // --- Meat & fish ---
        Rule("🍗", .meat, starts: ["chicken", "poulet", "turkey", "dinde"]),
        Rule("🥩", .meat, starts: ["steak", "beef", "boeuf", "bifteck", "ground beef", "viande", "meat"]),
        Rule("🥓", .meat, starts: ["bacon", "lardon", "lard"]),
        Rule("🌭", .meat, starts: ["sausage", "saucisse", "saucisson", "merguez", "chorizo"]),
        Rule("🍖", .meat, starts: ["pork", "porc", "rib", "cote", "cotelette", "jambon"], words: ["ham"]),
        Rule("🦐", .meat, starts: ["shrimp", "prawn", "crevette", "homard", "lobster", "crab"]),
        Rule("🐟", .meat, starts: ["fish", "poisson", "salmon", "saumon", "tuna", "thon", "tilapia", "morue", "cod", "truite", "trout", "sole", "sardine"]),

        // --- Fruits ---
        Rule("🍉", .fruits, starts: ["watermelon", "melon d eau", "pasteque"]),
        Rule("🍈", .fruits, starts: ["melon", "cantaloup"]),
        Rule("🍊", .fruits, starts: ["orange", "clementine", "mandarin", "pamplemousse", "grapefruit"]),
        Rule("🍎", .fruits, starts: ["apple", "pomme"]),
        Rule("🍌", .fruits, starts: ["banana", "banane"]),
        Rule("🍓", .fruits, starts: ["strawberr", "fraise", "raspberr", "framboise"]),
        Rule("🫐", .fruits, starts: ["blueberr", "bleuet", "myrtille"]),
        Rule("🍇", .fruits, starts: ["grape", "raisin"]),
        Rule("🍋", .fruits, starts: ["lemon", "citron", "lime"]),
        Rule("🍑", .fruits, starts: ["peach", "peche", "nectarine"]),
        Rule("🍒", .fruits, starts: ["cherr", "cerise"]),
        Rule("🍐", .fruits, starts: ["pear", "poire"]),
        Rule("🍍", .fruits, starts: ["pineapple", "ananas"]),
        Rule("🥭", .fruits, starts: ["mango", "mangue"]),
        Rule("🥝", .fruits, starts: ["kiwi"]),
        Rule("🥑", .fruits, starts: ["avocado", "avocat"]),

        // --- Vegetables ---
        Rule("🥕", .vegetables, starts: ["carrot", "carotte"]),
        Rule("🥒", .vegetables, starts: ["cucumber", "concombre", "zucchini", "courgette"]),
        Rule("🍅", .vegetables, starts: ["tomato", "tomate"]),
        Rule("🌽", .vegetables, starts: ["corn", "mais", "ble d inde"]),
        Rule("🧄", .vegetables, starts: ["garlic"], words: ["ail"]),
        Rule("🧅", .vegetables, starts: ["onion", "oignon", "echalote", "shallot"]),
        Rule("🍄", .vegetables, starts: ["mushroom", "champignon"]),
        Rule("🫑", .vegetables, starts: ["pepper", "poivron", "bell"]),
        Rule("🥦", .vegetables, starts: ["vegetable", "legume"]),

        // --- Bread & bakery ---
        Rule("🥐", .bakery, starts: ["croissant", "pain au chocolat", "chocolatine"]),
        Rule("🥖", .bakery, starts: ["baguette", "roll", "petit pain"]),
        Rule("🥯", .bakery, starts: ["bagel"]),
        Rule("🍩", .bakery, starts: ["donut", "doughnut", "beigne"]),
        Rule("🥨", .bakery, starts: ["pretzel", "bretzel"]),
        Rule("🧁", .bakery, starts: ["cupcake", "muffin"]),
        Rule("🍰", .bakery, starts: ["cake", "gateau", "tarte"], words: ["pie"]),
        Rule("🍪", .bakery, starts: ["cookie", "biscuit"]),
        Rule("🍞", .bakery, starts: ["bread", "pain", "pita", "brioche", "toast"]),

        // --- Prepared foods ---
        Rule("🍕", .prepared, starts: ["pizza"]),
        Rule("🥪", .prepared, starts: ["sandwich", "sous marin", "panini"]),
        Rule("🌮", .prepared, starts: ["taco"]),
        Rule("🌯", .prepared, starts: ["burrito", "wrap", "tortilla"]),
        Rule("🍝", .prepared, starts: ["pasta", "pate", "spaghetti", "macaroni", "lasagn", "penne", "fusilli"]),
        Rule("🍛", .prepared, starts: ["curry", "cari"]),
        Rule("🍣", .prepared, starts: ["sushi"]),
        Rule("🍜", .prepared, starts: ["ramen", "noodle", "nouille"]),
        Rule("🍚", .prepared, starts: ["rice", "riz"]),
        Rule("🍲", .prepared, starts: ["soup", "soupe", "chili", "stew", "ragout"]),

        // --- Drinks ---
        Rule("🧋", .beverages, starts: ["bubble tea", "boba"]),
        Rule("☕", .beverages, starts: ["coffee", "cafe", "latte", "cappu", "espresso", "americano", "mocha"]),
        Rule("🍵", .beverages, starts: ["tea", "tisane", "infusion"], words: ["the"]),
        Rule("🍷", .beverages, starts: ["wine"], words: ["vin", "vins"]),
        Rule("🍺", .beverages, starts: ["beer", "biere"]),
        Rule("💧", .beverages, starts: ["water"], words: ["eau", "eaux"]),
        Rule("🥤", .beverages, starts: ["soda", "coke", "pepsi", "sprite", "cola", "smoothie", "boisson", "limonade", "lemonade"], words: ["pop"]),

        // --- Snacks & condiments ---
        Rule("🍫", .snacks, starts: ["chocolate", "chocolat"]),
        Rule("🧂", .snacks, starts: ["salt"], words: ["sel"]),
        Rule("🍯", .snacks, starts: ["honey", "miel", "sirop", "syrup"]),
        Rule("🍬", .snacks, starts: ["candy", "bonbon"]),
        Rule("🍘", .snacks, starts: ["cracker", "craquelin"]),
        Rule("🥣", .snacks, starts: ["cereal", "cereale", "granola", "avoine", "oat"]),
    ]
}
