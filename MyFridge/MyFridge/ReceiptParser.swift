//
//  ReceiptParser.swift
//  MyFridge
//
//  Receipt parsing logic for scanning grocery receipts
//

import Foundation

struct ReceiptParser {
    
    // MARK: - Canadian Brand Database
    // Maps brand names (as they appear on receipts) to generic product name and category
    
    private static let canadianBrands: [String: (product: String, category: ItemCategory)] = [
        // ============================================
        // MILK BRANDS
        // ============================================
        
        // National Brands
        "neilson milk": ("Milk", .dairy),
        "natrel milk": ("Milk", .dairy),
        "lactantia milk": ("Milk", .dairy),
        "beatrice milk": ("Milk", .dairy),
        "no name milk": ("Milk", .dairy),
        "pc milk": ("Milk", .dairy),
        "gay lea milk": ("Milk", .dairy),
        "dairyland milk": ("Milk", .dairy),
        "island farms milk": ("Milk", .dairy),
        "sealtest milk": ("Milk", .dairy),
        "agropur milk": ("Milk", .dairy),
        "coop milk": ("Milk", .dairy),
        "kirkland milk": ("Milk", .dairy),
        "clover leaf dairy milk": ("Milk", .dairy),
        "mcdairy milk": ("Milk", .dairy),
        "quebecor lait": ("Milk", .dairy),
        "danone milk": ("Milk", .dairy),
        "saputo milk": ("Milk", .dairy),
        "parmalat milk": ("Milk", .dairy),
        "grassland milk": ("Milk", .dairy),
        "schroeder milk": ("Milk", .dairy),
        "baulne milk": ("Milk", .dairy),
        
        // Store Brands
        "presidents choice milk": ("Milk", .dairy),
        "compliments milk": ("Milk", .dairy),
        "great value milk": ("Milk", .dairy),
        "irresistibles milk": ("Milk", .dairy),
        "farmers milk": ("Milk", .dairy),
        "co-op gold milk": ("Milk", .dairy),
        "costco kirkland milk": ("Milk", .dairy),
        "longos milk": ("Milk", .dairy),
        "metro irresistibles milk": ("Milk", .dairy),
        "freshco compliments milk": ("Milk", .dairy),
        
        // Specialty/Organic/Lactose-Free
        "natrel lactose free": ("Lactose-Free Milk", .dairy),
        "lactantia organic": ("Organic Milk", .dairy),
        "neilson organic": ("Organic Milk", .dairy),
        "beatrice lactose free": ("Lactose-Free Milk", .dairy),
        "silk oat milk": ("Oat Milk", .dairy),
        "alpro milk": ("Plant Milk", .dairy),
        "oatly milk": ("Oat Milk", .dairy),
        "earths own oat milk": ("Oat Milk", .dairy),
        "so fresh almond milk": ("Almond Milk", .dairy),
        "elmurray milk": ("Milk", .dairy),
        
        // Regional
        "cape breton dairy milk": ("Milk", .dairy),
        "scots burn milk": ("Milk", .dairy),
        "central dairy milk": ("Milk", .dairy),
        "valacta lait": ("Milk", .dairy),
        "byrne dairy milk": ("Milk", .dairy),
        "country charm milk": ("Milk", .dairy),
        "dairyland bc milk": ("Milk", .dairy),
        "island farms bc milk": ("Milk", .dairy),
        
        // ============================================
        // BUTTER BRANDS
        // ============================================
        
        // National Brands
        "lactantia butter": ("Butter", .dairy),
        "gay lea butter": ("Butter", .dairy),
        "beatrice butter": ("Butter", .dairy),
        "natrel butter": ("Butter", .dairy),
        "saputo butter": ("Butter", .dairy),
        "neilson butter": ("Butter", .dairy),
        "presidents choice butter": ("Butter", .dairy),
        "no name butter": ("Butter", .dairy),
        "compliments butter": ("Butter", .dairy),
        "irresistibles butter": ("Butter", .dairy),
        "great value butter": ("Butter", .dairy),
        "coop gold butter": ("Butter", .dairy),
        "kirkland butter": ("Butter", .dairy),
        "sealtest butter": ("Butter", .dairy),
        "agropur butter": ("Butter", .dairy),
        
        // Premium/Specialty/Imported
        "president butter": ("Butter", .dairy),
        "lurpak butter": ("Butter", .dairy),
        "isigny sainte mere butter": ("Butter", .dairy),
        "kerrygold butter": ("Butter", .dairy),
        "anchor butter": ("Butter", .dairy),
        "devondal butter": ("Butter", .dairy),
        "parmalat butter": ("Butter", .dairy),
        "avonmore butter": ("Butter", .dairy),
        "les prairies bio butter": ("Organic Butter", .dairy),
        "organic meadow butter": ("Organic Butter", .dairy),
        "stonyfield organic butter": ("Organic Butter", .dairy),
        
        // Store & Regional
        "longos butter": ("Butter", .dairy),
        "farmers butter": ("Butter", .dairy),
        "island farms butter": ("Butter", .dairy),
        "dairyland butter": ("Butter", .dairy),
        "quebecor beurre": ("Butter", .dairy),
        "valacta beurre": ("Butter", .dairy),
        "agricop butter": ("Butter", .dairy),
        "shoppers butter": ("Butter", .dairy),
        "sdm butter": ("Butter", .dairy),
        "food basics butter": ("Butter", .dairy),
        "freshco butter": ("Butter", .dairy),
        
        // Variations
        "lactantia unsalted butter": ("Unsalted Butter", .dairy),
        "lactantia salted butter": ("Salted Butter", .dairy),
        "gay lea spreadable butter": ("Butter", .dairy),
        "kirkland irish butter": ("Butter", .dairy),
        "natrel unsalted butter": ("Unsalted Butter", .dairy),
        "pc european style butter": ("Butter", .dairy),
        "great value salted butter": ("Salted Butter", .dairy),
        "no name butter 454g": ("Butter", .dairy),
        "irresistibles unsalted butter": ("Unsalted Butter", .dairy),
        
        // ============================================
        // CHEESE BRANDS
        // ============================================
        
        // National Brands
        "saputo cheese": ("Cheese", .dairy),
        "cracker barrel cheese": ("Cheese", .dairy),
        "black diamond cheese": ("Cheese", .dairy),
        "armstrong cheese": ("Cheese", .dairy),
        "lactantia cheese": ("Cheese", .dairy),
        "beatrice cheese": ("Cheese", .dairy),
        "natrel cheese": ("Cheese", .dairy),
        "gay lea cheese": ("Cheese", .dairy),
        "island farms cheese": ("Cheese", .dairy),
        "dairyland cheese": ("Cheese", .dairy),
        "no name cheese": ("Cheese", .dairy),
        "presidents choice cheese": ("Cheese", .dairy),
        "compliments cheese": ("Cheese", .dairy),
        "irresistibles cheese": ("Cheese", .dairy),
        "great value cheese": ("Cheese", .dairy),
        "kirkland cheese": ("Cheese", .dairy),
        "coop gold cheese": ("Cheese", .dairy),
        "agropur cheese": ("Cheese", .dairy),
        
        // Imported & Specialty
        "president cheese": ("Cheese", .dairy),
        "babybel cheese": ("Cheese", .dairy),
        "the laughing cow cheese": ("Cheese", .dairy),
        "laugh cow cheese": ("Cheese", .dairy),
        "boursin cheese": ("Cheese", .dairy),
        "philadelphia cream cheese": ("Cream Cheese", .dairy),
        "philly cream cheese": ("Cream Cheese", .dairy),
        "castello cheese": ("Cheese", .dairy),
        "galbani cheese": ("Cheese", .dairy),
        "parmigiano reggiano cheese": ("Parmesan", .dairy),
        "grana padano cheese": ("Parmesan", .dairy),
        "pecorino romano cheese": ("Cheese", .dairy),
        "kerrygold cheese": ("Cheese", .dairy),
        "saputo mozzarella": ("Mozzarella", .dairy),
        "black diamond cheddar": ("Cheddar", .dairy),
        "cracker barrel old cheddar": ("Cheddar", .dairy),
        "armstrong marble cheese": ("Marble Cheese", .dairy),
        "oasis feta cheese": ("Feta", .dairy),
        "tre stelle cheese": ("Cheese", .dairy),
        "mediterraneo feta cheese": ("Feta", .dairy),
        "st-albert cheese curds": ("Cheese Curds", .dairy),
        "fromagerie bergeron cheese": ("Cheese", .dairy),
        "oka cheese": ("Cheese", .dairy),
        "le petit quebec cheese": ("Cheese", .dairy),
        "chevalier brie cheese": ("Brie", .dairy),
        
        // Organic/Local/Artisanal
        "organic meadow cheese": ("Organic Cheese", .dairy),
        "stonyfield cheese": ("Cheese", .dairy),
        "avonlea clothbound cheddar": ("Cheddar", .dairy),
        "cows creamery cheese": ("Cheese", .dairy),
        "cheese bouton dor": ("Cheese", .dairy),
        "fromagerie lancetre cheese": ("Organic Cheese", .dairy),
        "fine cheese co cheese": ("Cheese", .dairy),
        "natural pastures cheese": ("Cheese", .dairy),
        "mountain oak cheese": ("Cheese", .dairy),
        
        // Store Brand Variations
        "pc old cheddar": ("Cheddar", .dairy),
        "no name mozzarella": ("Mozzarella", .dairy),
        "compliments brick cheese": ("Brick Cheese", .dairy),
        "irresistibles cheddar": ("Cheddar", .dairy),
        "great value marble cheese": ("Marble Cheese", .dairy),
        "coop gold shredded cheese": ("Shredded Cheese", .dairy),
        "metro irresistibles feta": ("Feta", .dairy),
        "costco kirkland cheese block": ("Cheese", .dairy),
        "farmers cheese curds": ("Cheese Curds", .dairy),
        
        // ============================================
        // ICE CREAM BRANDS
        // ============================================
        
        // Major Brands
        "breyers ice cream": ("Ice Cream", .dairy),
        "haagen-dazs ice cream": ("Ice Cream", .dairy),
        "haagen dazs ice crm": ("Ice Cream", .dairy),
        "chapmans ice cream": ("Ice Cream", .dairy),
        "chapman ice crm": ("Ice Cream", .dairy),
        "nestle ice cream": ("Ice Cream", .dairy),
        "natrel ice cream": ("Ice Cream", .dairy),
        "lactantia ice cream": ("Ice Cream", .dairy),
        "beatrice ice cream": ("Ice Cream", .dairy),
        "kawartha dairy ice cream": ("Ice Cream", .dairy),
        "island farms ice cream": ("Ice Cream", .dairy),
        "dairyland ice cream": ("Ice Cream", .dairy),
        "gay lea ice cream": ("Ice Cream", .dairy),
        "saputo ice cream": ("Ice Cream", .dairy),
        "neilson ice cream": ("Ice Cream", .dairy),
        
        // Store Brands
        "presidents choice ice cream": ("Ice Cream", .dairy),
        "pc ice cream": ("Ice Cream", .dairy),
        "no name ice cream": ("Ice Cream", .dairy),
        "compliments ice cream": ("Ice Cream", .dairy),
        "irresistibles ice cream": ("Ice Cream", .dairy),
        "great value ice cream": ("Ice Cream", .dairy),
        "coop gold ice cream": ("Ice Cream", .dairy),
        "kirkland ice cream": ("Ice Cream", .dairy),
        "longos ice cream": ("Ice Cream", .dairy),
        "farm boy ice cream": ("Ice Cream", .dairy),
        "food basics ice cream": ("Ice Cream", .dairy),
        
        // Premium/Specialty
        "ben & jerrys ice cream": ("Ice Cream", .dairy),
        "ben and jerrys": ("Ice Cream", .dairy),
        "baskin robbins ice cream": ("Ice Cream", .dairy),
        "magnum ice cream": ("Ice Cream", .dairy),
        "talenti gelato": ("Gelato", .dairy),
        "talenti ice crm": ("Gelato", .dairy),
        "so delicious ice cream": ("Ice Cream", .dairy),
        "oatly ice cream": ("Ice Cream", .dairy),
        "silk ice cream": ("Ice Cream", .dairy),
        "alpro ice cream": ("Ice Cream", .dairy),
        "coconut bliss ice cream": ("Ice Cream", .dairy),
        "halo top ice cream": ("Ice Cream", .dairy),
        "hagen ice crm mini cup": ("Ice Cream", .dairy),
        "kerrygold ice cream": ("Ice Cream", .dairy),
        
        // Regional/Local
        "cows ice cream": ("Ice Cream", .dairy),
        "made in canada ice cream": ("Ice Cream", .dairy),
        "chapmans lite ice crm": ("Ice Cream", .dairy),
        "kawartha vanilla ice crm": ("Ice Cream", .dairy),
        "island farms neapolitan ice crm": ("Ice Cream", .dairy),
        "dairyland french vanilla ice crm": ("Ice Cream", .dairy),
        
        // ============================================
        // EGG BRANDS
        // ============================================
        
        // Major Brands
        "burnbrae farms eggs": ("Eggs", .dairy),
        "burnbrae eggs": ("Eggs", .dairy),
        "grey ridge eggs": ("Eggs", .dairy),
        "golden valley eggs": ("Eggs", .dairy),
        "conestoga eggs": ("Eggs", .dairy),
        "nestla eggs": ("Eggs", .dairy),
        "naturegg omega eggs": ("Omega-3 Eggs", .dairy),
        "naturegg": ("Eggs", .dairy),
        "egg creations": ("Liquid Eggs", .dairy),
        "eggsmart liquid eggs": ("Liquid Eggs", .dairy),
        "neilson eggs": ("Eggs", .dairy),
        "maplehill farms eggs": ("Eggs", .dairy),
        "vitae farms eggs": ("Eggs", .dairy),
        "omega pro eggs": ("Omega-3 Eggs", .dairy),
        "egglicious eggs": ("Eggs", .dairy),
        
        // Store Brands
        "presidents choice eggs": ("Eggs", .dairy),
        "pc eggs": ("Eggs", .dairy),
        "pc free run eggs": ("Free-Run Eggs", .dairy),
        "no name eggs": ("Eggs", .dairy),
        "compliments eggs": ("Eggs", .dairy),
        "irresistibles eggs": ("Eggs", .dairy),
        "great value eggs": ("Eggs", .dairy),
        "coop gold eggs": ("Eggs", .dairy),
        "kirkland eggs": ("Eggs", .dairy),
        "longos eggs": ("Eggs", .dairy),
        "farm boy eggs": ("Eggs", .dairy),
        "metro irresistibles eggs": ("Eggs", .dairy),
        "freshco compliments eggs": ("Eggs", .dairy),
        "costco kirkland omega eggs": ("Omega-3 Eggs", .dairy),
        
        // Organic/Specialty
        "burnbrae organic eggs": ("Organic Eggs", .dairy),
        "naturegg free run eggs": ("Free-Run Eggs", .dairy),
        "naturegg omega 3 eggs": ("Omega-3 Eggs", .dairy),
        "organic meadow eggs": ("Organic Eggs", .dairy),
        "vitae organic eggs": ("Organic Eggs", .dairy),
        "vitae free range eggs": ("Free-Range Eggs", .dairy),
        "conestoga organic eggs": ("Organic Eggs", .dairy),
        "maplehill organic eggs": ("Organic Eggs", .dairy),
        "cloverleaf organic eggs": ("Organic Eggs", .dairy),
        
        // Regional
        "nova scotia eggs": ("Eggs", .dairy),
        "pinehill farms eggs": ("Eggs", .dairy),
        "island eggs": ("Eggs", .dairy),
        "ontario egg producers": ("Eggs", .dairy),
        "manitoba egg farmers": ("Eggs", .dairy),
        "alberta farm fresh eggs": ("Eggs", .dairy),
        "bc fresh eggs": ("Eggs", .dairy),
        "abbotsford eggs": ("Eggs", .dairy),
        "sperling farms eggs": ("Eggs", .dairy),
        "st-lawrence eggs": ("Eggs", .dairy),
        "valacta oeufs": ("Eggs", .dairy),
        
        // Liquid Egg Products
        "egg creations original": ("Liquid Eggs", .dairy),
        "egg creations western": ("Liquid Eggs", .dairy),
        "burnbrae liquid eggs": ("Liquid Eggs", .dairy),
        "naturegg liquid whites": ("Egg Whites", .dairy),
        "pc liquid egg whites": ("Egg Whites", .dairy),
        "no name liquid egg": ("Liquid Eggs", .dairy),
        "great value liquid egg whites": ("Egg Whites", .dairy),
        
        // ============================================
        // YOGURT BRANDS
        // ============================================
        
        // Major Brands
        "astro yogurt": ("Yogurt", .dairy),
        "iogo yogurt": ("Yogurt", .dairy),
        "oikos yogurt": ("Greek Yogurt", .dairy),
        "activia yogurt": ("Yogurt", .dairy),
        "danone yogurt": ("Yogurt", .dairy),
        "liberte yogurt": ("Yogurt", .dairy),
        "silhouette yogurt": ("Yogurt", .dairy),
        "yoplait yogurt": ("Yogurt", .dairy),
        "yop drinkable yogurt": ("Yogurt Drink", .dairy),
        "yop yogurt drink": ("Yogurt Drink", .dairy),
        "source yogurt": ("Yogurt", .dairy),
        "tubes yogurt": ("Yogurt", .dairy),
        "natrel yogurt": ("Yogurt", .dairy),
        "beatrice yogurt": ("Yogurt", .dairy),
        "lactantia yogurt": ("Yogurt", .dairy),
        "no name yogurt": ("Yogurt", .dairy),
        "presidents choice yogurt": ("Yogurt", .dairy),
        "compliments yogurt": ("Yogurt", .dairy),
        "irresistibles yogurt": ("Yogurt", .dairy),
        "great value yogurt": ("Yogurt", .dairy),
        "coop gold yogurt": ("Yogurt", .dairy),
        "kirkland yogurt": ("Yogurt", .dairy),
        
        // Greek Yogurt
        "oikos greek yogurt": ("Greek Yogurt", .dairy),
        "liberte greek yogurt": ("Greek Yogurt", .dairy),
        "pc greek yogurt": ("Greek Yogurt", .dairy),
        "kirkland greek yogurt": ("Greek Yogurt", .dairy),
        "great value greek yogurt": ("Greek Yogurt", .dairy),
        "iogo greek yogurt": ("Greek Yogurt", .dairy),
        "activia greek yogurt": ("Greek Yogurt", .dairy),
        "danone greek yogurt": ("Greek Yogurt", .dairy),
        "riviera greek yogurt": ("Greek Yogurt", .dairy),
        "rachels greek yogurt": ("Greek Yogurt", .dairy),
        
        // Drinkable & Kefir
        "yop yogurt drink": ("Yogurt Drink", .dairy),
        "iogo nanos drink": ("Yogurt Drink", .dairy),
        "activia drinkable": ("Yogurt Drink", .dairy),
        "kefir yogurt drink": ("Kefir", .dairy),
        "liberte kefir": ("Kefir", .dairy),
        "pc kefir": ("Kefir", .dairy),
        "great value kefir": ("Kefir", .dairy),
        "natrel yogurt drink": ("Yogurt Drink", .dairy),
        "beatrice yogurt drink": ("Yogurt Drink", .dairy),
        
        // Organic/Specialty
        "organic meadow yogurt": ("Organic Yogurt", .dairy),
        "stonyfield organic yogurt": ("Organic Yogurt", .dairy),
        "riviera organic yogurt": ("Organic Yogurt", .dairy),
        "iogo probiotic yogurt": ("Probiotic Yogurt", .dairy),
        "activia probiotic yogurt": ("Probiotic Yogurt", .dairy),
        "green valley organic yogurt": ("Organic Yogurt", .dairy),
        "maple hill organic yogurt": ("Organic Yogurt", .dairy),
        "yoso dairy free yogurt": ("Plant-Based Yogurt", .dairy),
        "silk yogurt": ("Plant-Based Yogurt", .dairy),
        "so delicious yogurt": ("Plant-Based Yogurt", .dairy),
        "alpro yogurt": ("Plant-Based Yogurt", .dairy),
        "oatly yogurt": ("Plant-Based Yogurt", .dairy),
        
        // Regional/Local
        "maison riviera yogurt": ("Yogurt", .dairy),
        "la ferme bowker yogurt": ("Yogurt", .dairy),
        "island farms yogurt": ("Yogurt", .dairy),
        "dairyland yogurt": ("Yogurt", .dairy),
        "cows creamery yogurt": ("Yogurt", .dairy),
        "scots burn yogurt": ("Yogurt", .dairy),
        
        // Store Variants
        "pc yogurt": ("Yogurt", .dairy),
        "longos yogurt": ("Yogurt", .dairy),
        "farm boy yogurt": ("Yogurt", .dairy),
        
        // ============================================
        // CREAM BRANDS
        // ============================================
        
        // Major Brands
        "beatrice cream": ("Cream", .dairy),
        "lactantia cream": ("Cream", .dairy),
        "natrel cream": ("Cream", .dairy),
        "neilson cream": ("Cream", .dairy),
        "sealtest cream": ("Cream", .dairy),
        "dairyland cream": ("Cream", .dairy),
        "island farms cream": ("Cream", .dairy),
        "agropur cream": ("Cream", .dairy),
        "gay lea cream": ("Cream", .dairy),
        "saputo cream": ("Cream", .dairy),
        "coop gold cream": ("Cream", .dairy),
        "farmers cream": ("Cream", .dairy),
        "kirkland cream": ("Cream", .dairy),
        "presidents choice cream": ("Cream", .dairy),
        "pc cream": ("Cream", .dairy),
        "no name cream": ("Cream", .dairy),
        "compliments cream": ("Cream", .dairy),
        "irresistibles cream": ("Cream", .dairy),
        "great value cream": ("Cream", .dairy),
        
        // Cream Types
        "half and half cream": ("Half & Half", .dairy),
        "10% cream": ("Table Cream", .dairy),
        "18% coffee cream": ("Coffee Cream", .dairy),
        "35% whipping cream": ("Whipping Cream", .dairy),
        "whipping cream 1l": ("Whipping Cream", .dairy),
        "table cream": ("Table Cream", .dairy),
        "cooking cream": ("Cooking Cream", .dairy),
        "light cream": ("Light Cream", .dairy),
        "heavy cream": ("Heavy Cream", .dairy),
        "ultra cream": ("Cream", .dairy),
        "sour cream": ("Sour Cream", .dairy),
        "creme a cafe": ("Coffee Cream", .dairy),
        
        // Coffee Creamers
        "coffeemate creamer": ("Creamer", .dairy),
        "coffee mate crm": ("Creamer", .dairy),
        "international delight creamer": ("Creamer", .dairy),
        "intl delight crm": ("Creamer", .dairy),
        "baileys creamer": ("Creamer", .dairy),
        "nestle coffee mate": ("Creamer", .dairy),
        "starbucks creamer": ("Creamer", .dairy),
        "pc creamer": ("Creamer", .dairy),
        "no name coffee creamer": ("Creamer", .dairy),
        "compliments coffee creamer": ("Creamer", .dairy),
        "irresistibles creamer": ("Creamer", .dairy),
        "great value creamer": ("Creamer", .dairy),
        
        // Plant-Based Creamers
        "silk creamer": ("Plant-Based Creamer", .dairy),
        "oatly creamer": ("Oat Creamer", .dairy),
        "so delicious creamer": ("Plant-Based Creamer", .dairy),
        "alpro creamer": ("Plant-Based Creamer", .dairy),
        "earths own creamer": ("Plant-Based Creamer", .dairy),
        "nutpods creamer": ("Plant-Based Creamer", .dairy),
        "califia farms creamer": ("Plant-Based Creamer", .dairy),
        "maple hill organic creamer": ("Organic Creamer", .dairy),
        
        // Organic/Specialty
        "organic meadow cream": ("Organic Cream", .dairy),
        "stonyfield organic cream": ("Organic Cream", .dairy),
        "lactantia organic cream": ("Organic Cream", .dairy),
        "natrel organic cream": ("Organic Cream", .dairy),
        "gay lea organic cream": ("Organic Cream", .dairy),
        "valacta creme bio": ("Organic Cream", .dairy),
        
        // Regional
        "island farms cream": ("Cream", .dairy),
        "dairyland whipping cream": ("Whipping Cream", .dairy),
        "farmers 35% cream": ("Whipping Cream", .dairy),
        "scots burn cream": ("Cream", .dairy),
        "byrne dairy cream": ("Cream", .dairy),
        
        // ============================================
        // VEGETABLE BRANDS
        // ============================================

        // Frozen Vegetable Brands
        "arctic gardens vegetables": ("Frozen Vegetables", .vegetables),
        "green giant vegetables": ("Frozen Vegetables", .vegetables),
        "le sieur vegetables": ("Frozen Vegetables", .vegetables),
        "bonduelle vegetables": ("Frozen Vegetables", .vegetables),
        "birds eye vegetables": ("Frozen Vegetables", .vegetables),
        "mccain vegetables": ("Frozen Vegetables", .vegetables),
        "oxford frozen vegetables": ("Frozen Vegetables", .vegetables),
        "fennec vegetables": ("Frozen Vegetables", .vegetables),
        "natures touch vegetables": ("Frozen Vegetables", .vegetables),
        "green giant valley selections": ("Frozen Vegetables", .vegetables),

        // Store Brand Vegetables
        "no name vegetables": ("Frozen Vegetables", .vegetables),
        "presidents choice vegetables": ("Vegetables", .vegetables),
        "pc vegetables": ("Vegetables", .vegetables),
        "compliments vegetables": ("Vegetables", .vegetables),
        "irresistibles vegetables": ("Vegetables", .vegetables),
        "great value vegetables": ("Vegetables", .vegetables),
        "coop gold vegetables": ("Vegetables", .vegetables),
        "kirkland vegetables": ("Vegetables", .vegetables),
        "farm boy vegetables": ("Vegetables", .vegetables),
        "longos vegetables": ("Vegetables", .vegetables),
        "freshco vegetables": ("Vegetables", .vegetables),
        "metro vegetables": ("Vegetables", .vegetables),
        "simply selected vegetables": ("Vegetables", .vegetables),
        "marketside vegetables": ("Vegetables", .vegetables),
        "selection vegetables": ("Vegetables", .vegetables),

        // Fresh Produce Brands
        "dole vegetables": ("Vegetables", .vegetables),
        "del monte vegetables": ("Vegetables", .vegetables),
        "earthbound farm vegetables": ("Organic Vegetables", .vegetables),
        "organic girl": ("Organic Salad", .vegetables),
        "taylor farms": ("Fresh Vegetables", .vegetables),
        "fresh express": ("Salad Mix", .vegetables),
        "eat smart": ("Salad Kit", .vegetables),

        // Regional/Local
        "maple leaf vegetables": ("Vegetables", .vegetables),
        "island farms vegetables": ("Vegetables", .vegetables),
        "dairyland vegetables": ("Vegetables", .vegetables),
        "agropur vegetables": ("Vegetables", .vegetables),
        "farmers vegetables": ("Vegetables", .vegetables),
        "cows vegetables": ("Vegetables", .vegetables),
        "cavendish farms": ("Potatoes", .vegetables),

        // Organic/Specialty
        "green organic vegetables": ("Organic Vegetables", .vegetables),
        "organic meadow vegetables": ("Organic Vegetables", .vegetables),

        // Common Vegetable Products (as they appear on receipts)
        "mixed vegetables": ("Mixed Vegetables", .vegetables),
        "california blend": ("Vegetable Mix", .vegetables),
        "asian blend": ("Vegetable Mix", .vegetables),
        "stir fry mix": ("Stir Fry Mix", .vegetables),
        "salad mix": ("Salad Mix", .vegetables),
        "baby carrots": ("Baby Carrots", .vegetables),
        "mini cucumbers": ("Mini Cucumbers", .vegetables),
        "cherry tomatoes": ("Cherry Tomatoes", .vegetables),
        "grape tomatoes": ("Grape Tomatoes", .vegetables),
        "baby potatoes": ("Baby Potatoes", .vegetables),
        "sweet potato": ("Sweet Potato", .vegetables),
        "russet potatoes": ("Potatoes", .vegetables),
        "yukon gold potatoes": ("Potatoes", .vegetables),
        "red potatoes": ("Potatoes", .vegetables),
        "spring mix": ("Spring Mix", .vegetables),
        "romaine hearts": ("Romaine", .vegetables),
        "iceberg lettuce": ("Lettuce", .vegetables),
        "boston lettuce": ("Lettuce", .vegetables),
        "baby spinach": ("Spinach", .vegetables),
        "kale": ("Kale", .vegetables),
        "broccoli florets": ("Broccoli", .vegetables),
        "cauliflower florets": ("Cauliflower", .vegetables),
        "brussels sprouts": ("Brussels Sprouts", .vegetables),
        "green beans": ("Green Beans", .vegetables),
        "snap peas": ("Snap Peas", .vegetables),
        "snow peas": ("Snow Peas", .vegetables),
        "bell peppers": ("Bell Peppers", .vegetables),
        "red peppers": ("Bell Peppers", .vegetables),
        "yellow peppers": ("Bell Peppers", .vegetables),
        "orange peppers": ("Bell Peppers", .vegetables),
        "jalapeño": ("Jalapeño", .vegetables),
        "serrano": ("Serrano Pepper", .vegetables),
        "zucchini": ("Zucchini", .vegetables),
        "yellow squash": ("Squash", .vegetables),
        "butternut squash": ("Butternut Squash", .vegetables),
        "acorn squash": ("Acorn Squash", .vegetables),
        "spaghetti squash": ("Spaghetti Squash", .vegetables),
        "asparagus": ("Asparagus", .vegetables),
        "green onions": ("Green Onions", .vegetables),
        "red onions": ("Red Onions", .vegetables),
        "white onions": ("White Onions", .vegetables),
        "yellow onions": ("Yellow Onions", .vegetables),
        "sweet onions": ("Sweet Onions", .vegetables),
        "shallots": ("Shallots", .vegetables),
        "leeks": ("Leeks", .vegetables),
        "fresh ginger": ("Ginger", .vegetables),
        "fresh herbs": ("Fresh Herbs", .vegetables),
        "cilantro": ("Cilantro", .vegetables),
        "parsley": ("Parsley", .vegetables),
        "basil": ("Basil", .vegetables),
        "dill": ("Dill", .vegetables),
        "mint": ("Mint", .vegetables),
        "rosemary": ("Rosemary", .vegetables),
        "thyme": ("Thyme", .vegetables),
        "beets": ("Beets", .vegetables),
        "turnips": ("Turnips", .vegetables),
        "radishes": ("Radishes", .vegetables),
        "bok choy": ("Bok Choy", .vegetables),
        "cabbage": ("Cabbage", .vegetables),
        "red cabbage": ("Red Cabbage", .vegetables),
        "napa cabbage": ("Napa Cabbage", .vegetables),
        "coleslaw mix": ("Coleslaw Mix", .vegetables),
        "arugula": ("Arugula", .vegetables),
        "watercress": ("Watercress", .vegetables),
        
        // ============================================
        // FRUIT BRANDS
        // ============================================

        // Fresh Fruit Brands
        "dole fruits": ("Fruit", .fruits),
        "dole banana": ("Banana", .fruits),
        "del monte fruits": ("Fruit", .fruits),
        "chiquita bananas": ("Banana", .fruits),
        "chiquita banana": ("Banana", .fruits),
        "fyffes bananas": ("Banana", .fruits),
        "sunkist fruits": ("Fruit", .fruits),
        "sunkist oranges": ("Orange", .fruits),
        "driscoll strawberries": ("Strawberry", .fruits),
        "driscoll berries": ("Berries", .fruits),
        "driscoll straw": ("Strawberry", .fruits),
        "zespri kiwi": ("Kiwi", .fruits),
        "zespri gold kiwi": ("Kiwi", .fruits),

        // Apple Varieties (common on receipts)
        "jazz apples": ("Apple", .fruits),
        "ambrosia apples": ("Apple", .fruits),
        "honeycrisp apples": ("Apple", .fruits),
        "envy apples": ("Apple", .fruits),
        "pink lady apples": ("Apple", .fruits),
        "granny smith apples": ("Apple", .fruits),
        "royal gala apples": ("Apple", .fruits),
        "fuji apples": ("Apple", .fruits),
        "organic apples": ("Organic Apple", .fruits),
        "sunrise apples": ("Apple", .fruits),
        "mutsu apples": ("Apple", .fruits),
        "mcintosh apples": ("Apple", .fruits),
        "red delicious apples": ("Apple", .fruits),
        "gala apples": ("Apple", .fruits),
        "cortland apples": ("Apple", .fruits),
        "empire apples": ("Apple", .fruits),
        "spartan apples": ("Apple", .fruits),

        // Melons
        "honeydew melon": ("Honeydew", .fruits),
        "cantaloupe melon": ("Cantaloupe", .fruits),
        "watermelon seedless": ("Watermelon", .fruits),

        // Berries
        "berries mix": ("Mixed Berries", .fruits),
        "mixed berries": ("Mixed Berries", .fruits),
        "raspberries": ("Raspberry", .fruits),
        "blackberries": ("Blackberry", .fruits),
        "blueberries": ("Blueberry", .fruits),
        "strawberries": ("Strawberry", .fruits),

        // Tropical Fruits
        "mango": ("Mango", .fruits),
        "pineapple": ("Pineapple", .fruits),
        "papaya": ("Papaya", .fruits),
        "dragon fruit": ("Dragon Fruit", .fruits),
        "passion fruit": ("Passion Fruit", .fruits),
        "guava": ("Guava", .fruits),
        "lychee": ("Lychee", .fruits),
        "starfruit": ("Starfruit", .fruits),

        // Grapes
        "grapes": ("Grape", .fruits),
        "red seedless grapes": ("Red Grapes", .fruits),
        "green seedless grapes": ("Green Grapes", .fruits),
        "black grapes": ("Black Grapes", .fruits),
        "cotton candy grapes": ("Grapes", .fruits),

        // Stone Fruits
        "nectarines": ("Nectarine", .fruits),
        "peaches": ("Peach", .fruits),
        "plums": ("Plum", .fruits),
        "cherries": ("Cherry", .fruits),
        "apricots": ("Apricot", .fruits),

        // Citrus
        "oranges": ("Orange", .fruits),
        "navel oranges": ("Orange", .fruits),
        "clementines": ("Clementine", .fruits),
        "mandarins": ("Mandarin", .fruits),
        "tangerines": ("Tangerine", .fruits),
        "lemons": ("Lemon", .fruits),
        "limes": ("Lime", .fruits),
        "grapefruit": ("Grapefruit", .fruits),
        "blood oranges": ("Orange", .fruits),

        // Other Fruits
        "pears": ("Pear", .fruits),
        "bartlett pears": ("Pear", .fruits),
        "bosc pears": ("Pear", .fruits),
        "anjou pears": ("Pear", .fruits),
        "pomegranate": ("Pomegranate", .fruits),
        "coconut": ("Coconut", .fruits),
        "kiwi fruit": ("Kiwi", .fruits),
        "figs": ("Fig", .fruits),
        "dates": ("Dates", .fruits),
        "persimmons": ("Persimmon", .fruits),

        // Frozen Fruit Brands
        "arctic gardens fruits": ("Frozen Fruit", .fruits),
        "natures touch frozen fruit": ("Frozen Fruit", .fruits),
        "bonduelle fruits": ("Frozen Fruit", .fruits),
        "dole frozen fruit": ("Frozen Fruit", .fruits),
        "compliments frozen fruit": ("Frozen Fruit", .fruits),
        "no name frozen fruit": ("Frozen Fruit", .fruits),
        "presidents choice frozen fruit": ("Frozen Fruit", .fruits),
        "pc frozen fruit": ("Frozen Fruit", .fruits),
        "irresistibles frozen fruit": ("Frozen Fruit", .fruits),
        "great value frozen fruit": ("Frozen Fruit", .fruits),
        "kirkland frozen fruit": ("Frozen Fruit", .fruits),
        "coop gold frozen fruit": ("Frozen Fruit", .fruits),
        "natural sensations frozen fruit": ("Frozen Fruit", .fruits),
        "oasis smoothie fruit mix": ("Frozen Fruit Mix", .fruits),
        "tropical gold frozen fruit": ("Frozen Fruit", .fruits),
        "cascadian farm frozen fruit": ("Organic Frozen Fruit", .fruits),
        "earthbound farm frozen fruit": ("Organic Frozen Fruit", .fruits),

        // Canned / Jarred / Packaged Fruit
        "dole fruit cups": ("Fruit Cup", .fruits),
        "del monte fruit cups": ("Fruit Cup", .fruits),
        "presidents choice fruit cups": ("Fruit Cup", .fruits),
        "pc fruit cups": ("Fruit Cup", .fruits),
        "great value fruit cups": ("Fruit Cup", .fruits),
        "compliments fruit cups": ("Fruit Cup", .fruits),
        "irresistibles fruit cups": ("Fruit Cup", .fruits),
        "no name fruit cups": ("Fruit Cup", .fruits),
        "astro fruit yog mix": ("Yogurt Fruit Mix", .dairy),
        "tropicana fruit mix": ("Fruit Mix", .fruits),
        "oasis fruit salad": ("Fruit Salad", .fruits),
        "sunny fruit": ("Dried Fruit", .fruits),
        "prana organic fruit": ("Organic Dried Fruit", .fruits),
        "sunmaid raisins": ("Raisins", .fruits),
        "ocean spray cranberries": ("Cranberries", .fruits),

        // Dried Fruit Brands
        "sun-maid raisins": ("Raisins", .fruits),
        "sun maid": ("Raisins", .fruits),
        "ocean spray dried cranberries": ("Dried Cranberries", .fruits),
        "craisins": ("Dried Cranberries", .fruits),
        "made in nature": ("Dried Fruit", .fruits),
        "bare snacks": ("Dried Fruit", .fruits),
        "kirkland dried fruit": ("Dried Fruit", .fruits),
        "mariani dried fruit": ("Dried Fruit", .fruits),

        // Organic / Local Brands
        "organic meadow fruits": ("Organic Fruit", .fruits),
        "stonyfield organic fruit mix": ("Organic Fruit", .fruits),
        "earthbound farm organic fruits": ("Organic Fruit", .fruits),
        "natures touch organic fruits": ("Organic Fruit", .fruits),
        "green organic fruits": ("Organic Fruit", .fruits),
        "pc organics fruits": ("Organic Fruit", .fruits),
        "coop gold pure organic fruits": ("Organic Fruit", .fruits),
        "farm boy organic fruits": ("Organic Fruit", .fruits),
        "maison riviera organic fruits": ("Organic Fruit", .fruits),
        "frozenland organic fruits": ("Organic Fruit", .fruits),

        // Store Brand Fruits
        "no name fruit": ("Fruit", .fruits),
        "pc fruit": ("Fruit", .fruits),
        "pc organics fruit": ("Organic Fruit", .fruits),
        "compliments fruit": ("Fruit", .fruits),
        "irresistibles fruit": ("Fruit", .fruits),
        "great value fruit": ("Fruit", .fruits),
        "coop gold fruit": ("Fruit", .fruits),
        "kirkland fruit": ("Fruit", .fruits),
        "longos fruit": ("Fruit", .fruits),
        "farm boy fruit": ("Fruit", .fruits),
        "metro fruit": ("Fruit", .fruits),
        "freshco fruit": ("Fruit", .fruits),

        // Common Receipt Variants
        "fruit mix": ("Fruit Mix", .fruits),
        "fruit cup": ("Fruit Cup", .fruits),
        "frozen fruit": ("Frozen Fruit", .fruits),
        "smoothie fruit": ("Smoothie Fruit", .fruits),
        "fresh fruit": ("Fresh Fruit", .fruits),
        "organic fruit": ("Organic Fruit", .fruits),
        "fruit tray": ("Fruit Tray", .fruits),
        "fruit salad": ("Fruit Salad", .fruits),
        "fruit bowl": ("Fruit Bowl", .fruits),
        "dried fruit": ("Dried Fruit", .fruits),
        "canned fruit": ("Canned Fruit", .fruits),
        "tropical fruit mix": ("Tropical Fruit", .fruits),
        "fruit snacks": ("Fruit Snacks", .snacks),
        
        // ============================================
        // MEAT & FISH BRANDS
        // ============================================

        // Main Meat Brands
        "maple leaf meat": ("Meat", .meat),
        "j.m. schneiders meat": ("Meat", .meat),
        "schneiders": ("Meat", .meat),
        "zabiha halal meat": ("Halal Meat", .meat),
        "swift meat": ("Meat", .meat),
        "butterball turkey": ("Turkey", .meat),
        "janes chicken": ("Chicken", .meat),
        "oak run farms meat": ("Meat", .meat),
        "lilydale chicken": ("Chicken", .meat),
        "hormel meat": ("Meat", .meat),
        "maple lodge farms chicken": ("Chicken", .meat),
        "maple lodge": ("Chicken", .meat),
        "blue ribbon beef": ("Beef", .meat),
        "pintys chicken": ("Chicken", .meat),
        "fletchers meat": ("Meat", .meat),
        "beretta farms beef": ("Beef", .meat),
        "carvers choice meat": ("Meat", .meat),
        "aliments aston beef": ("Beef", .meat),
        "ferme des volailles chicken": ("Chicken", .meat),
        "top dog sausage": ("Sausage", .meat),

        // Plant-Based Meat Alternatives
        "yves veggie cuisine": ("Plant-Based Meat", .meat),
        "beyond meat": ("Plant-Based Meat", .meat),
        "beyond burger": ("Plant-Based Burger", .meat),
        "impossible meat": ("Plant-Based Meat", .meat),
        "morningstar meatless": ("Plant-Based Meat", .meat),
        "sol cuisine meatless": ("Plant-Based Meat", .meat),
        "gusta vegan sausage": ("Vegan Sausage", .meat),
        "lightlife": ("Plant-Based Meat", .meat),
        "gardein": ("Plant-Based Meat", .meat),

        // Chicken / Poultry Brands
        "maple lodge chicken": ("Chicken", .meat),
        "lilydale chicken": ("Chicken", .meat),
        "pintys chicken": ("Chicken", .meat),
        "exceldor chicken": ("Chicken", .meat),
        "farmers market chicken": ("Chicken", .meat),
        "coop gold chicken": ("Chicken", .meat),
        "great value chicken": ("Chicken", .meat),
        "compliments chicken": ("Chicken", .meat),
        "no name chicken": ("Chicken", .meat),
        "presidents choice chicken": ("Chicken", .meat),
        "pc chicken": ("Chicken", .meat),
        "irresistibles chicken": ("Chicken", .meat),
        "kirkland chicken": ("Chicken", .meat),
        "costco rotisserie chicken": ("Rotisserie Chicken", .meat),
        "kirkland rotisserie": ("Rotisserie Chicken", .meat),
        "maple leaf chicken strips": ("Chicken Strips", .meat),
        "schneiders chicken": ("Chicken", .meat),
        "ferme st-zotique chicken": ("Chicken", .meat),
        "agropur poultry": ("Poultry", .meat),
        "aliments dufresne chicken": ("Chicken", .meat),
        "perdue chicken": ("Chicken", .meat),
        "tyson chicken": ("Chicken", .meat),

        // Processed Meat / Cold Cuts / Deli
        "maple leaf deli": ("Deli Meat", .meat),
        "schneiders deli": ("Deli Meat", .meat),
        "dubreton ham": ("Ham", .meat),
        "fletchers deli": ("Deli Meat", .meat),
        "pillers deli": ("Deli Meat", .meat),
        "mcclelland meat": ("Deli Meat", .meat),
        "j.m. schneiders pepperettes": ("Pepperettes", .meat),
        "maple leaf bacon": ("Bacon", .meat),
        "swift bacon": ("Bacon", .meat),
        "lilydale deli meat": ("Deli Meat", .meat),
        "butterball deli": ("Deli Meat", .meat),
        "compliments deli": ("Deli Meat", .meat),
        "pc deli meat": ("Deli Meat", .meat),
        "great value deli meat": ("Deli Meat", .meat),
        "no name deli": ("Deli Meat", .meat),
        "irresistibles deli": ("Deli Meat", .meat),
        "coop gold deli": ("Deli Meat", .meat),
        "kirkland bacon": ("Bacon", .meat),
        "presidents choice ham": ("Ham", .meat),
        "presidents choice bacon": ("Bacon", .meat),
        "pc bacon": ("Bacon", .meat),
        "mccain bacon": ("Bacon", .meat),
        "maple leaf hot dogs": ("Hot Dogs", .meat),
        "schneiders wieners": ("Wieners", .meat),
        "top dog wieners": ("Wieners", .meat),
        "maple lodge franks": ("Hot Dogs", .meat),
        "maple leaf bologna": ("Bologna", .meat),
        "dubreton sausage": ("Sausage", .meat),
        "farm boy sausage": ("Sausage", .meat),
        "olymel": ("Meat", .meat),
        "olymel bacon": ("Bacon", .meat),
        "oscar mayer": ("Deli Meat", .meat),

        // Beef Specific
        "angus beef": ("Beef", .meat),
        "aaa beef": ("Beef", .meat),
        "aa beef": ("Beef", .meat),
        "striploin steak": ("Steak", .meat),
        "rib eye steak": ("Steak", .meat),
        "ribeye": ("Steak", .meat),
        "sirloin steak": ("Steak", .meat),
        "t-bone steak": ("Steak", .meat),
        "ground beef": ("Ground Beef", .meat),
        "beef mince": ("Ground Beef", .meat),
        "roast beef": ("Roast Beef", .meat),
        "prime rib": ("Prime Rib", .meat),
        "brisket": ("Brisket", .meat),
        "short ribs": ("Short Ribs", .meat),
        "stewing beef": ("Stewing Beef", .meat),

        // Pork Specific
        "pork chop": ("Pork Chop", .meat),
        "pork loin": ("Pork Loin", .meat),
        "pork tenderloin": ("Pork Tenderloin", .meat),
        "pork ribs": ("Pork Ribs", .meat),
        "spare ribs": ("Spare Ribs", .meat),
        "back ribs": ("Back Ribs", .meat),
        "ground pork": ("Ground Pork", .meat),
        "pork shoulder": ("Pork Shoulder", .meat),

        // Fish & Seafood Brands
        "high liner fish": ("Fish", .meat),
        "clover leaf tuna": ("Tuna", .meat),
        "cloverleaf tuna": ("Tuna", .meat),
        "oceans tuna": ("Tuna", .meat),
        "ocean's tuna": ("Tuna", .meat),
        "gold seal salmon": ("Salmon", .meat),
        "raincoast tuna": ("Tuna", .meat),
        "seaquest fish": ("Fish", .meat),
        "bluewater fish": ("Fish", .meat),
        "janes fish": ("Fish", .meat),
        "pc fish": ("Fish", .meat),
        "no name fish": ("Fish", .meat),
        "compliments fish": ("Fish", .meat),
        "irresistibles fish": ("Fish", .meat),
        "great value fish": ("Fish", .meat),
        "kirkland salmon": ("Salmon", .meat),
        "costco fresh salmon": ("Salmon", .meat),
        "presidents choice shrimp": ("Shrimp", .meat),
        "pc shrimp": ("Shrimp", .meat),
        "high liner shrimp": ("Shrimp", .meat),
        "oceans salmon": ("Salmon", .meat),
        "ocean's salmon": ("Salmon", .meat),
        "clover leaf salmon": ("Salmon", .meat),
        "nova scotia lobster": ("Lobster", .meat),
        "fisher king fish": ("Fish", .meat),
        "true north seafood": ("Seafood", .meat),
        "frozenland shrimp": ("Shrimp", .meat),
        "canadian seafood fish": ("Fish", .meat),
        "lobster pound lobster": ("Lobster", .meat),
        "sealord fish": ("Fish", .meat),
        "mccain fish sticks": ("Fish Sticks", .meat),
        "icelandic seafood": ("Seafood", .meat),
        "aquastar shrimp": ("Shrimp", .meat),
        "ocean jewel fish": ("Fish", .meat),
        "seaquest shrimp": ("Shrimp", .meat),
        "bela seafood": ("Seafood", .meat),
        "oceans crab": ("Crab", .meat),
        "ocean's crab": ("Crab", .meat),

        // Frozen Meat & Seafood
        "janes frozen chicken": ("Frozen Chicken", .meat),
        "high liner frozen fish": ("Frozen Fish", .meat),
        "maple leaf frozen meatballs": ("Frozen Meatballs", .meat),
        "pc frozen chicken": ("Frozen Chicken", .meat),
        "great value frozen meat": ("Frozen Meat", .meat),
        "compliments frozen chicken": ("Frozen Chicken", .meat),
        "irresistibles frozen fish": ("Frozen Fish", .meat),
        "kirkland frozen salmon": ("Frozen Salmon", .meat),
        "coop gold frozen fish": ("Frozen Fish", .meat),
        "no name frozen meat": ("Frozen Meat", .meat),
        "farm boy frozen chicken": ("Frozen Chicken", .meat),

        // Organic / Local / Premium Brands
        "dubreton organic pork": ("Organic Pork", .meat),
        "beretta farms beef": ("Beef", .meat),
        "rowe farms meat": ("Meat", .meat),
        "blue ridge farms chicken": ("Chicken", .meat),
        "fresh from the farm beef": ("Beef", .meat),
        "cows organic meat": ("Organic Meat", .meat),
        "farm boy meat": ("Meat", .meat),
        "stonyfield organic meat": ("Organic Meat", .meat),
        "cooks organic chicken": ("Organic Chicken", .meat),
        "organic meadow beef": ("Organic Beef", .meat),

        // Store / Private Label
        "no name meat": ("Meat", .meat),
        "pc meat": ("Meat", .meat),
        "pc organics meat": ("Organic Meat", .meat),
        "compliments meat": ("Meat", .meat),
        "irresistibles meat": ("Meat", .meat),
        "great value meat": ("Meat", .meat),
        "coop gold meat": ("Meat", .meat),
        "kirkland meat": ("Meat", .meat),
        "farm boy fish": ("Fish", .meat),
        "longos meat": ("Meat", .meat),
        "longos fish": ("Fish", .meat),
        "metro fish": ("Fish", .meat),
        "freshco fish": ("Fish", .meat),
        "safeway seafood": ("Seafood", .meat),
        "sobeys seafood": ("Seafood", .meat),

        // Common Meat Cuts (as they appear on receipts)
        "chicken breast": ("Chicken Breast", .meat),
        "chicken thigh": ("Chicken Thigh", .meat),
        "chicken drumstick": ("Chicken Drumstick", .meat),
        "chicken wing": ("Chicken Wing", .meat),
        "chicken leg": ("Chicken Leg", .meat),
        "whole chicken": ("Whole Chicken", .meat),
        "turkey breast": ("Turkey Breast", .meat),
        "deli ham": ("Ham", .meat),
        "cold cuts": ("Cold Cuts", .meat),
        "smoked meat": ("Smoked Meat", .meat),
        "pastrami": ("Pastrami", .meat),
        "salami": ("Salami", .meat),
        "pepperoni": ("Pepperoni", .meat),
        "prosciutto": ("Prosciutto", .meat),

        // Seafood Varieties
        "salmon fillet": ("Salmon", .meat),
        "salmon steak": ("Salmon", .meat),
        "atlantic salmon": ("Salmon", .meat),
        "sockeye salmon": ("Salmon", .meat),
        "coho salmon": ("Salmon", .meat),
        "tuna can": ("Canned Tuna", .meat),
        "tuna steak": ("Tuna", .meat),
        "shrimp": ("Shrimp", .meat),
        "prawns": ("Shrimp", .meat),
        "cod fish": ("Cod", .meat),
        "cod fillet": ("Cod", .meat),
        "haddock": ("Haddock", .meat),
        "halibut": ("Halibut", .meat),
        "tilapia": ("Tilapia", .meat),
        "frozen fish": ("Frozen Fish", .meat),
        "seafood mix": ("Seafood Mix", .meat),
        "lobster tail": ("Lobster Tail", .meat),
        "scallops": ("Scallops", .meat),
        "sea scallops": ("Scallops", .meat),
        "mussels": ("Mussels", .meat),
        "crab meat": ("Crab", .meat),
        "snow crab": ("Snow Crab", .meat),
        "king crab": ("King Crab", .meat),
        "crab legs": ("Crab Legs", .meat),
        "oysters": ("Oysters", .meat),
        "clams": ("Clams", .meat),
        "squid": ("Squid", .meat),
        "calamari": ("Calamari", .meat),
        "octopus": ("Octopus", .meat),

        // Lamb
        "lamb chop": ("Lamb Chop", .meat),
        "leg of lamb": ("Lamb", .meat),
        "lamb shank": ("Lamb Shank", .meat),
        "ground lamb": ("Ground Lamb", .meat),
        
        // ============================================
        // BREAD & BAKERY BRANDS
        // ============================================

        // Main Bread Brands
        "wonder bread": ("Bread", .bakery),
        "ditaliano bread": ("Bread", .bakery),
        "d'italiano bread": ("Bread", .bakery),
        "villaggio bread": ("Bread", .bakery),
        "country harvest bread": ("Bread", .bakery),
        "bens bread": ("Bread", .bakery),
        "bon matin bread": ("Bread", .bakery),
        "stonemill bread": ("Bread", .bakery),
        "dimpflmeier bread": ("Bread", .bakery),
        "artisano bread": ("Bread", .bakery),
        "orowheat bread": ("Bread", .bakery),
        "schneiders bread": ("Bread", .bakery),
        "beyond grain bread": ("Bread", .bakery),
        "weston bread": ("Bread", .bakery),
        "ace bakery bread": ("Bread", .bakery),
        "cobs bread": ("Bread", .bakery),
        "cobs bakery": ("Bread", .bakery),
        "daves killer bread": ("Bread", .bakery),
        "dave's killer bread": ("Bread", .bakery),
        "alpine valley bread": ("Bread", .bakery),
        "pom bread": ("Bread", .bakery),
        "pita break bread": ("Pita", .bakery),
        "sunrise bread": ("Bread", .bakery),
        "euro classic bread": ("Bread", .bakery),
        "pepperidge farm bread": ("Bread", .bakery),
        "arnold bread": ("Bread", .bakery),
        "dempsters bread": ("Bread", .bakery),
        "dempster's bread": ("Bread", .bakery),
        "wonder plus bread": ("Bread", .bakery),

        // Bagels, Tortillas, Flatbreads & Pitas
        "dempsters bagels": ("Bagels", .bakery),
        "dempster's bagels": ("Bagels", .bakery),
        "thomas bagels": ("Bagels", .bakery),
        "thomas' bagels": ("Bagels", .bakery),
        "montreal style bagels": ("Bagels", .bakery),
        "bagel house bagels": ("Bagels", .bakery),
        "bageltale bagels": ("Bagels", .bakery),
        "pita break pita": ("Pita", .bakery),
        "freybe flatbread": ("Flatbread", .bakery),
        "mission tortillas": ("Tortillas", .bakery),
        "old el paso tortillas": ("Tortillas", .bakery),
        "la tortilla factory": ("Tortillas", .bakery),
        "presidents choice tortillas": ("Tortillas", .bakery),
        "pc tortillas": ("Tortillas", .bakery),
        "no name tortillas": ("Tortillas", .bakery),
        "compliments tortillas": ("Tortillas", .bakery),
        "irresistibles pita": ("Pita", .bakery),
        "great value tortillas": ("Tortillas", .bakery),
        "coop gold tortillas": ("Tortillas", .bakery),
        "kirkland tortillas": ("Tortillas", .bakery),
        "pc pita bread": ("Pita", .bakery),
        "lavash flatbread": ("Flatbread", .bakery),
        "mediterranean pita": ("Pita", .bakery),
        "naan bread": ("Naan", .bakery),
        "greek pita": ("Pita", .bakery),

        // Bakery & Pastry Brands
        "ace bakery": ("Bakery", .bakery),
        "presidents choice bakery": ("Bakery", .bakery),
        "pc bakery": ("Bakery", .bakery),
        "irresistibles bakery": ("Bakery", .bakery),
        "compliments bakery": ("Bakery", .bakery),
        "no name bakery": ("Bakery", .bakery),
        "great value bakery": ("Bakery", .bakery),
        "coop gold bakery": ("Bakery", .bakery),
        "kirkland bakery": ("Bakery", .bakery),
        "farm boy bakery": ("Bakery", .bakery),
        "longos bakery": ("Bakery", .bakery),
        "metro bakery": ("Bakery", .bakery),
        "freshco bakery": ("Bakery", .bakery),
        "weston bakery": ("Bakery", .bakery),
        "canada bread": ("Bread", .bakery),
        "artisano bakery": ("Bakery", .bakery),
        "la fournee doree": ("Bakery", .bakery),
        "fournee doree": ("Bakery", .bakery),
        "brioche pasquier": ("Brioche", .bakery),
        "danish style pastries": ("Pastries", .bakery),
        "7 days croissants": ("Croissants", .bakery),
        "entenmanns pastries": ("Pastries", .bakery),
        "entenmann's pastries": ("Pastries", .bakery),
        "little debbie cakes": ("Cakes", .bakery),
        "hostess cupcakes": ("Cupcakes", .bakery),
        "vachon pastries": ("Pastries", .bakery),
        "jos louis": ("Pastries", .bakery),
        "ah caramel": ("Pastries", .bakery),
        "drakes pastries": ("Pastries", .bakery),
        "drake's pastries": ("Pastries", .bakery),
        "mccain cakes": ("Cakes", .bakery),
        "bens bakery pastries": ("Pastries", .bakery),
        "st pierre brioche": ("Brioche", .bakery),

        // Frozen Bread & Bakery
        "pc frozen croissants": ("Frozen Croissants", .bakery),
        "irresistibles frozen dough": ("Frozen Dough", .bakery),
        "compliments frozen bread": ("Frozen Bread", .bakery),
        "great value frozen buns": ("Frozen Buns", .bakery),
        "no name frozen dough": ("Frozen Dough", .bakery),
        "coop gold frozen bread": ("Frozen Bread", .bakery),
        "mccain frozen cake": ("Frozen Cake", .bakery),
        "pepperidge farm frozen pastry": ("Frozen Pastry", .bakery),
        "tenderflake pie shells": ("Pie Shells", .bakery),
        "kirkland frozen pastry": ("Frozen Pastry", .bakery),
        "lafayette mini croissants": ("Mini Croissants", .bakery),
        "rhodes frozen rolls": ("Frozen Rolls", .bakery),
        "pillsbury dough": ("Frozen Dough", .bakery),

        // Store / Private Label Bread
        "presidents choice bread": ("Bread", .bakery),
        "pc bread": ("Bread", .bakery),
        "pc organics bread": ("Organic Bread", .bakery),
        "no name bread": ("Bread", .bakery),
        "compliments bread": ("Bread", .bakery),
        "irresistibles bread": ("Bread", .bakery),
        "great value bread": ("Bread", .bakery),
        "coop gold bread": ("Bread", .bakery),
        "kirkland bread": ("Bread", .bakery),
        "farm boy bread": ("Bread", .bakery),
        "longos bread": ("Bread", .bakery),
        "metro bread": ("Bread", .bakery),
        "freshco bread": ("Bread", .bakery),
        "safeway bakery": ("Bakery", .bakery),
        "sobeys bakery": ("Bakery", .bakery),

        // Organic / Health-Focused Bread
        "silver hills bread": ("Sprouted Grain Bread", .bakery),
        "ezekiel bread": ("Sprouted Bread", .bakery),
        "food for life bread": ("Sprouted Bread", .bakery),
        "daves killer bread organic": ("Organic Bread", .bakery),
        "stans organic bread": ("Organic Bread", .bakery),
        "stan's organic bread": ("Organic Bread", .bakery),
        "rudis organic bread": ("Organic Bread", .bakery),
        "rudi's organic bread": ("Organic Bread", .bakery),
        "natures path bread": ("Organic Bread", .bakery),
        "nature's path bread": ("Organic Bread", .bakery),
        "flourish protein bread": ("Protein Bread", .bakery),
        "pc organics whole grain bread": ("Whole Grain Bread", .bakery),
        "country harvest seed & grain": ("Seed Bread", .bakery),
        "stans multigrain bread": ("Multigrain Bread", .bakery),
        "stan's multigrain bread": ("Multigrain Bread", .bakery),
        "alvarado street bakery": ("Sprouted Bread", .bakery),

        // Sweet Bakery / Desserts
        "vachon pastries": ("Pastries", .bakery),
        "hostess twinkies": ("Twinkies", .bakery),
        "little debbie snacks": ("Snacks", .bakery),
        "drakes cakes": ("Cakes", .bakery),
        "drake's cakes": ("Cakes", .bakery),
        "entenmanns donuts": ("Donuts", .bakery),
        "entenmann's donuts": ("Donuts", .bakery),
        "tim hortons muffins": ("Muffins", .bakery),
        "pc bakery muffins": ("Muffins", .bakery),
        "great value muffins": ("Muffins", .bakery),
        "irresistibles pastries": ("Pastries", .bakery),
        "no name cookies": ("Cookies", .bakery),
        "compliments donuts": ("Donuts", .bakery),
        "coop gold cookies": ("Cookies", .bakery),
        "kirkland cookies": ("Cookies", .bakery),
        "presidents choice cookies": ("Cookies", .bakery),
        "pc cookies": ("Cookies", .bakery),
        "oreo cookies": ("Cookies", .bakery),
        "chips ahoy cookies": ("Cookies", .bakery),
        "dad's cookies": ("Cookies", .bakery),

        // Common Bread Types (as they appear on receipts)
        "white bread": ("White Bread", .bakery),
        "whole wheat bread": ("Whole Wheat Bread", .bakery),
        "multigrain bread": ("Multigrain Bread", .bakery),
        "rye bread": ("Rye Bread", .bakery),
        "sourdough bread": ("Sourdough", .bakery),
        "seed bread": ("Seed Bread", .bakery),
        "bagels": ("Bagels", .bakery),
        "english muffins": ("English Muffins", .bakery),
        "burger buns": ("Burger Buns", .bakery),
        "hot dog buns": ("Hot Dog Buns", .bakery),
        "hamburger buns": ("Burger Buns", .bakery),
        "dinner rolls": ("Dinner Rolls", .bakery),
        "kaiser rolls": ("Kaiser Rolls", .bakery),
        "ciabatta rolls": ("Ciabatta", .bakery),
        "croissants": ("Croissants", .bakery),
        "pastries": ("Pastries", .bakery),
        "muffins": ("Muffins", .bakery),
        "cookies": ("Cookies", .bakery),
        "cakes": ("Cakes", .bakery),
        "pies": ("Pies", .bakery),
        "donuts": ("Donuts", .bakery),
        "doughnuts": ("Donuts", .bakery),
        "tortillas": ("Tortillas", .bakery),
        "pita": ("Pita", .bakery),
        "pita bread": ("Pita", .bakery),
        "flatbread": ("Flatbread", .bakery),
        "rolls": ("Rolls", .bakery),
        "garlic bread": ("Garlic Bread", .bakery),
        "baguette": ("Baguette", .bakery),
        "french bread": ("French Bread", .bakery),
        "italian bread": ("Italian Bread", .bakery),
        "pumpernickel": ("Pumpernickel", .bakery),
        "challah": ("Challah", .bakery),
        "brioche": ("Brioche", .bakery),
        "focaccia": ("Focaccia", .bakery),
        "pretzel buns": ("Pretzel Buns", .bakery),
        "texas toast": ("Texas Toast", .bakery),
        "bread crumbs": ("Bread Crumbs", .bakery),
        "croutons": ("Croutons", .bakery),
        "panko": ("Panko", .bakery),
        "stuffing": ("Stuffing", .bakery),
        
        // ============================================
        // BEVERAGES (DRINKS)
        // ============================================

        // Soft Drinks & Soda
        "coca cola": ("Coca-Cola", .beverages),
        "coke": ("Coca-Cola", .beverages),
        "coke zero": ("Coke Zero", .beverages),
        "diet coke": ("Diet Coke", .beverages),
        "pepsi": ("Pepsi", .beverages),
        "diet pepsi": ("Diet Pepsi", .beverages),
        "7up": ("7UP", .beverages),
        "sprite": ("Sprite", .beverages),
        "ginger ale": ("Ginger Ale", .beverages),
        "canada dry": ("Canada Dry Ginger Ale", .beverages),
        "dr pepper": ("Dr Pepper", .beverages),
        "crush": ("Crush", .beverages),
        "crush orange": ("Crush Orange", .beverages),
        "fanta": ("Fanta", .beverages),
        "mountain dew": ("Mountain Dew", .beverages),
        "barqs root beer": ("Barq's Root Beer", .beverages),
        "mug root beer": ("Mug Root Beer", .beverages),
        "a&w root beer": ("A&W Root Beer", .beverages),
        "pc cola": ("PC Cola", .beverages),
        "no name cola": ("No Name Cola", .beverages),
        "compliments cola": ("Compliments Cola", .beverages),
        "irresistibles cola": ("Irresistibles Cola", .beverages),
        "great value cola": ("Great Value Cola", .beverages),
        "coop gold cola": ("Co-op Gold Cola", .beverages),
        "kirkland cola": ("Kirkland Cola", .beverages),
        "presidents choice root beer": ("PC Root Beer", .beverages),
        "farm boy soda": ("Farm Boy Soda", .beverages),
        "fever tree": ("Fever Tree Tonic", .beverages),
        "fever tree tonic": ("Fever Tree Tonic", .beverages),
        "schweppes": ("Schweppes", .beverages),
        "schweppes tonic": ("Schweppes Tonic", .beverages),
        "boylan soda": ("Boylan Soda", .beverages),
        "jones soda": ("Jones Soda", .beverages),
        "sparkling ice": ("Sparkling Ice", .beverages),

        // Juices & Fruit Drinks
        "tropicana": ("Tropicana Juice", .beverages),
        "tropicana juice": ("Tropicana Juice", .beverages),
        "minute maid": ("Minute Maid Juice", .beverages),
        "minute maid juice": ("Minute Maid Juice", .beverages),
        "simply orange": ("Simply Orange Juice", .beverages),
        "simply orange juice": ("Simply Orange Juice", .beverages),
        "simply lemonade": ("Simply Lemonade", .beverages),
        "oasis juice": ("Oasis Juice", .beverages),
        "oasis": ("Oasis Juice", .beverages),
        "dole juice": ("Dole Juice", .beverages),
        "sunrype": ("SunRype Juice", .beverages),
        "sunrype juice": ("SunRype Juice", .beverages),
        "beatrice juice": ("Beatrice Juice", .beverages),
        "natrel juice": ("Natrel Juice", .beverages),
        "pc juice": ("PC Juice", .beverages),
        "pc organics juice": ("PC Organics Juice", .beverages),
        "no name juice": ("No Name Juice", .beverages),
        "compliments juice": ("Compliments Juice", .beverages),
        "irresistibles juice": ("Irresistibles Juice", .beverages),
        "great value juice": ("Great Value Juice", .beverages),
        "coop gold juice": ("Co-op Gold Juice", .beverages),
        "kirkland juice": ("Kirkland Juice", .beverages),
        "farm boy juice": ("Farm Boy Juice", .beverages),
        "ocean spray": ("Ocean Spray Cranberry Juice", .beverages),
        "ocean spray cranberry": ("Ocean Spray Cranberry Juice", .beverages),
        "v8 juice": ("V8 Juice", .beverages),
        "v8": ("V8 Juice", .beverages),
        "v8 fusion": ("V8 Fusion Juice", .beverages),
        "del monte juice": ("Del Monte Juice", .beverages),
        "allen's apple juice": ("Allen's Apple Juice", .beverages),
        "allens apple juice": ("Allen's Apple Juice", .beverages),
        "florida's natural": ("Florida's Natural Juice", .beverages),
        "floridas natural": ("Florida's Natural Juice", .beverages),
        "campbell's tomato juice": ("Campbell's Tomato Juice", .beverages),
        "campbells tomato juice": ("Campbell's Tomato Juice", .beverages),
        "sunny d": ("Sunny D", .beverages),
        "fruit2o": ("Fruit2O", .beverages),

        // Juice Boxes & Kids Drinks
        "kik juice box": ("Kik Juice Box", .beverages),
        "minute maid box": ("Minute Maid Juice Box", .beverages),
        "oasis box": ("Oasis Juice Box", .beverages),
        "sunrype box": ("SunRype Juice Box", .beverages),
        "pc juice box": ("PC Juice Box", .beverages),
        "great value juice box": ("Great Value Juice Box", .beverages),
        "tetra pak juice": ("Tetra Pak Juice", .beverages),
        "fruitopia": ("Fruitopia", .beverages),
        "beatrice juice box": ("Beatrice Juice Box", .beverages),
        "oasis smoothie box": ("Oasis Smoothie Box", .beverages),

        // Energy Drinks
        "red bull": ("Red Bull", .beverages),
        "redbull": ("Red Bull", .beverages),
        "red bull 4pk": ("Red Bull", .beverages),
        "monster energy": ("Monster Energy", .beverages),
        "monster": ("Monster Energy", .beverages),
        "monster ultra": ("Monster Ultra", .beverages),
        "monster 473ml": ("Monster Energy", .beverages),
        "rockstar energy": ("Rockstar Energy", .beverages),
        "rockstar": ("Rockstar Energy", .beverages),
        "rockstar 500ml": ("Rockstar Energy", .beverages),
        "nos energy": ("NOS Energy", .beverages),
        "reign energy": ("Reign Energy", .beverages),
        "c4 energy": ("C4 Energy", .beverages),
        "bang energy": ("Bang Energy", .beverages),
        "celsius energy": ("Celsius Energy", .beverages),
        "celsius": ("Celsius Energy", .beverages),
        "guru energy": ("Guru Energy", .beverages),
        "amp energy": ("AMP Energy", .beverages),
        "full throttle": ("Full Throttle Energy", .beverages),
        "pc energy drink": ("PC Energy Drink", .beverages),
        "great value energy": ("Great Value Energy Drink", .beverages),
        "kirkland energy": ("Kirkland Energy Drink", .beverages),

        // Water & Sparkling Water
        "eska": ("Eska Water", .beverages),
        "eska water": ("Eska Water", .beverages),
        "nestle pure life": ("Nestlé Pure Life Water", .beverages),
        "nestle water": ("Nestlé Pure Life Water", .beverages),
        "dasani": ("Dasani Water", .beverages),
        "dasani water": ("Dasani Water", .beverages),
        "aquafina": ("Aquafina Water", .beverages),
        "aquafina water": ("Aquafina Water", .beverages),
        "evian": ("Evian Water", .beverages),
        "evian water": ("Evian Water", .beverages),
        "fiji": ("Fiji Water", .beverages),
        "fiji water": ("Fiji Water", .beverages),
        "smartwater": ("Smartwater", .beverages),
        "perrier": ("Perrier Sparkling Water", .beverages),
        "perrier water": ("Perrier Sparkling Water", .beverages),
        "san pellegrino": ("San Pellegrino", .beverages),
        "bubly": ("Bubly Sparkling Water", .beverages),
        "bubly sparkling": ("Bubly Sparkling Water", .beverages),
        "bubly water": ("Bubly Sparkling Water", .beverages),
        "pc water": ("PC Water", .beverages),
        "no name water": ("No Name Water", .beverages),
        "compliments water": ("Compliments Water", .beverages),
        "irresistibles water": ("Irresistibles Water", .beverages),
        "great value water": ("Great Value Water", .beverages),
        "coop gold water": ("Co-op Gold Water", .beverages),
        "kirkland water": ("Kirkland Water", .beverages),
        "farm boy water": ("Farm Boy Water", .beverages),
        "montellier": ("Montellier Sparkling Water", .beverages),
        "ice river springs": ("Ice River Springs Water", .beverages),
        "canada dry club soda": ("Canada Dry Club Soda", .beverages),
        "sparkling q": ("Q Tonic Water", .beverages),
        "water 12pk": ("Water 12-Pack", .beverages),
        "water 24pk": ("Water 24-Pack", .beverages),

        // Coffee & Cold Brew
        "tim hortons coffee": ("Tim Hortons Coffee", .beverages),
        "tims coffee": ("Tim Hortons Coffee", .beverages),
        "starbucks coffee": ("Starbucks Coffee", .beverages),
        "starbucks frappuccino": ("Starbucks Frappuccino", .beverages),
        "starbucks cold brew": ("Starbucks Cold Brew", .beverages),
        "mccafe": ("McCafe Coffee", .beverages),
        "mccafe coffee": ("McCafe Coffee", .beverages),
        "nescafe": ("Nescafe Instant Coffee", .beverages),
        "nescafe instant": ("Nescafe Instant Coffee", .beverages),
        "maxwell house": ("Maxwell House Coffee", .beverages),
        "folgers": ("Folgers Coffee", .beverages),
        "folgers coffee": ("Folgers Coffee", .beverages),
        "tassimo coffee": ("Tassimo Coffee", .beverages),
        "tassimo": ("Tassimo Coffee", .beverages),
        "keurig": ("Keurig K-Cups", .beverages),
        "keurig k-cups": ("Keurig K-Cups", .beverages),
        "k-cups": ("Keurig K-Cups", .beverages),
        "pc coffee": ("PC Coffee", .beverages),
        "no name coffee": ("No Name Coffee", .beverages),
        "compliments coffee": ("Compliments Coffee", .beverages),
        "irresistibles coffee": ("Irresistibles Coffee", .beverages),
        "great value coffee": ("Great Value Coffee", .beverages),
        "kirkland coffee": ("Kirkland Coffee", .beverages),
        "lavazza": ("Lavazza Coffee", .beverages),
        "lavazza coffee": ("Lavazza Coffee", .beverages),
        "illy coffee": ("Illy Coffee", .beverages),
        "illy": ("Illy Coffee", .beverages),
        "nespresso": ("Nespresso Pods", .beverages),
        "nespresso pods": ("Nespresso Pods", .beverages),
        "javy": ("Javy Coffee Concentrate", .beverages),
        "beatrice iced coffee": ("Beatrice Iced Coffee", .beverages),
        "natrel coffee": ("Natrel Coffee Milk", .beverages),
        "oatly iced coffee": ("Oatly Iced Coffee", .beverages),
        "cold brew": ("Cold Brew Coffee", .beverages),

        // Tea & Iced Tea
        "lipton tea": ("Lipton Tea", .beverages),
        "lipton": ("Lipton Tea", .beverages),
        "tetley tea": ("Tetley Tea", .beverages),
        "tetley": ("Tetley Tea", .beverages),
        "red rose tea": ("Red Rose Tea", .beverages),
        "red rose": ("Red Rose Tea", .beverages),
        "twinings tea": ("Twinings Tea", .beverages),
        "twinings": ("Twinings Tea", .beverages),
        "bigelow tea": ("Bigelow Tea", .beverages),
        "pc tea": ("PC Tea", .beverages),
        "no name tea": ("No Name Tea", .beverages),
        "compliments tea": ("Compliments Tea", .beverages),
        "irresistibles tea": ("Irresistibles Tea", .beverages),
        "great value tea": ("Great Value Tea", .beverages),
        "davids tea": ("David's Tea", .beverages),
        "numi tea": ("Numi Tea", .beverages),
        "pg tips": ("PG Tips Tea", .beverages),
        "yorkshire tea": ("Yorkshire Tea", .beverages),
        "tassimo tea": ("Tassimo Tea", .beverages),
        "brisk": ("Brisk Iced Tea", .beverages),
        "brisk tea": ("Brisk Iced Tea", .beverages),
        "brisk iced tea": ("Brisk Iced Tea", .beverages),
        "arizona": ("Arizona Iced Tea", .beverages),
        "arizona iced tea": ("Arizona Iced Tea", .beverages),
        "nestea": ("Nestea Iced Tea", .beverages),
        "pc iced tea": ("PC Iced Tea", .beverages),
        "kirkland iced tea": ("Kirkland Iced Tea", .beverages),
        "snapple": ("Snapple Iced Tea", .beverages),
        "orange pekoe": ("Orange Pekoe Tea", .beverages),
        "king cole": ("King Cole Tea", .beverages),

        // Dairy & Alt Milk Beverages
        "natrel milk drink": ("Natrel Milk Drink", .beverages),
        "lactantia milk drink": ("Lactantia Milk Drink", .beverages),
        "beatrice chocolate milk": ("Beatrice Chocolate Milk", .beverages),
        "neilson chocolate milk": ("Neilson Chocolate Milk", .beverages),
        "chocolate milk": ("Chocolate Milk", .beverages),
        "nesquik": ("Nesquik Chocolate Milk", .beverages),
        "yop": ("Yop Drinkable Yogurt", .beverages),
        "oatly": ("Oatly Oat Drink", .beverages),
        "oatly oat drink": ("Oatly Oat Drink", .beverages),
        "earth's own": ("Earth's Own Oat Milk", .beverages),
        "earths own": ("Earth's Own Oat Milk", .beverages),
        "earth's own oat milk": ("Earth's Own Oat Milk", .beverages),
        "silk": ("Silk Almond Milk", .beverages),
        "silk almond milk": ("Silk Almond Milk", .beverages),
        "so delicious": ("So Delicious Coconut Milk", .beverages),
        "alpro": ("Alpro Soy Drink", .beverages),
        "alpro soy": ("Alpro Soy Drink", .beverages),
        "pc oat milk": ("PC Oat Milk", .beverages),
        "great value almond milk": ("Great Value Almond Milk", .beverages),
        "kirkland organic soy": ("Kirkland Organic Soy Milk", .beverages),
        "coop gold oat drink": ("Co-op Gold Oat Drink", .beverages),
        "oat drink": ("Oat Drink", .beverages),
        "almond milk": ("Almond Milk", .beverages),
        "soy milk": ("Soy Milk", .beverages),
        "coconut milk": ("Coconut Milk", .beverages),

        // Smoothies & Health Drinks
        "bolthouse farms": ("Bolthouse Farms Smoothie", .beverages),
        "naked juice": ("Naked Juice", .beverages),
        "oasis smoothie": ("Oasis Smoothie", .beverages),
        "tropicana smoothie": ("Tropicana Smoothie", .beverages),
        "pc smoothie": ("PC Smoothie", .beverages),
        "great value smoothie": ("Great Value Smoothie", .beverages),
        "compliments smoothie": ("Compliments Smoothie", .beverages),
        "irresistibles smoothie": ("Irresistibles Smoothie", .beverages),
        "kirkland smoothie": ("Kirkland Smoothie", .beverages),
        "farm boy smoothie": ("Farm Boy Smoothie", .beverages),
        "rivalhouse": ("RivalHouse Smoothie", .beverages),
        "goodfood smoothie": ("Goodfood Smoothie", .beverages),
        "evive": ("Evive Smoothie Cubes", .beverages),
        "booch": ("Booch Kombucha", .beverages),
        "gt's kombucha": ("GT's Kombucha", .beverages),
        "gts kombucha": ("GT's Kombucha", .beverages),
        "rise kombucha": ("Rise Kombucha", .beverages),
        "kombucha": ("Kombucha", .beverages),
        "flo water": ("FLO Alkaline Water", .beverages),
        "vita coco": ("Vita Coco Coconut Water", .beverages),
        "zico": ("Zico Coconut Water", .beverages),
        "coconut water": ("Coconut Water", .beverages),
        "gatorade": ("Gatorade", .beverages),
        "powerade": ("Powerade", .beverages),

        // Store Brand Beverages
        "presidents choice beverages": ("PC Beverages", .beverages),
        "pc beverages": ("PC Beverages", .beverages),
        "pc organics juice": ("PC Organics Juice", .beverages),
        "no name beverage": ("No Name Beverage", .beverages),
        "compliments beverage": ("Compliments Beverage", .beverages),
        "irresistibles beverage": ("Irresistibles Beverage", .beverages),
        "great value beverage": ("Great Value Beverage", .beverages),
        "coop gold beverage": ("Co-op Gold Beverage", .beverages),
        "kirkland beverage": ("Kirkland Beverage", .beverages),
        "farm boy beverage": ("Farm Boy Beverage", .beverages),
        "longos beverage": ("Longos Beverage", .beverages),
        "metro beverage": ("Metro Beverage", .beverages),
        "freshco beverage": ("FreshCo Beverage", .beverages),

        // Common Receipt Variants
        "soda": ("Soda", .beverages),
        "pop": ("Soda", .beverages),
        "soft drink": ("Soft Drink", .beverages),
        "mineral water": ("Mineral Water", .beverages),
        "tonic water": ("Tonic Water", .beverages),
        "club soda": ("Club Soda", .beverages),
        "sports drink": ("Sports Drink", .beverages),
        "electrolyte drink": ("Electrolyte Drink", .beverages),
        "energy drink": ("Energy Drink", .beverages),
        "iced tea": ("Iced Tea", .beverages),
        "juice box": ("Juice Box", .beverages),
        "orange juice": ("Orange Juice", .beverages),
        "apple juice": ("Apple Juice", .beverages),
        "smoothie": ("Smoothie", .beverages),
        
        // ============================================
        // SNACKS & CONDIMENTS
        // ============================================

        // Chips & Savory Snacks
        "lays chips": ("Lay's Chips", .snacks),
        "lays": ("Lay's Chips", .snacks),
        "lay's chips": ("Lay's Chips", .snacks),
        "ruffles chips": ("Ruffles Chips", .snacks),
        "ruffles": ("Ruffles Chips", .snacks),
        "doritos chips": ("Doritos Chips", .snacks),
        "doritos": ("Doritos Chips", .snacks),
        "tostitos chips": ("Tostitos Chips", .snacks),
        "tostitos": ("Tostitos Chips", .snacks),
        "miss vickie's chips": ("Miss Vickie's Chips", .snacks),
        "miss vickies chips": ("Miss Vickie's Chips", .snacks),
        "miss vickies": ("Miss Vickie's Chips", .snacks),
        "smartfood popcorn": ("Smartfood Popcorn", .snacks),
        "smartfood": ("Smartfood Popcorn", .snacks),
        "cheetos": ("Cheetos", .snacks),
        "funyuns": ("Funyuns", .snacks),
        "sunchips": ("SunChips", .snacks),
        "sun chips": ("SunChips", .snacks),
        "bugles": ("Bugles", .snacks),
        "munchies snack mix": ("Munchies Snack Mix", .snacks),
        "munchies": ("Munchies Snack Mix", .snacks),
        "ritz chips": ("Ritz Chips", .snacks),
        "hickory sticks": ("Hickory Sticks", .snacks),
        "kettle brand chips": ("Kettle Brand Chips", .snacks),
        "kettle chips": ("Kettle Brand Chips", .snacks),
        "cape cod chips": ("Cape Cod Chips", .snacks),
        "popcorners": ("Popcorners", .snacks),
        "orville redenbacher": ("Orville Redenbacher Popcorn", .snacks),
        "act ii popcorn": ("Act II Popcorn", .snacks),
        "act ii": ("Act II Popcorn", .snacks),
        "pc chips": ("PC Chips", .snacks),
        "no name chips": ("No Name Chips", .snacks),
        "compliments chips": ("Compliments Chips", .snacks),
        "irresistibles chips": ("Irresistibles Chips", .snacks),
        "great value chips": ("Great Value Chips", .snacks),
        "coop gold chips": ("Co-op Gold Chips", .snacks),
        "kirkland chips": ("Kirkland Chips", .snacks),
        "farm boy chips": ("Farm Boy Chips", .snacks),
        "old dutch chips": ("Old Dutch Chips", .snacks),
        "hostess chips": ("Hostess Chips", .snacks),
        "yves veggie chips": ("Yves Veggie Chips", .snacks),
        "veggie straws": ("Veggie Straws", .snacks),
        "pringles": ("Pringles", .snacks),
        "stackers": ("Stackers", .snacks),
        "mccain potato chips": ("McCain Potato Chips", .snacks),
        "covered bridge chips": ("Covered Bridge Chips", .snacks),
        "hardbite chips": ("Hardbite Chips", .snacks),

        // Crackers, Pretzels & Savory Bites
        "ritz crackers": ("Ritz Crackers", .snacks),
        "ritz": ("Ritz Crackers", .snacks),
        "triscuit crackers": ("Triscuit Crackers", .snacks),
        "triscuit": ("Triscuit Crackers", .snacks),
        "wheat thins": ("Wheat Thins", .snacks),
        "tuc crackers": ("Tuc Crackers", .snacks),
        "tuc": ("Tuc Crackers", .snacks),
        "society crackers": ("Society Crackers", .snacks),
        "goldfish crackers": ("Goldfish Crackers", .snacks),
        "goldfish": ("Goldfish Crackers", .snacks),
        "cheez-it crackers": ("Cheez-It Crackers", .snacks),
        "cheez it": ("Cheez-It Crackers", .snacks),
        "breton crackers": ("Breton Crackers", .snacks),
        "breton": ("Breton Crackers", .snacks),
        "melba toast": ("Melba Toast", .snacks),
        "pita chips": ("Pita Chips", .snacks),
        "pretzel crisp": ("Pretzel Crisps", .snacks),
        "snyder's pretzels": ("Snyder's Pretzels", .snacks),
        "snyders pretzels": ("Snyder's Pretzels", .snacks),
        "rold gold pretzels": ("Rold Gold Pretzels", .snacks),
        "carr's crackers": ("Carr's Crackers", .snacks),
        "carrs crackers": ("Carr's Crackers", .snacks),
        "stacy's pita chips": ("Stacy's Pita Chips", .snacks),
        "stacys pita chips": ("Stacy's Pita Chips", .snacks),
        "pc crackers": ("PC Crackers", .snacks),
        "no name crackers": ("No Name Crackers", .snacks),
        "compliments crackers": ("Compliments Crackers", .snacks),
        "irresistibles crackers": ("Irresistibles Crackers", .snacks),
        "great value crackers": ("Great Value Crackers", .snacks),
        "coop gold crackers": ("Co-op Gold Crackers", .snacks),
        "kirkland crackers": ("Kirkland Crackers", .snacks),
        "farm boy crackers": ("Farm Boy Crackers", .snacks),

        // Cookies, Candy & Sweets
        "oreo cookies": ("Oreo Cookies", .snacks),
        "oreo": ("Oreo Cookies", .snacks),
        "chips ahoy cookies": ("Chips Ahoy Cookies", .snacks),
        "chips ahoy": ("Chips Ahoy Cookies", .snacks),
        "famous amos cookies": ("Famous Amos Cookies", .snacks),
        "famous amos": ("Famous Amos Cookies", .snacks),
        "dad's cookies": ("Dad's Cookies", .snacks),
        "dads cookies": ("Dad's Cookies", .snacks),
        "pirate cookies": ("Pirate Cookies", .snacks),
        "voortman cookies": ("Voortman Cookies", .snacks),
        "maynard's candy": ("Maynard's Candy", .snacks),
        "maynards candy": ("Maynard's Candy", .snacks),
        "maynards": ("Maynard's Candy", .snacks),
        "nestle chocolate": ("Nestlé Chocolate", .snacks),
        "mars chocolate": ("Mars Chocolate", .snacks),
        "kitkat": ("KitKat", .snacks),
        "kit kat": ("KitKat", .snacks),
        "aero bar": ("Aero Bar", .snacks),
        "aero": ("Aero Bar", .snacks),
        "coffee crisp": ("Coffee Crisp", .snacks),
        "twix": ("Twix", .snacks),
        "snickers": ("Snickers", .snacks),
        "reese": ("Reese's", .snacks),
        "reese's": ("Reese's", .snacks),
        "reeses": ("Reese's", .snacks),
        "hershey bar": ("Hershey Bar", .snacks),
        "hershey": ("Hershey Bar", .snacks),
        "m&m's": ("M&M's", .snacks),
        "m&ms": ("M&M's", .snacks),
        "skittles": ("Skittles", .snacks),
        "starburst": ("Starburst", .snacks),
        "toblerone": ("Toblerone", .snacks),
        "caramilk": ("Caramilk", .snacks),
        "smarties": ("Smarties", .snacks),
        "rolo": ("Rolo", .snacks),
        "hershey kisses": ("Hershey Kisses", .snacks),
        "twizzlers": ("Twizzlers", .snacks),
        "red vines": ("Red Vines", .snacks),
        "sour patch kids": ("Sour Patch Kids", .snacks),
        "jolly rancher": ("Jolly Rancher", .snacks),
        "halls candy": ("Halls Candy", .snacks),
        "halls": ("Halls Candy", .snacks),
        "vachon snack cakes": ("Vachon Snack Cakes", .snacks),
        "vachon": ("Vachon Snack Cakes", .snacks),
        "hostess cupcakes": ("Hostess Cupcakes", .snacks),
        "little debbie snacks": ("Little Debbie Snacks", .snacks),
        "little debbie": ("Little Debbie Snacks", .snacks),
        "pc cookies": ("PC Cookies", .snacks),
        "no name cookies": ("No Name Cookies", .snacks),
        "compliments cookies": ("Compliments Cookies", .snacks),
        "irresistibles cookies": ("Irresistibles Cookies", .snacks),
        "great value cookies": ("Great Value Cookies", .snacks),
        "kirkland cookies": ("Kirkland Cookies", .snacks),
        "coop gold cookies": ("Co-op Gold Cookies", .snacks),
        "ferrero rocher": ("Ferrero Rocher", .snacks),
        "lindt chocolate": ("Lindt Chocolate", .snacks),
        "godiva chocolate": ("Godiva Chocolate", .snacks),
        "cadbury chocolate": ("Cadbury Chocolate", .snacks),
        "dairy milk": ("Dairy Milk Chocolate", .snacks),
        "wunderbar": ("Wunderbar", .snacks),
        "crispy crunch": ("Crispy Crunch", .snacks),
        "mr big": ("Mr. Big", .snacks),
        "oh henry": ("Oh Henry", .snacks),
        "3 musketeers": ("3 Musketeers", .snacks),
        "milky way": ("Milky Way", .snacks),
        "bounty": ("Bounty", .snacks),

        // Spreads, Nut Butters & Jams
        "nutella": ("Nutella", .snacks),
        "kraft peanut butter": ("Kraft Peanut Butter", .snacks),
        "kraft pb": ("Kraft Peanut Butter", .snacks),
        "jif peanut butter": ("Jif Peanut Butter", .snacks),
        "jif": ("Jif Peanut Butter", .snacks),
        "skippy peanut butter": ("Skippy Peanut Butter", .snacks),
        "skippy": ("Skippy Peanut Butter", .snacks),
        "adams peanut butter": ("Adams Peanut Butter", .snacks),
        "wowbutter": ("Wowbutter", .snacks),
        "pc peanut butter": ("PC Peanut Butter", .snacks),
        "no name peanut butter": ("No Name Peanut Butter", .snacks),
        "compliments peanut butter": ("Compliments Peanut Butter", .snacks),
        "irresistibles peanut butter": ("Irresistibles Peanut Butter", .snacks),
        "great value peanut butter": ("Great Value Peanut Butter", .snacks),
        "kirkland almond butter": ("Kirkland Almond Butter", .snacks),
        "coop gold peanut butter": ("Co-op Gold Peanut Butter", .snacks),
        "smucker's jam": ("Smucker's Jam", .snacks),
        "smuckers jam": ("Smucker's Jam", .snacks),
        "crofter's organic jam": ("Crofter's Organic Jam", .snacks),
        "crofters jam": ("Crofter's Organic Jam", .snacks),
        "president's choice jam": ("PC Jam", .snacks),
        "pc jam": ("PC Jam", .snacks),
        "no name jam": ("No Name Jam", .snacks),
        "compliments jam": ("Compliments Jam", .snacks),
        "st. dalfour jam": ("St. Dalfour Jam", .snacks),
        "bonne maman jam": ("Bonne Maman Jam", .snacks),
        "welch's jelly": ("Welch's Jelly", .snacks),
        "welchs jelly": ("Welch's Jelly", .snacks),
        "sunnyside honey": ("Sunnyside Honey", .snacks),
        "bee maid honey": ("Bee Maid Honey", .snacks),
        "billy bee honey": ("Billy Bee Honey", .snacks),
        "pc honey": ("PC Honey", .snacks),
        "kirkland honey": ("Kirkland Honey", .snacks),
        "peanut butter": ("Peanut Butter", .snacks),
        "almond butter": ("Almond Butter", .snacks),
        "jam": ("Jam", .snacks),
        "jelly": ("Jelly", .snacks),
        "honey": ("Honey", .snacks),

        // Condiments (Ketchup, Mayo, Mustard, Sauces)
        "heinz ketchup": ("Heinz Ketchup", .snacks),
        "heinz": ("Heinz Ketchup", .snacks),
        "french's ketchup": ("French's Ketchup", .snacks),
        "frenchs ketchup": ("French's Ketchup", .snacks),
        "pc ketchup": ("PC Ketchup", .snacks),
        "no name ketchup": ("No Name Ketchup", .snacks),
        "compliments ketchup": ("Compliments Ketchup", .snacks),
        "irresistibles ketchup": ("Irresistibles Ketchup", .snacks),
        "great value ketchup": ("Great Value Ketchup", .snacks),
        "kirkland ketchup": ("Kirkland Ketchup", .snacks),
        "coop gold ketchup": ("Co-op Gold Ketchup", .snacks),
        "hellmann's mayonnaise": ("Hellmann's Mayonnaise", .snacks),
        "hellmanns mayo": ("Hellmann's Mayonnaise", .snacks),
        "hellmanns": ("Hellmann's Mayonnaise", .snacks),
        "kraft mayo": ("Kraft Mayonnaise", .snacks),
        "pc mayo": ("PC Mayonnaise", .snacks),
        "compliments mayo": ("Compliments Mayonnaise", .snacks),
        "great value mayo": ("Great Value Mayonnaise", .snacks),
        "miracle whip": ("Miracle Whip", .snacks),
        "maille mustard": ("Maille Mustard", .snacks),
        "french's mustard": ("French's Mustard", .snacks),
        "frenchs mustard": ("French's Mustard", .snacks),
        "pc mustard": ("PC Mustard", .snacks),
        "dijon mustard": ("Dijon Mustard", .snacks),
        "grey poupon": ("Grey Poupon", .snacks),
        "hp sauce": ("HP Sauce", .snacks),
        "a1 steak sauce": ("A1 Steak Sauce", .snacks),
        "lea & perrins": ("Lea & Perrins Worcestershire", .snacks),
        "lea perrins": ("Lea & Perrins Worcestershire", .snacks),
        "tabasco sauce": ("Tabasco Sauce", .snacks),
        "tabasco": ("Tabasco Sauce", .snacks),
        "frank's redhot": ("Frank's RedHot Sauce", .snacks),
        "franks redhot": ("Frank's RedHot Sauce", .snacks),
        "cholula sauce": ("Cholula Sauce", .snacks),
        "cholula": ("Cholula Sauce", .snacks),
        "sriracha sauce": ("Sriracha Sauce", .snacks),
        "sriracha": ("Sriracha Sauce", .snacks),
        "pc hot sauce": ("PC Hot Sauce", .snacks),
        "great value bbq sauce": ("Great Value BBQ Sauce", .snacks),
        "kraft bbq sauce": ("Kraft BBQ Sauce", .snacks),
        "diana bbq sauce": ("Diana BBQ Sauce", .snacks),
        "sweet baby ray's": ("Sweet Baby Ray's BBQ Sauce", .snacks),
        "sweet baby rays": ("Sweet Baby Ray's BBQ Sauce", .snacks),
        "bull's-eye bbq": ("Bull's-Eye BBQ Sauce", .snacks),
        "bulls eye bbq": ("Bull's-Eye BBQ Sauce", .snacks),
        "pc bbq sauce": ("PC BBQ Sauce", .snacks),
        "no name bbq sauce": ("No Name BBQ Sauce", .snacks),
        "compliments bbq sauce": ("Compliments BBQ Sauce", .snacks),
        "kikkoman soy sauce": ("Kikkoman Soy Sauce", .snacks),
        "kikkoman": ("Kikkoman Soy Sauce", .snacks),
        "vh sauce": ("VH Sauce", .snacks),
        "hoisin sauce": ("Hoisin Sauce", .snacks),
        "hunt's tomato sauce": ("Hunt's Tomato Sauce", .snacks),
        "hunts tomato sauce": ("Hunt's Tomato Sauce", .snacks),
        "campbell's sauce": ("Campbell's Sauce", .snacks),
        "campbells sauce": ("Campbell's Sauce", .snacks),
        "classico pasta sauce": ("Classico Pasta Sauce", .snacks),
        "classico": ("Classico Pasta Sauce", .snacks),
        "ragu pasta sauce": ("Ragu Pasta Sauce", .snacks),
        "ragu": ("Ragu Pasta Sauce", .snacks),
        "catelli sauce": ("Catelli Sauce", .snacks),
        "primo pasta sauce": ("Primo Pasta Sauce", .snacks),
        "primo": ("Primo Pasta Sauce", .snacks),
        "barilla sauce": ("Barilla Sauce", .snacks),
        "pc pasta sauce": ("PC Pasta Sauce", .snacks),
        "irresistibles pasta sauce": ("Irresistibles Pasta Sauce", .snacks),
        "great value pasta sauce": ("Great Value Pasta Sauce", .snacks),
        "ketchup": ("Ketchup", .snacks),
        "mayo": ("Mayonnaise", .snacks),
        "mayonnaise": ("Mayonnaise", .snacks),
        "mustard": ("Mustard", .snacks),
        "hot sauce": ("Hot Sauce", .snacks),
        "bbq sauce": ("BBQ Sauce", .snacks),
        "pasta sauce": ("Pasta Sauce", .snacks),
        "tomato sauce": ("Tomato Sauce", .snacks),
        "soy sauce": ("Soy Sauce", .snacks),

        // Dressings, Dips & Marinades
        "kraft dressing": ("Kraft Dressing", .snacks),
        "hidden valley ranch": ("Hidden Valley Ranch", .snacks),
        "hidden valley": ("Hidden Valley Ranch", .snacks),
        "pc dressing": ("PC Dressing", .snacks),
        "no name dressing": ("No Name Dressing", .snacks),
        "compliments dressing": ("Compliments Dressing", .snacks),
        "irresistibles dressing": ("Irresistibles Dressing", .snacks),
        "great value dressing": ("Great Value Dressing", .snacks),
        "coop gold dressing": ("Co-op Gold Dressing", .snacks),
        "kirkland dressing": ("Kirkland Dressing", .snacks),
        "bick's pickles": ("Bick's Pickles", .snacks),
        "bicks pickles": ("Bick's Pickles", .snacks),
        "vh marinade": ("VH Marinade", .snacks),
        "renée's dressing": ("Renée's Dressing", .snacks),
        "renees dressing": ("Renée's Dressing", .snacks),
        "renees": ("Renée's Dressing", .snacks),
        "hellofresh sauce": ("HelloFresh Sauce", .snacks),
        "yucatan guacamole": ("Yucatan Guacamole", .snacks),
        "sabra hummus": ("Sabra Hummus", .snacks),
        "pc hummus": ("PC Hummus", .snacks),
        "farm boy hummus": ("Farm Boy Hummus", .snacks),
        "summ! hummus": ("Summ! Hummus", .snacks),
        "cedar hummus": ("Cedar Hummus", .snacks),
        "zesty guacamole": ("Zesty Guacamole", .snacks),
        "pc salsa": ("PC Salsa", .snacks),
        "tostitos salsa": ("Tostitos Salsa", .snacks),
        "herdez salsa": ("Herdez Salsa", .snacks),
        "old el paso salsa": ("Old El Paso Salsa", .snacks),
        "pace salsa": ("Pace Salsa", .snacks),
        "tabasco dressing": ("Tabasco Dressing", .snacks),
        "dressing": ("Dressing", .snacks),
        "ranch dressing": ("Ranch Dressing", .snacks),
        "caesar dressing": ("Caesar Dressing", .snacks),
        "salsa": ("Salsa", .snacks),
        "hummus": ("Hummus", .snacks),
        "guacamole": ("Guacamole", .snacks),
        "dip": ("Dip", .snacks),
        "marinade": ("Marinade", .snacks),

        // Nuts, Trail Mix & Snack Packs
        "planters peanuts": ("Planters Peanuts", .snacks),
        "planters": ("Planters Peanuts", .snacks),
        "munchies trail mix": ("Munchies Trail Mix", .snacks),
        "kirkland mixed nuts": ("Kirkland Mixed Nuts", .snacks),
        "great value peanuts": ("Great Value Peanuts", .snacks),
        "pc trail mix": ("PC Trail Mix", .snacks),
        "compliments nuts": ("Compliments Nuts", .snacks),
        "coop gold nuts": ("Co-op Gold Nuts", .snacks),
        "no name peanuts": ("No Name Peanuts", .snacks),
        "wonderful pistachios": ("Wonderful Pistachios", .snacks),
        "blue diamond almonds": ("Blue Diamond Almonds", .snacks),
        "farm boy nuts": ("Farm Boy Nuts", .snacks),
        "irresistibles nuts": ("Irresistibles Nuts", .snacks),
        "sahara trail mix": ("Sahara Trail Mix", .snacks),
        "prana organic nuts": ("Prana Organic Nuts", .snacks),
        "nature's nuts": ("Nature's Nuts", .snacks),
        "natures nuts": ("Nature's Nuts", .snacks),
        "sunkist dried fruit": ("Sunkist Dried Fruit", .snacks),
        "sunmaid raisins": ("Sun-Maid Raisins", .snacks),
        "sun-maid raisins": ("Sun-Maid Raisins", .snacks),
        "ocean spray craisins": ("Ocean Spray Craisins", .snacks),
        "craisins": ("Craisins", .snacks),
        "nuts": ("Nuts", .snacks),
        "trail mix": ("Trail Mix", .snacks),
        "mixed nuts": ("Mixed Nuts", .snacks),
        "peanuts": ("Peanuts", .snacks),
        "almonds": ("Almonds", .snacks),
        "cashews": ("Cashews", .snacks),
        "pistachios": ("Pistachios", .snacks),
        "snack pack": ("Snack Pack", .snacks),
        "protein bar": ("Protein Bar", .snacks),

        // Common Receipt Variants
        "chips": ("Chips", .snacks),
        "popcorn": ("Popcorn", .snacks),
        "snack mix": ("Snack Mix", .snacks),
        "crackers": ("Crackers", .snacks),
        "cookies": ("Cookies", .snacks),
        "candy": ("Candy", .snacks),
        "chocolate": ("Chocolate", .snacks),
        "chocolate bar": ("Chocolate Bar", .snacks),
        "gum": ("Gum", .snacks),
        "mints": ("Mints", .snacks),
        "pretzels": ("Pretzels", .snacks),
        
        // ============================================
        // FROZEN FOODS
        // ============================================

        // Frozen Pizza
        "delissio pizza": ("Delissio Pizza", .frozen),
        "delissio": ("Delissio Pizza", .frozen),
        "delissio frozen pizza": ("Delissio Pizza", .frozen),
        "dr oetker pizza": ("Dr. Oetker Pizza", .frozen),
        "dr oetker ristorante": ("Dr. Oetker Pizza", .frozen),
        "dr oetker": ("Dr. Oetker Pizza", .frozen),
        "mccain pizza": ("McCain Pizza", .frozen),
        "pizza pockets": ("Pizza Pockets", .frozen),
        "pizza pops": ("Pizza Pops", .frozen),
        "mama mia pizza": ("Mama Mia Pizza", .frozen),
        "pc frozen pizza": ("PC Frozen Pizza", .frozen),
        "pc pizza": ("PC Pizza", .frozen),
        "no name pizza": ("No Name Pizza", .frozen),
        "compliments pizza": ("Compliments Pizza", .frozen),
        "irresistibles pizza": ("Irresistibles Pizza", .frozen),
        "great value pizza": ("Great Value Pizza", .frozen),
        "coop gold pizza": ("Co-op Gold Pizza", .frozen),
        "kirkland pizza": ("Kirkland Pizza", .frozen),
        "mott's pizza": ("Mott's Pizza", .frozen),
        "farm boy pizza": ("Farm Boy Pizza", .frozen),
        "amy's organic pizza": ("Amy's Organic Pizza", .frozen),
        "amys organic pizza": ("Amy's Organic Pizza", .frozen),
        "caulipower pizza": ("Caulipower Pizza", .frozen),
        "di giorno pizza": ("DiGiorno Pizza", .frozen),
        "digiorno pizza": ("DiGiorno Pizza", .frozen),
        "mike's frozen pizza": ("Mike's Frozen Pizza", .frozen),
        "mikes frozen pizza": ("Mike's Frozen Pizza", .frozen),

        // Frozen Vegetables & Fruit
        "arctic gardens vegetables": ("Arctic Gardens Vegetables", .frozen),
        "arctic gardens": ("Arctic Gardens Vegetables", .frozen),
        "green giant vegetables": ("Green Giant Vegetables", .frozen),
        "green giant frozen": ("Green Giant Vegetables", .frozen),
        "bonduelle vegetables": ("Bonduelle Vegetables", .frozen),
        "bonduelle frozen": ("Bonduelle Vegetables", .frozen),
        "nature's touch fruit": ("Nature's Touch Fruit", .frozen),
        "natures touch fruit": ("Nature's Touch Fruit", .frozen),
        "natures touch": ("Nature's Touch Fruit", .frozen),
        "dole frozen fruit": ("Dole Frozen Fruit", .frozen),
        "sunrype frozen fruit": ("SunRype Frozen Fruit", .frozen),
        "sunrype frozen": ("SunRype Frozen Fruit", .frozen),
        "pc frozen vegetables": ("PC Frozen Vegetables", .frozen),
        "no name frozen vegetables": ("No Name Frozen Vegetables", .frozen),
        "compliments frozen vegetables": ("Compliments Frozen Vegetables", .frozen),
        "irresistibles frozen vegetables": ("Irresistibles Frozen Vegetables", .frozen),
        "great value frozen vegetables": ("Great Value Frozen Vegetables", .frozen),
        "coop gold frozen vegetables": ("Co-op Gold Frozen Vegetables", .frozen),
        "kirkland frozen vegetables": ("Kirkland Frozen Vegetables", .frozen),
        "farm boy frozen vegetables": ("Farm Boy Frozen Vegetables", .frozen),
        "cascadian farm organic": ("Cascadian Farm Organic Vegetables", .frozen),
        "cascadian farm": ("Cascadian Farm Organic Vegetables", .frozen),
        "earthbound farm veggies": ("Earthbound Farm Vegetables", .frozen),
        "mccain veggies": ("McCain Vegetables", .frozen),
        "mccain frozen vegetables": ("McCain Vegetables", .frozen),

        // Frozen Meat & Poultry
        "janes chicken strips": ("Janes Chicken Strips", .frozen),
        "janes strips": ("Janes Chicken Strips", .frozen),
        "janes chicken burgers": ("Janes Chicken Burgers", .frozen),
        "janes burgers": ("Janes Chicken Burgers", .frozen),
        "janes frozen chicken": ("Janes Frozen Chicken", .frozen),
        "maple leaf meatballs": ("Maple Leaf Meatballs", .frozen),
        "schneiders sausages": ("Schneiders Sausages", .frozen),
        "schneiders frozen": ("Schneiders Frozen Sausages", .frozen),
        "lilydale chicken strips": ("Lilydale Chicken Strips", .frozen),
        "lilydale frozen": ("Lilydale Frozen Chicken", .frozen),
        "butterball turkey burgers": ("Butterball Turkey Burgers", .frozen),
        "butterball frozen": ("Butterball Frozen Turkey", .frozen),
        "pinty's wings": ("Pinty's Wings", .frozen),
        "pintys wings": ("Pinty's Wings", .frozen),
        "pintys frozen": ("Pinty's Frozen Chicken", .frozen),
        "pc chicken burgers": ("PC Chicken Burgers", .frozen),
        "no name chicken": ("No Name Frozen Chicken", .frozen),
        "no name frozen chicken": ("No Name Frozen Chicken", .frozen),
        "compliments chicken": ("Compliments Frozen Chicken", .frozen),
        "compliments frozen chicken": ("Compliments Frozen Chicken", .frozen),
        "irresistibles chicken": ("Irresistibles Frozen Chicken", .frozen),
        "irresistibles frozen chicken": ("Irresistibles Frozen Chicken", .frozen),
        "great value chicken": ("Great Value Frozen Chicken", .frozen),
        "great value frozen chicken": ("Great Value Frozen Chicken", .frozen),
        "coop gold chicken": ("Co-op Gold Frozen Chicken", .frozen),
        "coop gold frozen chicken": ("Co-op Gold Frozen Chicken", .frozen),
        "kirkland chicken": ("Kirkland Frozen Chicken", .frozen),
        "kirkland frozen chicken": ("Kirkland Frozen Chicken", .frozen),
        "beyond meat burgers": ("Beyond Meat Burgers", .frozen),
        "impossible burgers": ("Impossible Burgers", .frozen),
        "sol cuisine burgers": ("Sol Cuisine Burgers", .frozen),
        "gusta vegan sausage": ("Gusta Vegan Sausage", .frozen),
        "high liner fish": ("High Liner Fish", .frozen),
        "high liner frozen fish": ("High Liner Fish", .frozen),
        "high liner cod": ("High Liner Cod", .frozen),
        "blue water fish": ("Blue Water Fish", .frozen),
        "ocean's shrimp": ("Ocean's Shrimp", .frozen),
        "oceans shrimp": ("Ocean's Shrimp", .frozen),
        "pc salmon": ("PC Frozen Salmon", .frozen),
        "pc frozen salmon": ("PC Frozen Salmon", .frozen),
        "no name fish": ("No Name Frozen Fish", .frozen),
        "no name frozen fish": ("No Name Frozen Fish", .frozen),

        // Frozen Breakfast / Waffles / Pancakes
        "eggo waffles": ("Eggo Waffles", .frozen),
        "eggo": ("Eggo Waffles", .frozen),
        "pc waffles": ("PC Waffles", .frozen),
        "no name waffles": ("No Name Waffles", .frozen),
        "compliments waffles": ("Compliments Waffles", .frozen),
        "irresistibles waffles": ("Irresistibles Waffles", .frozen),
        "great value waffles": ("Great Value Waffles", .frozen),
        "coop gold waffles": ("Co-op Gold Waffles", .frozen),
        "kirkland waffles": ("Kirkland Waffles", .frozen),
        "aunt jemima pancakes": ("Aunt Jemima Pancakes", .frozen),
        "pearl milling": ("Pearl Milling Pancakes", .frozen),
        "pc pancakes": ("PC Pancakes", .frozen),
        "mccain breakfast potatoes": ("McCain Breakfast Potatoes", .frozen),
        "mccain hashbrowns": ("McCain Hashbrowns", .frozen),
        "hashbrowns": ("Hashbrowns", .frozen),
        "no name tater tots": ("No Name Tater Tots", .frozen),
        "tater tots": ("Tater Tots", .frozen),
        "great value hashbrowns": ("Great Value Hashbrowns", .frozen),
        "morningstar breakfast patties": ("MorningStar Breakfast Patties", .frozen),
        "morningstar": ("MorningStar Breakfast Patties", .frozen),
        "jimmy dean breakfast sandwich": ("Jimmy Dean Breakfast Sandwich", .frozen),
        "jimmy dean": ("Jimmy Dean Breakfast Sandwich", .frozen),
        "pc breakfast sandwich": ("PC Breakfast Sandwich", .frozen),

        // Frozen Ready Meals / Entrees
        "lean cuisine": ("Lean Cuisine", .frozen),
        "stouffer's": ("Stouffer's", .frozen),
        "stouffers": ("Stouffer's", .frozen),
        "michelina's": ("Michelina's", .frozen),
        "michelinas": ("Michelina's", .frozen),
        "smart ones": ("Smart Ones", .frozen),
        "pc blue menu meals": ("PC Blue Menu Meals", .frozen),
        "pc blue menu": ("PC Blue Menu", .frozen),
        "no name meals": ("No Name Frozen Meals", .frozen),
        "no name frozen meals": ("No Name Frozen Meals", .frozen),
        "compliments meals": ("Compliments Frozen Meals", .frozen),
        "compliments frozen meals": ("Compliments Frozen Meals", .frozen),
        "irresistibles meals": ("Irresistibles Frozen Meals", .frozen),
        "irresistibles frozen meals": ("Irresistibles Frozen Meals", .frozen),
        "great value meals": ("Great Value Frozen Meals", .frozen),
        "great value frozen meals": ("Great Value Frozen Meals", .frozen),
        "coop gold meals": ("Co-op Gold Frozen Meals", .frozen),
        "coop gold frozen meals": ("Co-op Gold Frozen Meals", .frozen),
        "kirkland lasagna": ("Kirkland Lasagna", .frozen),
        "pc lasagna": ("PC Lasagna", .frozen),
        "mccain dinners": ("McCain Dinners", .frozen),
        "hungry-man": ("Hungry-Man", .frozen),
        "hungry man": ("Hungry-Man", .frozen),
        "birds eye meals": ("Birds Eye Meals", .frozen),
        "amy's organic meals": ("Amy's Organic Meals", .frozen),
        "amys organic meals": ("Amy's Organic Meals", .frozen),
        "evol meals": ("Evol Meals", .frozen),
        "caulipower bowls": ("Caulipower Bowls", .frozen),
        "lucerne meals": ("Lucerne Meals", .frozen),
        "southwest kitchen": ("Southwest Kitchen", .frozen),
        "farm boy lasagna": ("Farm Boy Lasagna", .frozen),

        // Frozen Potatoes & Appetizers
        "mccain fries": ("McCain Fries", .frozen),
        "mccain superfries": ("McCain Superfries", .frozen),
        "mccain tater tots": ("McCain Tater Tots", .frozen),
        "mccain smile fries": ("McCain Smile Fries", .frozen),
        "mccain appetizers": ("McCain Appetizers", .frozen),
        "alexia fries": ("Alexia Fries", .frozen),
        "pc frozen fries": ("PC Frozen Fries", .frozen),
        "pc fries": ("PC Fries", .frozen),
        "no name fries": ("No Name Fries", .frozen),
        "compliments fries": ("Compliments Fries", .frozen),
        "irresistibles fries": ("Irresistibles Fries", .frozen),
        "great value fries": ("Great Value Fries", .frozen),
        "coop gold fries": ("Co-op Gold Fries", .frozen),
        "kirkland fries": ("Kirkland Fries", .frozen),
        "tgi fridays appetizers": ("TGI Fridays Appetizers", .frozen),
        "tgi fridays": ("TGI Fridays Appetizers", .frozen),
        "chef boss appetizers": ("Chef Boss Appetizers", .frozen),
        "pinty's appetizers": ("Pinty's Appetizers", .frozen),
        "pintys appetizers": ("Pinty's Appetizers", .frozen),
        "janes fingers": ("Janes Fingers", .frozen),
        "farm boy appetizers": ("Farm Boy Appetizers", .frozen),

        // Frozen Desserts & Sweets (Ice Cream already covered in Dairy, but frozen cakes/pies here)
        "mccain deep n delicious": ("McCain Deep N Delicious Cake", .frozen),
        "deep n delicious": ("McCain Deep N Delicious Cake", .frozen),
        "pc cake": ("PC Frozen Cake", .frozen),
        "pc frozen cake": ("PC Frozen Cake", .frozen),
        "no name cake": ("No Name Frozen Cake", .frozen),
        "compliments pie": ("Compliments Frozen Pie", .frozen),
        "compliments frozen pie": ("Compliments Frozen Pie", .frozen),
        "irresistibles cake": ("Irresistibles Frozen Cake", .frozen),
        "great value pie": ("Great Value Frozen Pie", .frozen),
        "tenderflake pie": ("Tenderflake Pie", .frozen),
        "vachon pastry": ("Vachon Frozen Pastry", .frozen),
        "hostess frozen treats": ("Hostess Frozen Treats", .frozen),

        // Frozen Pasta, Sides & Ethnic
        "olivieri pasta": ("Olivieri Pasta", .frozen),
        "olivieri": ("Olivieri Pasta", .frozen),
        "catelli lasagna": ("Catelli Lasagna", .frozen),
        "catelli frozen": ("Catelli Frozen Pasta", .frozen),
        "pc ravioli": ("PC Ravioli", .frozen),
        "no name lasagna": ("No Name Lasagna", .frozen),
        "compliments pasta": ("Compliments Frozen Pasta", .frozen),
        "compliments frozen pasta": ("Compliments Frozen Pasta", .frozen),
        "irresistibles pasta": ("Irresistibles Frozen Pasta", .frozen),
        "great value pasta": ("Great Value Frozen Pasta", .frozen),
        "great value frozen pasta": ("Great Value Frozen Pasta", .frozen),
        "coop gold pasta": ("Co-op Gold Frozen Pasta", .frozen),
        "kirkland pasta": ("Kirkland Frozen Pasta", .frozen),
        "chef boyardee frozen": ("Chef Boyardee Frozen", .frozen),
        "pc chinese dinner": ("PC Chinese Dinner", .frozen),
        "compliments indian meal": ("Compliments Indian Meal", .frozen),
        "no name fried rice": ("No Name Fried Rice", .frozen),
        "tandoori kitchen": ("Tandoori Kitchen", .frozen),
        "asian inspirations": ("Asian Inspirations", .frozen),
        "biryani kitchen": ("Biryani Kitchen", .frozen),
        "sushi frozen": ("Frozen Sushi", .frozen),
        "frozen sushi": ("Frozen Sushi", .frozen),
        "pc dumplings": ("PC Dumplings", .frozen),
        "summ! dumplings": ("Summ! Dumplings", .frozen),
        "siwin foods dumplings": ("Siwin Foods Dumplings", .frozen),
        "siwin dumplings": ("Siwin Foods Dumplings", .frozen),

        // Store / Private Label Frozen Lines
        "pc frozen food": ("PC Frozen Food", .frozen),
        "no name frozen food": ("No Name Frozen Food", .frozen),
        "compliments frozen food": ("Compliments Frozen Food", .frozen),
        "irresistibles frozen food": ("Irresistibles Frozen Food", .frozen),
        "great value frozen food": ("Great Value Frozen Food", .frozen),
        "coop gold frozen food": ("Co-op Gold Frozen Food", .frozen),
        "kirkland frozen food": ("Kirkland Frozen Food", .frozen),
        "farm boy frozen food": ("Farm Boy Frozen Food", .frozen),
        "longos frozen food": ("Longos Frozen Food", .frozen),
        "metro frozen food": ("Metro Frozen Food", .frozen),
        "freshco frozen food": ("FreshCo Frozen Food", .frozen),
        "safeway frozen food": ("Safeway Frozen Food", .frozen),
        "sobeys frozen food": ("Sobeys Frozen Food", .frozen),

        // Common Receipt Variants
        "frozen pizza": ("Frozen Pizza", .frozen),
        "frozen meal": ("Frozen Meal", .frozen),
        "frozen dinner": ("Frozen Dinner", .frozen),
        "frozen fries": ("Frozen Fries", .frozen),
        "frozen vegetables": ("Frozen Vegetables", .frozen),
        "frozen fruit": ("Frozen Fruit", .frozen),
        "frozen chicken": ("Frozen Chicken", .frozen),
        "frozen burgers": ("Frozen Burgers", .frozen),
        "frozen wings": ("Frozen Wings", .frozen),
        "frozen fish": ("Frozen Fish", .frozen),
        "frozen shrimp": ("Frozen Shrimp", .frozen),
        "frozen lasagna": ("Frozen Lasagna", .frozen),
        "frozen dessert": ("Frozen Dessert", .frozen),
        "frozen waffles": ("Frozen Waffles", .frozen),
        "frozen breakfast": ("Frozen Breakfast", .frozen),
        "frozen pie": ("Frozen Pie", .frozen),
        "frozen pastry": ("Frozen Pastry", .frozen),
        "frozen bread": ("Frozen Bread", .frozen),
        "frozen appetizers": ("Frozen Appetizers", .frozen),
    ]
    
