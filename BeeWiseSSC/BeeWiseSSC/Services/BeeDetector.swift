//
//  BeeDetector.swift
//  BeeWiseSSC
//
//  Created by Steinhauer, Jan on 15.02.26.
//

import UIKit
import Vision
import CoreML

class BeeDetector {
    
    enum DetectionError: Error {
        case invalidImage
        case detectionFailed
        case modelLoadFailed
    }
    
    private static var cachedVNModel: VNCoreMLModel?
    private static let modelLock = NSLock()

    private static func getVNModel() throws -> VNCoreMLModel {
        modelLock.lock()
        defer { modelLock.unlock() }

        if let model = cachedVNModel {
            return model
        }

        var sourceURL: URL?
        for bundle in [Bundle.main] + Bundle.allBundles {
            if let url = bundle.url(forResource: "BeeDetectionModel", withExtension: "mlmodel_src") {
                sourceURL = url
                break
            }
        }

        guard let src = sourceURL else {
            print("Failed to find BeeDetectionModel.mlmodel_src in bundles")
            throw DetectionError.modelLoadFailed
        }

        let tempDir = FileManager.default.temporaryDirectory
        let tempModelURL = tempDir.appendingPathComponent("BeeDetectionModel.mlmodel")
        
        if FileManager.default.fileExists(atPath: tempModelURL.path) {
            try? FileManager.default.removeItem(at: tempModelURL)
        }
        
        try FileManager.default.copyItem(at: src, to: tempModelURL)
        
        let compiledUrl = try MLModel.compileModel(at: tempModelURL)
        let mlModel = try MLModel(contentsOf: compiledUrl)
        let vnModel = try VNCoreMLModel(for: mlModel)
        
        cachedVNModel = vnModel
        return vnModel
    }
    
    static func containsBee(in cgImage: CGImage) async -> Bool {
        return await withCheckedContinuation { continuation in
            final class ResumeOnce: @unchecked Sendable {
                var didResume = false
            }
            let once = ResumeOnce()
            
            let request = VNClassifyImageRequest { request, error in
                guard !once.didResume else { return }
                
                guard error == nil,
                      let results = request.results as? [VNClassificationObservation] else {
                    once.didResume = true
                    continuation.resume(returning: true)
                    return
                }
                
                let validIdentifiers = ["insect", "bee", "invertebrate", "arthropod", "animal", "honeycomb", "hive"]
                
                let hasBee = results.contains { observation in
                    guard observation.confidence > 0.05 else { return false }
                    let id = observation.identifier.lowercased()
                    return validIdentifiers.contains { id.contains($0) }
                }
                
                once.didResume = true
                continuation.resume(returning: hasBee)
            }
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                guard !once.didResume else { return }
                once.didResume = true
                continuation.resume(returning: true)
            }
        }
    }
    
    static func detectBeesSalience(in image: UIImage) async throws -> [(CGRect, Float)] {
        guard let cgImage = image.cgImage else {
            throw DetectionError.invalidImage
        }
        
        let isBeeImage = await containsBee(in: cgImage)
        guard isBeeImage else {
            return []
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            final class ResumeOnce: @unchecked Sendable {
                var didResume = false
            }
            let once = ResumeOnce()

            let request = VNGenerateAttentionBasedSaliencyImageRequest { request, error in
                guard !once.didResume else { return }
                once.didResume = true

                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let observation = request.results?.first as? VNSaliencyImageObservation,
                      let salientObjects = observation.salientObjects, !salientObjects.isEmpty else {
                    continuation.resume(returning: [])
                    return
                }
                
                let results = salientObjects.map { ($0.boundingBox, observation.confidence) }
                continuation.resume(returning: results)
            }
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                guard !once.didResume else { return }
                once.didResume = true
                continuation.resume(throwing: error)
            }
        }
    }
    
    static func detectBeesML(in image: UIImage) async throws -> [(CGRect, Float)] {
        guard let cgImage = image.cgImage else {
            throw DetectionError.invalidImage
        }
        
        let vnModel = try getVNModel()
        
        return try await withCheckedThrowingContinuation { continuation in
            final class ResumeOnce: @unchecked Sendable {
                var didResume = false
            }
            let once = ResumeOnce()

            let mlRequest = VNCoreMLRequest(model: vnModel) { req, err in
                guard !once.didResume else { return }

                if let error = err {
                    once.didResume = true
                    continuation.resume(throwing: error)
                    return
                }
                
                var beeResults: [(CGRect, Float)] = []
                
                if let results = req.results as? [VNRecognizedObjectObservation] {
                    for observation in results {
                        if let topLabel = observation.labels.first, topLabel.identifier.lowercased().contains("bee") {
                            beeResults.append((observation.boundingBox, topLabel.confidence))
                        } else if let topLabel = observation.labels.first {
                            print("Detected unknown object: \(topLabel.identifier) at \(observation.boundingBox) with confidence: \(topLabel.confidence)")
                        }
                    }
                } else if req.results is [VNClassificationObservation] {
                    print("⚠️ Model behaves as an Image Classifier. Returning empty for bounding boxes.")
                } else {
                    print("⚠️ Unrecognized observation type: \(type(of: req.results?.first))")
                }
                
                print("Total bees detected in this image: \(beeResults.count)")
                
                once.didResume = true
                continuation.resume(returning: beeResults)
            }
            
            mlRequest.imageCropAndScaleOption = .scaleFill
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([mlRequest])
            } catch {
                guard !once.didResume else { return }
                once.didResume = true
                continuation.resume(throwing: error)
            }
        }
    }
    
    static func generateSaliencyHeatmap(for image: UIImage) async throws -> UIImage? {
         guard let cgImage = image.cgImage else { return nil }
         
         return try await withCheckedThrowingContinuation { continuation in
             final class ResumeOnce: @unchecked Sendable {
                 var didResume = false
             }
             let once = ResumeOnce()

             let request = VNGenerateAttentionBasedSaliencyImageRequest { request, error in
                 guard !once.didResume else { return }
                 once.didResume = true

                 if let _ = error {
                     continuation.resume(returning: nil)
                     return
                 }
                 
                 guard let observation = request.results?.first as? VNSaliencyImageObservation else {
                     continuation.resume(returning: nil)
                     return
                 }
                 
                 let pixelBuffer = observation.pixelBuffer
                 let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
                 
                 let context = CIContext()
                 if let cgImageResult = context.createCGImage(ciImage, from: ciImage.extent) {
                     continuation.resume(returning: UIImage(cgImage: cgImageResult))
                 } else {
                     continuation.resume(returning: nil)
                 }
             }
             
             let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
             do {
                 try handler.perform([request])
             } catch {
                 guard !once.didResume else { return }
                 once.didResume = true
                 continuation.resume(returning: nil)
             }
         }
    }
}

