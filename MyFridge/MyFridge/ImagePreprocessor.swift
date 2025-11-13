//
//  ImagePreprocessor.swift
//  MyFridge
//
//  Image preprocessing utilities for receipt enhancement (crop, de-skew, enhance)
//

import UIKit
import Vision
import CoreImage

struct ImagePreprocessor {
    
    // MARK: - Main Preprocessing Pipeline
    
    /// Preprocess receipt image: detect, crop, de-skew, enhance
    static func preprocessReceipt(_ image: UIImage, rectangle: VNRectangleObservation?) async -> UIImage {
        
        var processedImage = image
        
        // Step 1: If rectangle detected, crop and perspective correct
        if let rectangle = rectangle {
            if let croppedImage = await cropAndCorrect(image, rectangle: rectangle) {
                processedImage = croppedImage
            }
        }
        
        // Step 2: Enhance contrast and sharpen for better OCR
        if let enhancedImage = await enhanceForOCR(processedImage) {
            processedImage = enhancedImage
        }
        
        return processedImage
    }
    
    // MARK: - Crop & Perspective Correction
    
    /// Crop to detected rectangle and apply perspective correction
    private static func cropAndCorrect(_ image: UIImage, rectangle: VNRectangleObservation) async -> UIImage? {
        
        guard let ciImage = CIImage(image: image) else { return nil }
        
        let imageSize = ciImage.extent.size
        
        // Convert normalized coordinates to image coordinates
        let topLeft = CGPoint(
            x: rectangle.topLeft.x * imageSize.width,
            y: (1 - rectangle.topLeft.y) * imageSize.height
        )
        let topRight = CGPoint(
            x: rectangle.topRight.x * imageSize.width,
            y: (1 - rectangle.topRight.y) * imageSize.height
        )
        let bottomLeft = CGPoint(
            x: rectangle.bottomLeft.x * imageSize.width,
            y: (1 - rectangle.bottomLeft.y) * imageSize.height
        )
        let bottomRight = CGPoint(
            x: rectangle.bottomRight.x * imageSize.width,
            y: (1 - rectangle.bottomRight.y) * imageSize.height
        )
        
        // Apply perspective correction
        let perspectiveCorrection = CIFilter(name: "CIPerspectiveCorrection")!
        perspectiveCorrection.setValue(ciImage, forKey: kCIInputImageKey)
        perspectiveCorrection.setValue(CIVector(cgPoint: topLeft), forKey: "inputTopLeft")
        perspectiveCorrection.setValue(CIVector(cgPoint: topRight), forKey: "inputTopRight")
        perspectiveCorrection.setValue(CIVector(cgPoint: bottomLeft), forKey: "inputBottomLeft")
        perspectiveCorrection.setValue(CIVector(cgPoint: bottomRight), forKey: "inputBottomRight")
        
        guard let outputImage = perspectiveCorrection.outputImage else { return nil }
        
        let context = CIContext()
        guard let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            return nil
        }
        
