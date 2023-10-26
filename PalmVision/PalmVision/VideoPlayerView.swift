//
//  VideoView.swift
//  PalmVision
//
//  Created by Katelyn Fritz on 10/22/23.
//
/*
import SwiftUI
import AVFoundation
import CoreML

struct VideoPlayerView: UIViewRepresentable {
    let asset: AVAsset
    @Binding var boundingBoxes: [CGRect]
    
    func makeUIView(context: Context) -> CustomPlayerView {
        let playerView = CustomPlayerView(asset: asset)
        playerView.delegate = context.coordinator
        return playerView
    }
    
    func updateUIView(_ uiView: CustomPlayerView, context: Context) {
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, CustomPlayerViewDelegate {
        var parent: VideoPlayerView
        
        init(_ parent: VideoPlayerView) {
            self.parent = parent
        }
        
        func updatedBoundingBoxes(_ boxes: [CGRect]) {
            parent.boundingBoxes = boxes
        }
    }
}

protocol CustomPlayerViewDelegate: AnyObject {
    func updatedBoundingBoxes(_ boxes: [CGRect])
}

class CustomPlayerView: UIView {
    weak var delegate: CustomPlayerViewDelegate?
    // Add your player, output, etc. implementations here
    // ...
}

#Preview {
    VideoPlayerView()
}

*/
