//
//  SimpleVideoPlayerView.swift
//  PalmVision
//
//  Created by Katelyn Fritz on 10/23/23.
//

import SwiftUI
import AVKit
import AVFoundation

struct SimpleVideoPlayerView: UIViewControllerRepresentable {
    let videoURL: URL

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let playerViewController = AVPlayerViewController()
        let player = AVPlayer(url: videoURL)
        playerViewController.player = player
        return playerViewController
    }

    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        // You can update your AVPlayerViewController here if needed
    }
}


#Preview {
    SimpleVideoPlayerView(videoURL: Bundle.main.url(forResource: "world", withExtension: "mp4")!)
}
