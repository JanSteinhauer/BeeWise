//
//  BeeDetectorView.swift
//  BeeWise
//
//  Created by Steinhauer, Jan on 01.02.26.
//

import SwiftUI

@main
struct MyApp: App {
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
