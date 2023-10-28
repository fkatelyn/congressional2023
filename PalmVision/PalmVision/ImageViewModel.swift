//
//  ImageViewModel.swift
//  PalmVision

//  Source: Apple WWDC 2023 PhotosPicker tutorial
//  Modified by Katelyn Fritz on 10/10/23.
//

import SwiftUI
import PhotosUI

@MainActor class ImageAttachment: ObservableObject, Identifiable {
    /// Statuses that indicate the app's progress in loading a selected photo.
    enum Status {
    
        /// A status indicating that the app has requested a photo.
        case loading
        
        /// A status indicating that the app has loaded a photo.
        case finished(UIImage)
        
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
    @Published var imageLocationLat: String = ""
    @Published var imageLocationLon: String = ""
    @Published var imageAnalysis: Analysis = Analysis([])
    
    
    //@Published var isSelected: Bool = false
    
    /// An identifier for the photo.
    nonisolated var id: String {
        pickerItem.identifier
    }
    
    /// Creates an image attachment for the given picker item.
    init(_ pickerItem: PhotosPickerItem) {
        self.pickerItem = pickerItem
    }
    
    /// Loads the photo
    func loadImage() async {
        guard imageStatus == nil || imageStatus?.isFailed == true else {
            return
        }
        imageStatus = .loading
        do {
            if let data = try await pickerItem.loadTransferable(type: Data.self),
               let uiImage = UIImage(data: data) {
                var photoLocation : CLLocation?
                if pickerItem.itemIdentifier != nil {
                    let assetId = pickerItem.itemIdentifier!
                    let assetResults = PHAsset.fetchAssets(withLocalIdentifiers: [assetId], options: nil)
                    if assetResults.count != 0 {
                        photoLocation = assetResults.firstObject?.location
                        imageLocationLat = String(photoLocation?.coordinate.latitude ?? 0)
                        imageLocationLon = String(photoLocation?.coordinate.longitude ?? 0)
                    }
                }
                
                // Send it to the model for prediction
                let observations = ObjectDetection.detect(uiImage)
                imageStatus = .finished(uiImage)
                imageAnalysis = Analysis(observations)
                imageDescription = imageAnalysis.getPlantCondition().rawValue
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
