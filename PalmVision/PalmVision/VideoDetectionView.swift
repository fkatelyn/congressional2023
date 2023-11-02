//
//  VideoDetectionView.swift
//  PalmVision
//
//  From https://github.com/npna/CoreMLPlayer
//  Modified by Katelyn Fritz on 10/24/23.
//

import SwiftUI
import AVFoundation
import AVKit
import Combine
import Vision

class VideoDetection: ObservableObject {
    var isPlayable: Bool = false
    var errorMessage: String? = ""
    
    var videoURL: URL? {
        didSet {
            Task {
                await prepareToPlay(videoURL: videoURL)
            }
        }
    }
    @Published var player: AVPlayer?
    @Published var canStart = false
    @Published var playing = false {
        didSet {
            playManager()
        }
    }
    @Published var frameObjects: [Observation] = []
    private var playerOutput = AVPlayerItemVideoOutput(pixelBufferAttributes: nil)
    private var timeTracker = DispatchTime.now()
    private var lastDetectionTime: Double = 0
    private var videoHasEnded = false
    
    private var avPlayerItemStatus: AVPlayerItem.Status = .unknown {
        didSet {
            print("avPlayerItemStatus")
            if avPlayerItemStatus == .readyToPlay {
                canStart = true
                print("PlayerItem is readyToPlay")
            } else {
                canStart = false
                print("PlayerItem is not readyToPlay")
            }
        }
    }
    
    func disappearing() {
        playing = false
        frameObjects = []
    }
    
    private var avPlayerTimeControlStatus: AVPlayer.TimeControlStatus = .paused {
        didSet {
            print("avPlayerTimeControlStatus")
            if avPlayerTimeControlStatus != oldValue {
                DispatchQueue.main.async {
                    switch self.avPlayerTimeControlStatus {
                    case .playing:
                        self.playing = true
                        print("player is playing")
                    default:
                        print("player is not playing")
                        self.playing = false
                    }
                }
            }
        }
    }
    
    var frameRate: Double = 30.0
    var duration: CMTime? = .zero
    var size: CGSize = .zero
    
    func getRepeatInterval(_ reduceLastDetectionTime: Bool = true) -> Double {
        var interval = 0.0
        if frameRate > 0 {
            interval = (1 / frameRate)
        } else {
            interval = 30
        }
        
        if reduceLastDetectionTime {
            interval = max((interval - lastDetectionTime), 0.02)
        }
        return interval
    }
    
    func getPlayerItemIfContinuing() -> AVPlayerItem? {
        guard let playerItem = player?.currentItem,
              playing == true
        else {
            return nil
        }
        
        if playerItem.currentTime() >= playerItem.duration {
            DispatchQueue.main.async {
                self.playing = false
            }
            
            return nil
        }
        
        return playerItem
    }
    
    func startNormalDetection() {
        print("Start normal detection")
        guard getPlayerItemIfContinuing() != nil else {
            return
        }
        
        self.detectObjectsInFrame() {
            DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + self.getRepeatInterval()) { [weak self] in
                self?.startNormalDetection()
            }
        }
    }
    
    func playManager() {
        if let playerItem = player?.currentItem, playerItem.currentTime() >= playerItem.duration {
            player?.seek(to: CMTime.zero)
            print("VM Seek to zero")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.detectObjectsInFrame()
            }
            videoHasEnded = true
            frameObjects = []
        }
        
        if playing {
            print("VM playing")
            videoHasEnded = false
            startNormalDetection()
            player?.play()
        } else {
            print("VM pause")
            player?.pause()
        }
    }
    
    func prepareToPlay(videoURL: URL?) async {
        guard let url = videoURL,
              url.isFileURL,
              let isReachable = try? url.checkResourceIsReachable(),
              isReachable
        else {
            return
        }
        
        let asset = AVAsset(url: url)
        do {
            if let videoTrack = try await asset.loadTracks(withMediaType: .video).first {
                let (frameRate, size) = try await videoTrack.load(.nominalFrameRate, .naturalSize)
                let (isPlayable, duration) = try await asset.load(.isPlayable, .duration)
                let playerItem = AVPlayerItem(asset: asset)
                playerItem.add(playerOutput)
                
                DispatchQueue.main.async {
                    self.frameRate = Double(frameRate)
                    self.duration = duration
                    self.size = size
                    if isPlayable {
                        self.player = AVPlayer(playerItem: playerItem)
                        self.isPlayable = true
                        
                        // Set avPlayerItemStatus when playerItem.status changes, when it is readyToPlay avPlayerItemStatus will set canStart to true
                        let playerItemStatusPublisher = playerItem.publisher(for: \.status)
                        let playerItemStatusSubscriber = Subscribers.Assign(object: self, keyPath: \.avPlayerItemStatus)
                        playerItemStatusPublisher.receive(subscriber: playerItemStatusSubscriber)
                        // AVPlayer.TimeControlStatus
                        let timeControlStatusPublisher = self.player?.publisher(for: \.timeControlStatus)
                        let timeControlStatusSubscriber = Subscribers.Assign(object: self, keyPath: \.avPlayerTimeControlStatus)
                        timeControlStatusPublisher?.receive(subscriber: timeControlStatusSubscriber)
                    } else {
                        self.errorMessage = "Video item is not playable."
                    }
                }
            }
        } catch {
            print("There was an error trying to load asset.")
        }
    }
    
    func getPixelBuffer() -> CVPixelBuffer? {
        if let currentTime = player?.currentTime() {
            return playerOutput.copyPixelBuffer(forItemTime: currentTime, itemTimeForDisplay: nil)
        }
        
        return nil
    }
  
    func detectObjectsInFrame(completion: (() -> ())? = nil) {
        guard let pixelBuffer = getPixelBuffer() else { return }
        let detectionResult = ObjectDetection.detect(pixelBuffer)
        
        DispatchQueue.main.async {
            self.frameObjects = detectionResult.observations
            let timePassed = DispatchTime.now().uptimeNanoseconds - self.timeTracker.uptimeNanoseconds
            if timePassed >= 1_000_000_000 {
                self.timeTracker = DispatchTime.now()
            }
            let detTime = Double(detectionResult.detectionTime.replacingOccurrences(of: " ms", with: "")) ?? 0
            self.lastDetectionTime = detTime / 1000
            if completion != nil {
                completion!()
            }
        }
    }
}

struct VideoDetectionView: View {
    @State var videoUrl: URL
    @StateObject private var videoDetection = VideoDetection()
    var body: some View {
        Group {
            VideoPlayer(player: videoDetection.player)
        }
        .overlay {
            DetectionView(videoDetection.frameObjects, videoSize: videoDetection.size)
        }
        .onAppear() {
            videoDetection.videoURL = videoUrl
        }
    }
}

#Preview {
    VideoDetectionView(videoUrl: Bundle.main.url(forResource: "world", withExtension: "mp4")!)
}
