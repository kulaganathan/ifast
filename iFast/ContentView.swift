//
//  ContentView.swift
//  iFast
//
//  Created by Kalaiselvan Ulaganathan on 8/6/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var fastDatabase = FastDatabase()
    
    var body: some View {
        TabView {
            TodayView()
                .environmentObject(fastDatabase)
                .tabItem {
                    Image(systemName: "calendar")
                    Text("Today")
                }
            
            FastView()
                .environmentObject(fastDatabase)
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
    @EnvironmentObject var fastDatabase: FastDatabase
    @StateObject private var healthKitManager = HealthKitManager()
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
                        StatCard(title: "Current Fast", value: currentFast != nil ? formatDuration(currentElapsedTime) : "Not Fasting", subtitle: "hours", color: .blue)
                        StatCard(title: "Calories", value: "\(healthKitManager.calculateCalories(from: healthKitManager.todaySteps))", subtitle: "burned", color: .green)
                        StatCard(title: "Steps", value: "\(healthKitManager.todaySteps)", subtitle: "today", color: .orange)
                        StatCard(title: "Water", value: "6/8", subtitle: "glasses", color: .cyan)
                    }
                    .padding(.horizontal)
                    
                    // Today's Progress
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Today's Progress")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        ProgressCard(title: "Fasting Goal", progress: fastingProgress, color: .blue, subtitle: fastingProgressText)
                        ProgressCard(title: "Steps Goal", progress: healthKitManager.getStepProgress(), color: .orange, subtitle: "\(healthKitManager.todaySteps) / \(healthKitManager.getStepGoal()) steps")
                        ProgressCard(title: "Water Goal", progress: 0.75, color: .cyan, subtitle: "6 / 8 glasses")
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

struct FastView: View {
    @EnvironmentObject var fastDatabase: FastDatabase
    @State private var selectedFastType: FastType = .sixteenEight
    @State private var showingFastTypePicker = false
    @State private var notes: String = ""
    @State private var showingNotesSheet = false
    @State private var currentElapsedTime: TimeInterval = 0
    @State private var showingStopConfirmation = false
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var currentFast: FastRecord? {
        fastDatabase.getCurrentFast()
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    // Timer Display
                    VStack(spacing: 20) {
                        if let fast = currentFast {
                            Text(timeString(from: currentElapsedTime))
                                .font(.system(size: 60, weight: .thin, design: .monospaced))
                                .foregroundColor(.blue)
                            
                            Text("Fasting - \(fast.type.displayName)")
                                .font(.title2)
                                .fontWeight(.medium)
                                .foregroundColor(.blue)
                        } else {
                            Text("00:00:00")
                                .font(.system(size: 60, weight: .thin, design: .monospaced))
                                .foregroundColor(.secondary)
                            
                            Text("Not Fasting")
                                .font(.title2)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.top, 50)
                    .onReceive(timer) { _ in
                        if let fast = currentFast {
                            currentElapsedTime = Date().timeIntervalSince(fast.startTime)
                        } else {
                            currentElapsedTime = 0
                        }
                    }
                    
                    // Fast Type Selector
                    if currentFast == nil {
                        Button(action: {
                            showingFastTypePicker = true
                        }) {
                            HStack {
                                Text("Fast Type: \(selectedFastType.displayName)")
                                    .font(.headline)
                                Image(systemName: "chevron.down")
                            }
                            .foregroundColor(.blue)
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(10)
                        }
                        .actionSheet(isPresented: $showingFastTypePicker) {
                            ActionSheet(
                                title: Text("Select Fast Type"),
                                buttons: FastType.allCases.map { fastType in
                                    .default(Text(fastType.displayName)) {
                                        selectedFastType = fastType
                                    }
                                } + [.cancel()]
                            )
                        }
                    }
                    
                    // Start/Stop Button
                    Button(action: {
                        if currentFast != nil {
                            showingStopConfirmation = true
                        } else {
                            startFasting()
                        }
                    }) {
                        Text(currentFast != nil ? "Stop Fast" : "Start Fast")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 60)
                            .background(currentFast != nil ? Color.red : Color.blue)
                            .cornerRadius(15)
                    }
                    .padding(.horizontal, 40)
                    .alert("Stop Fast", isPresented: $showingStopConfirmation) {
                        Button("Cancel", role: .cancel) { }
                        Button("Stop Fast", role: .destructive) {
                            stopFasting()
                        }
                    } message: {
                        Text("Are you sure you want to stop your current fast? This will log it as completed.")
                    }
                    
                    // Notes Button
                    if currentFast != nil {
                        Button(action: {
                            showingNotesSheet = true
                        }) {
                            HStack {
                                Image(systemName: "note.text")
                                Text("Add Notes")
                            }
                            .font(.headline)
                            .foregroundColor(.blue)
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(10)
                        }
                    }
                    
                    // Fast History
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Recent Fasts")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        if fastDatabase.fastRecords.isEmpty {
                            Text("No fasting history yet")
                                .foregroundColor(.secondary)
                                .padding()
                        } else {
                            LazyVStack(spacing: 12) {
                                ForEach(fastDatabase.fastRecords) { record in
                                    FastHistoryRow(record: record)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Add some bottom padding for better scrolling
                    Spacer(minLength: 50)
                }
            }
            .navigationTitle("Fast")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingNotesSheet) {
                NotesSheet(notes: $notes, onSave: {
                    updateFastNotes()
                })
            }
        }
    }
    
    private func startFasting() {
        let newFast = FastRecord(startTime: Date(), type: selectedFastType)
        fastDatabase.saveFastRecord(newFast)
    }
    
    private func stopFasting() {
        guard let currentFast = currentFast else { return }
        
        // Create updated record with the same ID but with end time
        let updatedFast = FastRecord(
            id: currentFast.id,
            startTime: currentFast.startTime,
            endTime: Date(),
            duration: Date().timeIntervalSince(currentFast.startTime),
            type: currentFast.type,
            notes: currentFast.notes,
            createdAt: currentFast.createdAt
        )
        
        fastDatabase.updateFastRecord(updatedFast)
    }
    
    private func updateFastNotes() {
        guard let currentFast = currentFast else { return }
        
        // Create updated record with the same ID but with new notes
        let updatedFast = FastRecord(
            id: currentFast.id,
            startTime: currentFast.startTime,
            endTime: currentFast.endTime,
            duration: currentFast.duration,
            type: currentFast.type,
            notes: notes.isEmpty ? nil : notes,
            createdAt: currentFast.createdAt
        )
        
        fastDatabase.updateFastRecord(updatedFast)
        notes = ""
    }
    
    private func timeString(from timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = Int(timeInterval) % 3600 / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}

