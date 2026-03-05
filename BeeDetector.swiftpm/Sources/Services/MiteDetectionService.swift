//
//  MiteDetectionService.swift
//  BeeWise
//
//  Created by Steinhauer, Jan on 23.02.26.
//

import UIKit
import CoreGraphics

enum MiteDetectionService {
    static func checkForMites(in image: UIImage, roi: CGRect) async -> (Int, Float) {
        guard let cgImage = image.cgImage else { return (0, 0.0) }
        
        let width = CGFloat(cgImage.width)
        let height = CGFloat(cgImage.height)
        
        let correctedY = 1.0 - roi.maxY
        let pixelRect = CGRect(
            x: roi.minX * width,
            y: correctedY * height,
            width: roi.width * width,
            height: roi.height * height
        )
        
        guard let croppedCG = cgImage.cropping(to: pixelRect) else { return (0, 0.0) }
        
        let targetSize = CGSize(width: 40, height: 50)
        guard let resizedContext = ImageUtilities.resize(cgImage: croppedCG, to: targetSize) else { return (0, 0.0) }
        
        let widthInt = Int(targetSize.width)
        let heightInt = Int(targetSize.height)
        
        guard let pixelData = resizedContext.data else { return (0, 0.0) }
        let data = pixelData.bindMemory(to: UInt32.self, capacity: widthInt * heightInt)
        
        return await Task.detached {
            _ = resizedContext
            
            var binaryMask = [Bool](repeating: false, count: widthInt * heightInt)
            
            for y in 0..<heightInt {
                for x in 0..<widthInt {
                    let offset = y * widthInt + x
                    let pixel = data[offset]
                    
                    let b = CGFloat((pixel >> 0) & 0xFF) / 255.0
                    let g = CGFloat((pixel >> 8) & 0xFF) / 255.0
                    let r = CGFloat((pixel >> 16) & 0xFF) / 255.0
                    
                    let hsv = ImageUtilities.rgbToHsv(r: r, g: g, b: b)
                    
                    let isReddish = (hsv.h <= 25 || hsv.h >= 335)
                    let isSaturated = hsv.s > 0.45
                    let isDarkEnough = hsv.v < 0.85 && hsv.v > 0.2
                    
                    if isReddish && isSaturated && isDarkEnough {
                        binaryMask[offset] = true
                    }
                }
            }
            
            let (circleCount, confidence) = houghCircleTransform(mask: binaryMask, width: widthInt, height: heightInt)
            
            return (circleCount, confidence)
        }.value
    }
    
    static func houghCircleTransform(mask: [Bool], width: Int, height: Int) -> (Int, Float) {
        let minR = 2
        let maxR = 6
        
        var accumulator = [Int: Int]()
        
        for y in 1..<height-1 {
            for x in 1..<width-1 {
                let offset = y * width + x
                if mask[offset] {
                    let neighbors = [mask[offset-1], mask[offset+1], mask[offset-width], mask[offset+width]]
                    if neighbors.contains(false) {
                        for r in minR...maxR {
                            for t in stride(from: 0, to: 360, by: 10) {
                                let rad = CGFloat(t) * .pi / 180.0
                                let a = Int(CGFloat(x) - CGFloat(r) * cos(rad))
                                let b = Int(CGFloat(y) - CGFloat(r) * sin(rad))
                                
                                if a >= 0 && a < width && b >= 0 && b < height {
                                    let key = (a & 0xFFF) << 20 | (b & 0xFFF) << 8 | (r & 0xFF)
                                    accumulator[key, default: 0] += 1
                                }
                            }
                        }
                    }
                }
            }
        }
        
        let voteThreshold = 12
        var maxVotes = 0
        
        struct CircleCandidate {
            let x: Int
            let y: Int
            let r: Int
            let votes: Int
        }
        
        var candidates = [CircleCandidate]()
        
        for (key, votes) in accumulator {
            if votes > maxVotes {
                maxVotes = votes
            }
            if votes > voteThreshold {
                let r = key & 0xFF
                let y = (key >> 8) & 0xFFF
                let x = (key >> 20) & 0xFFF
                candidates.append(CircleCandidate(x: x, y: y, r: r, votes: votes))
            }
        }
        
        candidates.sort { $0.votes > $1.votes }
        
        var selectedCircles = [CircleCandidate]()
        let minDistanceSquared = 10 * 10
        
        for candidate in candidates {
            var tooClose = false
            for selected in selectedCircles {
                let dx = candidate.x - selected.x
                let dy = candidate.y - selected.y
                if (dx * dx + dy * dy) < minDistanceSquared {
                    tooClose = true
                    break
                }
            }
            
            if !tooClose {
                selectedCircles.append(candidate)
            }
        }
        
        let idealVotes: Float = 25.0
        let confidence = min(Float(maxVotes) / idealVotes, 1.0)
        
        return (selectedCircles.count, confidence)
    }
}
