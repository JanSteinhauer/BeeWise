//
//  SimulatorFallbackView.swift
//  BeeWise
//
//  Created by Steinhauer, Jan on 18.02.26.
//

import SwiftUI

/// Shown when Vision/CoreML detection fails (e.g. on Simulator where
/// the Neural Engine / saliency APIs are unavailable).
struct SimulatorFallbackView: View {
    @State private var isTalking: Bool  = false
    @State private var isFlapping: Bool = false

    var body: some View {
        ZStack {
            AmbientBackground()

            VStack(spacing: 32) {

                LogoAnimation(isTalking: $isTalking, isFlapping: $isFlapping)
                    .frame(width: 300, height: 300)
                    .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                            isFlapping = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                            isTalking = true
                        }
                    }

                VStack(spacing: 10) {
                    Label("Real Device Required", systemImage: "exclamationmark.triangle.fill")
                        .font(.title2.bold())
                        .foregroundStyle(.orange)

                    Text("Varroa mite detection relies on Apple's Neural Engine and Vision saliency APIs, which are not available on the Simulator.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .padding(.horizontal, 24)
            }
        }
        .ignoresSafeArea()
    }
}

#Preview {
    SimulatorFallbackView()
}
