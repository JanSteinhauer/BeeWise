import CoreML
import Foundation

let url = URL(fileURLWithPath: "/Users/I759164/Documents/Private Projects/BeeWise/BeeWiseSSC/BeeWiseSSC/Resources/VarroaMiteDetection.mlmodel")
do {
    let compiledUrl = try MLModel.compileModel(at: url)
    let model = try MLModel(contentsOf: compiledUrl)
    print("Model description:")
    print(model.modelDescription)
} catch {
    print("Error: \(error)")
}
