//
//  LaunchScreen.swift
//  PalmVision
//
//  Created by Katelyn Fritz on 10/31/23.
//

import SwiftUI

struct LaunchScreenView: View {
    var body: some View {
        VStack {
            Image("launch")
                .resizable()
                .scaledToFit()
                //.frame(width: 100, height: 100)
            Text("Agrificial")
                .font(.largeTitle)
                .fontWeight(.bold)
        }
    }
}

#Preview {
    LaunchScreenView()
}
