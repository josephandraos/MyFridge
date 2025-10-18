//
//  ContentView.swift
//  MyFridge
//
//  Created by Joe Andraos on 2025-10-03.
//

import SwiftUI
import SwiftData
import VisionKit

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var notificationManager: NotificationManager
    @Query private var items: [Item]
    @State private var showingAddItem = false
    @State private var showingItemsList = false
    @State private var showingSettings = false
    @State private var showingProfile = false
    @State private var showingScanner = false
    @State private var isAnimating = false
    @State private var showNotificationPermissionAlert = false
    @State private var showScannerUnavailableAlert = false
    
    private var totalItems: Int {
        items.count
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    Spacer()
                        .frame(height: 40)
                    
                    Text("MyFridge")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .blue.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .padding(.bottom, 8)
                        .opacity(isAnimating ? 1 : 0)
                        .offset(y: isAnimating ? 0 : -20)
                    
                    Button(action: { showingItemsList = true }) {
                        ZStack {
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [.blue.opacity(0.2), .clear],
                                        center: .center,
                                        startRadius: 80,
                                        endRadius: 140
                                    )
                                )
                                .frame(width: 280, height: 280)
                            
                            Image(systemName: "refrigerator.fill")
                                .font(.system(size: 150))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.blue, .blue.opacity(0.6)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: .blue.opacity(0.4), radius: 15, x: -5, y: 10)
                                .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 15)
                            
                            if totalItems > 0 {
                                Text("\(totalItems)")
                                    .font(.system(size: 40, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white)
                                    .frame(width: 80, height: 80)
                                    .background(
                                        Circle()
                                            .fill(.blue)
                                            .shadow(color: .blue.opacity(0.5), radius: 10, y: 5)
                                    )
                                    .offset(x: 50, y: -50)
                            }
                        }
                        .scaleEffect(isAnimating ? 1 : 0.8)
                    }
                    .buttonStyle(.plain)
                    
                    Text("Track your groceries, reduce waste")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                        .padding(.top, 16)
                        .opacity(isAnimating ? 1 : 0)
                    
                    Spacer()
                        .frame(height: 60)
                    
                    VStack(spacing: 16) {
                        Text("Quick Actions")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 24)
                            .padding(.bottom, 4)
                            .opacity(isAnimating ? 1 : 0)
                        
                        Button(action: { showingAddItem = true }) {
                            HStack(spacing: 16) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(.green.opacity(0.1))
                                        .frame(width: 46, height: 46)
                                    
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundStyle(.green)
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Add Manually")
                                        .font(.system(size: 17, weight: .semibold))
                                        .foregroundStyle(.primary)
                                    
                                    Text("Quick entry for single items")
                                        .font(.system(size: 13))
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(.systemBackground))
                                    .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
                            )
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 24)
                        .opacity(isAnimating ? 1 : 0)
                        .offset(x: isAnimating ? 0 : -20)
                    }
                    .padding(.bottom, 40)
                    
                    Spacer()
                        .frame(height: 20)
                    
                    Button(action: scanNow) {
                        HStack(spacing: 14) {
                            Image(systemName: "barcode.viewfinder")
                                .font(.system(size: 30, weight: .semibold))
                            
                            Text("Scan Receipt")
                                .font(.system(size: 24, weight: .bold))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 100)
                        .background(
                            RoundedRectangle(cornerRadius: 18)
                                .fill(
                                    LinearGradient(
                                        colors: [.blue, .blue.opacity(0.85)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: .blue.opacity(0.5), radius: 15, y: 8)
                        )
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .padding(.horizontal, 16)
                    .padding(.bottom, 50)
                    .opacity(isAnimating ? 1 : 0)
                    .offset(y: isAnimating ? 0 : 20)
                }
            }
            .background(Color(.systemGroupedBackground))
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showingProfile = true }) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(.blue)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingSettings = true }) {
                        Image(systemName: "gearshape.fill")
                            .foregroundStyle(.blue)
                    }
                }
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.6)) {
                    isAnimating = true
                }
            }
            .sheet(isPresented: $showingAddItem) {
                AddItemView(showNotificationPermissionAlert: $showNotificationPermissionAlert)
            }
            .sheet(isPresented: $showingItemsList) {
                ItemsListView()
            }
            .sheet(isPresented: $showingProfile) {
                ProfileView()
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showingScanner) {
                if #available(iOS 16.0, *) {
                    ReceiptScannerView()
                }
            }
            .alert("Enable Notifications?", isPresented: $showNotificationPermissionAlert) {
                Button("Enable") {
                    notificationManager.requestPermission { granted in
                        if granted {
                            // Schedule notifications for all existing items
                            Task { @MainActor in
                                for item in items where !item.isExpired {
                                    item.notificationScheduled = true
                                    await notificationManager.scheduleNotification(for: item)
                                }
                            }
                        }
                    }
                }
                Button("Not Now", role: .cancel) {}
            } message: {
                Text("Get reminded before items expire so you can use them and reduce food waste. We'll notify you \(notificationManager.defaultLeadTimeDays) days before items expire.")
            }
            .alert("Scanner Unavailable", isPresented: $showScannerUnavailableAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("The receipt scanner requires iOS 16 or later with a compatible camera. You can still add items manually.")
            }
        }
    }
    
    private func scanNow() {
        // Check iOS version and scanner availability
        if #available(iOS 16.0, *) {
            if DataScannerViewController.isSupported && DataScannerViewController.isAvailable {
                showingScanner = true
            } else {
                showScannerUnavailableAlert = true
            }
        } else {
            showScannerUnavailableAlert = true
        }
    }
}

