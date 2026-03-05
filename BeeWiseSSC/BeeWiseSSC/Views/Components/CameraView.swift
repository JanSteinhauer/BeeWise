//
//  CameraView.swift
//  BeeWiseSSC
//
//  Created by Steinhauer, Jan on 13.02.26.
//

import SwiftUI

struct CameraView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                VStack(spacing: 20) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(.yellow)

                    Text("Camera")
                        .font(.title.bold())

                    Text("Live camera detection coming soon.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
            }
            .navigationTitle("Camera")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}
