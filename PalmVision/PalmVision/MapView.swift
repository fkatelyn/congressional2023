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
    
    func attachmentToLocation(_ attachment: ImageAttachment) -> LocationPoint {
        print("\(attachment.imageLocationLat) \(attachment.imageLocationLon)")
        return LocationPoint(coordinate: CLLocationCoordinate2D(
            latitude: Double(attachment.imageLocationLat) ?? 0,
            longitude: Double(attachment.imageLocationLon) ?? 0))
    }
    
    var locations: [LocationPoint] {
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
    
    
    @State private var selectedTag: Int?
    @State private var showSheet = false
    var body: some View {
        VStack {
            Text(selectedTag == nil ? "Nothing Selected" : "\(selectedTag!)")
                .bold()
                .padding()
            Map(selection: $selectedTag) {
                ForEach(imagesModel.attachments.indices, id: \.self) {
                    index in
                    let attachment = imagesModel.attachments[index]
                    let location = attachmentToLocation(attachment)
                    Marker("palm", coordinate: location.coordinate)
                        .tint(selectedTag == index + 1 ? .blue :
                                attachment.imageAnalysis.isHealthy() ? .green : .red)
                        .tag(index + 1)
                }
            }
            .mapStyle(.imagery(elevation: .realistic))
            .mapControls {
                MapCompass()
                MapScaleView()
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
                        if selectedTag != nil {
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
