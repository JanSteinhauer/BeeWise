//
//  AnalysisModels.swift
//  BeeWise
//
//  Created by Steinhauer, Jan on 24.02.26.
//

import Foundation

public enum AnalysisStatus: String, Codable {
    case safe = "Safe"
    case warning = "Warning"
    case danger = "Danger"
}

public struct VarroaAnalysisResult: Codable {
    public let status: AnalysisStatus
    public let ratio: Double
    public let recommendation: String
    public let scientificContext: String
    
    public init(status: AnalysisStatus, ratio: Double, recommendation: String, scientificContext: String) {
        self.status = status
        self.ratio = ratio
        self.recommendation = recommendation
        self.scientificContext = scientificContext
    }
}