// MARK: - Custom Button Style
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Items List View
struct ItemsListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var notificationManager: NotificationManager
    @Query(sort: \Item.expirationDate) private var items: [Item]
    @State private var selectedItem: Item?
    @State private var showingEditItem = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(items) { item in
                    ItemRowView(item: item)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .transition(.asymmetric(
                            insertion: .scale.combined(with: .opacity),
                            removal: .opacity
                        ))
                        .onTapGesture {
                            selectedItem = item
                            showingEditItem = true
                        }
                }
                .onDelete(perform: deleteItems)
            }
            .animation(.easeInOut(duration: 0.3), value: items.count)
            .listStyle(.plain)
            .background(Color(.systemGroupedBackground))
            .scrollContentBackground(.hidden)
            .navigationTitle("My Items")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .overlay {
                if items.isEmpty {
                    ContentUnavailableView(
                        "No Items in Fridge",
                        systemImage: "refrigerator",
                        description: Text("Add items to start tracking your groceries")
                    )
                }
            }
            .sheet(isPresented: $showingEditItem) {
                if let item = selectedItem {
                    EditItemView(item: item)
                }
            }
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                let item = items[index]
                // Cancel notification before deleting
                Task {
                    await notificationManager.cancelNotification(for: item)
                }
                modelContext.delete(item)
            }
        }
    }
}

// MARK: - Item Row View
struct ItemRowView: View {
    let item: Item
    
    var body: some View {
        HStack(spacing: 14) {
            Text(ItemEmojiHelper.emoji(for: item.name))
                .font(.system(size: 32))
                .frame(width: 44, height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(expirationColor(for: item).opacity(0.1))
                )
            
            VStack(alignment: .leading, spacing: 5) {
                Text(item.name)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.primary)
                
                HStack(spacing: 6) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                    
                    Text("Expires: \(item.expirationDate, format: .dateTime.month().day().year())")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
                
                HStack(spacing: 4) {
                    Circle()
                        .fill(expirationColor(for: item))
                        .frame(width: 6, height: 6)
                    
                    Text(item.expirationStatus)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(expirationColor(for: item))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(expirationColor(for: item).opacity(0.12))
                )
            }
            
            Spacer()
            
            VStack(spacing: 4) {
                Text("\(item.quantity)")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                
                Text("qty")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
            }
            .frame(width: 50)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        )
    }
    
    private func expirationColor(for item: Item) -> Color {
        let days = Calendar.current.dateComponents([.day], from: Date(), to: item.expirationDate).day ?? 0
        if days < 0 { return .red }
        if days <= 7 { return .orange }
        return .green
    }
}

