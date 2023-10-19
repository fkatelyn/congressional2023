//
//  RandomView.swift
//  PalmVision
//
//  Created by Katelyn Fritz on 10/19/23.
//

import Foundation
import SwiftUI
import CoreML
import Vision
import PhotosUI

struct RandomView: View {
    @State private var isImagePickerShown: Bool = false
    @State private var avatarItem: PhotosPickerItem?
    @State private var avatarImage: Image?
    @State private var selectedImage: PhotosPickerItem?
    @State private var selectedUiImage: UIImage?
    @State private var detectedObjects: [Observation] = []
    
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
    
    var body: some View {
        Text("Hello")
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
