//
//  ContentView.swift
//  iFast
//
//  Created by Kalaiselvan Ulaganathan on 8/6/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            TodayView()
                .tabItem {
                    Image(systemName: "calendar")
                    Text("Today")
                }
            
            FastView()
                .tabItem {
                    Image(systemName: "timer")
                    Text("Fast")
                }
            
            StepsView()
                .tabItem {
                    Image(systemName: "figure.walk")
                    Text("Steps")
                }
            
            WaterView()
                .tabItem {
                    Image(systemName: "drop.fill")
                    Text("Water")
                }
        }
        .accentColor(.blue)
    }
}

struct TodayView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Today")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Track your daily progress")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    
                    // Quick Stats Cards
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                        StatCard(title: "Current Fast", value: "16:24", subtitle: "hours", color: .blue)
                        StatCard(title: "Calories", value: "0", subtitle: "burned", color: .green)
                        StatCard(title: "Steps", value: "8,432", subtitle: "today", color: .orange)
                        StatCard(title: "Water", value: "6/8", subtitle: "glasses", color: .cyan)
                    }
                    .padding(.horizontal)
                    
                    // Today's Progress
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Today's Progress")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        ProgressCard(title: "Fasting Goal", progress: 0.68, color: .blue)
                        ProgressCard(title: "Steps Goal", progress: 0.84, color: .orange)
                        ProgressCard(title: "Water Goal", progress: 0.75, color: .cyan)
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationBarHidden(true)
        }
    }
}

struct FastView: View {
    @State private var isFasting = false
    @State private var fastingStartTime: Date?
    @State private var elapsedTime: TimeInterval = 0
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Timer Display
                VStack(spacing: 20) {
                    Text(timeString(from: elapsedTime))
                        .font(.system(size: 60, weight: .thin, design: .monospaced))
                        .foregroundColor(isFasting ? .blue : .secondary)
                    
                    Text(isFasting ? "Fasting" : "Not Fasting")
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(isFasting ? .blue : .secondary)
                }
                .padding(.top, 50)
                
                // Start/Stop Button
                Button(action: {
                    if isFasting {
                        stopFasting()
                    } else {
                        startFasting()
                    }
                }) {
                    Text(isFasting ? "Stop Fast" : "Start Fast")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(isFasting ? Color.red : Color.blue)
                        .cornerRadius(15)
                }
                .padding(.horizontal, 40)
                
                // Fast History
                VStack(alignment: .leading, spacing: 16) {
                    Text("Recent Fasts")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    VStack(spacing: 12) {
                        FastHistoryRow(date: "Yesterday", duration: "18:32", type: "16:8")
                        FastHistoryRow(date: "2 days ago", duration: "16:45", type: "16:8")
                        FastHistoryRow(date: "3 days ago", duration: "14:20", type: "14:10")
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("Fast")
            .navigationBarTitleDisplayMode(.large)
            .onReceive(timer) { _ in
                if isFasting {
                    elapsedTime = Date().timeIntervalSince(fastingStartTime ?? Date())
                }
            }
        }
    }
    
    private func startFasting() {
        isFasting = true
        fastingStartTime = Date()
        elapsedTime = 0
    }
    
    private func stopFasting() {
        isFasting = false
        fastingStartTime = nil
        elapsedTime = 0
    }
    
    private func timeString(from timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = Int(timeInterval) % 3600 / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}

struct StepsView: View {
    @State private var steps = 8432
    @State private var goal = 10000
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Steps Circle
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 20)
                        .frame(width: 250, height: 250)
                    
                    Circle()
                        .trim(from: 0, to: min(Double(steps) / Double(goal), 1.0))
                        .stroke(Color.orange, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                        .frame(width: 250, height: 250)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 1), value: steps)
                    
                    VStack {
                        Text("\(steps)")
                            .font(.system(size: 48, weight: .bold))
                        Text("of \(goal)")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.top, 50)
                
                // Stats
                HStack(spacing: 40) {
                    VStack {
                        Text("\(steps)")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("Steps")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack {
                        Text("\(Int(Double(steps) * 0.04))")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("Calories")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack {
                        Text("\(Int(Double(steps) * 0.0005))")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("Miles")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
            .navigationTitle("Steps")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

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
                            .stroke(Color.cyan, style: StrokeStyle(lineWidth: 20, lineCap: .round))
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
                    .background(waterGlasses < goal ? Color.cyan : Color.gray)
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

// Helper Views
struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct ProgressCard: View {
    let title: String
    let progress: Double
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text("\(Int(progress * 100))%")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(color)
            }
            
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: color))
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct FastHistoryRow: View {
    let date: String
    let duration: String
    let type: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(date)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(type)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(duration)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.blue)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    ContentView()
}
