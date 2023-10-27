//
//  VideoListView.swift
//  PalmVision
//
//  Created by Katelyn Fritz on 10/25/23.
//
import SwiftUI
import PhotosUI
import CoreML
import Vision

struct VideoListView: View {
    @ObservedObject var viewModel: VideoViewModel
    
    var body: some View {
        VStack {
            VideoList(viewModel: viewModel)
        }
        .navigationTitle("Video View")
        .ignoresSafeArea(.keyboard)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { } ) {
                    // Define the app's Photos picker.
                    PhotosPicker(
                        selection: $viewModel.selection,
                        
                        // Enable the app to dynamically respond to user adjustments.
                        selectionBehavior: .continuousAndOrdered,
                        matching: .videos,
                        preferredItemEncoding: .current,
                        photoLibrary: .shared()
                    ) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
    }
}


/// A view that lists selected photos and their descriptions.
struct VideoList: View {
    
    /// A view model for the list.
    @ObservedObject var viewModel: VideoViewModel
    
    /// A container view for the list.
    var body: some View {
        
        // Display a stub image if the Photos picker lacks a selection.
        if viewModel.attachments.isEmpty {
            Spacer()
            Image(systemName: "text.below.photo")
                .font(.system(size: 150))
                .opacity(0.2)
            Spacer()
        } else {
            // Create a row for each selected photo in the picker.
            List(viewModel.attachments, id: \.self) { videoAttachment in
                NavigationLink(value: videoAttachment) {
                    VideoAttachmentView(videoAttachment: videoAttachment)
                }
                .navigationDestination(for: VideoAttachment.self) {
                    item in 
                    switch item.videoStatus {
                    case .loaded(let movie):
                        VideoDetectionView(videoUrl: movie.url)
                    default:
                        Text("error")
                    }
                }
            }
            .listStyle(.plain)
        }
    }
}

/// A row item that displays a photo and a description.
struct VideoAttachmentView: View {
    
    /// An image that a person selects in the Photos picker.
    @ObservedObject var videoAttachment: VideoAttachment
                            
    func getVideoThumbnail(url: URL) -> UIImage {
        let asset = AVAsset(url: url)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        
        var time = asset.duration
        time.value = min(time.value, 2)
        
        do {
            let imageRef = try imageGenerator.copyCGImage(at: time, actualTime: nil)
            return UIImage(cgImage: imageRef)
        } catch {
            print("Error generating thumbnail: \(error)")
            return UIImage(systemName: "play")!
        }
    }
    
    /// A container view for the row.
    var body: some View {
        HStack {
            
            // Define text that describes a selected photo.
            VStack(alignment: .leading) {
                Text("Hello")
            }
            
            // Add space after the description.
            Spacer()
            
            // Display the image that the text describes.
            switch videoAttachment.videoStatus {
            case .loaded(let movie):
                let image = Image(uiImage: getVideoThumbnail(url: movie.url))
                image.resizable().aspectRatio(contentMode: .fit).frame(height: 100)
            case .failed:
                Image(systemName: "exclamationmark.triangle.fill")
            default:
                ProgressView()
            }
        }.task {
            // Asynchronously display the photo.
            await videoAttachment.loadVideo()
        }
    }
}


#Preview
{
    VideoListView(viewModel: VideoViewModel())
}

