//
//  CameraViewControllerPro.swift
//  MyFridge
//
//  Advanced camera controller with rectangle detection and filtered text recognition
//

import UIKit
import AVFoundation
import Vision

class CameraViewControllerPro: UIViewController {
    
    weak var delegate: CameraViewControllerDelegate?
    
    // Camera components
    private var captureSession: AVCaptureSession?
    private var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    private var photoOutput: AVCapturePhotoOutput?
    
    // Vision requests
    private var rectangleDetectionRequest: VNDetectRectanglesRequest!
    private var textRecognitionRequest: VNRecognizeTextRequest!
    
    // State
    private var isSessionRunning = false
    private var detectedRectangle: VNRectangleObservation?
    private var accumulatedText: Set<String> = []
    
    // Auto-capture state
    private var stableFrameCount = 0
    private let requiredStableFrames = 5 // ~0.3 seconds at 15fps - VERY FAST
    private var isCapturing = false
    private var framesSinceStart = 0
    private let maxWaitFrames = 60 // 4 seconds max - then capture anyway
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
        setupVision()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        videoPreviewLayer?.frame = view.bounds
    }
    
    // MARK: - Camera Setup
    
    private func setupCamera() {
        captureSession = AVCaptureSession()
        guard let captureSession = captureSession else { return }
        
        captureSession.sessionPreset = .photo
        
        // Setup camera input
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            print("❌ No camera available")
            return
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: camera)
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
            }
        } catch {
            print("❌ Error setting up camera input: \(error)")
            return
        }
        
        // Setup video output for real-time processing
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        }
        
        // Setup photo output for capturing
        photoOutput = AVCapturePhotoOutput()
        if let photoOutput = photoOutput, captureSession.canAddOutput(photoOutput) {
            captureSession.addOutput(photoOutput)
        }
        
        // Setup preview layer
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        videoPreviewLayer?.videoGravity = .resizeAspectFill
        videoPreviewLayer?.frame = view.bounds
        
        if let videoPreviewLayer = videoPreviewLayer {
            view.layer.addSublayer(videoPreviewLayer)
        }
    }
    
    // MARK: - Vision Setup
    
    private func setupVision() {
        // Rectangle detection request
        rectangleDetectionRequest = VNDetectRectanglesRequest { [weak self] request, error in
            guard let self = self else { return }
            
            if let error = error {
                print("❌ Rectangle detection error: \(error)")
                return
            }
            
            // Increment total frames counter
            self.framesSinceStart += 1
            
            // FALLBACK: If no rectangle detected after 4 seconds, capture anyway
            if self.framesSinceStart >= self.maxWaitFrames && !self.isCapturing {
                print("⏰ Timeout - capturing without rectangle detection")
                self.isCapturing = true
                DispatchQueue.main.async {
                    self.delegate?.didReachStableState()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        self.capturePhoto()
                    }
                }
                return
            }
            
            guard let observations = request.results as? [VNRectangleObservation],
                  let topRectangle = observations.first else {
                // No rectangle detected - reset stability counter
                self.stableFrameCount = 0
                DispatchQueue.main.async {
                    self.detectedRectangle = nil
                    self.delegate?.didDetectRectangle(nil)
                    self.delegate?.didUpdateStability(progress: 0)
                }
                return
            }
            
            // Filter for receipt-like rectangles (VERY lenient now)
            if self.isReceiptLikeRectangle(topRectangle) {
                self.detectedRectangle = topRectangle
                
                // Increment stability counter
                if !self.isCapturing {
                    self.stableFrameCount += 1
                    
                    let progress = Double(self.stableFrameCount) / Double(self.requiredStableFrames)
                    
                    DispatchQueue.main.async {
                        self.delegate?.didDetectRectangle(topRectangle)
                        self.delegate?.didUpdateStability(progress: min(progress, 1.0))
                    }
                    
                    // Auto-capture when stable enough (now only ~0.3 seconds!)
                    if self.stableFrameCount >= self.requiredStableFrames {
                        self.isCapturing = true
                        self.stableFrameCount = 0
                        
                        DispatchQueue.main.async {
                            self.delegate?.didReachStableState()
                            // Small delay for smooth UX
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                self.capturePhoto()
                            }
                        }
                    }
                }
            } else {
                // Rectangle not receipt-like - reset
                self.stableFrameCount = 0
                DispatchQueue.main.async {
                    self.detectedRectangle = nil
                    self.delegate?.didDetectRectangle(nil)
                    self.delegate?.didUpdateStability(progress: 0)
                }
            }
        }
        
        rectangleDetectionRequest.minimumAspectRatio = 0.2  // More lenient (was 0.3)
        rectangleDetectionRequest.maximumAspectRatio = 1.0  // More lenient (was 0.9)
        rectangleDetectionRequest.minimumSize = 0.2  // Smaller receipts OK (was 0.3)
        rectangleDetectionRequest.maximumObservations = 1
        
        // Text recognition request - NOW WITH RECTANGLE FILTERING
        textRecognitionRequest = VNRecognizeTextRequest { [weak self] request, error in
            guard let self = self else { return }
            
            if let error = error {
                print("❌ Text recognition error: \(error)")
                return
            }
            
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                return
            }
            
            // CRITICAL: Only accumulate text if we have a detected rectangle
            guard let detectedRect = self.detectedRectangle else {
                // No receipt detected - don't scan anything
                return
            }
            
            // Filter text to only include what's inside the detected rectangle
            for observation in observations {
                // Check if this text is inside the detected receipt rectangle
                if self.isTextInsideRectangle(observation.boundingBox, rectangle: detectedRect) {
                    guard let topCandidate = observation.topCandidates(1).first else { continue }
                    
                    // Only include high-confidence text (increased from 0.7 to 0.8)
                    if topCandidate.confidence >= 0.8 {
                        self.accumulatedText.insert(topCandidate.string)
                    }
                }
            }
            
            let combinedText = self.accumulatedText.sorted().joined(separator: "\n")
            DispatchQueue.main.async {
                self.delegate?.didDetectText(combinedText)
            }
        }
        
        textRecognitionRequest.recognitionLevel = .accurate
        textRecognitionRequest.usesLanguageCorrection = true
        textRecognitionRequest.recognitionLanguages = ["fr-FR", "en-US"]
        textRecognitionRequest.minimumTextHeight = 0.03 // Increased to ignore small noise
    }
    
    // MARK: - Rectangle Validation
    
    private func isReceiptLikeRectangle(_ rectangle: VNRectangleObservation) -> Bool {
        let topWidth = distance(from: rectangle.topLeft, to: rectangle.topRight)
        let bottomWidth = distance(from: rectangle.bottomLeft, to: rectangle.bottomRight)
        let leftHeight = distance(from: rectangle.topLeft, to: rectangle.bottomLeft)
        let rightHeight = distance(from: rectangle.topRight, to: rectangle.bottomRight)
        
        let avgWidth = (topWidth + bottomWidth) / 2.0
        let avgHeight = (leftHeight + rightHeight) / 2.0
        
        let aspectRatio = avgHeight / avgWidth
        
        // VERY lenient - accept almost any rectangle that's not too small
        // Aspect ratio from 0.5 (wide) to 5.0 (very tall)
        return aspectRatio >= 0.5 && aspectRatio <= 5.0 && avgHeight > 0.15
    }
    
    private func distance(from p1: CGPoint, to p2: CGPoint) -> CGFloat {
        let dx = p2.x - p1.x
        let dy = p2.y - p1.y
        return sqrt(dx * dx + dy * dy)
    }
    
    // MARK: - Text Inside Rectangle Check
    
    /// Check if text bounding box is inside receipt rectangle
    private func isTextInsideRectangle(_ textBox: CGRect, rectangle: VNRectangleObservation) -> Bool {
        
        // Get receipt bounds from corner points
        let minX = min(rectangle.topLeft.x, rectangle.bottomLeft.x)
        let maxX = max(rectangle.topRight.x, rectangle.bottomRight.x)
        let minY = min(rectangle.bottomLeft.y, rectangle.bottomRight.y)
        let maxY = max(rectangle.topLeft.y, rectangle.topRight.y)
        
        // Create rectangle with slight padding (2% on each side)
        let padding: CGFloat = 0.02
        let receiptRect = CGRect(
            x: max(0, minX - padding),
            y: max(0, minY - padding),
            width: min(1, maxX + padding) - max(0, minX - padding),
            height: min(1, maxY + padding) - max(0, minY - padding)
        )
        
        // Check if text center is inside receipt
        // Using center point is more lenient than requiring full containment
        let textCenter = CGPoint(x: textBox.midX, y: textBox.midY)
        
        return receiptRect.contains(textCenter)
    }
    
    // MARK: - Camera Control
    
    func startScanning() {
        guard let captureSession = captureSession, !isSessionRunning else { return }
        
        // Reset counters
        framesSinceStart = 0
        stableFrameCount = 0
        isCapturing = false
        
        // CRITICAL: Must run on main thread to avoid -17281 error
        DispatchQueue.main.async { [weak self] in
            captureSession.startRunning()
            self?.isSessionRunning = true
        }
    }
    
    func stopScanning() {
        guard let captureSession = captureSession, isSessionRunning else { return }
        
        DispatchQueue.main.async { [weak self] in
            captureSession.stopRunning()
            self?.isSessionRunning = false
        }
    }
    
    func capturePhoto() {
        guard let photoOutput = photoOutput else { return }
        
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    // Clear accumulated text (useful when starting a new scan)
    func clearAccumulatedText() {
        accumulatedText.removeAll()
    }
}

// MARK: - Video Output Delegate

extension CameraViewControllerPro: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
        
        do {
            // Always run rectangle detection
            try imageRequestHandler.perform([rectangleDetectionRequest])
            
            // Only run text recognition occasionally (every ~10 frames) to save performance
            // AND only if we have a detected rectangle
            if detectedRectangle != nil && Int.random(in: 0...10) == 0 {
                try imageRequestHandler.perform([textRecognitionRequest])
            }
        } catch {
            print("❌ Vision request failed: \(error)")
        }
    }
}

// MARK: - Photo Capture Delegate

extension CameraViewControllerPro: AVCapturePhotoCaptureDelegate {
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        
        if let error = error {
            print("❌ Photo capture error: \(error)")
            isCapturing = false
            return
        }
        
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            print("❌ Could not create image from photo data")
            isCapturing = false
            return
        }
        
        DispatchQueue.main.async {
            self.delegate?.didCaptureImage(image)
            // Reset for next scan
            self.isCapturing = false
            self.stableFrameCount = 0
            self.framesSinceStart = 0
        }
    }
}
