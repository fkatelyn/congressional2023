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
    @State private var scale: CGFloat = 1.0
    @State private var currentScale: CGFloat = 1.0
    @State private var lastScaleValue: CGFloat = 1.0
    
    
    var body: some View {
        VStack {
            switch imageAttachment.imageStatus {
            case .finished(let uiImage):
                GeometryReader { proxy in
                    ZStack {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .overlay(ObjectDetectionView(imageAttachment: imageAttachment))
                            .frame(width: proxy.size.width, height: proxy.size.height)
                            .clipShape(Rectangle())
                    }
                    .modifier(ImageModifier(contentSize: CGSize(width: proxy.size.width, height: proxy.size.height)))
                    //.overlay(ObjectDetectionView(imageAttachment: imageAttachment))
                    
                }
            case .failed:
                Image(systemName: "exclamationmark.triangle.fill")
            default:
                ProgressView()
            }
            
            Text("Trees \(imageAttachment.imageAnalysis.treeCountsText)")
            Spacer()
        }
    }
}

#Preview
{
    ObjectAnalysisView(imageAttachment: ImageAttachment(PhotosPickerItem(itemIdentifier: "")))
}
