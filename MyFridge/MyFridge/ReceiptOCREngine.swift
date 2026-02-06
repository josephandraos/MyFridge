//
//  ReceiptOCREngine.swift
//  MyFridge
//
//  Enhanced OCR engine with region-based filtering and Vision support
//

import UIKit
import Vision

// MARK: - INSTALLATION INSTRUCTIONS FOR GOOGLE ML KIT
/*
 To use Google ML Kit (FREE, better OCR for receipts):
 
 1. Add to your Podfile:
    pod 'GoogleMLKit/TextRecognition', '~> 4.0.0'
 
 2. Run: pod install
 
 3. Import at top of file:
    import MLKitTextRecognition
    import MLKitVision
 
 4. Uncomment the Google ML Kit code below
 
 If you don't install ML Kit, the code will automatically fall back to Apple's Vision framework.
 */

struct ReceiptOCREngine {
    
    // MARK: - Main OCR Function
    
    /// Extract text from image using best available OCR engine
    static func extractText(from image: UIImage) async -> String {
        return await extractTextWithVision(image, filterRegion: nil)
    }
    
    /// Extract text only from a specific region of the image (inside detected rectangle)
    static func extractText(from image: UIImage, region: VNRectangleObservation?) async -> String {
        
        // If we have a detected rectangle, crop and preprocess first
        if let region = region {
            // Use ImagePreprocessor to crop and enhance the image
            let croppedImage = await ImagePreprocessor.preprocessReceipt(image, rectangle: region)
            // Now scan the cropped image (no need to filter again since it's already cropped)
            return await extractText(from: croppedImage)
        }
        
        // No region detected - scan entire image
        return await extractText(from: image)
    }
    
    // MARK: - Google ML Kit OCR (Best Quality)
    
    /* UNCOMMENT THIS AFTER INSTALLING GOOGLE ML KIT
    
    private static func extractTextWithMLKit(_ image: UIImage) async -> String? {
        
        return await withCheckedContinuation { continuation in
            
            let visionImage = VisionImage(image: image)
            visionImage.orientation = image.imageOrientation
            
            // Configure text recognizer for best accuracy
            let options = TextRecognizerOptions()
            let textRecognizer = TextRecognizer.textRecognizer(options: options)
            
            textRecognizer.process(visionImage) { result, error in
                
                if let error = error {
                    print("❌ ML Kit error: \(error)")
                    continuation.resume(returning: nil)
                    return
                }
                
                guard let result = result else {
                    continuation.resume(returning: nil)
                    return
                }
                
                // Extract text with confidence filtering
                var extractedText = ""
                
                for block in result.blocks {
                    // Only include high-confidence text
                    if block.confidence >= 0.75 {
                        extractedText += block.text + "\n"
                    }
                }
                
                continuation.resume(returning: extractedText.isEmpty ? nil : extractedText)
            }
        }
    }
    
    END OF ML KIT CODE */
    
    // MARK: - Apple Vision OCR (Good Quality, Built-in)
    
