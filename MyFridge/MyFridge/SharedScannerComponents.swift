//
//  SharedScannerComponents.swift
//  MyFridge
//
//  Shared components used by both scanner views
//

import SwiftUI

// MARK: - Parsed Item Model
struct ParsedItem: Identifiable, Equatable {
    let id = UUID()
    var name: String
    var quantity: Int
    var isSelected: Bool = true
    var estimatedCategory: ItemCategory = .snacks
    
    static func == (lhs: ParsedItem, rhs: ParsedItem) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Review Scanned Items View
struct ReviewScannedItemsView: View {
    @Binding var parsedItems: [ParsedItem]
    let onSave: () -> Void
    let onCancel: () -> Void
    
    @State private var searchText = ""
    
    private var filteredItems: [Binding<ParsedItem>] {
        if searchText.isEmpty {
            return $parsedItems.map { $0 }
        } else {
            return $parsedItems.filter { item in
                item.wrappedValue.name.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    private var selectedCount: Int {
        parsedItems.filter { $0.isSelected }.count
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(.green)
                    
                    Text("Found \(parsedItems.count) Items")
                        .font(.system(size: 26, weight: .bold))
                    
                    Text("\(selectedCount) selected • Review and edit before adding")
                        .font(.system(size: 15))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)
                .padding(.bottom, 16)
                .padding(.horizontal)
                
                // Select/Deselect All
                HStack {
                    Button(action: selectAll) {
                        Label("Select All", systemImage: "checkmark.circle")
                            .font(.system(size: 14, weight: .medium))
                    }
                    
                    Spacer()
                    
                    Button(action: deselectAll) {
                        Label("Deselect All", systemImage: "circle")
                            .font(.system(size: 14, weight: .medium))
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color(.systemGroupedBackground))
                
                // Items list
                List {
                    ForEach(filteredItems, id: \.id) { $item in
                        ItemRowEditor(item: $item)
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    }
                    .onDelete(perform: deleteItems)
                }
                .listStyle(.plain)
                .searchable(text: $searchText, prompt: "Search items")
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: onCancel) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Back")
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add \(selectedCount)") {
                        onSave()
                    }
                    .fontWeight(.semibold)
                    .disabled(selectedCount == 0)
                }
            }
        }
    }
    
    private func selectAll() {
        for index in parsedItems.indices {
            parsedItems[index].isSelected = true
        }
    }
    
    private func deselectAll() {
        for index in parsedItems.indices {
            parsedItems[index].isSelected = false
        }
    }
    
    private func deleteItems(at offsets: IndexSet) {
        parsedItems.remove(atOffsets: offsets)
    }
}

// MARK: - Item Row Editor
struct ItemRowEditor: View {
    @Binding var item: ParsedItem
    @State private var isEditing = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Checkbox
            Button(action: {
                withAnimation(.spring(response: 0.3)) {
                    item.isSelected.toggle()
                }
            }) {
                Image(systemName: item.isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 28))
                    .foregroundStyle(item.isSelected ? .blue : .gray.opacity(0.5))
            }
            .buttonStyle(.plain)
            
            // Emoji
            Text(ItemEmojiHelper.emoji(for: item.name))
                .font(.system(size: 36))
                .frame(width: 44, height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.blue.opacity(0.1))
                )
            
            // Item info
            VStack(alignment: .leading, spacing: 6) {
                if isEditing {
                    TextField("Item name", text: $item.name)
                        .font(.system(size: 17, weight: .semibold))
                        .textFieldStyle(.roundedBorder)
                } else {
                    Text(item.name)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(item.isSelected ? .primary : .secondary)
                }
                
                HStack(spacing: 16) {
                    Stepper("Qty: \(item.quantity)", value: $item.quantity, in: 1...99)
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                    
                    Button(action: { isEditing.toggle() }) {
                        Image(systemName: isEditing ? "checkmark" : "pencil")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.blue)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.vertical, 8)
        .opacity(item.isSelected ? 1.0 : 0.6)
    }
}
