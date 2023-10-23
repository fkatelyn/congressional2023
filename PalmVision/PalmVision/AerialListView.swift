//
//  ContentView.swift
//  PalmVision
//
//  Created by Katelyn Fritz on 6/24/23.
//

import SwiftUI
import PhotosUI
import CoreML
import Vision

struct AerialListView: View {
    @ObservedObject var viewModel: ImageViewModel
    @State var showMap: Bool = false
    @State var showPhotosPicker: Bool = false
    
    var body: some View {
        //NavigationStack {
            
            VStack {
                
                // Define a list for photos and descriptions.
                ImageList(viewModel: viewModel)
               /*
                // Define the app's Photos picker.
                PhotosPicker(
                    selection: $viewModel.selection,
                    
                    // Enable the app to dynamically respond to user adjustments.
                    selectionBehavior: .continuousAndOrdered,
                    matching: .images,
                    preferredItemEncoding: .current,
                    photoLibrary: .shared()
                ) {
                    Text("Select Photos")
                }
                */
                
                // Configure a half-height Photos picker.
                //.photosPickerStyle(.inline)
                
                // Disable the cancel button for an inline use case.
                //.photosPickerDisabledCapabilities(.selectionActions)
                
                // Hide padding around all edges in the picker UI.
                //.photosPickerAccessoryVisibility(.hidden, edges: .all)
                //.ignoresSafeArea()
                //.frame(height: 200)
               /*
                Button("map view") {
                    //MapView(imagesModel: viewModel)
                    showMap.toggle()
                }*/
            }
        /*
            .sheet(isPresented: $showMap) {
                MapView(imagesModel: viewModel)
            }
         */
            .navigationTitle("Aerial View")
            .ignoresSafeArea(.keyboard)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { } ) {
                        // Define the app's Photos picker.
                        PhotosPicker(
                            selection: $viewModel.selection,
                            
                            // Enable the app to dynamically respond to user adjustments.
                            selectionBehavior: .continuousAndOrdered,
                            matching: .images,
                            preferredItemEncoding: .current,
                            photoLibrary: .shared()
                        ) {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
        //}
    }
}


/// A view that lists selected photos and their descriptions.
struct ImageList: View {
    
    /// A view model for the list.
    @ObservedObject var viewModel: ImageViewModel
    
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
            List(viewModel.attachments, id: \.self) { imageAttachment in
                NavigationLink(value: imageAttachment) {
                    ImageAttachmentView(imageAttachment: imageAttachment)
                }
                .navigationDestination(for: ImageAttachment.self) {
                    item in ObjectAnalysisView(imageAttachment: item)
                }
            }
            .listStyle(.plain)
        }
    }
}

/// A row item that displays a photo and a description.
struct ImageAttachmentView: View {
    
    /// An image that a person selects in the Photos picker.
    @ObservedObject var imageAttachment: ImageAttachment
    
    /// A container view for the row.
    var body: some View {
        HStack {
            
            // Define text that describes a selected photo.
            VStack(alignment: .leading) {
                Text(imageAttachment.imageDescription)
                Text("Trees: \(imageAttachment.imageAnalysis.treeCountsText)")
            }
            
            // Add space after the description.
            Spacer()
            
            // Display the image that the text describes.
            switch imageAttachment.imageStatus {
            case .finished(let uiImage):
                let image = Image(uiImage: uiImage)
                image.resizable().aspectRatio(contentMode: .fit).frame(height: 100)
            case .failed:
                Image(systemName: "exclamationmark.triangle.fill")
            default:
                ProgressView()
            }
        }.task {
            // Asynchronously display the photo.
            await imageAttachment.loadImage()
        }
    }
}


#Preview
{
    AerialListView(viewModel: ImageViewModel())
}
