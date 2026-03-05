//
//  HiveModels.swift
//  BeeWiseSSC
//
//  Created by Steinhauer, Jan on 24.02.26.
//

import Foundation

public enum BeeBreed: String, CaseIterable, Codable {
    case carniolan  = "Carniolan"
    case italian    = "Italian"
    case buckfast   = "Buckfast"
    case saskatraz  = "Saskatraz"
    case caucasian  = "Caucasian"
}

public enum TreatmentMethod: String, CaseIterable, Codable {
    case oxalicAcid = "Oxalic Acid"
    case formicPro  = "Formic Pro"
    case apivar     = "Apivar"
}

public struct DetectionRecord: Identifiable, Codable {
    public var id = UUID()
    public var date: Date = Date()
    public var bees: Int
    public var mites: Int
    public var result: VarroaAnalysisResult
    
    public init(id: UUID = UUID(), date: Date = Date(), bees: Int, mites: Int, result: VarroaAnalysisResult) {
        self.id = id
        self.date = date
        self.bees = bees
        self.mites = mites
        self.result = result
    }
}

public struct Hive: Identifiable, Codable {
    public var id: UUID               = UUID()
    public var name: String
    public var breed: BeeBreed
    public var queenAgeYears: Int
    public var lastTreatment: TreatmentMethod
    public var notes: String
    public var dateAdded: Date        = Date()
    public var pastDetections: [DetectionRecord] = []
    
    enum CodingKeys: String, CodingKey {
        case id, name, breed, queenAgeYears, lastTreatment, notes, dateAdded, pastDetections
    }
    
    public init(id: UUID = UUID(), name: String, breed: BeeBreed, queenAgeYears: Int, lastTreatment: TreatmentMethod, notes: String, dateAdded: Date = Date(), pastDetections: [DetectionRecord] = []) {
        self.id = id
        self.name = name
        self.breed = breed
        self.queenAgeYears = queenAgeYears
        self.lastTreatment = lastTreatment
        self.notes = notes
        self.dateAdded = dateAdded
        self.pastDetections = pastDetections
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try container.decode(String.self, forKey: .name)
        breed = try container.decode(BeeBreed.self, forKey: .breed)
        queenAgeYears = try container.decode(Int.self, forKey: .queenAgeYears)
        lastTreatment = try container.decode(TreatmentMethod.self, forKey: .lastTreatment)
        notes = try container.decode(String.self, forKey: .notes)
        dateAdded = try container.decodeIfPresent(Date.self, forKey: .dateAdded) ?? Date()
        pastDetections = try container.decodeIfPresent([DetectionRecord].self, forKey: .pastDetections) ?? []
    }
}
