//
//  SettingsView.swift
//  BeeWise
//
//  Created by Steinhauer, Jan on 08.02.26.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("isOnboardingCompleted") var isOnboardingCompleted: Bool = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button(role: .destructive) {
                        isOnboardingCompleted = false
                        dismiss()
                    } label: {
                        Label("Reset Onboarding", systemImage: "arrow.counterclockwise")
                    }
                } header: {
                    Text("Onboarding")
                } footer: {
                    Text("This will show the onboarding screens again on the next launch.")
                }

                Section("About") {
                    LabeledContent("App", value: "Bee Wise")
                    LabeledContent("Version", value: "1.0")
                    LabeledContent("Author", value: "Jan Steinhauer")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }
}
