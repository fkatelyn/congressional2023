//
//  PalmVisionApp.swift
//  PalmVision
//
//  Created by Katelyn Fritz on 6/24/23.
//

import SwiftUI

@main
struct PalmVisionApp: App {
    @State private var isActive: Bool = false
    var body: some Scene {
        WindowGroup {
            if isActive {
                ContentView()
            } else {
                LaunchScreen()
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation {
                                self.isActive = true
                            }
                        }
                    }
            }
        }
    }
    
    /*var body: some Scene {
     WindowGroup {
     ContentView()
     }
     }*/
}