struct NotesSheet: View {
    @Binding var notes: String
    let onSave: () -> Void
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack {
                TextEditor(text: $notes)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding()
                
                Spacer()
            }
            .navigationTitle("Add Notes")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Save") {
                    onSave()
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

struct FastHistoryRow: View {
    let record: FastRecord
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(formatDate(record.startTime))
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(record.type.displayName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(formatDuration(record.duration))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
                
                if record.notes != nil {
                    Image(systemName: "note.text")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        return String(format: "%02d:%02d", hours, minutes)
    }
}

struct StepsView: View {
    @StateObject private var healthKitManager = HealthKitManager()
    @State private var showingPermissionAlert = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Steps Circle
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 20)
                        .frame(width: 250, height: 250)
                    
                    Circle()
                        .trim(from: 0, to: healthKitManager.getStepProgress())
                        .stroke(Color.orange, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                        .frame(width: 250, height: 250)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 1), value: healthKitManager.todaySteps)
                    
                    VStack {
                        if healthKitManager.isLoading {
                            ProgressView()
                                .scaleEffect(1.5)
                        } else {
                            Text("\(healthKitManager.todaySteps)")
                                .font(.system(size: 48, weight: .bold))
                            Text("of \(healthKitManager.getStepGoal())")
                                .font(.title3)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.top, 50)
                
                // Stats
                HStack(spacing: 40) {
                    VStack {
                        Text("\(healthKitManager.todaySteps)")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("Steps")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack {
                        Text("\(healthKitManager.calculateCalories(from: healthKitManager.todaySteps))")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("Calories")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack {
                        Text(String(format: "%.1f", healthKitManager.calculateDistance(from: healthKitManager.todaySteps)))
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("Miles")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Permission Status
                if !healthKitManager.isAuthorized {
                    VStack(spacing: 16) {
                        Image(systemName: "heart.slash")
                            .font(.system(size: 50))
                            .foregroundColor(.orange)
                        
                        Text("Health Access Required")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("To track your steps, please allow access to Health data in Settings.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button("Grant Permission") {
                            showingPermissionAlert = true
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.orange)
                        .cornerRadius(10)
                    }
                    .padding()
                }
                
                // Refresh Button
                Button(action: {
                    healthKitManager.refreshSteps()
                }) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Refresh Steps")
                    }
                    .font(.headline)
                    .foregroundColor(.orange)
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(10)
                }
                
                Spacer()
            }
            .navigationTitle("Steps")
            .navigationBarTitleDisplayMode(.large)
            .alert("Health Permission", isPresented: $showingPermissionAlert) {
                Button("Open Settings") {
                    if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsUrl)
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Please enable Health access in Settings to track your steps.")
            }
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
    let subtitle: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text(subtitle ?? "\(Int(progress * 100))%")
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

#Preview {
    ContentView()
}
