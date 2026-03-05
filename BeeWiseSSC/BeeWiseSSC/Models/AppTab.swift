//
//  AppTab.swift
//  BeeWiseSSC
//
//  Created by Steinhauer, Jan on 25.02.26.
//

import Foundation

enum AppTab: CaseIterable {
    case detector, hive, learn

    var title: String {
        switch self {
        case .detector: return "Detector"
        case .hive:     return "Hives"
        case .learn:    return "Learn"
        }
    }

    var icon: String {
        switch self {
        case .detector: return "ant.circle.fill"
        case .hive:     return "house.fill"
        case .learn:    return "books.vertical.fill"
        }
    }
}
