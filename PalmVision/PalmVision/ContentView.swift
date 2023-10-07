//
//  ContentView.swift
//  PalmVision
//
//  Created by Katelyn Fritz on 6/24/23.
//

import SwiftUI
import PhotosUI

struct ContentView: View {
    @State private var avatarItem: PhotosPickerItem?
    @State private var avatarImage: Image?
    
    @State private var isImagePickerShown: Bool = false
    @State private var selectedImage: PhotosPickerItem?
    @State private var selectedUiImage: UIImage?

    
    
    var body: some View {
        VStack {
            
            VStack(spacing: 20) {
                if let img = selectedUiImage {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFit()
                }
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
            .onChange(of: selectedImage) { _ in
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
                _ in
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

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
