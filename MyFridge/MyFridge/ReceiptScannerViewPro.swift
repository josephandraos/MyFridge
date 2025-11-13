
//
//  ReceiptScannerViewPro.swift
//  MyFridge
//
//  Professional receipt scanner with Scandit-like UI and enhanced OCR
//

import SwiftUI
import VisionKit
import SwiftData
import Vision
import UIKit

@available(iOS 16.0, *)
struct ReceiptScannerViewPro: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var notificationManager: NotificationManager
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    
    @State private var scannedText = ""
    @State private var isScanning = false
    @State private var showPreview = false
    @State private var parsedItems: [ParsedItem] = []
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showLimitReached = false
    @State private var showPaywall = false
    @State private var capturedImage: UIImage?
    @State private var isProcessing = false
    @State private var detectedRectangle: VNRectangleObservation?
    @State private var scanProgress: Double = 0.0
    
    var body: some View {
        ZStack {
            if !showPreview {
                // Camera Scanner View
                CameraViewPro(
                    scannedText: $scannedText,
                    isScanning: $isScanning,
                    capturedImage: $capturedImage,
                    detectedRectangle: $detectedRectangle
                )
                .ignoresSafeArea()
                
                // Professional overlay UI
                professionalScannerOverlay
            } else {
                // Preview parsed items
                ReviewScannedItemsView(
                    parsedItems: $parsedItems,
                    onSave: saveItems,
                    onCancel: {
                        showPreview = false
                        scannedText = ""
                        capturedImage = nil
                        isProcessing = false
                    }
                )
            }
            
            // Processing overlay
            if isProcessing {
                processingOverlay
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
                capturedImage = nil
                isScanning = true
                isProcessing = false
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
    
    // MARK: - Professional Scanner Overlay (Scandit-style)
    
    private var professionalScannerOverlay: some View {
        ZStack {
            // Dimmed overlay with cutout
            Color.black.opacity(0.5)
                .ignoresSafeArea()
            
            // Scanner frame with corner guides (like Scandit)
            VStack {
                Spacer()
                
                // Receipt scanning area
                ZStack {
                    // White frame
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(
                            detectedRectangle != nil ? Color.green : Color.white,
                            lineWidth: 3
                        )
                        .frame(width: 300, height: 450)
                        .blendMode(.destinationOut)
                    
                    // Corner brackets (Scandit style)
                    CornerBracketsView(
                        isDetected: detectedRectangle != nil,
                        size: CGSize(width: 300, height: 450)
                    )
                }
                .compositingGroup()
                
                Spacer()
            }
            
            // Top UI
            VStack {
                topBar
                
                Spacer()
                
                // Instructions & bottom UI
                VStack(spacing: 24) {
                    if detectedRectangle != nil {
                        // Receipt detected indicator
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 24))
                                .foregroundStyle(.green)
                            
                            Text("Receipt Detected")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(.ultraThinMaterial)
                        )
                        .transition(.scale.combined(with: .opacity))
                    } else {
                        // Scanning instructions
                        VStack(spacing: 8) {
                            Text("Position receipt in frame")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(.white)
                            
                            Text("Hold steady for best results")
                                .font(.system(size: 14))
                                .foregroundStyle(.white.opacity(0.8))
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(.ultraThinMaterial)
                        )
                    }
                    
                    // Capture button (only show when text detected or manual mode)
                    if !scannedText.isEmpty || detectedRectangle != nil {
                        Button(action: captureAndProcess) {
                            HStack(spacing: 12) {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 20))
                                Text("Capture & Process")
                                    .font(.system(size: 17, weight: .semibold))
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 16)
                            .background(
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [.blue, .blue.opacity(0.8)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            )
                            .shadow(color: .blue.opacity(0.5), radius: 12, y: 6)
                        }
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .padding(.bottom, 60)
            }
        }
    }
    
    // MARK: - Top Bar
    
    private var topBar: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.5), radius: 4)
            }
            
            Spacer()
            
            VStack(spacing: 4) {
                Text("Scan Receipt")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.5), radius: 4)
                
                if !subscriptionManager.isPremium {
                    Text("\(subscriptionManager.remainingScans()) scans left")
                        .font(.system(size: 13))
                        .foregroundStyle(.yellow)
                        .shadow(color: .black.opacity(0.5), radius: 4)
                }
            }
            
            Spacer()
            
            // Flash toggle
            Button(action: {
                // Toggle flash (implement in camera controller)
            }) {
                Image(systemName: "bolt.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.5), radius: 4)
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [.black.opacity(0.6), .clear],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    // MARK: - Processing Overlay
    
    private var processingOverlay: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Animated processing indicator
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)
                
                VStack(spacing: 12) {
                    Text("Processing Receipt...")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(.white)
                    
                    Text("Extracting grocery items")
                        .font(.system(size: 15))
                        .foregroundStyle(.white.opacity(0.8))
                }
                
                // Progress bar
                ProgressView(value: scanProgress, total: 1.0)
                    .tint(.blue)
                    .frame(width: 200)
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(.ultraThinMaterial)
            )
        }
    }
    
    // MARK: - Processing Functions
    
    private func checkScanLimit() {
        if !subscriptionManager.canUserScan() {
            showLimitReached = true
        } else {
            isScanning = true
        }
    }
    
    private func captureAndProcess() {
        isScanning = false
        isProcessing = true
        scanProgress = 0.0
        
        Task {
            // Simulate processing stages
            await MainActor.run { scanProgress = 0.2 }
            
            // Step 1: If we have a captured image, preprocess it
            if let image = capturedImage {
                await MainActor.run { scanProgress = 0.4 }
                
                // Preprocess image (crop, enhance, de-skew)
                let processedImage = await ImagePreprocessor.preprocessReceipt(image, rectangle: detectedRectangle)
                
                await MainActor.run { scanProgress = 0.6 }
                
                // Run enhanced OCR on processed image
                let extractedText = await ReceiptOCREngine.extractText(from: processedImage)
                scannedText = extractedText
            }
            
            await MainActor.run { scanProgress = 0.8 }
            
            // Step 2: Parse the text
            guard !scannedText.isEmpty else {
                await MainActor.run {
                    isProcessing = false
                    errorMessage = "Could not extract text from receipt. Please try again with better lighting."
                    showError = true
                }
                return
            }
            
            parsedItems = ReceiptParserPro.parseReceipt(scannedText)
            
            await MainActor.run { scanProgress = 1.0 }
            
            // Step 3: Show results
            if parsedItems.isEmpty {
                await MainActor.run {
                    isProcessing = false
                    errorMessage = "No grocery items found. Please ensure the receipt is clearly visible."
                    showError = true
                }
            } else {
                // Add small delay for smooth transition
                try? await Task.sleep(nanoseconds: 300_000_000)
                
                await MainActor.run {
                    isProcessing = false
                    showPreview = true
                }
            }
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
            
            if notificationManager.notificationPermissionGranted {
                Task {
                    newItem.notificationScheduled = true
                    await notificationManager.scheduleNotification(for: newItem)
                }
            }
        }
        
        subscriptionManager.incrementScanCount()
        
        print("✅ Saved \(selectedItems.count) items from receipt scan")
        dismiss()
    }
}

