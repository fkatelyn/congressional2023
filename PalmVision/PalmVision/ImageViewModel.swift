//
//  ImageViewModel.swift
//  PalmVision
//
//  Created by Katelyn Fritz on 10/10/23.
//

import SwiftUI
import PhotosUI


@MainActor class ImageAttachment: ObservableObject, Identifiable {
    
    
/*
    //@State private var location: CLLocationCoordinate2D?
    private func extractLocation(from image: UIImage) -> CLLocationCoordinate2D{
        let options: [String: Any] = [kCGImageSourceShouldCache: false as CFBoolean]
        if let imageData = image.jpegData(compressionQuality: 1.0),
           let source = CGImageSourceCreateWithData(imageData as CFData, options as CFDictionary) {
            let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as NSDictionary?
            if let gpsInfo = properties?[kCGImagePropertyGPSDictionary] as? [String: Any],
               let latitude = gpsInfo[kCGImagePropertyGPSLatitude] as? CLLocationDegrees,
               let longitude = gpsInfo[kCGImagePropertyGPSLongitude] as? CLLocationDegrees {
                location = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                print("Latitude: \(latitude), Longitude: \(longitude)")
            } else {
                print("GPS information not found in the selected photo.")
            }
        }
    }
    
    private func extractLocation2(from image: UIImage) -> CLLocationCoordinate2D {
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
                var location: CLLocationCoordinate2D?
                location = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                print("Latitude: \(String(describing: location?.latitude)), Longitude: \(String(describing: location?.longitude))")
                return location ?? kCLLocationCoordinate2DInvalid
            }
        }
        return kCLLocationCoordinate2DInvalid
    }
*/
    
    /// Statuses that indicate the app's progress in loading a selected photo.
    enum Status {
    
        /// A status indicating that the app has requested a photo.
        case loading
        
        /// A status indicating that the app has loaded a photo.
        case finished(Image, CLLocation?)
        
        /// A status indicating that the photo has failed to load.
        case failed(Error)
        
        /// Determines whether the photo has failed to load.
        var isFailed: Bool {
            return switch self {
            case .failed: true
            default: false
            }
        }
    }
    
    /// An error that indicates why a photo has failed to load.
    enum LoadingError: Error {
        case contentTypeNotSupported
    }
    
    /// A reference to a selected photo in the picker.
    public let pickerItem: PhotosPickerItem
    
    /// A load progress for the photo.
    @Published var imageStatus: Status?
    
    /// A textual description for the photo.
    @Published var imageDescription: String = ""
    
    /// An identifier for the photo.
    nonisolated var id: String {
        pickerItem.identifier
    }
    
    /// Creates an image attachment for the given picker item.
    init(_ pickerItem: PhotosPickerItem) {
        self.pickerItem = pickerItem
    }
    
    /// Loads the photo that the picker item features.
    func loadImage() async {
        guard imageStatus == nil || imageStatus?.isFailed == true else {
            return
        }
        imageStatus = .loading
        do {
            if let data = try await pickerItem.loadTransferable(type: Data.self),
               let uiImage = UIImage(data: data) {
                print("\(pickerItem.itemIdentifier)")
                var photoLocation : CLLocation?
                if pickerItem.itemIdentifier != nil {
                    let assetId = pickerItem.itemIdentifier!
                    let assetResults = PHAsset.fetchAssets(withLocalIdentifiers: [assetId], options: nil)
                    if assetResults.count != 0 {
                        print("Creation date")
                        print(assetResults.firstObject?.creationDate ?? "No date")
                        print(assetResults.firstObject?.location?.coordinate ?? "No location")
                        photoLocation = assetResults.firstObject?.location
                    }
                }
                
                // Send it to the model for prediction
                ObjectDetection.detect(uiImage)
                imageStatus = .finished(Image(uiImage: uiImage), photoLocation)
            } else {
                throw LoadingError.contentTypeNotSupported
            }
        } catch {
            imageStatus = .failed(error)
        }
    }
}

extension ImageAttachment : Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }

    static func == (lhs: ImageAttachment, rhs: ImageAttachment) -> Bool {
        lhs.pickerItem.itemIdentifier == rhs.pickerItem.itemIdentifier
    }
}



/// A view model that integrates a Photos picker.
@MainActor final class ImageViewModel: ObservableObject {

   /// A class that manages an image that a person selects in the Photos picker.
   /// An array of items for the picker's selected photos.
    ///
    /// On set, this method updates the image attachments for the current selection.
    @Published var selection = [PhotosPickerItem]() {
        didSet {
            // Update the attachments according to the current picker selection.
            let newAttachments = selection.map { item in
                // Access an existing attachment, if it exists; otherwise, create a new attachment.
                attachmentByIdentifier[item.identifier] ?? ImageAttachment(item)
            }
            // Update the saved attachments array for any new attachments loaded in scope.
            let newAttachmentByIdentifier = newAttachments.reduce(into: [:]) { partialResult, attachment in
                partialResult[attachment.id] = attachment
            }
            // To support asynchronous access, assign new arrays to the instance properties rather than updating the existing arrays.
            attachments = newAttachments
            attachmentByIdentifier = newAttachmentByIdentifier
        }
    }
    
    /// An array of image attachments for the picker's selected photos.
    @Published var attachments = [ImageAttachment]()
    
    /// A dictionary that stores previously loaded attachments for performance.
    private var attachmentByIdentifier = [String: ImageAttachment]()
}

/// A extension that handles the situation in which a picker item lacks a photo library.
private extension PhotosPickerItem {
    var identifier: String {
        guard let identifier = itemIdentifier else {
            fatalError("The photos picker lacks a photo library.")
        }
        return identifier
    }
}
