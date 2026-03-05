//
//  ImageUtilities.swift
//  BeeWise
//
//  Created by Steinhauer, Jan on 14.02.26.
//

import UIKit
import CoreGraphics

enum ImageUtilities {
    static func resize(cgImage: CGImage, to size: CGSize) -> CGContext? {
        let width = Int(size.width)
        let height = Int(size.height)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue)
        
        guard let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4, space: colorSpace, bitmapInfo: bitmapInfo.rawValue) else { return nil }
        
        context.interpolationQuality = .high
        context.draw(cgImage, in: CGRect(origin: .zero, size: size))
        
        return context
    }
    
    static func rgbToHsv(r: CGFloat, g: CGFloat, b: CGFloat) -> (h: CGFloat, s: CGFloat, v: CGFloat) {
        let maxVal = max(r, max(g, b))
        let minVal = min(r, min(g, b))
        let delta = maxVal - minVal
        
        var h: CGFloat = 0
        var s: CGFloat = 0
        let v: CGFloat = maxVal
        
        if delta != 0 {
            s = delta / maxVal
            
            if r == maxVal {
                h = (g - b) / delta
            } else if g == maxVal {
                h = 2 + (b - r) / delta
            } else {
                h = 4 + (r - g) / delta
            }
            
            h *= 60
            if h < 0 { h += 360 }
        }
        
        return (h, s, v)
    }
}
