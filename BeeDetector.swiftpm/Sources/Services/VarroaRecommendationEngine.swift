//
//  VarroaRecommendationEngine.swift
//  BeeWise
//
//  Created by Steinhauer, Jan on 09.02.26.
//

import Foundation

class VarroaRecommendationEngine {
    
    static func analyze(totalBees: Int, totalMites: Int, hive: Hive) -> VarroaAnalysisResult {
        guard totalBees > 0 else {
            return VarroaAnalysisResult(
                status: .safe,
                ratio: 0.0,
                recommendation: "No bees detected.",
                scientificContext: "Ensure the photos are clear and contain bees to get an accurate analysis."
            )
        }
        
        let ratio = (Double(totalMites) / Double(totalBees)) * 100.0
        
        var dangerThreshold = 3.0
        var warningThreshold = 1.0
        
        if hive.queenAgeYears > 1 {
            warningThreshold = 0.5
            dangerThreshold = 2.0
        }
        
        var breedContext = ""
        switch hive.breed {
        case .carniolan:
            breedContext = "Carniolans are generally good winterers and responsive to forage changes but can be susceptible to mites."
        case .saskatraz, .buckfast:
            breedContext = "Breeds like \(hive.breed.rawValue) often exhibit Varroa Sensitive Hygiene (VSH) traits, helping to keep mite levels manageable, but treatment is still required if thresholds are exceeded."
        default:
            breedContext = "\(hive.breed.rawValue) bees have standard susceptibility. Monitoring is essential."
        }
        
        let queenContext = hive.queenAgeYears > 1 ?
        "Older queens (\(hive.queenAgeYears)yr) decrease colony resilience. Thresholds have been lowered for this analysis." :
        "Young queens are generally better at maintaining strong populations that can withstand low mite loads."
        
        var status: AnalysisStatus = .safe
        var recommendation = ""
        
        if ratio >= dangerThreshold {
            status = .danger
            recommendation = "Immediate treatment is strongly advised. Levels exceed the critical threshold for colony survival."
        } else if ratio >= warningThreshold {
            status = .warning
            recommendation = "Treatment should be planned soon, especially before winter or during broodless periods."
        } else {
            status = .safe
            recommendation = "Mite levels are low. Continue to monitor every 3-4 weeks."
        }
        
        let context = """
Scientific Guidelines (Honey Bee Health Coalition):
- A standard economic threshold for Varroa mites is ~3% infestation on adult bees.
- Mite levels above 2% in the late summer or fall significantly reduce winter survival odds.

Hive Variables:
- \(breedContext)
- \(queenContext)
- Last Treatment: \(hive.lastTreatment.rawValue). Rotate treatment methods to prevent resistance.
"""
        return VarroaAnalysisResult(status: status, ratio: ratio, recommendation: recommendation, scientificContext: context)
    }
}
