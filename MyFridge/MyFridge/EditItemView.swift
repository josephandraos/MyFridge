//
//  EditItemView.swift
//  MyFridge
//
//  Created by Joe Andraos on 2025-10-03.
//

import SwiftUI
import SwiftData

struct EditItemView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var notificationManager: NotificationManager
    
    @Bindable var item: Item
    
    @State private var name: String
    @State private var quantity: Int
    @State private var quantityText: String
    @State private var showingQuantityInput = false
    @State private var expirationDate: Date
    @State private var category: ItemCategory
    @State private var notes: String
    @State private var showDeleteConfirmation = false
    
    @FocusState private var isNameFieldFocused: Bool
    @FocusState private var isNotesFieldFocused: Bool
    @FocusState private var isQuantityFieldFocused: Bool
    
    init(item: Item) {
        self.item = item
        _name = State(initialValue: item.name)
        _quantity = State(initialValue: item.quantity)
        _quantityText = State(initialValue: "\(item.quantity)")
        _expirationDate = State(initialValue: item.expirationDate)
        _category = State(initialValue: item.itemCategory)
        _notes = State(initialValue: item.notes ?? "")
    }
    
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
                
                Section {
                    Button(role: .destructive, action: {
                        showDeleteConfirmation = true
                    }) {
                        HStack {
                            Spacer()
                            Text("Delete Item")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Edit Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveItem()
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
            .alert("Delete Item?", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    deleteItem()
                }
            } message: {
                Text("Are you sure you want to delete \(item.name)? This action cannot be undone.")
            }
        }
    }
    
    private func saveItem() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }
        
        // Update item properties
        item.name = trimmedName
        item.quantity = quantity
        item.expirationDate = expirationDate
        item.category = category.rawValue
        item.notes = notes.isEmpty ? nil : notes
        item.updateModifiedDate()
        
        // Reschedule notification if needed
        if notificationManager.notificationPermissionGranted && !item.isExpired {
            Task {
                await notificationManager.cancelNotification(for: item)
                await notificationManager.scheduleNotification(for: item)
            }
        }
        
        dismiss()
    }
    
    private func deleteItem() {
        // Cancel notification before deleting
        Task {
            await notificationManager.cancelNotification(for: item)
        }
        modelContext.delete(item)
        dismiss()
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Item.self, configurations: config)
    let context = container.mainContext
    
    let sampleItem = Item(
        name: "Milk",
        quantity: 2,
        expirationDate: Date().addingTimeInterval(5 * 24 * 60 * 60),
        category: "Dairy & Eggs"
    )
    context.insert(sampleItem)
    
    return EditItemView(item: sampleItem)
        .modelContainer(container)
        .environmentObject(NotificationManager.shared)
}
