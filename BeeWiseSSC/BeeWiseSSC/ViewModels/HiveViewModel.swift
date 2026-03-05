//
//  HiveViewModel.swift
//  BeeWiseSSC
//
//  Created by Steinhauer, Jan on 21.02.26.
//

import SwiftUI
import Combine

@MainActor
class HiveViewModel: ObservableObject {
    @Published var hives: [Hive] = []
    
    @AppStorage("hivesData") private var hivesData: Data = Data()
    
    init() {
        load()
    }
    
    func addHive(_ hive: Hive) {
        hives.append(hive)
        save()
    }
    
    func deleteHive(at offsets: IndexSet) {
        hives.remove(atOffsets: offsets)
        save()
    }
    
    func updateHive(_ hive: Hive) {
        if let index = hives.firstIndex(where: { $0.id == hive.id }) {
            hives[index] = hive
            save()
        }
    }
    
    func save() {
        if let encoded = try? JSONEncoder().encode(hives) {
            hivesData = encoded
        }
    }
    
    private func load() {
        if let decoded = try? JSONDecoder().decode([Hive].self, from: hivesData) {
            hives = decoded
        } else {
            hives = []
        }
    }
}
