import CoreML
import Foundation

let sourcePath = "/Users/JanSteinhauer/Documents/Private Projects/Apple Swift Student Challenge/Varroa Mite Swift Student Challange/BeeDetector.swiftpm/Sources/Resources/BeeDetectionModel.mlmodel"
let sourceUrl = URL(fileURLWithPath: sourcePath)

do {
    let compiledUrl = try MLModel.compileModel(at: sourceUrl)
    print("Compiled to: \(compiledUrl.path)")
    
    let fm = FileManager.default
    let destPath = "/Users/JanSteinhauer/Documents/Private Projects/Apple Swift Student Challenge/Varroa Mite Swift Student Challange/BeeDetector.swiftpm/Sources/Resources/BeeDetectionModel.mlmodelc"
    let destUrl = URL(fileURLWithPath: destPath)
    
    if fm.fileExists(atPath: destPath) {
        try fm.removeItem(at: destUrl)
    }
    
    try fm.moveItem(at: compiledUrl, to: destUrl)
    print("Moved to: \(destUrl.path)")
    
    try fm.removeItem(at: sourceUrl)
    print("Removed original .mlmodel file")
    
} catch {
    print("Error: \(error)")
}
