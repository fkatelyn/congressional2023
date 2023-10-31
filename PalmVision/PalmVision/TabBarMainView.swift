//
//  TabBarMainView.swift
//  PalmVision
//
//  Created by Katelyn Fritz on 10/21/23.
//

import Foundation
import SwiftUI


// Our observable object class
class Settings: ObservableObject {
    @Published var imageAttachement: ImageAttachment?
    @Published var selectedRow: Int = 0
}


struct TabBarMainView: View {
    @StateObject private var viewModel = ImageViewModel()
    @StateObject private var videoViewModel = VideoViewModel()
    @State private var selectedTab = 0
    @StateObject var settings = Settings()

    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                AerialListView(viewModel: viewModel)
                /*
                NavigationLink("Go to Library Detail", destination: Text("Library Detail View"))
                    .navigationBarTitle("Aerial", displayMode: .inline)
                 */
            }
            .tabItem {
                Image(systemName: "list.bullet")
                Text("Aerial")
            }
            .tag(0)
            
            NavigationStack {
                MapView(imagesModel: viewModel, overwriteLocations: nil)
                /*
                NavigationLink("Go to For You Detail", destination: Text("For You Detail View"))
                    .navigationBarTitle("For You", displayMode: .inline)
                 */
            }
            .tabItem {
                Image(systemName: "map")
                Text("Map")
            }
            .tag(1)
            
            NavigationStack {
                VideoListView(viewModel: videoViewModel)
            }
            .tabItem {
                Image(systemName: "play")
                Text("Video")
            }
            .tag(2)
            
            NavigationStack {
                ChatView(imagesModel: viewModel)
            }
            .tabItem {
                Image(systemName: "message")
                Text("Chat")
            }
            .tag(3)
            
            /*
            NavigationView {
                NavigationLink("Go to Search Detail", destination: Text("Search Detail View"))
                    .navigationBarTitle("Search", displayMode: .inline)
            }
            .tabItem {
                Image(systemName: "video")
                Text("video")
            }
            .tag(4)
             */
        }
        .environmentObject(settings)
    }
}

#Preview
{
    TabBarMainView()
}
