//
//  TabNavView.swift
//  PalmVision
//
//  Created by Katelyn Fritz on 10/21/23.
//

import Foundation
import SwiftUI

struct TabBarMainView: View {
    @StateObject private var viewModel = ImageViewModel()
    @State private var selectedTab = 0
    
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
                MapView(imagesModel: viewModel)
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
            /*
            
            NavigationView {
                NavigationLink("Go to Browse Detail", destination: Text("Browse Detail View"))
                    .navigationBarTitle("Browse", displayMode: .inline)
            }
            .tabItem {
                Image(systemName: "play")
                Text("Browse")
            }
            .tag(2)
            
            NavigationView {
                NavigationLink("Go to Radio Detail", destination: Text("Radio Detail View"))
                    .navigationBarTitle("Radio", displayMode: .inline)
            }
            .tabItem {
                Image(systemName: "message")
                Text("Radio")
            }
            .tag(3)
            
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
    }
}

struct TabBarMainView_Previews: PreviewProvider {
    static var previews: some View {
        TabBarMainView()
    }
}
