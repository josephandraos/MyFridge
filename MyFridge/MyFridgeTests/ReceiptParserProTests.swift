//
//  ReceiptParserProTests.swift
//  MyFridgeTests
//
//  Receipt scanning regression tests. Run with Cmd+U in Xcode.
//
//  - "presseCafe" is transcribed from the real photo in Receipt Examples/.
//  - The other receipts are SYNTHETIC but follow real Quebec/Ontario layouts.
//    Real OCR output will be messier: when a real scan goes wrong, paste its OCR text
//    here as a new test (print `scannedText` in ReceiptScannerViewPro to get it).
//

import Testing
import CoreGraphics
@testable import MyFridge

struct ReceiptParserProTests {

    // MARK: - Helpers

    private struct Row: Equatable, CustomStringConvertible {
        let name: String
        let quantity: Int
        let category: ItemCategory

        init(_ name: String, _ quantity: Int, _ category: ItemCategory) {
            self.name = name.lowercased()
            self.quantity = quantity
            self.category = category
        }

        var description: String { "\(name) x\(quantity) [\(category)]" }
    }

    private func parse(_ text: String) -> [Row] {
        ReceiptParserPro.parseReceipt(text).map { Row($0.name, $0.quantity, $0.estimatedCategory) }
    }

    // MARK: - Real receipt

    @Test func presseCafe() {
        let text = """
        Presse Café CENTROPOLIS
        (450) 978-2233
        1794
        Av. Pierre-Péladeau
        Laval (Québec), H7T2Z1
        terminal 1
        employé: CAISSIER 1
        2025-10-16 12:01:22
        Transaction # x0.ftkoQdq
        Commande # 112627
        1 Latte/Cappu Reg (5.55$) FP
        Sous-total 5.55$
        TPS 851598680RT0001
        TVQ 1218078873TQ0001
        Total VENTE 6.38$
        MASTER CARD 6.38$
        AUTRE MODE DE PAIEMENT
        TPS: 0.28$
        TVQ: 0.55$
        Total: 6.38$
        PAIEMENT REÇU
        """
        #expect(parse(text) == [Row("Latte/cappu Reg", 1, .beverages)])
    }

    // MARK: - Quebec grocery layouts

