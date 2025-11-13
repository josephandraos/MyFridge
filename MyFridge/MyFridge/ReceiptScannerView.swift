//
//  ReceiptScannerView.swift
//  MyFridge
//
//  Receipt scanner with scan limit checking for free tier
//

import SwiftUI
import VisionKit
import SwiftData

@available(iOS 16.0, *)
struct ReceiptScannerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var notificationManager: NotificationManager
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    
    @State private var scannedText = ""
    @State private var isScanning = true
    @State private var showPreview = false
    @State private var parsedItems: [ParsedItem] = []
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showLimitReached = false
    @State private var showPaywall = false
    
    var body: some View {
        ZStack {
            if !showPreview {
                // Camera Scanner View
                if DataScannerViewController.isSupported && DataScannerViewController.isAvailable {
                    DataScannerRepresentable(
                        scannedText: $scannedText,
                        isScanning: $isScanning
                    )
                    .ignoresSafeArea()
                    
                    // Minimal Overlay UI
                    scannerOverlay
                } else {
                    // Fallback for unsupported devices
                    unsupportedDeviceView
                }
            } else {
                // Preview parsed items
                ReviewScannedItemsView(
                    parsedItems: $parsedItems,
                    onSave: saveItems,
                    onCancel: {
                        showPreview = false
                        scannedText = ""
                    }
                )
            }
        }
        .alert("Scan Limit Reached", isPresented: $showLimitReached) {
            Button("Upgrade to Premium") {
                showPaywall = true
            }
            Button("Cancel", role: .cancel) {
                dismiss()
            }
        } message: {
            Text("You've used your free scan for this month. Upgrade to Premium for unlimited scans!")
        }
        .alert("Scanning Error", isPresented: $showError) {
            Button("Try Again") {
                scannedText = ""
                isScanning = true
            }
            Button("Cancel", role: .cancel) {
                dismiss()
            }
        } message: {
            Text(errorMessage)
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
        .onAppear {
            checkScanLimit()
        }
    }
    
    // MARK: - Check Scan Limit
    
    private func checkScanLimit() {
        if !subscriptionManager.canUserScan() {
            showLimitReached = true
        } else {
            isScanning = true
        }
    }
    
    // MARK: - Minimal Scanner Overlay
    
    private var scannerOverlay: some View {
        VStack {
            // Top bar
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.5), radius: 4)
                }
                
                Spacer()
                
                VStack(spacing: 2) {
                    Text("Scan Your Receipt")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.5), radius: 4)
                    
                    // Show scan count for free users
                    if !subscriptionManager.isPremium {
                        Text("Scans left: \(subscriptionManager.remainingScans())")
                            .font(.system(size: 13))
                            .foregroundStyle(.yellow)
                            .shadow(color: .black.opacity(0.5), radius: 4)
                    }
                }
                
                Spacer()
                
                // Placeholder for symmetry
                Color.clear.frame(width: 32, height: 32)
            }
            .padding()
            .background(
                LinearGradient(
                    colors: [.black.opacity(0.6), .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            
            Spacer()
            
            // Minimal status indicator at bottom
            VStack(spacing: 16) {
                // Status card
                HStack(spacing: 16) {
                    Image(systemName: isScanning ? "camera.fill" : "camera.slash.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(isScanning ? .green : .orange)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(isScanning ? "Scanning..." : "Paused")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.primary)
                        
                        Text(scannedText.isEmpty ? "Waiting for text" : "Text detected")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                )
                .padding(.horizontal)
                
                // Floating Done button (only shows when text detected)
                if !scannedText.isEmpty {
                    Button(action: processScannedText) {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 20))
                            Text("Done Scanning")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                colors: [.blue, .blue.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(Capsule())
                        .shadow(color: .blue.opacity(0.4), radius: 8, y: 4)
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.bottom, 40)
        }
    }
    
    // MARK: - Unsupported Device View
    
    private var unsupportedDeviceView: some View {
        VStack(spacing: 24) {
            Image(systemName: "camera.metering.unknown")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
            
            VStack(spacing: 8) {
                Text("Scanner Unavailable")
                    .font(.system(size: 24, weight: .bold))
                
                Text("The receipt scanner requires a device with iOS 16 or later and a compatible camera.")
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Button(action: { dismiss() }) {
                Text("Go Back")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.blue)
                    )
            }
            .padding(.horizontal, 32)
            .padding(.top, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - Processing Functions
    
    private func processScannedText() {
        guard !scannedText.isEmpty else { return }
        
        // Stop scanning while processing
        isScanning = false
        
        // Parse the receipt
        parsedItems = ReceiptParser.parseReceipt(scannedText)
        
        if parsedItems.isEmpty {
            errorMessage = "No grocery items found on receipt. Please try scanning again and ensure the text is clear."
            showError = true
        } else {
            showPreview = true
        }
    }
    
    private func saveItems() {
        let selectedItems = parsedItems.filter { $0.isSelected }
        
        guard !selectedItems.isEmpty else {
            dismiss()
            return
        }
        
        for parsedItem in selectedItems {
            let category = ReceiptParser.inferCategory(from: parsedItem.name)
            let expirationDate = ReceiptParser.estimateExpirationDate(
                for: parsedItem.name,
                category: category
            )
            
            let newItem = Item(
                name: parsedItem.name,
                quantity: parsedItem.quantity,
                expirationDate: expirationDate,
                category: category.rawValue,
                notes: "Added from receipt scan"
            )
            
            modelContext.insert(newItem)
            
            // Schedule notification if enabled
            if notificationManager.notificationPermissionGranted {
                Task {
                    newItem.notificationScheduled = true
                    await notificationManager.scheduleNotification(for: newItem)
                }
            }
        }
        
        // Increment scan count for free tier users
        subscriptionManager.incrementScanCount()
        
        print("✅ Saved \(selectedItems.count) items from receipt scan")
        dismiss()
    }
}

// MARK: - DataScanner UIKit Wrapper
@available(iOS 16.0, *)
struct DataScannerRepresentable: UIViewControllerRepresentable {
    @Binding var scannedText: String
    @Binding var isScanning: Bool
    
    func makeUIViewController(context: Context) -> DataScannerViewController {
        let scanner = DataScannerViewController(
            recognizedDataTypes: [.text()],
            qualityLevel: .balanced,
            recognizesMultipleItems: true,
            isHighFrameRateTrackingEnabled: true,
            isPinchToZoomEnabled: true,
            isGuidanceEnabled: true,
            isHighlightingEnabled: true
        )
        
        scanner.delegate = context.coordinator
        
        return scanner
    }
    
    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {
        if isScanning {
            try? uiViewController.startScanning()
        } else {
            uiViewController.stopScanning()
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(scannedText: $scannedText)
    }
    
    class Coordinator: NSObject, DataScannerViewControllerDelegate {
        @Binding var scannedText: String
        private var accumulatedText: Set<String> = []
        
        init(scannedText: Binding<String>) {
            self._scannedText = scannedText
        }
        
        func dataScanner(_ dataScanner: DataScannerViewController, didTapOn item: RecognizedItem) {
            switch item {
            case .text(let text):
                accumulatedText.insert(text.transcript)
                updateScannedText()
            default:
                break
            }
        }
        
        func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            for item in addedItems {
                if case .text(let text) = item {
                    accumulatedText.insert(text.transcript)
                }
            }
            updateScannedText()
        }
        
        func dataScanner(_ dataScanner: DataScannerViewController, didUpdate updatedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            for item in updatedItems {
                if case .text(let text) = item {
                    accumulatedText.insert(text.transcript)
                }
            }
            updateScannedText()
        }
        
        private func updateScannedText() {
            scannedText = accumulatedText.sorted().joined(separator: "\n")
        }
    }
    
    static func dismantleUIViewController(_ uiViewController: DataScannerViewController, coordinator: Coordinator) {
        uiViewController.stopScanning()
    }
}

// MARK: - Preview
#Preview {
    if #available(iOS 16.0, *) {
        ReceiptScannerView()
            .modelContainer(for: Item.self, inMemory: true)
            .environmentObject(NotificationManager.shared)
            .environmentObject(SubscriptionManager())
    } else {
        Text("Receipt Scanner requires iOS 16+")
    }
}

