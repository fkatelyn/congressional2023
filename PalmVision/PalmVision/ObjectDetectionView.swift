//
//  ObjectDetectionView.swift
//  PalmVision
//
//  Created by Katelyn Fritz on 10/19/23.
//

import Foundation
import SwiftUI
import Vision

struct ObjectDetectionView: View {
    @ObservedObject var imageAttachment: ImageAttachment

    var body: some View {
        let detectedObjects = imageAttachment.imageAnalysis.observations
        GeometryReader { geometry in
            Path { path in
                for observation in detectedObjects {
                    let rect = VNImageRectForNormalizedRect(observation.boundingBox, Int(geometry.size.width), Int(geometry.size.height))
                    let cgRect = CGRect(x: rect.origin.x, y: (geometry.size.height - rect.origin.y - rect.size.height), width: rect.size.width, height: rect.size.height)
                    path.addRect(cgRect)
                }
            }
            .stroke(Color.red, lineWidth: 2)
        }
    }
}
