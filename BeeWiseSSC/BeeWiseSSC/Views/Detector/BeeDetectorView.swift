//
//  BeeDetectorView.swift
//  BeeWiseSSC
//
//  Created by Steinhauer, Jan on 03.02.26.
//

import SwiftUI

struct BeeDetectorView: View {
    let imageNames = [
        "bee_01",
        "bee_03",
        "bee_05",
        "bee_06",
        "bee_07"
    ]

    @State private var index: Int = 0
    @State private var isDetecting: Bool = false
    @State private var errorMessage: String? = nil
    @State private var isUnsupported: Bool = false
    @State private var beeResults: [BeeDetectionResult] = []
    @State private var showAlgoExplain: Bool = false

    var body: some View {
        if isUnsupported {
            SimulatorFallbackView()
        } else {
            VStack(spacing: 20) {
                // ── Image + result overlays ──────────────────────────
                ZStack {
                    if let uiImage = UIImage(named: imageNames[index]) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: 600, maxHeight: 600)
                            .overlay(
                                GeometryReader { geometry in
                                    ForEach(beeResults) { result in
                                        // Bounding box
                                        Rectangle()
                                            .stroke(result.isInfected ? Color.red : Color.green, lineWidth: 4)
                                            .frame(
                                                width: result.rect.width * geometry.size.width,
                                                height: result.rect.height * geometry.size.height
                                            )
                                            .position(
                                                x: result.rect.midX * geometry.size.width,
                                                y: (1 - result.rect.midY) * geometry.size.height
                                            )

                                        // Label
                                        Text(result.isInfected ? "INFECTED (\(result.miteCount))" : "HEALTHY")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                            .padding(5)
                                            .background(result.isInfected ? Color.red : Color.green)
                                            .cornerRadius(5)
                                            .position(
                                                x: result.rect.midX * geometry.size.width,
                                                y: (1 - result.rect.midY) * geometry.size.height
                                                    - (result.rect.height * geometry.size.height / 2) - 20
                                            )
                                    }
                                }
                            )
                            .padding()
                            .border(Color.gray.opacity(0.3), width: 2)
                    } else {
                        ZStack {
                            Rectangle()
                                .fill(Color.gray.opacity(0.1))
                                .frame(width: 400, height: 400)
                                .border(Color.gray, width: 2)
                            VStack(spacing: 12) {
                                Image(systemName: "photo")
                                    .font(.system(size: 60))
                                    .foregroundColor(.gray)
                                Text("Image not found: \(imageNames[index])")
                                    .foregroundColor(.gray)
                                    .padding(.top)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }

                    if isDetecting {
                        ProgressView()
                            .scaleEffect(2)
                            .tint(.yellow)
                    }
                }

                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                }

                // ── Controls: Previous | Algo Explain | Next ─────────
                HStack(spacing: 20) {
                    Button("Previous") { changeIndex(-1) }
                        .buttonStyle(.borderedProminent)
                        .tint(.yellow)
                        .foregroundStyle(.white)

                    Button {
                        showAlgoExplain = true
                    } label: {
                        Label("Algo Explain", systemImage: "sparkles")
                            .font(.subheadline.bold())
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Color.beeGold.opacity(0.15), in: Capsule())
                            .foregroundStyle(Color.beeGold)
                            .overlay(Capsule().stroke(Color.beeGold, lineWidth: 1))
                    }
                    .disabled(isDetecting || beeResults.isEmpty)

                    Button("Next") { changeIndex(1) }
                        .buttonStyle(.borderedProminent)
                        .tint(.yellow)
                        .foregroundStyle(.white)
                }
                .disabled(isDetecting)
                
                Spacer()
            }
            .padding()
            .task(id: index) {
                await detectBee()
            }
            .sheet(isPresented: $showAlgoExplain) {
                if let uiImage = UIImage(named: imageNames[index]) {
                    AlgoExplainView(image: uiImage, beeResults: beeResults)
                        .presentationDetents([.large])
                        .presentationDragIndicator(.visible)

                }
            }
        }
    }

    // MARK: - Helpers

    private func changeIndex(_ delta: Int) {
        var newIndex = index + delta
        if newIndex < 0 { newIndex = imageNames.count - 1 }
        if newIndex >= imageNames.count { newIndex = 0 }
        index = newIndex
        beeResults = []
        errorMessage = nil
    }

    private func detectBee() async {
        guard let uiImage = UIImage(named: imageNames[index]) else {
            errorMessage = "Please add \(imageNames[index]) to Assets."
            return
        }

        isDetecting = true
        errorMessage = nil

        do {
            async let rectsAndConfs = BeeDetector.detectBeesSalience(in: uiImage)
            var detections = try await rectsAndConfs

            if detections.isEmpty {
                detections = [(CGRect(x: 0, y: 0, width: 1, height: 1), 0.0)]
            }

            var newResults: [BeeDetectionResult] = []
            for (boundingBox, beeConf) in detections {
                let (count, miteConf) = await MiteDetectionService.checkForMites(in: uiImage, roi: boundingBox)
                newResults.append(BeeDetectionResult(
                    rect: boundingBox,
                    isInfected: count > 0,
                    miteCount: count,
                    beeConfidence: beeConf,
                    miteConfidence: miteConf
                ))
            }

            withAnimation {
                self.beeResults = newResults
            }
        } catch {
            withAnimation(.spring()) {
                isUnsupported = true
            }
        }

        isDetecting = false
    }
}