    /// Extract text using Apple's Vision framework with optimal settings and optional region filtering
    private static func extractTextWithVision(_ image: UIImage, filterRegion: VNRectangleObservation? = nil) async -> String {
        
        return await withCheckedContinuation { continuation in
            
            guard let cgImage = image.cgImage else {
                continuation.resume(returning: "")
                return
            }
            
            let request = VNRecognizeTextRequest { request, error in
                
                if let error = error {
                    print("❌ Vision OCR error: \(error)")
                    continuation.resume(returning: "")
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: "")
                    return
                }
                
                var extractedText = ""
                
                for observation in observations {
                    // Filter by region if provided (for non-cropped images)
                    if let region = filterRegion {
                        // Check if text is inside the receipt rectangle
                        if !isTextInsideRectangle(observation.boundingBox, rectangle: region) {
                            continue // Skip text outside receipt
                        }
                    }
                    
                    guard let topCandidate = observation.topCandidates(1).first else { continue }
                    
                    // Only include text with good confidence (increased from 0.6 to 0.75)
                    if topCandidate.confidence >= 0.75 {
                        extractedText += topCandidate.string + "\n"
                    }
                }
                
                continuation.resume(returning: extractedText)
            }
            
            // Configure for BEST accuracy
            request.recognitionLevel = .accurate // Slower but much better
            request.usesLanguageCorrection = true
            request.recognitionLanguages = ["en-US", "fr-CA"] // English + French
            request.minimumTextHeight = 0.03 // Increased from 0.01 - ignore tiny text (likely noise)
            request.revision = VNRecognizeTextRequestRevision3 // Use latest revision
            
            // Perform request
            let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            do {
                try requestHandler.perform([request])
            } catch {
                print("❌ Vision request failed: \(error)")
                continuation.resume(returning: "")
            }
        }
    }
    
    /// Check if text bounding box is inside receipt rectangle
    private static func isTextInsideRectangle(_ textBox: CGRect, rectangle: VNRectangleObservation) -> Bool {
        
        // Get receipt bounds from corner points
        let minX = min(rectangle.topLeft.x, rectangle.bottomLeft.x)
        let maxX = max(rectangle.topRight.x, rectangle.bottomRight.x)
        let minY = min(rectangle.bottomLeft.y, rectangle.bottomRight.y)
        let maxY = max(rectangle.topLeft.y, rectangle.topRight.y)
        
        // Add small padding to be more lenient (5% on each side)
        let padding: CGFloat = 0.05
        let receiptRect = CGRect(
            x: max(0, minX - padding),
            y: max(0, minY - padding),
            width: min(1, maxX + padding) - max(0, minX - padding),
            height: min(1, maxY + padding) - max(0, minY - padding)
        )
        
        // Check if text center is inside receipt (more lenient than requiring full containment)
        let textCenter = CGPoint(x: textBox.midX, y: textBox.midY)
        
        return receiptRect.contains(textCenter)
    }
    
    // MARK: - Two-Pass OCR (Optional optimization)
    
    /// First pass: fast scan to find text region. Second pass: accurate scan on cropped area.
    static func extractTextTwoPass(from image: UIImage) async -> String {
        
        // PASS 1: Fast scan to detect text bounding boxes
        let textRegion = await detectTextRegion(image)
        
        // If we found a region, crop and run accurate scan
        if let region = textRegion {
            if let croppedImage = cropImage(image, to: region) {
                // PASS 2: Accurate scan on cropped region
                return await extractText(from: croppedImage)
            }
        }
        
        // Fallback: scan entire image
        return await extractText(from: image)
    }
    
    /// Detect the main text region using fast mode
    private static func detectTextRegion(_ image: UIImage) async -> CGRect? {
        
        return await withCheckedContinuation { continuation in
            
            guard let cgImage = image.cgImage else {
                continuation.resume(returning: nil)
                return
            }
            
            let request = VNRecognizeTextRequest { request, error in
                
                guard error == nil,
                      let observations = request.results as? [VNRecognizedTextObservation],
                      !observations.isEmpty else {
                    continuation.resume(returning: nil)
                    return
                }
                
                // Find bounding box that contains most text
                var minX: CGFloat = 1.0
                var minY: CGFloat = 1.0
                var maxX: CGFloat = 0.0
                var maxY: CGFloat = 0.0
                
                for observation in observations {
                    let box = observation.boundingBox
                    minX = min(minX, box.minX)
                    minY = min(minY, box.minY)
                    maxX = max(maxX, box.maxX)
                    maxY = max(maxY, box.maxY)
                }
                
                // Add small padding
                let padding: CGFloat = 0.05
                minX = max(0, minX - padding)
                minY = max(0, minY - padding)
                maxX = min(1, maxX + padding)
                maxY = min(1, maxY + padding)
                
                let region = CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
                continuation.resume(returning: region)
            }
            
            // Use FAST mode for first pass
            request.recognitionLevel = .fast
            
            let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            do {
                try requestHandler.perform([request])
            } catch {
                continuation.resume(returning: nil)
            }
        }
    }
    
    /// Crop image to normalized CGRect
    private static func cropImage(_ image: UIImage, to normalizedRect: CGRect) -> UIImage? {
        
        guard let cgImage = image.cgImage else { return nil }
        
        // Convert normalized rect to pixel coordinates
        let width = CGFloat(cgImage.width)
        let height = CGFloat(cgImage.height)
        
        let pixelRect = CGRect(
            x: normalizedRect.minX * width,
            y: (1 - normalizedRect.maxY) * height, // Flip Y coordinate
            width: normalizedRect.width * width,
            height: normalizedRect.height * height
        )
        
        guard let croppedCGImage = cgImage.cropping(to: pixelRect) else {
            return nil
        }
        
        return UIImage(cgImage: croppedCGImage)
    }
}
