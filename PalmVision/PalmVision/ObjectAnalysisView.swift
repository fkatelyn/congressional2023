//
//  ImageDetectView.swift
//  PalmVision
//
//  Created by Katelyn Fritz on 10/18/23.
//

import Foundation
import SwiftUI
import PhotosUI
import CoreML
import Vision

struct ObjectAnalysisView: View {
    @ObservedObject var imageAttachment: ImageAttachment
    
    /// A body property for the app's UI.
    var body: some View {
        VStack {
            switch imageAttachment.imageStatus {
            case .finished(let uiImage):
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                //.frame(height: 100)
                    .overlay(ObjectDetectionView(imageAttachment: imageAttachment))
            case .failed:
                Image(systemName: "exclamationmark.triangle.fill")
            default:
                ProgressView()
            }
            
            Text("Trees \(imageAttachment.imageAnalysis.treeCountsText)")
        }
    }
}

/*
 struct ObjectDetectView_Previews: PreviewProvider {
 static var previews: some View {
 ObjectDetectView(imageAttachment: ImageAttachment(PhotosPickerItem()))
 }
 
 */
