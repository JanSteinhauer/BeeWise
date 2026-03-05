//
//  HiveDetectionView.swift
//  BeeWiseSSC
//
//  Created by Steinhauer, Jan on 06.02.26.
//

import SwiftUI
import PhotosUI

struct HiveDetectionView: View {
    @StateObject private var viewModel: HiveDetectionViewModel
    var onSave: (Hive) -> Void    
    
    init(hive: Binding<Hive>, onSave: @escaping (Hive) -> Void) {
        self._viewModel = StateObject(wrappedValue: HiveDetectionViewModel(hive: hive.wrappedValue))
        self.onSave = onSave
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if viewModel.isUnsupported {
                    SimulatorFallbackView()
                } else if let result = viewModel.analysisResult {
                    // Result View
                    resultCard(result: result)
                } else {
                    // Selection and Analysis View
                    Text("Select photos of frames from '\(viewModel.hive.name)' to count bees and mites.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    let demoImageNames = [
                        "bee_01", "bee_02", "bee_03", "bee_04",
                        "bee_05", "bee_06", "bee_07"
                    ]
                    
                    VStack(spacing: 16) {
                        HStack(spacing: 20) {
                            Button {
                                viewModel.showingCamera = true
                            } label: {
                                Label("Camera", systemImage: "camera.fill")
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.blue.opacity(0.15))
                                    .foregroundStyle(.blue)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            
                            PhotosPicker(selection: $viewModel.selectedItems, matching: .images, photoLibrary: .shared()) {
                                Label("Library", systemImage: "photo.fill.on.rectangle.fill")
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.purple.opacity(0.15))
                                    .foregroundStyle(.purple)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .onChange(of: viewModel.selectedItems) { oldValue, newValue in
                                Task { await viewModel.loadImages(from: newValue) }
                            }
                        }
                        
                        Text("Or select a demo image:")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 8)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 5), spacing: 12) {
                            ForEach(demoImageNames, id: \.self) { name in
                                if let uiImage = UIImage(named: name) {
                                    Button {
                                        viewModel.addDemoImage(name)
                                    } label: {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(minWidth: 0, maxWidth: .infinity)
                                            .aspectRatio(1, contentMode: .fit)
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(viewModel.selectedImages.contains(uiImage) ? Color.beeGold : Color.gray.opacity(0.3), lineWidth: viewModel.selectedImages.contains(uiImage) ? 3 : 1)
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    if !viewModel.selectedImages.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(0..<viewModel.selectedImages.count, id: \.self) { idx in
                                    Image(uiImage: viewModel.selectedImages[idx])
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 80, height: 80)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                        .overlay(alignment: .topTrailing) {
                                            Button {
                                                viewModel.removeImage(at: idx)
                                            } label: {
                                                Image(systemName: "xmark.circle.fill")
                                                    .foregroundStyle(.white, .red)
                                                    .padding(4)
                                            }
                                        }
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        Button {
                            Task { await viewModel.analyzeImages() }
                        } label: {
                            HStack {
                                if viewModel.isDetecting {
                                    ProgressView().tint(.white)
                                } else {
                                    Text("Analyze \(viewModel.selectedImages.count) Image\(viewModel.selectedImages.count == 1 ? "" : "s")")
                                }
                            }
                            .font(.headline)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.beeGold)
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                        }
                        .disabled(viewModel.isDetecting)
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
            .padding(.bottom, 120) // extra padding for tab bar
        }
        .navigationTitle("Mite Detection")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $viewModel.showingCamera) {
            ImagePicker(selectedImage: $viewModel.cameraImage, sourceType: .camera)
        }
        .onChange(of: viewModel.cameraImage) { oldValue, newValue in
            viewModel.handleCameraImage(newValue)
        }
    }
    
    // MARK: - Result View
    
    @ViewBuilder
    private func resultCard(result: VarroaAnalysisResult) -> some View {
        VStack(spacing: 20) {
            // Status Header
            let (icon, color) = getStatusUI(status: result.status)
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 48))
                    .foregroundStyle(color)
                
                Text(result.status.rawValue)
                    .font(.largeTitle.bold())
                    .foregroundStyle(color)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 16))
            
            // Raw Counts
            HStack(spacing: 30) {
                VStack {
                    Text("\(viewModel.totalBeesFound)").font(.title.bold())
                    Text("Total Bees").font(.caption).foregroundStyle(.secondary)
                }
                VStack {
                    Text("\(viewModel.totalMitesFound)").font(.title.bold())
                    Text("Total Mites").font(.caption).foregroundStyle(.secondary)
                }
            }
            
            // Recommendation
            VStack(alignment: .leading, spacing: 6) {
                Label("Recommendation", systemImage: "stethoscope")
                    .font(.headline)
                Text(result.recommendation)
                    .font(.body)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
            
            // Scientific Context
            VStack(alignment: .leading, spacing: 6) {
                Label("Scientific Context", systemImage: "book.fill")
                    .font(.headline)
                Text(result.scientificContext)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
            
            VStack(spacing: 12) {
                
                Button("Run Another Analysis") {
                    viewModel.reset()
                }
                .font(.headline)
                .foregroundStyle(.primary)
                .padding()
                .frame(maxWidth: .infinity)
                .background(.primary.opacity(0.1))
                .clipShape(Capsule())
                

                if !viewModel.isSaved {
                    Button {
                        viewModel.saveToHistory()
                        onSave(viewModel.hive)
                    } label: {
                        Text("Save to History")
                            .font(.headline)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.beeGold)
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                    }
                } else {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Saved to History")
                    }
                    .font(.headline)
                    .foregroundColor(.green)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.green.opacity(0.1))
                    .clipShape(Capsule())
                }

            }
            .padding(.top, 10)
        }
        .padding(.horizontal)
    }
    
    private func getStatusUI(status: AnalysisStatus) -> (String, Color) {
        switch status {
        case .safe: return ("checkmark.shield.fill", .green)
        case .warning: return ("exclamationmark.triangle.fill", .orange)
        case .danger: return ("xmark.octagon.fill", .red)
        }
    }
}