// MARK: - Add Item View
struct AddItemView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var notificationManager: NotificationManager
    @Binding var showNotificationPermissionAlert: Bool
    
    @State private var name = ""
    @State private var quantity = 1
    @State private var quantityText = "1"
    @State private var showingQuantityInput = false
    @State private var expirationDate = Date().addingTimeInterval(7 * 24 * 60 * 60)
    @State private var category: ItemCategory = .snacks
    @State private var notes = ""
    @FocusState private var isNameFieldFocused: Bool
    @FocusState private var isNotesFieldFocused: Bool
    @FocusState private var isQuantityFieldFocused: Bool
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Item Details") {
                    HStack {
                        Text(ItemEmojiHelper.emoji(for: name))
                            .font(.system(size: 40))
                        
                        TextField("Item name", text: $name)
                            .font(.system(size: 17))
                            .focused($isNameFieldFocused)
                            .submitLabel(.done)
                            .onChange(of: name) { oldValue, newValue in
                                // Auto-detect category when name changes
                                category = ItemEmojiHelper.detectCategory(for: newValue)
                            }
                    }
                    
                    // Quantity with manual input option
                    HStack {
                        Text("Quantity:")
                        
                        Spacer()
                        
                        Button(action: {
                            if quantity > 1 {
                                quantity -= 1
                                quantityText = "\(quantity)"
                            }
                        }) {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 24))
                                .foregroundStyle(quantity > 1 ? .blue : .gray)
                        }
                        .buttonStyle(.plain)
                        .disabled(quantity <= 1)
                        
                        if showingQuantityInput {
                            TextField("", text: $quantityText)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.center)
                                .frame(width: 60)
                                .padding(8)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                                .focused($isQuantityFieldFocused)
                                .onChange(of: quantityText) { oldValue, newValue in
                                    if let value = Int(newValue), value > 0, value <= 999 {
                                        quantity = value
                                    } else if newValue.isEmpty {
                                        quantity = 1
                                    }
                                }
                                .onSubmit {
                                    showingQuantityInput = false
                                    if quantityText.isEmpty || Int(quantityText) == nil {
                                        quantityText = "1"
                                        quantity = 1
                                    }
                                }
                        } else {
                            Button(action: {
                                showingQuantityInput = true
                                isQuantityFieldFocused = true
                            }) {
                                Text("\(quantity)")
                                    .font(.system(size: 20, weight: .bold, design: .rounded))
                                    .foregroundStyle(.blue)
                                    .frame(width: 60, height: 36)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                            }
                            .buttonStyle(.plain)
                        }
                        
                        Button(action: {
                            if quantity < 999 {
                                quantity += 1
                                quantityText = "\(quantity)"
                            }
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 24))
                                .foregroundStyle(quantity < 999 ? .blue : .gray)
                        }
                        .buttonStyle(.plain)
                        .disabled(quantity >= 999)
                    }
                    
                    Picker("Category", selection: $category) {
                        ForEach(ItemCategory.allCases, id: \.self) { cat in
                            Text(cat.rawValue).tag(cat)
                        }
                    }
                }
                
                Section("Expiration") {
                    DatePicker("Expiration Date", selection: $expirationDate, in: Date()..., displayedComponents: .date)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            QuickDateButton(title: "3 days", days: 3, selection: $expirationDate)
                            QuickDateButton(title: "1 week", days: 7, selection: $expirationDate)
                            QuickDateButton(title: "2 weeks", days: 14, selection: $expirationDate)
                            QuickDateButton(title: "1 month", days: 30, selection: $expirationDate)
                        }
                        .padding(.vertical, 4)
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                }
                
                Section("Notes (Optional)") {
                    TextField("Add notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                        .focused($isNotesFieldFocused)
                }
            }
            .navigationTitle("Add Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        addItem()
                    }
                    .fontWeight(.semibold)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        isNameFieldFocused = false
                        isNotesFieldFocused = false
                        if isQuantityFieldFocused {
                            showingQuantityInput = false
                            isQuantityFieldFocused = false
                            if quantityText.isEmpty || Int(quantityText) == nil {
                                quantityText = "1"
                                quantity = 1
                            }
                        }
                    }
                }
            }
            .onAppear {
                isNameFieldFocused = true
            }
        }
    }
    
    private func addItem() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }
        
        let newItem = Item(
            name: trimmedName,
            quantity: quantity,
            expirationDate: expirationDate,
            category: category.rawValue,
            notes: notes.isEmpty ? nil : notes
        )
        modelContext.insert(newItem)
        
        // Request notification permission if this is the first item being saved
        if !notificationManager.hasAskedForPermission {
            // Dismiss the sheet first
            dismiss()
            
            // Slight delay to ensure sheet is dismissed, then show permission alert
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showNotificationPermissionAlert = true
            }
        } else if notificationManager.notificationPermissionGranted {
            // Schedule notification for this item
            Task {
                newItem.notificationScheduled = true
                await notificationManager.scheduleNotification(for: newItem)
            }
            dismiss()
        } else {
            dismiss()
        }
    }
}

