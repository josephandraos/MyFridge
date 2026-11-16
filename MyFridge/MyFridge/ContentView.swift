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
    @Environment(\.scenePhase) private var scenePhase
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
            VStack(spacing: 0) {
                Spacer()
                    .frame(height: 15)
                
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
                                    endRadius: 130
                                )
                            )
                            .frame(width: 260, height: 260)
                        
                        Image(systemName: "refrigerator.fill")
                            .font(.system(size: 140))
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
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .frame(width: 70, height: 70)
                                .background(
                                    Circle()
                                        .fill(.blue)
                                        .shadow(color: .blue.opacity(0.5), radius: 10, y: 5)
                                )
                                .offset(x: 45, y: -45)
                        }
                    }
                    .scaleEffect(isAnimating ? 1 : 0.8)
                }
                .buttonStyle(.plain)
                
                Text("Track your groceries, reduce waste")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .padding(.top, 12)
                    .opacity(isAnimating ? 1 : 0)
                
                Spacer()
                
                VStack(spacing: 12) {
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
                    
                    // Cookbook Button (Coming Soon - Premium Feature)
                    Button(action: {}) {
                        HStack(spacing: 16) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color(.systemGray5))
                                    .frame(width: 46, height: 46)
                                
                                Image(systemName: "book.fill")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundStyle(.gray)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 6) {
                                    Text("Cookbook")
                                        .font(.system(size: 17, weight: .semibold))
                                        .foregroundStyle(.secondary)
                                    
                                    // Premium badge
                                    Text("PREMIUM")
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(
                                            Capsule()
                                                .fill(Color.orange.opacity(0.7))
                                        )
                                }
                                
                                Text("Coming soon")
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
                        .opacity(0.85)
                    }
                    .disabled(true)
                    .buttonStyle(.plain)
                    .padding(.horizontal, 24)
                    .opacity(isAnimating ? 1 : 0)
                    .offset(x: isAnimating ? 0 : -20)
                }
                .padding(.bottom, 16)
                
                Button(action: scanNow) {
                    HStack(spacing: 14) {
                        Image(systemName: "barcode.viewfinder")
                            .font(.system(size: 26, weight: .semibold))
                        
                        Text("Scan Receipt")
                            .font(.system(size: 22, weight: .bold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 85)
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
                .padding(.bottom, 35)
                .opacity(isAnimating ? 1 : 0)
                .offset(y: isAnimating ? 0 : 20)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                WidgetDataUpdater.syncWithWidget(modelContext: modelContext)
            }
            // Keep the home-screen widget in sync (also applies items checked off in the widget)
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active || newPhase == .background {
                    WidgetDataUpdater.syncWithWidget(modelContext: modelContext)
                }
            }
            .onChange(of: items.count) { _, _ in
                WidgetDataUpdater.syncWithWidget(modelContext: modelContext)
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
                    ReceiptScannerViewPro()
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
    @State private var expandedCategories: Set<ItemCategory> = []
    
    // Group items by category
    private var groupedItems: [ItemCategory: [Item]] {
        Dictionary(grouping: items) { item in
            item.itemCategory
        }
    }
    
    // Get categories that have items, sorted in a logical order
    private var categoriesWithItems: [ItemCategory] {
        ItemCategory.allCases.filter { category in
            groupedItems[category]?.isEmpty == false
        }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(categoriesWithItems, id: \.self) { category in
                    Section {
                        if expandedCategories.contains(category) {
                            ForEach(groupedItems[category] ?? []) { item in
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
                            .onDelete { offsets in
                                deleteItems(in: category, at: offsets)
                            }
                        }
                    } header: {
                        CategoryHeaderView(
                            category: category,
                            itemCount: groupedItems[category]?.count ?? 0,
                            isExpanded: expandedCategories.contains(category)
                        )
                        .listRowBackground(Color.clear)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                if expandedCategories.contains(category) {
                                    expandedCategories.remove(category)
                                } else {
                                    expandedCategories.insert(category)
                                }
                            }
                        }
                    }
                    .listSectionSeparator(.hidden)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: expandedCategories)
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

    private func deleteItems(in category: ItemCategory, at offsets: IndexSet) {
        withAnimation {
            let categoryItems = groupedItems[category] ?? []
            for index in offsets {
                let item = categoryItems[index]
                // Cancel notification before deleting
                Task {
                    await notificationManager.cancelNotification(for: item)
                }
                modelContext.delete(item)
            }
        }
    }
}

// MARK: - Category Header View
struct CategoryHeaderView: View {
    let category: ItemCategory
    let itemCount: Int
    let isExpanded: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Category emoji
            Text(category.emoji)
                .font(.system(size: 28))
            
            // Category name
            Text(category.displayName)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.primary)
            
            Spacer()
            
            // Item count
            Text("\(itemCount) items")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(Color(.systemGray5))
                )
            
            // Chevron indicator
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.secondary)
                .rotationEffect(.degrees(isExpanded ? 90 : 0))
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isExpanded)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .listRowInsets(EdgeInsets())
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
                            Text(cat.displayName).tag(cat)
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
    let title: LocalizedStringKey
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

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
        .environmentObject(NotificationManager.shared)
}
