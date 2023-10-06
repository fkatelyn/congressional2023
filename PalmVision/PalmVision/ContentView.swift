//
//  ContentView.swift
//  PalmVision
//
//  Created by Katelyn Fritz on 6/24/23.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image("palmtree")
                .resizable()
                .aspectRatio(contentMode: .fit)
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundColor(.accentColor)
            Text("Hello, world!")
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
