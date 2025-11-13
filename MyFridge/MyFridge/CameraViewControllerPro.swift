//
//  CameraViewControllerPro.swift
//  MyFridge
//
//  Advanced camera controller with rectangle detection and image capture
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
            
            guard let observations = request.results as? [VNRectangleObservation],
                  let topRectangle = observations.first else {
                DispatchQueue.main.async {
                    self.delegate?.didDetectRectangle(nil)
                }
                return
            }
            
            // Filter for receipt-like rectangles (vertical, not too small)
            if self.isReceiptLikeRectangle(topRectangle) {
                self.detectedRectangle = topRectangle
                DispatchQueue.main.async {
                    self.delegate?.didDetectRectangle(topRectangle)
                }
            } else {
                DispatchQueue.main.async {
                    self.delegate?.didDetectRectangle(nil)
                }
            }
        }
        
        rectangleDetectionRequest.minimumAspectRatio = 0.3
        rectangleDetectionRequest.maximumAspectRatio = 0.9
        rectangleDetectionRequest.minimumSize = 0.3
        rectangleDetectionRequest.maximumObservations = 1
        
        // Text recognition request
        textRecognitionRequest = VNRecognizeTextRequest { [weak self] request, error in
            guard let self = self else { return }
            
            if let error = error {
                print("❌ Text recognition error: \(error)")
                return
            }
            
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                return
            }
            
            for observation in observations {
                guard let topCandidate = observation.topCandidates(1).first else { continue }
                self.accumulatedText.insert(topCandidate.string)
            }
            
            let combinedText = self.accumulatedText.sorted().joined(separator: "\n")
            DispatchQueue.main.async {
                self.delegate?.didDetectText(combinedText)
            }
        }
        
        textRecognitionRequest.recognitionLevel = .accurate
        textRecognitionRequest.usesLanguageCorrection = true
        textRecognitionRequest.recognitionLanguages = ["en-US", "fr-CA"]
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
        
        return aspectRatio >= 1.2 && aspectRatio <= 4.0
    }
    
    private func distance(from p1: CGPoint, to p2: CGPoint) -> CGFloat {
        let dx = p2.x - p1.x
        let dy = p2.y - p1.y
        return sqrt(dx * dx + dy * dy)
    }
    
    // MARK: - Camera Control
    
    func startScanning() {
        guard let captureSession = captureSession, !isSessionRunning else { return }
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            captureSession.startRunning()
            self?.isSessionRunning = true
        }
    }
    
    func stopScanning() {
        guard let captureSession = captureSession, isSessionRunning else { return }
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            captureSession.stopRunning()
            self?.isSessionRunning = false
        }
    }
    
    func capturePhoto() {
        guard let photoOutput = photoOutput else { return }
        
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
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
            try imageRequestHandler.perform([rectangleDetectionRequest])
            
            if Int.random(in: 0...10) == 0 {
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
            return
        }
        
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            print("❌ Could not create image from photo data")
            return
        }
        
        DispatchQueue.main.async {
            self.delegate?.didCaptureImage(image)
        }
    }
}
