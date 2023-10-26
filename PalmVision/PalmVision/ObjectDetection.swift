//
//  ObjectDetection.swift
//  PalmVision
//
//  Created by Katelyn Fritz on 10/17/23.
//

import Foundation
import CoreML
import Vision
import SwiftUI

struct Observation: Identifiable {
    let id: UUID
    let label: String
    let confidence: VNConfidence
    let boundingBox: CGRect
}

struct Observations {
    let observations: [Observation]
    let detectionTime: String
}

enum ObjectLabel: String {
    case unknown, healthy, nitrogen, ganoderna, banana, cattle, young
    
    public static func from(observation: Observation) -> ObjectLabel {
        return ObjectLabel(rawValue: observation.label) ?? .unknown
    }
}
 
struct ObjectDetection {
    static let compiledModel = try! best(configuration: MLModelConfiguration())
    
    static func detect(_ image: UIImage ) -> [Observation] {
        let mlModel = compiledModel.model
        var detectedObjects: [Observation] = []
        guard let coreMlModel = try? VNCoreMLModel(for: mlModel) else { return [] }
        let request = VNCoreMLRequest(model: coreMlModel) {
            request, error in
            guard let results = request.results as? [VNRecognizedObjectObservation] else {
                return
            }
            
            detectedObjects = results.map { result in
                guard let label = result.labels.first?.identifier else {
                    return Observation(id: result.uuid, label: "", confidence: VNConfidence.zero, boundingBox: .zero)
                }
                let confidence = result.labels.first?.confidence ?? 0.0
                let boundingBox = result.boundingBox
                print("\(label) \(confidence)")
                return Observation(id: result.uuid, label: label, confidence: confidence, boundingBox: boundingBox)
            }
        }
        //guard let image = selectedUiImage,
        guard let cgImage = image.cgImage else { return [] }
        let requestHandler = VNImageRequestHandler(cgImage: cgImage)
        do {
            try requestHandler.perform([request])
        } catch {
            print(error.localizedDescription)
        }
        
        return detectedObjects
    }
    
    static func detect(_ pixelBuffer: CVPixelBuffer) -> Observations {
        let mlModel = compiledModel.model
        var detectedObjects: [Observation] = []
        guard let coreMlModel = try? VNCoreMLModel(for: mlModel) else { 
            return Observations(observations: detectedObjects, detectionTime: "0") }
        let request = VNCoreMLRequest(model: coreMlModel) {
            request, error in
            guard let results = request.results as? [VNRecognizedObjectObservation] else {
                return
            }
            
            detectedObjects = results.map { result in
                guard let label = result.labels.first?.identifier else {
                    return Observation(id: result.uuid, label: "", confidence: VNConfidence.zero, boundingBox: .zero)
                }
                let confidence = result.labels.first?.confidence ?? 0.0
                let boundingBox = result.boundingBox
                print("\(label) \(confidence)")
                return Observation(id: result.uuid, label: label, confidence: confidence, boundingBox: boundingBox)
            }
        }
        let requestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer)
        /*
        do {
            try requestHandler.perform([request])
        } catch {
            print(error.localizedDescription)
        }
         */
        let detectionTime = ContinuousClock().measure {
            try? requestHandler.perform([request])
        }
        let msTime = detectionTime.formatted(.units(allowed: [.seconds, .milliseconds], width: .narrow))
        return Observations(observations: detectedObjects, detectionTime: msTime)
    }
}
