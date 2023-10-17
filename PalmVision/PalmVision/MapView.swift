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


struct DetailView: View {
    let name: String

    var body: some View {
        NavigationLink {
            Text("This is the detail view")
                .navigationTitle("Levo")
        } label: {
            Label("Another Show Detail View", systemImage: "globe")
        }
        .navigationTitle("Mando")
    }
}

struct MapView: View {
    /*
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194), // Default to San Francisco for this example
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
     */
    
    // Sample data: Replace this with your list of CLLocation
    let locations: [LocationPoint] = [
        LocationPoint(coordinate: CLLocationCoordinate2D(latitude: 37.7349, longitude: -122.4184)),
        LocationPoint(coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194))
        // Add more locations as needed
    ]
    
    @State private var selectedTag: Int?
    @State private var showSheet = false
    var body: some View {
        VStack {
            Text(selectedTag == nil ? "Nothing Selected" : "\(selectedTag!)")
                .bold()
                .padding()
            Map(selection: $selectedTag) {
                ForEach(locations.indices, id: \.self) {
                    index in Marker("palm", coordinate: locations[index].coordinate)
                        .tint(selectedTag == index + 1 ? .blue : .teal)
                        .tag(index + 1)
                    MapCircle(center: locations[index].coordinate, radius: CLLocationDistance(175))
                        .foregroundStyle(.teal.opacity(0.60))
                        .mapOverlayLevel(level: .aboveRoads)
                    
                }
            }
            .mapStyle(.standard(elevation: .realistic))
            .mapControls {
                MapUserLocationButton()
                MapCompass()
                MapScaleView()
            }
            .onTapGesture(count:2) {
                if selectedTag != nil {
                    showSheet.toggle()
                }
            }
        }
        .sheet(isPresented: $showSheet) {
            Text("FOO")
            Button("Dismiss") {
                showSheet = false
            }
        }
        /*
        .onTapGesture(count: 1) {
            if selectedTag != nil {
                showSheet.toggle()
            }
        }
         */
    }
}


struct MapView_Previews: PreviewProvider {
    static var previews: some View {
        MapView()
    }
}