// MARK: - Quick Date Button Component
struct QuickDateButton: View {
    let title: String
    let days: Int
    @Binding var selection: Date
    
    var body: some View {
        Button(action: {
            selection = Calendar.current.date(byAdding: .day, value: days, to: Date()) ?? Date()
        }) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.blue)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(.blue.opacity(0.1))
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Emoji Helper (Strict Whitelist - matches ReceiptParser)
struct ItemEmojiHelper {
    static func emoji(for itemName: String) -> String {
        let lower = itemName.lowercased().trimmingCharacters(in: .whitespaces)
        
        guard !lower.isEmpty else { return "🍿" }
        
        // DAIRY & EGGS
        if lower.contains("milk") { return "🥛" }
        if lower.contains("butter") { return "🧈" }
        if lower.contains("cheese") { return "🧀" }
        if lower.contains("ice cream") { return "🍦" }
        if lower.contains("egg") { return "🥚" }
        if lower.contains("yogurt") || lower.contains("yoghurt") { return "🍶" }
        if lower.contains("cream") { return "🥛" }
        
        // MEAT & FISH
        if lower.contains("chicken") { return "🍗" }
        if lower.contains("steak") || lower.contains("beef") { return "🥩" }
        if lower.contains("bacon") { return "🥓" }
        if lower.contains("rib") || lower.contains("pork") { return "🍖" }
        if lower.contains("fish") { return "🐟" }
        if lower.contains("salmon") { return "🐟" }
        if lower.contains("tuna") { return "🐟" }
        if lower.contains("shrimp") || lower.contains("prawn") { return "🦐" }
        if lower.contains("turkey") { return "🍗" }
        if lower.contains("ham") { return "🍖" }
        if lower.contains("sausage") { return "🌭" }
        
        // FRUITS
        if lower.contains("apple") { return "🍎" }
        if lower.contains("banana") { return "🍌" }
        if lower.contains("strawberr") { return "🍓" }
        if lower.contains("grape") { return "🍇" }
        if lower.contains("orange") { return "🍊" }
        if lower.contains("watermelon") { return "🍉" }
        if lower.contains("lemon") { return "🍋" }
        if lower.contains("peach") { return "🍑" }
        if lower.contains("cherry") || lower.contains("cherries") { return "🍒" }
        if lower.contains("pear") { return "🍐" }
        if lower.contains("pineapple") { return "🍍" }
        if lower.contains("mango") { return "🥭" }
        if lower.contains("kiwi") { return "🥝" }
        if lower.contains("avocado") { return "🥑" }
        if lower.contains("blueberr") { return "🫐" }
        if lower.contains("raspberr") { return "🍓" }
        
        // VEGETABLES
        if lower.contains("carrot") { return "🥕" }
        if lower.contains("cucumber") { return "🥒" }
        if lower.contains("tomato") { return "🍅" }
        if lower.contains("lettuce") || lower.contains("salad") { return "🥬" }
        if lower.contains("corn") { return "🌽" }
        if lower.contains("broccoli") { return "🥦" }
        if lower.contains("garlic") { return "🧄" }
        if lower.contains("onion") { return "🧅" }
        if lower.contains("potato") { return "🥔" }
        if lower.contains("mushroom") { return "🍄" }
        if lower.contains("pepper") || lower.contains("bell") { return "🫑" }
        if lower.contains("eggplant") { return "🍆" }
        if lower.contains("spinach") { return "🥬" }
        if lower.contains("celery") { return "🥬" }
        
        // BREAD & BAKERY
        if lower.contains("bread") { return "🍞" }
        if lower.contains("croissant") { return "🥐" }
        if lower.contains("baguette") { return "🥖" }
        if lower.contains("cupcake") { return "🧁" }
        if lower.contains("cake") { return "🍰" }
        if lower.contains("bagel") { return "🥯" }
        if lower.contains("donut") || lower.contains("doughnut") { return "🍩" }
        if lower.contains("pretzel") { return "🥨" }
        if lower.contains("muffin") { return "🧁" }
        if lower.contains("cookie") { return "🍪" }
        if lower.contains("roll") { return "🥖" }
        
        // PREPARED FOODS
        if lower.contains("pizza") { return "🍕" }
        if lower.contains("burger") { return "🍔" }
        if lower.contains("sandwich") { return "🥪" }
        if lower.contains("hot dog") || lower.contains("hotdog") { return "🌭" }
        if lower.contains("taco") { return "🌮" }
        if lower.contains("burrito") { return "🌯" }
        if lower.contains("pasta") || lower.contains("spaghetti") { return "🍝" }
        if lower.contains("curry") { return "🍛" }
        if lower.contains("sushi") { return "🍣" }
        if lower.contains("ramen") || lower.contains("noodle") { return "🍜" }
        if lower.contains("rice") { return "🍚" }
        if lower.contains("wrap") { return "🌯" }
        if lower.contains("soup") { return "🍲" }
        
        // BEVERAGES
        if lower.contains("coffee") { return "☕" }
        if lower.contains("latte") { return "☕" }
        if lower.contains("cappuccino") || lower.contains("cappu") { return "☕" }
        if lower.contains("espresso") { return "☕" }
        if lower.contains("americano") { return "☕" }
        if lower.contains("mocha") { return "☕" }
        if lower.contains("juice") { return "🧃" }
        if lower.contains("soda") || lower.contains("pop") { return "🥤" }
        if lower.contains("bubble tea") || lower.contains("boba") { return "🧋" }
        if lower.contains("tea") && !lower.contains("bubble") { return "🍵" }
        if lower.contains("wine") { return "🍷" }
        if lower.contains("beer") { return "🍺" }
        if lower.contains("water") { return "💧" }
        if lower.contains("smoothie") { return "🥤" }
        
        // SNACKS & CONDIMENTS
        if lower.contains("chocolate") { return "🍫" }
        if lower.contains("cookie") { return "🍪" }
        if lower.contains("popcorn") { return "🍿" }
        if lower.contains("salt") { return "🧂" }
        if lower.contains("ketchup") { return "🍅" }
        if lower.contains("jar") || lower.contains("jam") || lower.contains("pickle") { return "🫙" }
        if lower.contains("honey") { return "🍯" }
        if lower.contains("peanut") || lower.contains("nut") { return "🥜" }
        if lower.contains("candy") { return "🍬" }
        if lower.contains("chips") { return "🍟" }
        if lower.contains("crackers") { return "🍘" }
        
        // FROZEN
        if lower.contains("ice") && !lower.contains("ice cream") { return "🧊" }
        if lower.contains("dumpling") { return "🥟" }
        if lower.contains("frozen") { return "🧊" }
        
        // Default fallback (popcorn = snacks category)
        return "🍿"
    }
    
