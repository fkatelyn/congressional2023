//
//  VideoViewModel.swift
//  PalmVision
//
//  Created by Katelyn Fritz on 10/25/23.
//

import SwiftUI
import PhotosUI

struct Movie: Transferable {
    let url: URL
    
    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { movie in
            SentTransferredFile(movie.url)
        } importing: { receivedData in
            let fileName = receivedData.file.lastPathComponent
            let copy: URL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
            
            if FileManager.default.fileExists(atPath: copy.path) {
                try FileManager.default.removeItem(at: copy)
            }
            
            try FileManager.default.copyItem(at: receivedData.file, to: copy)
            return .init(url: copy)
        }
    }
}

@MainActor class VideoAttachment: ObservableObject, Identifiable {
    /// Statuses that indicate the app's progress in loading a selected photo.
    enum Status {
        
        case unknown
    
        case loading
        
        case loaded(Movie)
        
        case failed
        
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
    @Published var videoStatus: Status?
    
    /// A textual description for the photo.
    @Published var videoDescription: String = ""
    
    /// An identifier for the photo.
    nonisolated var id: String {
        pickerItem.identifier
    }
    
    /// Creates an image attachment for the given picker item.
    init(_ pickerItem: PhotosPickerItem) {
        self.pickerItem = pickerItem
    }
    
    /// Loads the photo
    func loadVideo() async {
        guard videoStatus == nil || videoStatus?.isFailed == true else {
            return
        }
        videoStatus = .loading
        do {
            if let data = try await pickerItem.loadTransferable(type: Movie.self) {
                videoStatus = .loaded(data)
            } else {
                videoStatus = .failed
            }
        } catch {
            videoStatus = .failed
        }
    }
}

extension VideoAttachment : Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }

    static func == (lhs: VideoAttachment, rhs: VideoAttachment) -> Bool {
        lhs.pickerItem.itemIdentifier == rhs.pickerItem.itemIdentifier
    }
}

/// A view model that integrates a Photos picker.
@MainActor final class VideoViewModel: ObservableObject {

   /// A class that manages an image that a person selects in the Photos picker.
   /// An array of items for the picker's selected photos.
    ///
    /// On set, this method updates the image attachments for the current selection.
    @Published var selection = [PhotosPickerItem]() {
        didSet {
            // Update the attachments according to the current picker selection.
            let newAttachments = selection.map { item in
                // Access an existing attachment, if it exists; otherwise, create a new attachment.
                attachmentByIdentifier[item.identifier] ?? VideoAttachment(item)
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
    @Published var attachments = [VideoAttachment]()
    
    /// A dictionary that stores previously loaded attachments for performance.
    private var attachmentByIdentifier = [String: VideoAttachment]()
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
