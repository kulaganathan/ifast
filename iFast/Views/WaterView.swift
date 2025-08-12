//
//  WaterView.swift
//  iFast
//
//  Created by Kalaiselvan Ulaganathan on 8/11/25.
//
import SwiftUI

struct WaterView: View {
    @State private var waterGlasses = 6
    @State private var goal = 8
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Water Progress
                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.2), lineWidth: 20)
                            .frame(width: 250, height: 250)
                        
                        Circle()
                            .trim(from: 0, to: min(Double(waterGlasses) / Double(goal), 1.0))
                            .stroke(Color(red: 0.06, green: 0.72, blue: 0.83), style: StrokeStyle(lineWidth: 20, lineCap: .round))
                            .frame(width: 250, height: 250)
                            .rotationEffect(.degrees(-90))
                            .animation(.easeInOut(duration: 1), value: waterGlasses)
                        
                        VStack {
                            Text("\(waterGlasses)")
                                .font(.system(size: 48, weight: .bold))
                            Text("of \(goal) glasses")
                                .font(.title3)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.top, 50)
                    
                    Text("\(waterGlasses * 250)ml / \(goal * 250)ml")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                
                // Add Water Button
                Button(action: {
                    if waterGlasses < goal {
                        waterGlasses += 1
                    }
                }) {
                    HStack {
                        Image(systemName: "plus")
                        Text("Add Glass")
                    }
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                    .background(waterGlasses < goal ? Color(red: 0.06, green: 0.72, blue: 0.83) : Color.gray)
                    .cornerRadius(15)
                }
                .disabled(waterGlasses >= goal)
                .padding(.horizontal, 40)
                
                Spacer()
            }
            .navigationTitle("Water")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}