        return UIImage(cgImage: cgImage)
    }
    
    // MARK: - Image Enhancement for OCR
    
    /// Enhance image for better OCR: grayscale, contrast, sharpen
    private static func enhanceForOCR(_ image: UIImage) async -> UIImage? {
        
        guard let ciImage = CIImage(image: image) else { return nil }
        
        var outputImage = ciImage
        
        // Step 1: Convert to grayscale
        if let grayscaleFilter = CIFilter(name: "CIPhotoEffectMono") {
            grayscaleFilter.setValue(outputImage, forKey: kCIInputImageKey)
            if let grayscaleOutput = grayscaleFilter.outputImage {
                outputImage = grayscaleOutput
            }
        }
        
        // Step 2: Increase contrast (helps with faded thermal receipts)
        if let contrastFilter = CIFilter(name: "CIColorControls") {
            contrastFilter.setValue(outputImage, forKey: kCIInputImageKey)
            contrastFilter.setValue(1.2, forKey: kCIInputContrastKey) // Boost contrast
            contrastFilter.setValue(0.0, forKey: kCIInputSaturationKey) // Remove color
            contrastFilter.setValue(0.1, forKey: kCIInputBrightnessKey) // Slight brightness boost
            
            if let contrastOutput = contrastFilter.outputImage {
                outputImage = contrastOutput
            }
        }
        
        // Step 3: Sharpen text
        if let sharpenFilter = CIFilter(name: "CISharpenLuminance") {
            sharpenFilter.setValue(outputImage, forKey: kCIInputImageKey)
            sharpenFilter.setValue(0.7, forKey: kCIInputSharpnessKey)
            
            if let sharpenOutput = sharpenFilter.outputImage {
                outputImage = sharpenOutput
            }
        }
        
        // Step 4: Apply unsharp mask for extra clarity
        if let unsharpFilter = CIFilter(name: "CIUnsharpMask") {
            unsharpFilter.setValue(outputImage, forKey: kCIInputImageKey)
            unsharpFilter.setValue(1.0, forKey: kCIInputRadiusKey)
            unsharpFilter.setValue(0.5, forKey: kCIInputIntensityKey)
            
            if let unsharpOutput = unsharpFilter.outputImage {
                outputImage = unsharpOutput
            }
        }
        
        // Convert back to UIImage
        let context = CIContext()
        guard let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            return nil
        }
        
        return UIImage(cgImage: cgImage)
    }
    
    // MARK: - Rotation Correction
    
    /// Detect and correct image rotation
    static func correctRotation(_ image: UIImage) async -> UIImage {
        
        // Create Vision request to detect text orientation
        let request = VNDetectTextRectanglesRequest()
        
        guard let cgImage = image.cgImage else { return image }
        
        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        do {
            try requestHandler.perform([request])
            
            // Analyze text orientation
            if let observations = request.results as? [VNTextObservation] {
                // Calculate average angle of text rectangles
                var totalAngle: CGFloat = 0
                var count = 0
                
                for observation in observations {
                    // Simple rotation detection based on bounding box
                    let rect = observation.boundingBox
                    if rect.width > rect.height {
                        // Likely rotated text
                        totalAngle += .pi / 2 // 90 degrees
                        count += 1
                    }
                }
                
                if count > observations.count / 2 {
                    // Majority of text is rotated, rotate image
                    return rotateImage(image, by: .pi / 2)
                }
            }
        } catch {
            print("❌ Rotation detection failed: \(error)")
        }
        
        return image
    }
    
    private static func rotateImage(_ image: UIImage, by angle: CGFloat) -> UIImage {
        guard let cgImage = image.cgImage else { return image }
        
        let ciImage = CIImage(cgImage: cgImage)
        
        let transform = CGAffineTransform(rotationAngle: angle)
        let rotatedImage = ciImage.transformed(by: transform)
        
        let context = CIContext()
        guard let outputCGImage = context.createCGImage(rotatedImage, from: rotatedImage.extent) else {
            return image
        }
        
        return UIImage(cgImage: outputCGImage)
    }
    
    // MARK: - Binarization (Black & White conversion for OCR)
    
    /// Convert image to pure black and white for maximum OCR accuracy
    static func binarize(_ image: UIImage, threshold: CGFloat = 0.5) async -> UIImage? {
        
        guard let ciImage = CIImage(image: image) else { return nil }
        
        // Apply color monochrome filter with threshold
        if let binarizeFilter = CIFilter(name: "CIColorMonochrome") {
            binarizeFilter.setValue(ciImage, forKey: kCIInputImageKey)
            binarizeFilter.setValue(CIColor(red: 1, green: 1, blue: 1), forKey: kCIInputColorKey)
            binarizeFilter.setValue(threshold, forKey: kCIInputIntensityKey)
            
            if let outputImage = binarizeFilter.outputImage {
                let context = CIContext()
                if let cgImage = context.createCGImage(outputImage, from: outputImage.extent) {
                    return UIImage(cgImage: cgImage)
                }
            }
        }
        
        return nil
    }
    
    // MARK: - Noise Reduction
    
    /// Remove noise from image (helpful for low-light photos)
    static func reduceNoise(_ image: UIImage) async -> UIImage? {
        
        guard let ciImage = CIImage(image: image) else { return nil }
        
        // Apply noise reduction filter
        if let noiseReductionFilter = CIFilter(name: "CINoiseReduction") {
            noiseReductionFilter.setValue(ciImage, forKey: kCIInputImageKey)
            noiseReductionFilter.setValue(0.02, forKey: "inputNoiseLevel")
            noiseReductionFilter.setValue(0.4, forKey: "inputSharpness")
            
            if let outputImage = noiseReductionFilter.outputImage {
                let context = CIContext()
                if let cgImage = context.createCGImage(outputImage, from: outputImage.extent) {
                    return UIImage(cgImage: cgImage)
                }
            }
        }
        
        return nil
    }
}
