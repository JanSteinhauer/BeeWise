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

        var compiledURL: URL?
        var sourceURL: URL?
        
        for bundle in [Bundle.main] + Bundle.allBundles {
            if let url = bundle.url(forResource: "VarroaMiteDetection", withExtension: "mlmodelc") {
                compiledURL = url
                break
            }
            if sourceURL == nil, let url = bundle.url(forResource: "VarroaMiteDetection", withExtension: "mlmodel") {
                sourceURL = url
            }
        }

        let finalCompiledURL: URL
        if let cURL = compiledURL {
            finalCompiledURL = cURL
        } else if let src = sourceURL {
            let tempDir = FileManager.default.temporaryDirectory
            let tempModelURL = tempDir.appendingPathComponent("VarroaMiteDetection.mlmodel")
            
            if FileManager.default.fileExists(atPath: tempModelURL.path) {
                try? FileManager.default.removeItem(at: tempModelURL)
            }
            
            try FileManager.default.copyItem(at: src, to: tempModelURL)
            finalCompiledURL = try MLModel.compileModel(at: tempModelURL)
        } else {
            print("Failed to find VarroaMiteDetection in bundles (neither .mlmodelc nor .mlmodel)")
            throw DetectionError.modelLoadFailed
        }
        
        let mlModel = try MLModel(contentsOf: finalCompiledURL)
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
    static func detectBeesAndMitesML(in image: UIImage) async throws -> (bees: [(CGRect, Float)], mites: [(CGRect, Float)]) {
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
                var miteResults: [(CGRect, Float)] = []
                
                if let results = req.results as? [VNRecognizedObjectObservation] {
                    for observation in results {
                        if let topLabel = observation.labels.first {
                            let labelID = topLabel.identifier.lowercased()
                            if labelID.contains("bee") {
                                beeResults.append((observation.boundingBox, topLabel.confidence))
                            } else if labelID.contains("varroa") || labelID.contains("mite") {
                                miteResults.append((observation.boundingBox, topLabel.confidence))
                            } else {
                                print("Detected other object: \(labelID) at \(observation.boundingBox) with confidence: \(topLabel.confidence)")
                            }
                        }
                    }
                } else if req.results is [VNClassificationObservation] {
                    print("⚠️ Model behaves as an Image Classifier. Returning empty for bounding boxes.")
                } else {
                    print("⚠️ Unrecognized observation type: \(type(of: req.results?.first))")
                }
                
                print("Total bees detected: \(beeResults.count), Total mites detected: \(miteResults.count)")
                
                once.didResume = true
                continuation.resume(returning: (beeResults, miteResults))
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
}