    @Test func igaQuebec() {
        let text = """
        IGA EXTRA FAMILLE LAROCHE
        1234 BOUL. DES LAURENTIDES
        LAVAL QC H7G 2T4
        TEL: 450-555-0199
        2025-10-12 17:42 CAISSE 3
        LAIT 2% 2L 4.99 F
        PAIN TRANCHE BLE ENTIER 3.49 F
        POULET ENTIER 12.37 F
        1.856 kg @ 6.66/kg
        BANANES 1.84 F
        0.920 kg @ 1.99/kg
        FROMAGE CHEDDAR 400G 7.99 F
        OEUFS GROS 12 4.29 F
        YOGOURT NATUREL 650G 3.99 F
        RABAIS COUPON -1.00
        JUS D'ORANGE 1.89L 3.49 FP
        CAROTTES 3.58 F
        2 @ 1.79
        BLEUETS 4.49 F
        SAC REUTILISABLE 0.25 FP
        SOUS-TOTAL 40.35
        TPS 5% 0.00
        TVQ 9.975% 0.25
        TOTAL 40.60
        VISA 40.60
        MERCI ET A BIENTOT
        """
        #expect(parse(text) == [
            Row("Lait 2%", 1, .dairy),                      // "2L" is a SIZE, not a quantity
            Row("Pain Tranche Ble Entier", 1, .bakery),
            Row("Poulet Entier", 1, .meat),
            Row("Bananes", 1, .fruits),
            Row("Fromage Cheddar", 1, .dairy),
            Row("Oeufs Gros", 1, .dairy),                   // "12" (eggs per carton) is not a quantity
            Row("Yogourt Naturel", 1, .dairy),
            Row("Jus D'orange", 1, .beverages),             // juice, not fruit
            Row("Carottes", 2, .vegetables),                // "2 @ 1.79" on the next line
            Row("Bleuets", 1, .fruits),
        ])
    }

    @Test func metroPriceOnNextLine() {
        let text = """
        METRO PLUS FAMILLE
        Magasin 548
        RUE SAINT-DENIS
        MONTREAL QC
        514-555-0123
        NATREL LAIT 1% 4L
        7.49 F
        OEUFS BLANCS GRADE A GROS
        4.99 F
        2 X 4.99
        FRAISES 454G 3.49 F
        MAYONNAISE HELLMANN'S 890ML 6.99 F
        PATES PENNE BARILLA 450G 2.49 F
        2 X 2.49
        SAUCE TOMATE CLASSICO 650ML 3.29 F
        POMMES DE TERRE 10LB 5.99 F
        CONSIGNE 0.10
        SOUS-TOTAL 30.34
        TOTAL 30.34
        """
        #expect(parse(text) == [
            Row("Natrel Lait 1%", 1, .dairy),               // 4L milk is ONE item
            Row("Oeufs Blancs Grade A Gros", 2, .dairy),
            Row("Fraises", 1, .fruits),
            Row("Mayonnaise Hellmann's", 1, .snacks),
            Row("Pates Penne Barilla", 2, .prepared),
            Row("Sauce Tomate Classico", 1, .snacks),
            Row("Pommes De Terre", 1, .vegetables),         // 10LB bag is ONE item, not 10
        ])
    }

    @Test func weighedItemWithPriceOnWeightLine() {
        let text = """
        SUPER C
        3025 BOUL. TASCHEREAU
        LONGUEUIL QC J4V 2H9
        05/11/2025 14:22
        POULET FRAIS ENTIER
        2.150 kg @ 5.49/kg 11.80 F
        CAROTTES 2LB 1.99 F
        LAITUE ROMAINE 2.49 F
        YOGOURT GREC 2X 6.49 F
        CROUSTILLES BBQ 3.99 F
        LAIT 2% 2L 4.69 F
        SOUS-TOTAL 31.45
        TOTAL 31.45
        """
        #expect(parse(text) == [
            Row("Poulet Frais Entier", 1, .meat),
            Row("Carottes", 1, .vegetables),
            Row("Laitue Romaine", 1, .vegetables),          // lettuce, not milk ("lait")
            Row("Yogourt Grec", 2, .dairy),
            Row("Croustilles Bbq", 1, .snacks),
            Row("Lait 2%", 1, .dairy),
        ])
    }

    // MARK: - Costco / English

    @Test func costco() {
        let text = """
        COSTCO WHOLESALE
        Montreal Gateway #1234
        2000 AVENUE DES PINS
        Membre 111234567890
        E 1234567 KS ORGANIC EGGS 11.99 A
        E 1357924 ROTISSERIE CHICKEN 7.99 A
        E 2468013 BANANAS 3LB 2.19 A
        E 3141592 KS BUTTER UNSALTED 15.99 A
        1234567 /1234567 -3.00
        E 5551212 KIRKLAND TOILET PAPER 24.99 Y
        E 7777777 SALMON FILLET 1.234KG 18.55 A
        SUBTOTAL 81.70
        TAX 0.00
        **** TOTAL 81.70
        """
        #expect(parse(text) == [
            Row("Organic Eggs", 1, .dairy),
            Row("Rotisserie Chicken", 1, .meat),
            Row("Bananas", 1, .fruits),
            Row("Butter Unsalted", 1, .dairy),
            Row("Salmon Fillet", 1, .meat),
        ])
    }

    @Test func loblawsOntario() {
        let text = """
        LOBLAWS
        75 QUEEN STREET
        TORONTO ON M5V 2X5
        416-555-0188
        NO NAME BREAD WHITE 675G 1.99 MRJ
        LACTANTIA BUTTER UNSALTED 454G 5.99 MRJ
        CHICKEN BREAST BONELESS 8.45 MRJ
        2 @ 2.99
        SPECIAL K CEREAL 410G 4.99 HMRJ
        PC OPTIMUM POINTS 150
        CASHEWS ROASTED 6.99 MRJ
        SUBTOTAL 28.41
        HST 13% 0.00
        TOTAL 28.41
        """
        #expect(parse(text) == [
            Row("No Name Bread White", 1, .bakery),         // "NO NAME" brand must not be dropped
            Row("Lactantia Butter Unsalted", 1, .dairy),
            Row("Chicken Breast Boneless", 2, .meat),
            Row("Special K Cereal", 1, .snacks),
            Row("Cashews Roasted", 1, .snacks),             // "cashews" must not be read as "cash"
        ])
    }

    // MARK: - Things that must NOT become items

    @Test func nonGroceryReceiptGivesNothing() {
        let text = """
        PHARMAPRIX
        123 RUE PRINCIPALE
        MONTREAL QC H2X 1Y2
        Tel: (514) 555-0100
        2025-11-02 10:15
        Client: 4021
        MERCI DE VOTRE VISITE
        SOUS-TOTAL 0.00
        """
        #expect(parse(text).isEmpty)
    }

    @Test func emptyTextGivesNothing() {
        #expect(parse("").isEmpty)
        #expect(parse("\n\n   \n").isEmpty)
    }

    @Test func duplicateLinesAreMerged() {
        let text = """
        BANANES 1.84 F
        BANANES 1.84 F
        LAIT 2% 4.99 F
        TOTAL 8.67
        """
        #expect(parse(text) == [Row("Bananes", 2, .fruits), Row("Lait 2%", 1, .dairy)])
    }

    @Test func decimalCommaAndSpacedCents() {
        let text = """
        BEURRE SALE 5,99 F
        FROMAGE BRIE 7 49 F
        TOTAL 13.48
        """
        #expect(parse(text) == [Row("Beurre Sale", 1, .dairy), Row("Fromage Brie", 1, .dairy)])
    }

    // MARK: - OCR row reconstruction

    @Test func rowsAreRebuiltFromSeparatePieces() {
        // Vision coordinates: y grows upward. Item name on the left, price on the right, same height.
        let fragments = [
            OCRFragment(text: "4.99 F", box: CGRect(x: 0.75, y: 0.801, width: 0.12, height: 0.02)),
            OCRFragment(text: "LAIT 2% 2L", box: CGRect(x: 0.10, y: 0.800, width: 0.30, height: 0.02)),
            OCRFragment(text: "3.49 F", box: CGRect(x: 0.75, y: 0.700, width: 0.12, height: 0.02)),
            OCRFragment(text: "PAIN BLE", box: CGRect(x: 0.10, y: 0.699, width: 0.25, height: 0.02)),
        ]
        let rows = ReceiptOCREngine.rowsText(from: fragments).components(separatedBy: "\n")
        #expect(rows.count == 2)
        #expect(rows[0] == "LAIT 2% 2L  4.99 F")   // top row first, name before price
        #expect(rows[1] == "PAIN BLE  3.49 F")
    }

    // MARK: - French / English name matching

    @Test(arguments: [
        ("Lait 2%", ItemCategory.dairy), ("Laitue romaine", .vegetables), ("Poulet", .meat),
        ("Pommes de terre", .vegetables), ("Jus d'orange", .beverages), ("Champignons", .vegetables),
        ("Hamburger", .prepared), ("Beurre d'arachide", .snacks), ("Yogourt grec", .dairy),
        ("Poutine", .prepared), ("Croustilles", .snacks), ("Jambon", .meat), ("Bleuets", .fruits),
        ("Potato chips", .snacks), ("Frozen pizza", .frozen), ("Ice cream", .dairy), ("Eggplant", .vegetables),
        ("Butternut squash", .vegetables), ("Thé vert", .beverages), ("Pâté chinois", .prepared),
    ])
    func categoryDetection(name: String, expected: ItemCategory) {
        #expect(ItemEmojiHelper.detectCategory(for: name) == expected)
    }
}
