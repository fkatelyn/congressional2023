//
//  ObjectDetectionView.swift
//  PalmVision
//
//  Created by Katelyn Fritz on 10/19/23.
//

import Foundation
import SwiftUI
import Vision
import PhotosUI

struct ObjectDetectionView: View {
    @ObservedObject var imageAttachment: ImageAttachment
   
    @ViewBuilder
    func drawObjects(detectedObjects: [Observation],
                     label: ObjectLabel,
                     geometry: GeometryProxy) -> some View {
        Path { path in
            for observation in detectedObjects {
                if observation.label != label.rawValue {
                    continue
                }
                let rect = VNImageRectForNormalizedRect(observation.boundingBox, Int(geometry.size.width), Int(geometry.size.height))
                let cgRect = CGRect(x: rect.origin.x, y: (geometry.size.height - rect.origin.y - rect.size.height), width: rect.size.width, height: rect.size.height)
                path.addRect(cgRect)
            }
        }
        .stroke(label.color, lineWidth: 2)
    }
    
    var body: some View {
        let detectedObjects = imageAttachment.imageAnalysis.observations
        GeometryReader { geometry in
            
            ForEach(ObjectLabel.allCases) {
                label in
                drawObjects(detectedObjects: detectedObjects,
                            label: label,
                            geometry: geometry)
            }
        }
    }
}

#Preview
{
    ObjectDetectionView(imageAttachment: ImageAttachment(PhotosPickerItem(itemIdentifier: "")))
}
