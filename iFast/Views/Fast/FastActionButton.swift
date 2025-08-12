//
//  FastButton.swift
//  iFast
//
//  Created by Kalaiselvan Ulaganathan on 8/11/25.
//
import SwiftUI

struct FastActionButton: View {

     var currentFast: FastRecord?
    @Binding var showingStopConfirmation: Bool
     var startFasting: () -> Void
     var stopFasting: () -> Void
    
    var body: some View {
        // Start/Stop Button
        Button(action: {
            if currentFast != nil {
                showingStopConfirmation = true
            } else {
                startFasting()
            }
        }) {
            HStack {
                Image(systemName: currentFast != nil ? "stop.fill" : "play.fill")
                Text(currentFast != nil ? "Stop Fast" : "Let's Start Fast")
            }
            .foregroundColor(.white)
            .padding()
            .font(.headline)
            .fontWeight(.semibold)
            .background(currentFast != nil ? Color.red : Color(red: 0.31, green: 0.275, blue: 0.918))
            .cornerRadius(10)
        }
        .alert("Stop Fast", isPresented: $showingStopConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Stop Fast", role: .destructive) {
                stopFasting()
            }
        } message: {
            Text("Are you sure you want to stop your current fast? This will log it as completed.")
        }
    }
}
