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
    @State private var cameraController: CameraViewControllerPro?
    
    // Auto-capture state
    @State private var stabilityProgress: Double = 0.0
    @State private var showCountdown = false
    
    var body: some View {
        ZStack {
            if !showPreview {
                // Camera Scanner View
                CameraViewPro(
                    scannedText: $scannedText,
                    isScanning: $isScanning,
                    capturedImage: $capturedImage,
                    detectedRectangle: $detectedRectangle,
                    cameraController: $cameraController,
                    stabilityProgress: $stabilityProgress,
                    showCountdown: $showCountdown
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
                        isScanning = true
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
        .onChange(of: capturedImage) { oldValue, newValue in
            // Automatically start processing when image is captured
            if newValue != nil && !isProcessing {
                processReceipt()
            }
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
                        if showCountdown {
                            // Countdown indicator (super fast now - just show checkmark!)
                            VStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .stroke(Color.white.opacity(0.3), lineWidth: 8)
                                        .frame(width: 80, height: 80)
                                    
                                    Circle()
                                        .trim(from: 0, to: stabilityProgress)
                                        .stroke(Color.green, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                                        .frame(width: 80, height: 80)
                                        .rotationEffect(.degrees(-90))
                                    
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 36, weight: .bold))
                                        .foregroundStyle(.green)
                                }
                                
                                Text("Capturing...")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundStyle(.white)
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(.ultraThinMaterial)
                            )
                            .transition(.scale.combined(with: .opacity))
                        } else {
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
                        }
                    } else {
                        // Scanning instructions
                        VStack(spacing: 8) {
                            Text("Position receipt in frame")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(.white)
                            
                            Text("Captures in <1 second")
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
                }
                .padding(.bottom, 60)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: detectedRectangle != nil)
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
                // Toggle flash (implement in camera controller if needed)
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
    
    /// Process the captured receipt image
    private func processReceipt() {
        guard let image = capturedImage else {
            return
        }
        
        isProcessing = true
        scanProgress = 0.0
        
        Task {
            // Simulate processing stages
            await MainActor.run { scanProgress = 0.2 }
            
            // Step 1: Preprocess image (crop to rectangle, enhance, de-skew)
            let processedImage = await ImagePreprocessor.preprocessReceipt(image, rectangle: detectedRectangle)
            
            await MainActor.run { scanProgress = 0.5 }
            
            // Step 2: Run enhanced OCR on processed image
            let extractedText = await ReceiptOCREngine.extractText(from: processedImage, region: detectedRectangle)
            
            await MainActor.run {
                scannedText = extractedText
                scanProgress = 0.7
            }
            
            // Step 3: Parse the text
            guard !extractedText.isEmpty else {
                await MainActor.run {
                    isProcessing = false
                    errorMessage = "Could not extract text from receipt. Please try again with better lighting."
                    showError = true
                }
                return
            }
            
            let items = ReceiptParserPro.parseReceipt(extractedText)
            
            await MainActor.run {
                parsedItems = items
                scanProgress = 1.0
            }
            
            // Step 4: Show results
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
            // Use the category that ReceiptParserPro already assigned (has French support!)
            let category = parsedItem.estimatedCategory
            
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
    @Binding var cameraController: CameraViewControllerPro?
    @Binding var stabilityProgress: Double
    @Binding var showCountdown: Bool
    
    func makeUIViewController(context: Context) -> CameraViewControllerPro {
        let controller = CameraViewControllerPro()
        controller.delegate = context.coordinator
        
        // Store reference to controller
        DispatchQueue.main.async {
            cameraController = controller
        }
        
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
        Coordinator(
            scannedText: $scannedText,
            capturedImage: $capturedImage,
            detectedRectangle: $detectedRectangle,
            stabilityProgress: $stabilityProgress,
            showCountdown: $showCountdown
        )
    }
    
    class Coordinator: NSObject, CameraViewControllerDelegate {
        @Binding var scannedText: String
        @Binding var capturedImage: UIImage?
        @Binding var detectedRectangle: VNRectangleObservation?
        @Binding var stabilityProgress: Double
        @Binding var showCountdown: Bool
        
        init(scannedText: Binding<String>, capturedImage: Binding<UIImage?>, detectedRectangle: Binding<VNRectangleObservation?>, stabilityProgress: Binding<Double>, showCountdown: Binding<Bool>) {
            self._scannedText = scannedText
            self._capturedImage = capturedImage
            self._detectedRectangle = detectedRectangle
            self._stabilityProgress = stabilityProgress
            self._showCountdown = showCountdown
        }
        
        func didCaptureImage(_ image: UIImage) {
            DispatchQueue.main.async {
                self.capturedImage = image
                self.showCountdown = false
                self.stabilityProgress = 0
            }
        }
        
        func didDetectText(_ text: String) {
            DispatchQueue.main.async {
                self.scannedText = text
            }
        }
        
        func didDetectRectangle(_ rectangle: VNRectangleObservation?) {
            DispatchQueue.main.async {
                self.detectedRectangle = rectangle
                if rectangle == nil {
                    self.showCountdown = false
                    self.stabilityProgress = 0
                }
            }
        }
        
        func didUpdateStability(progress: Double) {
            DispatchQueue.main.async {
                self.stabilityProgress = progress
                self.showCountdown = progress > 0.1
            }
        }
        
        func didReachStableState() {
            DispatchQueue.main.async {
                self.showCountdown = false
            }
        }
    }
}

// MARK: - Camera View Controller Protocol

protocol CameraViewControllerDelegate: AnyObject {
    func didCaptureImage(_ image: UIImage)
    func didDetectText(_ text: String)
    func didDetectRectangle(_ rectangle: VNRectangleObservation?)
    func didUpdateStability(progress: Double)
    func didReachStableState()
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
