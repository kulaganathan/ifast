//
//  TodayView.swift
//  iFast
//
//  Created by Kalaiselvan Ulaganathan on 8/11/25.
//
import SwiftUI

struct TodayView: View {
    @EnvironmentObject var fastDatabase: FastDatabase
    @EnvironmentObject var healthKitManager: HealthKitManager
    @State private var currentElapsedTime: TimeInterval = 0
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    // Computed properties for progress calculations
    private var todayFasts: [FastRecord] {
        fastDatabase.getFastRecordsForDate(Date())
    }
    
    private var currentFast: FastRecord? {
        fastDatabase.getCurrentFast()
    }
    
    private var totalFastingDuration: TimeInterval {
        var totalDuration: TimeInterval = 0
        
        // Add completed fasts
        for fast in todayFasts {
            if fast.endTime != nil { // Only completed fasts
                totalDuration += fast.duration
            }
        }
        
        // Add current fast if it started today
        if let current = currentFast {
            let calendar = Calendar.current
            if calendar.isDate(current.startTime, inSameDayAs: Date()) {
                totalDuration += currentElapsedTime
            }
        }
        
        return totalDuration
    }
    
    private var fastingProgress: Double {
        let targetHours: Double = 16.0
        let targetSeconds = targetHours * 3600
        return min(totalFastingDuration / targetSeconds, 1.0)
    }
    
    private var fastingProgressText: String {
        let hours = Int(totalFastingDuration) / 3600
        let minutes = Int(totalFastingDuration) % 3600 / 60
        return "\(hours)h \(minutes)m / 16h"
    }
    
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
                        StatCard(title: "Current Fast", value: currentFast != nil ? formatDuration(currentElapsedTime) : "Not Fasting", subtitle: "hours", color: Color(red: 0.31, green: 0.275, blue: 0.918))
                        StatCard(title: "Calories", value: "\(healthKitManager.calculateCalories(from: healthKitManager.todaySteps))", subtitle: "burned", color: .green)
                        StatCard(title: "Steps", value: "\(healthKitManager.todaySteps)", subtitle: "today", color: .orange)
                        StatCard(title: "Water", value: "6/8", subtitle: "glasses", color: Color(red: 0.06, green: 0.72, blue: 0.83))
                    }
                    .padding(.horizontal)
                    
                    // Today's Progress
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Today's Progress")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        ProgressCard(title: "Fasting Goal", progress: fastingProgress, color: Color(red: 0.31, green: 0.275, blue: 0.918), subtitle: fastingProgressText)
                        ProgressCard(title: "Steps Goal", progress: healthKitManager.getStepProgress(), color: .orange, subtitle: "\(healthKitManager.todaySteps) / \(healthKitManager.getStepGoal()) steps")
                        ProgressCard(title: "Water Goal", progress: 0.75, color: Color(red: 0.06, green: 0.72, blue: 0.83), subtitle: "6 / 8 glasses")
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationBarHidden(true)
            .onReceive(timer) { _ in
                if let fast = currentFast {
                    currentElapsedTime = Date().timeIntervalSince(fast.startTime)
                } else {
                    currentElapsedTime = 0
                }
            }
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        return String(format: "%02d:%02d", hours, minutes)
    }
}