    // Auto-detect category based on item name
    static func detectCategory(for itemName: String) -> ItemCategory {
        let lower = itemName.lowercased().trimmingCharacters(in: .whitespaces)
        
        guard !lower.isEmpty else { return .snacks }
        
        // DAIRY & EGGS
        if lower.contains("milk") || lower.contains("butter") || lower.contains("cheese") ||
           lower.contains("ice cream") || lower.contains("egg") || lower.contains("yogurt") ||
           lower.contains("yoghurt") || lower.contains("cream") {
            return .dairy
        }
        
        // MEAT & FISH
        if lower.contains("chicken") || lower.contains("steak") || lower.contains("beef") ||
           lower.contains("bacon") || lower.contains("rib") || lower.contains("pork") ||
           lower.contains("fish") || lower.contains("salmon") || lower.contains("tuna") ||
           lower.contains("shrimp") || lower.contains("prawn") || lower.contains("turkey") ||
           lower.contains("ham") || lower.contains("sausage") {
            return .meat
        }
        
        // FRUITS
        if lower.contains("apple") || lower.contains("banana") || lower.contains("strawberr") ||
           lower.contains("grape") || lower.contains("orange") || lower.contains("watermelon") ||
           lower.contains("lemon") || lower.contains("peach") || lower.contains("cherry") ||
           lower.contains("cherries") || lower.contains("pear") || lower.contains("pineapple") ||
           lower.contains("mango") || lower.contains("kiwi") || lower.contains("avocado") ||
           lower.contains("blueberr") || lower.contains("raspberr") {
            return .fruits
        }
        
        // VEGETABLES
        if lower.contains("carrot") || lower.contains("cucumber") || lower.contains("tomato") ||
           lower.contains("lettuce") || lower.contains("salad") || lower.contains("corn") ||
           lower.contains("broccoli") || lower.contains("garlic") || lower.contains("onion") ||
           lower.contains("potato") || lower.contains("mushroom") || lower.contains("pepper") ||
           lower.contains("bell") || lower.contains("eggplant") || lower.contains("spinach") ||
           lower.contains("celery") {
            return .vegetables
        }
        
        // BREAD & BAKERY
        if lower.contains("bread") || lower.contains("croissant") || lower.contains("baguette") ||
           lower.contains("cupcake") || lower.contains("cake") || lower.contains("bagel") ||
           lower.contains("donut") || lower.contains("doughnut") || lower.contains("pretzel") ||
           lower.contains("muffin") || lower.contains("cookie") || lower.contains("roll") {
            return .bakery
        }
        
        // PREPARED FOODS
        if lower.contains("pizza") || lower.contains("burger") || lower.contains("sandwich") ||
           lower.contains("hot dog") || lower.contains("hotdog") || lower.contains("taco") ||
           lower.contains("burrito") || lower.contains("pasta") || lower.contains("spaghetti") ||
           lower.contains("curry") || lower.contains("sushi") || lower.contains("ramen") ||
           lower.contains("noodle") || lower.contains("rice") || lower.contains("wrap") ||
           lower.contains("soup") {
            return .prepared
        }
        
        // BEVERAGES
        if lower.contains("coffee") || lower.contains("latte") || lower.contains("cappuccino") ||
           lower.contains("cappu") || lower.contains("espresso") || lower.contains("americano") ||
           lower.contains("mocha") || lower.contains("juice") || lower.contains("soda") ||
           lower.contains("pop") || lower.contains("bubble tea") || lower.contains("boba") ||
           lower.contains("tea") || lower.contains("wine") || lower.contains("beer") ||
           lower.contains("water") || lower.contains("smoothie") {
            return .beverages
        }
        
        // FROZEN
        if lower.contains("ice") || lower.contains("dumpling") || lower.contains("frozen") {
            return .frozen
        }
        
        // SNACKS & CONDIMENTS (default)
        return .snacks
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
        .environmentObject(NotificationManager.shared)
}
