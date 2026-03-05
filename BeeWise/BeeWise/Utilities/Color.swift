//
//  Color.swift
//  BeeDetector
//
//  Created by Steinhauer, Jan on 16.02.26.
//

import SwiftUI

extension Color {
    static let appBackground = Color(hex: "#FFFFFF")
    static let appSecondaryBackground = Color(hex: "#F2F6F9")
    
    static let appTextPrimary = Color(hex: "#2C2C2E")
    static let appTextSecondary = Color(hex: "#5E6164")
    
    static let techBlue = Color(hex: "#6F97B3")
    static let beeGold = Color(hex: "#E1A83D")
    
    static let bugRed = Color(hex: "#D13535")
    static let debugGreen = Color(hex: "#61B076")
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
