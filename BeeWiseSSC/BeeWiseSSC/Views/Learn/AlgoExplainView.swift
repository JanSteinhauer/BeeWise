//
//  AlgoExplainView.swift
//  BeeWiseSSC
//
//  Created by Steinhauer, Jan on 18.02.26.
//

import SwiftUI

// MARK: - Data

struct AlgoStep: Identifiable {
    let id = UUID()
    let stepNumber: Int
    let title: String
    let summary: String
    let detail: String
    let icon: String
    let iconColor: Color
}

// MARK: - Main View

struct AlgoExplainView: View {
    let image: UIImage
    let beeResults: [BeeDetectionResult]
    @Environment(\.dismiss) private var dismiss
    @State private var currentStep = 0

    private let steps: [AlgoStep] = [
        AlgoStep(
            stepNumber: 0,
            title: "The Original Image",
            summary: "What the camera sees",
            detail: "We start with a plain photo of a bee frame. At this point nothing has been processed. This is the raw input that goes into the pipeline.",
            icon: "photo.fill",
            iconColor: .blue
        ),
        AlgoStep(
            stepNumber: 1,
            title: "Step 1: Machine Learning & Saliency",
            summary: "Finding the bees",
            detail: "First, my custom trained Machine Learning model identifies exactly where the bees are located on the frame. Then, Apple's Vision framework runs an Attention Based Saliency analysis to highlight the most prominent features within those detected regions. Each highlighted bee becomes a bounding box for further inspection.",
            icon: "sparkles",
            iconColor: .indigo
        ),
        AlgoStep(
            stepNumber: 2,
            title: "Step 2: Color Filtering",
            summary: "Spotting the mite's colour",
            detail: "Each bee region is converted to HSB (Hue, Saturation, Brightness) colour space. Pixels with hue 0–25° or 335–360° (reddish-brown), high saturation (> 0.45) and moderate brightness (0.2–0.85) are flagged. This range closely matches Varroa's distinctive colour.",
            icon: "paintpalette.fill",
            iconColor: .orange
        ),
        AlgoStep(
            stepNumber: 3,
            title: "Step 3: Shape Detection",
            summary: "Hough Circle Transform",
            detail: "A Hough Circle Transform scans the colour filtered pixels for round shapes that match a mite's radius (roughly 2–6 pixels at this scale). Each circle that collects enough \"votes\" in the accumulator is counted as one mite. Non Maximum Suppression prevents double counting overlapping circles.",
            icon: "circle.dashed",
            iconColor: .purple
        ),
        AlgoStep(
            stepNumber: 4,
            title: "The Result",
            summary: "Infected vs. Healthy",
            detail: "Bees where one or more mites were detected are marked RED with a mite count. Bees that passed the checks are marked GREEN. The detection runs independently for every salient region found in Step 1.",
            icon: "checkmark.seal.fill",
            iconColor: .green
        ),
        AlgoStep(
            stepNumber: 5,
            title: "Based on Research",
            summary: "Scientific foundation",
            detail: "The overall approach follows the method described in:\n\n\"Deep Learning Beehive Monitoring System for Early Detection of the Varroa Mite\" by Voudiotis, Moraiti & Kontogiannis from the University of Ioannina, Greece.\n\nTheir pipeline combines object detection for bees with image processing to identify mites, reaching ~70% combined accuracy. This app replicates the core idea using Apple's on device Vision & CoreImage frameworks.",
            icon: "book.closed.fill",
            iconColor: .brown
        )
    ]

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // ── Slide pager ──────────────────────────────────────────
            TabView(selection: $currentStep) {
                ForEach(steps) { step in
                    StepSlide(
                        step: step,
                        image: image,
                        beeResults: beeResults,
                        isLastSlide: step.stepNumber == steps.count - 1,
                        onDismiss: { dismiss() }
                    )
                    .tag(step.stepNumber)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
            .ignoresSafeArea()

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title)
                    .foregroundStyle(.secondary)
                    .padding()
            }
            .padding(.top, 8)
        }
    }
}

// MARK: - Single Slide

struct StepSlide: View {
    let step: AlgoStep
    let image: UIImage
    let beeResults: [BeeDetectionResult]
    let isLastSlide: Bool
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Color(.systemBackground)

                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .overlay(annotationOverlay)
            }
            .frame(maxHeight: 340)

            ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(step.iconColor.opacity(0.15))
                            .frame(width: 48, height: 48)
                        Image(systemName: step.icon)
                            .font(.system(size: 22))
                            .foregroundStyle(step.iconColor)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        if step.stepNumber < 5 {
                            Text(step.stepNumber == 0 ? "Introduction" : "Step \(step.stepNumber) of 4")
                                .font(.caption.bold())
                                .foregroundStyle(step.iconColor)
                        }
                        Text(step.title)
                            .font(.title2.bold())
                    }
                }

                Text(step.summary)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)

                Text(step.detail)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer()

                if isLastSlide {
                    Button {
                        onDismiss()
                    } label: {
                        Text("Got it!")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.beeGold, in: Capsule())
                            .foregroundStyle(.white)
                    }
                }
            }
            .padding(24)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.systemBackground))
            }
        }
    

    // MARK: Annotation overlay per step

    @ViewBuilder
    private var annotationOverlay: some View {
        switch step.stepNumber {
        case 1: // Saliency boxes (plain, no labels)
            GeometryReader { geo in
                ForEach(beeResults) { result in
                    Rectangle()
                        .stroke(Color.yellow, lineWidth: 3)
                        .frame(
                            width: result.rect.width * geo.size.width,
                            height: result.rect.height * geo.size.height
                        )
                        .position(
                            x: result.rect.midX * geo.size.width,
                            y: (1 - result.rect.midY) * geo.size.height
                        )
                }
            }

        case 2:
            Color.orange.opacity(0.15)
                .blendMode(.multiply)

        case 3:
            GeometryReader { geo in
                ForEach(beeResults) { result in
                    Circle()
                        .stroke(Color.purple, lineWidth: 2)
                        .frame(
                            width: result.rect.width * geo.size.width * 0.4,
                            height: result.rect.width * geo.size.width * 0.4
                        )
                        .position(
                            x: result.rect.midX * geo.size.width,
                            y: (1 - result.rect.midY) * geo.size.height
                        )
                }
            }

        case 4:
            GeometryReader { geo in
                ForEach(beeResults) { result in
                    Rectangle()
                        .stroke(result.isInfected ? Color.red : Color.green, lineWidth: 3)
                        .frame(
                            width: result.rect.width * geo.size.width,
                            height: result.rect.height * geo.size.height
                        )
                        .position(
                            x: result.rect.midX * geo.size.width,
                            y: (1 - result.rect.midY) * geo.size.height
                        )

                    Text(result.isInfected ? "\(result.miteCount) mite\(result.miteCount == 1 ? "" : "s")" : "✅ Clean")
                        .font(.caption.bold())
                        .padding(.horizontal, 6).padding(.vertical, 3)
                        .background(result.isInfected ? Color.red : Color.green, in: Capsule())
                        .foregroundStyle(.white)
                        .position(
                            x: result.rect.midX * geo.size.width,
                            y: (1 - result.rect.midY) * geo.size.height - (result.rect.height * geo.size.height / 2) - 16
                        )
                }
            }

        default:
            EmptyView()
        }
    }
}

// MARK: - Shared result type (used by both BeeDetectorView and AlgoExplainView)

struct BeeDetectionResult: Identifiable {
    let id = UUID()
    let rect: CGRect
    let isInfected: Bool
    let miteCount: Int
    let beeConfidence: Float
    let miteConfidence: Float
}