// MARK: - Corner Brackets View (Scandit-style)

struct CornerBracketsView: View {
    let isDetected: Bool
    let size: CGSize
    let bracketLength: CGFloat = 30
    let bracketWidth: CGFloat = 4
    
    var body: some View {
        ZStack {
            // Top-left
            Path { path in
                path.move(to: CGPoint(x: 0, y: bracketLength))
                path.addLine(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: bracketLength, y: 0))
            }
            .stroke(isDetected ? Color.green : Color.white, lineWidth: bracketWidth)
            .position(x: -size.width/2 + bracketLength/2, y: -size.height/2 + bracketLength/2)
            
            // Top-right
            Path { path in
                path.move(to: CGPoint(x: -bracketLength, y: 0))
                path.addLine(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: 0, y: bracketLength))
            }
            .stroke(isDetected ? Color.green : Color.white, lineWidth: bracketWidth)
            .position(x: size.width/2 - bracketLength/2, y: -size.height/2 + bracketLength/2)
            
            // Bottom-left
            Path { path in
                path.move(to: CGPoint(x: 0, y: -bracketLength))
                path.addLine(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: bracketLength, y: 0))
            }
            .stroke(isDetected ? Color.green : Color.white, lineWidth: bracketWidth)
            .position(x: -size.width/2 + bracketLength/2, y: size.height/2 - bracketLength/2)
            
            // Bottom-right
            Path { path in
                path.move(to: CGPoint(x: -bracketLength, y: 0))
                path.addLine(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: 0, y: -bracketLength))
            }
            .stroke(isDetected ? Color.green : Color.white, lineWidth: bracketWidth)
            .position(x: size.width/2 - bracketLength/2, y: size.height/2 - bracketLength/2)
        }
        .frame(width: size.width, height: size.height)
    }
}

// MARK: - Professional Camera View

struct CameraViewPro: UIViewControllerRepresentable {
    @Binding var scannedText: String
    @Binding var isScanning: Bool
    @Binding var capturedImage: UIImage?
    @Binding var detectedRectangle: VNRectangleObservation?
    
    func makeUIViewController(context: Context) -> CameraViewControllerPro {
        let controller = CameraViewControllerPro()
        controller.delegate = context.coordinator
        return controller
    }
    
    func updateUIViewController(_ uiViewController: CameraViewControllerPro, context: Context) {
        if isScanning {
            uiViewController.startScanning()
        } else {
            uiViewController.stopScanning()
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(scannedText: $scannedText, capturedImage: $capturedImage, detectedRectangle: $detectedRectangle)
    }
    
    class Coordinator: NSObject, CameraViewControllerDelegate {
        @Binding var scannedText: String
        @Binding var capturedImage: UIImage?
        @Binding var detectedRectangle: VNRectangleObservation?
        
        init(scannedText: Binding<String>, capturedImage: Binding<UIImage?>, detectedRectangle: Binding<VNRectangleObservation?>) {
            self._scannedText = scannedText
            self._capturedImage = capturedImage
            self._detectedRectangle = detectedRectangle
        }
        
        func didCaptureImage(_ image: UIImage) {
            capturedImage = image
        }
        
        func didDetectText(_ text: String) {
            scannedText = text
        }
        
        func didDetectRectangle(_ rectangle: VNRectangleObservation?) {
            detectedRectangle = rectangle
        }
    }
}

// MARK: - Camera View Controller Protocol

protocol CameraViewControllerDelegate: AnyObject {
    func didCaptureImage(_ image: UIImage)
    func didDetectText(_ text: String)
    func didDetectRectangle(_ rectangle: VNRectangleObservation?)
}

// MARK: - Preview
#Preview {
    if #available(iOS 16.0, *) {
        ReceiptScannerViewPro()
            .modelContainer(for: Item.self, inMemory: true)
            .environmentObject(NotificationManager.shared)
            .environmentObject(SubscriptionManager())
    }
}
