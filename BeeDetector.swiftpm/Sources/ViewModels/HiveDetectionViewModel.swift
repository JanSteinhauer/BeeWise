//
//  HiveDetectionViewModel.swift
//  BeeWise
//
//  Created by Steinhauer, Jan on 21.02.26.
//


import SwiftUI
import PhotosUI

@MainActor
class HiveDetectionViewModel: ObservableObject {
    @Published var hive: Hive
    @Published var selectedImages: [UIImage] = []
    @Published var isDetecting: Bool = false
    @Published var showingCamera: Bool = false
    @Published var cameraImage: UIImage?
    
    @Published var analysisResult: VarroaAnalysisResult?
    @Published var totalBeesFound: Int = 0
    @Published var totalMitesFound: Int = 0
    @Published var isUnsupported: Bool = false
    @Published var isSaved: Bool = false
    @Published var selectedItems: [PhotosPickerItem] = []
    
    init(hive: Hive) {
        self.hive = hive
    }
    
    func reset() {
        selectedImages.removeAll()
        selectedItems.removeAll()
        analysisResult = nil
        totalBeesFound = 0
        totalMitesFound = 0
        isSaved = false
    }
    
    func saveToHistory() {
        guard let result = analysisResult else { return }
        let record = DetectionRecord(date: Date(), bees: totalBeesFound, mites: totalMitesFound, result: result)
        hive.pastDetections.insert(record, at: 0)
        isSaved = true
    }
    
    func addDemoImage(_ name: String) {
        if let uiImage = UIImage(named: name), !selectedImages.contains(uiImage) {
            selectedImages.append(uiImage)
        }
    }
    
    func removeImage(at index: Int) {
        if selectedImages.indices.contains(index) {
            selectedImages.remove(at: index)
        }
    }
    
    func handleCameraImage(_ image: UIImage?) {
        if let img = image {
            selectedImages.append(img)
            cameraImage = nil
        }
    }
    
    func loadImages(from items: [PhotosPickerItem]) async {
        var newImages: [UIImage] = []
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self),
               let uiImage = UIImage(data: data) {
                newImages.append(uiImage)
            }
        }
        
        await MainActor.run {
            self.selectedImages.append(contentsOf: newImages)
            self.selectedItems.removeAll()
        }
    }
    
    func analyzeImages() async {
        isDetecting = true
        var bees = 0
        var mites = 0
        
        do {
            for image in selectedImages {
                let rectsAndConfs = try await BeeDetector.detectBeesML(in: image)
                bees += rectsAndConfs.count
                
                for (boundingBox, _) in rectsAndConfs {
                    let (miteCount, _) = await MiteDetectionService.checkForMites(in: image, roi: boundingBox)
                    mites += min(miteCount, 1)
                }
            }
            
            // The ML model often has a ~30% false positive rate for mites, so we deduct 30%
            let adjustedMites = Int(Double(mites) * 0.7)
            let result = VarroaRecommendationEngine.analyze(totalBees: bees, totalMites: adjustedMites, hive: hive)
            
            await MainActor.run {
                withAnimation {
                    self.totalBeesFound = bees
                    self.totalMitesFound = adjustedMites
                    self.analysisResult = result
                }
            }
        } catch {
            await MainActor.run {
                withAnimation {
                    self.isUnsupported = true
                }
            }
        }
        
        await MainActor.run {
            isDetecting = false
        }
    }
}
