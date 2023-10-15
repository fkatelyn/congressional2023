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

struct Observation {
    let label: String
    let confidence: VNConfidence
    let boundingBox: CGRect
}

struct ContentView: View {
    @State private var avatarItem: PhotosPickerItem?
    @State private var avatarImage: Image?
    
    @State private var isImagePickerShown: Bool = false
    @State private var selectedImage: PhotosPickerItem?
    @State private var selectedUiImage: UIImage?
    
    @State private var detectedObjects: [Observation] = []
    
    
    @StateObject private var viewModel = ImageViewModel()



    let compiledModel = try! best(configuration: MLModelConfiguration())
    private var overlayView: some View {
        GeometryReader { geometry in
            Path { path in
                for observation in detectedObjects {
                    let rect = VNImageRectForNormalizedRect(observation.boundingBox, Int(geometry.size.width), Int(geometry.size.height))
                    let cgRect = CGRect(x: rect.origin.x, y: geometry.size.height - rect.origin.y - rect.size.height, width: rect.size.width, height: rect.size.height)
                    path.addRect(cgRect)
                }
            }
            .stroke(Color.red, lineWidth: 2)
        }
    }
    
    let assetName = "palm"
    let assetImage = UIImage(named: "palm")
   
    /// A body property for the app's UI.
    var body: some View {
        NavigationStack {
            VStack {
                
                // Define a list for photos and descriptions.
                ImageList(viewModel: viewModel)
                
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
                
                // Configure a half-height Photos picker.
                //.photosPickerStyle(.inline)
                
                // Disable the cancel button for an inline use case.
                //.photosPickerDisabledCapabilities(.selectionActions)
                
                // Hide padding around all edges in the picker UI.
                //.photosPickerAccessoryVisibility(.hidden, edges: .all)
                .ignoresSafeArea()
                .frame(height: 200)
            }
            .navigationTitle("Aerial View")
            .ignoresSafeArea(.keyboard)
        }
    }

    @State private var location: CLLocationCoordinate2D?

    private func extractLocation(from image: UIImage) {
        if let ciImage = CIImage(image: image) {
            let options = [CIDetectorAccuracy: CIDetectorAccuracyHigh]
            let context = CIContext(options: nil)
            let features = CIDetector(ofType: CIDetectorTypeQRCode, context: context, options: options)
            
            if let feature = features?.features(in: ciImage).first as? CIQRCodeFeature,
               let messageString = feature.messageString,
               let data = messageString.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
               let latitude = json["latitude"] as? CLLocationDegrees,
               let longitude = json["longitude"] as? CLLocationDegrees {
                location = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                print("Latitude: \(latitude), Longitude: \(longitude)")
            }
        }
    }
    
    var abody: some View {
        VStack {
            
            VStack(spacing: 20) {
                Image(assetName)
                    .resizable()
                    .scaledToFit()
                    .overlay(overlayView)
                /*
                
                if let img = selectedUiImage {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFit()
                        .overlay(overlayView)
                }
                 */
                Button(
                    action: { isImagePickerShown = true }
                ) {
                    Text("Pick Image using PhotosPicker")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            
            .photosPicker(isPresented: $isImagePickerShown,
                          selection: $selectedImage,
                          matching: .images,
                          photoLibrary: .shared())
            .onChange(of: selectedImage) { _, _ in
                Task {
                    if let data = try? await selectedImage?.loadTransferable(type: Data.self) {
                        if let uiImage = UIImage(data: data) {
                            self.selectedUiImage = uiImage
                            extractLocation(from: uiImage)
                            return
                        }
                    }
                    
                    print("Failed")
                }         
            }
            Button("Predict") {
                let mlModel = compiledModel.model
                guard let coreMlModel = try? VNCoreMLModel(for: mlModel) else { return }
                let request = VNCoreMLRequest(model: coreMlModel) {
                    request, error in
                    guard let results = request.results as? [VNRecognizedObjectObservation] else {
                        return
                    }

                    detectedObjects = results.map { result in
                        guard let label = result.labels.first?.identifier else {
                            return Observation(label: "", confidence: VNConfidence.zero, boundingBox: .zero)
                        }
                        let confidence = result.labels.first?.confidence ?? 0.0
                        let boundingBox = result.boundingBox
                        print("\(label) \(confidence)")
                        return Observation(label: label, confidence: confidence, boundingBox: boundingBox)
                    }
                }
                //guard let image = selectedUiImage,
                guard let image = UIImage(named: assetName),
                      let cgImage = image.cgImage else { return }
                let requestHandler = VNImageRequestHandler(cgImage: cgImage)
                do {
                    try requestHandler.perform([request])
                } catch {
                    print(error.localizedDescription)
                }
            }
            /*{ result in
                switch result {
                case .success(let photos):
                    // For simplicity, taking the first image. You can handle multiple images if needed.
                    if let firstPhoto = photos.first {
                        // Requesting the UIImage representation of the photo.
                        firstPhoto.requestUIImage { uiImage in
                            self.selectedUiImage = uiImage
                        }
                    }
                case .failure(let error):
                    // Handle any errors here.
                    print("Error picking photo: \(error)")
                }
            }
             */
             
        
            VStack {
                PhotosPicker("Select avatar", selection: $avatarItem, matching: .images)
                
                if let avatarImage {
                    avatarImage
                        .resizable()
                        .scaledToFit()
                        .frame(width: 300, height: 300)
                    
                }
            }
            .onChange(of: avatarItem) {
                _, _ in
                Task {
                    if let data = try? await avatarItem?.loadTransferable(type: Data.self) {
                        if let uiImage = UIImage(data: data) {
                            avatarImage = Image(uiImage: uiImage)
                            return
                        }
                    }
                    
                    print("Failed")
                }
            }
            HStack(alignment: .center, spacing: 10) {
                // Body/Bold
                Text("Image")
                  .font(
                    Font.custom("SF Pro Text", size: 17)
                      .weight(.semibold)
                  )
                  .multilineTextAlignment(.center)
                  .foregroundColor(.white)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(Color(red: 0, green: 0.48, blue: 1))
            .cornerRadius(14)
            
            HStack(alignment: .center, spacing: 10) {
                // Body/Bold
                Text("Video")
                  .font(
                    Font.custom("SF Pro Text", size: 17)
                      .weight(.semibold)
                  )
                  .multilineTextAlignment(.center)
                  .foregroundColor(.white)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(Color(red: 0, green: 0.48, blue: 1))
            .cornerRadius(14)
        }
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
            List(viewModel.attachments) { imageAttachment in
                ImageAttachmentView(imageAttachment: imageAttachment)
            }.listStyle(.plain)
        }
    }
}

/// A row item that displays a photo and a description.
struct ImageAttachmentView: View {
    
    /// An image that a person selects in the Photos picker.
    @ObservedObject var imageAttachment: ImageViewModel.ImageAttachment
    
    /// A container view for the row.
    var body: some View {
        HStack {
            
            // Define text that describes a selected photo.
            TextField("Image Description", text: $imageAttachment.imageDescription)
            
            // Add space after the description.
            Spacer()
            
            // Display the image that the text describes.
            switch imageAttachment.imageStatus {
            case .finished(let image, let location):
                image.resizable().aspectRatio(contentMode: .fit).frame(height: 100)
                let locationString = "\(location?.coordinate.latitude), \(location?.coordinate.longitude)"
                Text(locationString)
                //Text("longitude: \(location?.coordinate.longitude), latitude: \(location?.coordinate.latitude)")
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


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
