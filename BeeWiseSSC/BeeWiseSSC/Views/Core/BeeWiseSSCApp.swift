//
//  BeeWiseSSCApp.swift
//  BeeWiseSSC
//
//  Created by Steinhauer, Jan on 05.03.26.
//

import SwiftUI

@main
struct BeeWiseSSCApp: App {
    @AppStorage("isOnboardingCompleted") var isOnboardingCompleted: Bool = false

    var body: some Scene {
        WindowGroup {
            Group {
                if isOnboardingCompleted {
                    ContentView()
                } else {
                    OnboardingView()
                }
            }
            .preferredColorScheme(.light)
        }
    }
}
