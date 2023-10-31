//
//  MapView.swift
//  PalmVision
//
//  Created by Katelyn Fritz on 10/15/23.
//

import Foundation
import SwiftUI
import MapKit

struct LocationPoint: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}

struct MapView: View {
    @ObservedObject var imagesModel: ImageViewModel
    var overwriteLocations: LocationsContainer?
    @EnvironmentObject var settings: Settings
    @State private var selectedTag: Int?
    @State private var showSheet = false
  
    
    func attachmentToLocation(_ attachment: ImageAttachment) -> LocationPoint {
        print("\(attachment.imageLocationLat) \(attachment.imageLocationLon)")
        return LocationPoint(coordinate: CLLocationCoordinate2D(
            latitude: Double(attachment.imageLocationLat) ?? 0,
            longitude: Double(attachment.imageLocationLon) ?? 0))
    }
    
    var locations: [LocationPoint] {
        if overwriteLocations != nil {
            var computedLocations: [LocationPoint] = []
           
            var locations = overwriteLocations!.lastMentionedLocations
            for location in locations {
                computedLocations.append(
                    LocationPoint(coordinate: CLLocationCoordinate2D(
                        latitude: location.latitude,
                        longitude: location.longitude)))
            }
            return computedLocations
        }
        var computedLocations: [LocationPoint] = []
        
        for attachment in imagesModel.attachments {
            if attachment.imageLocationLat == "0" || attachment.imageLocationLat == "" ||
                attachment.imageLocationLon == "0" || attachment.imageLocationLon == "" {
                
            } else {
                computedLocations.append(
                    LocationPoint(coordinate: CLLocationCoordinate2D(
                        latitude: Double(attachment.imageLocationLat) ?? 0,
                        longitude: Double(attachment.imageLocationLon) ?? 0)))
            }
        }
        return computedLocations
    }
    
    
   var body: some View {
        VStack {
            /*
            Text(selectedTag == nil ? "Nothing Selected" : "\(selectedTag!)")
                .bold()
                .padding()
             */
            Map(selection: $selectedTag) {
                if overwriteLocations != nil {
                    let locations = overwriteLocations!.lastMentionedLocations
                    ForEach(locations) {
                        location in
                        let coordinate = CLLocationCoordinate2D(
                            latitude: location.latitude,
                            longitude: location.longitude)
                        Marker("\(location.id)", coordinate: coordinate)
                            .tint(.blue)
                    }
                } else {
                    ForEach(imagesModel.attachments.indices, id: \.self) {
                        index in
                        let attachment = imagesModel.attachments[index]
                        let location = attachmentToLocation(attachment)
                        Marker("\(index + 1)", coordinate: location.coordinate)
                            .tint(.blue)
                    }
                }
            }
            .mapStyle(.imagery(elevation: .realistic))
            .mapControls {
                MapCompass()
                MapScaleView()
            }
            .onAppear {
                if settings.imageAttachement != nil {
                    for index in imagesModel.attachments.indices {
                        if imagesModel.attachments[index] == settings.imageAttachement {
                            selectedTag = index + 1
                        }
                    }
                }
            }
            .onChange(of: selectedTag) {
                if selectedTag != nil {
                    for index in imagesModel.attachments.indices {
                        if index + 1 == selectedTag {
                            let a = imagesModel.attachments[index]
                            settings.imageAttachement = a
                        }
                    }
                }
            }
       }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if selectedTag != nil {
                    Button(action: {
                        if selectedTag != nil {
                            showSheet = true
                        }
                    }) {
                        Image(systemName: "magnifyingglass")
                    }
                    .navigationDestination(isPresented: $showSheet) {
                        if selectedTag != nil && selectedTag! <= imagesModel.attachments.count {
                            ObjectAnalysisView(imageAttachment: imagesModel.attachments[selectedTag!-1])
                        }
                    }
                }
            }
        }
    }
}

#Preview
{
    MapView(imagesModel: ImageViewModel())
}