    // MARK: - Whitelist of Recognized Food Items (Fallback)
    
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
            
            // STEP 1: Try brand matching first (most specific)
            if let item = matchCanadianBrand(from: cleanLine) {
                items.append(item)
                continue
            }
            
            // STEP 2: Fall back to keyword matching
            if let item = matchRecognizedFood(from: cleanLine) {
                items.append(item)
            }
        }
        
        // Remove duplicates and merge quantities
        items = mergeDuplicates(items)
        
        return items
    }
    
    // MARK: - Brand Matching
    
    private static func matchCanadianBrand(from line: String) -> ParsedItem? {
        let lowercaseLine = line.lowercased()
        
        // Try to find exact brand match
        for (brandKey, brandInfo) in canadianBrands {
            if lowercaseLine.contains(brandKey) {
                let quantity = extractQuantity(from: line)
                
                return ParsedItem(
                    name: brandInfo.product,
                    quantity: quantity,
                    isSelected: true,
                    estimatedCategory: brandInfo.category
                )
            }
        }
        
        return nil
    }
    
    // MARK: - Whitelist Matching (Fallback)
    
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
    
    // MARK: - Category Inference
    
    static func inferCategory(from name: String) -> ItemCategory {
        let lowercaseName = name.lowercased()
        
        // Check brand database first
        for (_, brandInfo) in canadianBrands {
            if brandInfo.product.lowercased() == lowercaseName {
                return brandInfo.category
            }
        }
        
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
