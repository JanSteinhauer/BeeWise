//
//  BeeWiseApp.swift
//  BeeWise
//
//  Created by Steinhauer, Jan on 05.03.26.
//

import SwiftUI

@main
struct BeeWiseApp: App {
    @AppStorage("isOnboardingCompleted") var isOnboardingCompleted: Bool = false

    var body: some Scene {
        WindowGroup {
            if isOnboardingCompleted {
                ContentView()
                    
            } else {
                OnboardingView()
            }
            
        }
    }
}
