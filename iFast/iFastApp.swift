//
//  iFastApp.swift
//  iFast
//
//  Created by Kalaiselvan Ulaganathan on 8/6/25.
//

import SwiftUI

@main
struct iFastApp: App {
    @StateObject private var authManager = AuthManager()
    
    var body: some Scene {
        WindowGroup {
            Group {
                if authManager.isAuthenticated {
                    ContentView()
                        .environmentObject(authManager)
                } else {
                    LoginView()
                        .environmentObject(authManager)
                }
            }
            .animation(.easeInOut, value: authManager.isAuthenticated)
        }
    }
}
