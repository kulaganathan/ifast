//
//  ContentView.swift
//  iFast
//
//  Created by Kalaiselvan Ulaganathan on 8/6/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var fastDatabase = FastDatabase()
    @StateObject private var healthKitManager = HealthKitManager()
    
    var body: some View {
        TabView {
            TodayView()
                .environmentObject(fastDatabase)
                .environmentObject(healthKitManager)
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
                .environmentObject(healthKitManager)
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
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            healthKitManager.applicationDidBecomeActive()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            healthKitManager.applicationWillEnterForeground()
        }
    }
}

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

struct FastView: View {
    @EnvironmentObject var fastDatabase: FastDatabase
    @State private var selectedFastType: FastType = .sixteenEight
    @State private var showingFastTypePicker = false
    @State private var notes: String = ""
    @State private var showingNotesSheet = false
    @State private var currentElapsedTime: TimeInterval = 0
    @State private var showingStopConfirmation = false
    @State private var showingEditSheet = false
    @State private var selectedDate: Date = Date()
    @State private var editingHours: String = ""
    @State private var editingMinutes: String = ""
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var currentFast: FastRecord? {
        fastDatabase.getCurrentFast()
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    // Fasting Dial
                    ZStack {
                        // Background circle
                        Circle()
                            .stroke(Color(red: 0.31, green: 0.275, blue: 0.918).opacity(0.2), lineWidth: 25)
                            .frame(width: 300, height: 300)
                        
                        // Progress circle
                        Circle()
                            .trim(from: 0, to: getFastingProgress())
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(red: 0.31, green: 0.275, blue: 0.918),
                                        Color(red: 0.4, green: 0.35, blue: 0.95)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                style: StrokeStyle(lineWidth: 25, lineCap: .round)
                            )
                            .frame(width: 300, height: 300)
                            .rotationEffect(.degrees(-90))
                            .animation(.easeInOut(duration: 1), value: currentElapsedTime)
                        
                        // Center content
                        VStack(spacing: 8) {
                            if let fast = currentFast {
                                Text(timeString(from: currentElapsedTime))
                                    .font(.system(size: 48, weight: .thin, design: .monospaced))
                                    .foregroundColor(Color(red: 0.31, green: 0.275, blue: 0.918))
                                
                                Text("Fasting")
                                    .font(.title3)
                                    .fontWeight(.medium)
                                    .foregroundColor(Color(red: 0.31, green: 0.275, blue: 0.918))
                                
                                Text(fast.type.displayName)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 4)
                                    .background(Color(red: 0.31, green: 0.275, blue: 0.918).opacity(0.1))
                                    .cornerRadius(8)
                            } else {
                                Text("00:00:00")
                                    .font(.system(size: 48, weight: .thin, design: .monospaced))
                                    .foregroundColor(.secondary)
                                
                                Text("Not Fasting")
                                    .font(.title3)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                                
                                Text("Ready to start")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.top, 30)
                    .onReceive(timer) { _ in
                        if let fast = currentFast {
                            currentElapsedTime = Date().timeIntervalSince(fast.startTime)
                        } else {
                            currentElapsedTime = 0
                        }
                    }
                    
                    // Progress Info
                    if let fast = currentFast {
                        VStack(spacing: 12) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Target")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("\(fast.type.targetHours) hours")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing) {
                                    Text("Completed")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("\(Int(currentElapsedTime / 3600))h \(Int((currentElapsedTime.truncatingRemainder(dividingBy: 3600)) / 60))m")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(Color(red: 0.31, green: 0.275, blue: 0.918))
                                }
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            
                            // Progress percentage
                            Text("\(Int(getFastingProgress() * 100))% Complete")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(Color(red: 0.31, green: 0.275, blue: 0.918))
                        }
                        .padding(.horizontal)
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
                            .foregroundColor(Color(red: 0.31, green: 0.275, blue: 0.918))
                            .padding()
                            .background(Color(red: 0.31, green: 0.275, blue: 0.918).opacity(0.1))
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
                        HStack {
                            Image(systemName: currentFast != nil ? "stop.fill" : "play.fill")
                            Text(currentFast != nil ? "Stop Fast" : "Start Fast")
                        }
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(currentFast != nil ? Color.red : Color(red: 0.31, green: 0.275, blue: 0.918))
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
                            .foregroundColor(Color(red: 0.31, green: 0.275, blue: 0.918))
                            .padding()
                            .background(Color(red: 0.31, green: 0.275, blue: 0.918).opacity(0.1))
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
                            // Horizontal scrollable tall bars
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(Array(getRecentDays().enumerated()), id: \.offset) { index, date in
                                        TallDayFastBar(
                                            date: date,
                                            fastRecords: fastDatabase.getFastRecordsForDate(date),
                                            isToday: Calendar.current.isDateInToday(date),
                                            isFuture: date > Date(),
                                            onTap: {
                                                if date < Date() && !Calendar.current.isDateInToday(date) {
                                                    selectedDate = date
                                                    let records = fastDatabase.getFastRecordsForDate(date)
                                                    if let firstRecord = records.first {
                                                        let totalHours = firstRecord.duration / 3600
                                                        editingHours = "\(Int(totalHours))"
                                                        editingMinutes = "\(Int((firstRecord.duration.truncatingRemainder(dividingBy: 3600)) / 60))"
                                                    } else {
                                                        editingHours = "0"
                                                        editingMinutes = "0"
                                                    }
                                                    showingEditSheet = true
                                                }
                                            }
                                        )
                                    }
                                }
                                .padding(.horizontal, 20)
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
            .sheet(isPresented: $showingEditSheet) {
                EditFastSheet(
                    date: selectedDate,
                    hours: $editingHours,
                    minutes: $editingMinutes,
                    onSave: {
                        updateFastDuration()
                    }
                )
            }
        }
    }
    
    private func getFastingProgress() -> Double {
        guard let fast = currentFast else { return 0.0 }
        let targetSeconds = Double(fast.type.targetHours) * 3600
        return min(currentElapsedTime / targetSeconds, 1.0)
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
    
    private func updateFastDuration() {
        let hours = Double(editingHours) ?? 0
        let minutes = Double(editingMinutes) ?? 0
        let newDuration = (hours * 3600) + (minutes * 60)
        
        let records = fastDatabase.getFastRecordsForDate(selectedDate)
        if let firstRecord = records.first {
            // Create updated record with new duration
            let updatedFast = FastRecord(
                id: firstRecord.id,
                startTime: firstRecord.startTime,
                endTime: firstRecord.endTime,
                duration: newDuration,
                type: firstRecord.type,
                notes: firstRecord.notes,
                createdAt: firstRecord.createdAt
            )
            
            fastDatabase.updateFastRecord(updatedFast)
        }
        
        editingHours = ""
        editingMinutes = ""
    }
    
    private func timeString(from timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = Int(timeInterval) % 3600 / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    private func getCalendarDays() -> [Date] {
        let calendar = Calendar.current
        let today = Date()
        
        // Get the start of the current week (Sunday)
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: today)?.start ?? today
        let startOfWeekSunday = calendar.date(byAdding: .day, value: -calendar.component(.weekday, from: startOfWeek) + 1, to: startOfWeek) ?? startOfWeek
        
        var days: [Date] = []
        
        // Generate 35 days (5 weeks) starting from the Sunday of the current week
        for i in 0..<35 {
            if let day = calendar.date(byAdding: .day, value: i, to: startOfWeekSunday) {
                days.append(day)
            }
        }
        
        return days
    }
    
    private func getRecentDays() -> [Date] {
        let calendar = Calendar.current
        let today = Date()
        
        var days: [Date] = []
        
        // Generate 14 days (2 weeks) starting from 7 days ago
        for i in -7..<7 {
            if let day = calendar.date(byAdding: .day, value: i, to: today) {
                days.append(day)
            }
        }
        
        return days
    }
}

// MARK: - DayFastBar View
struct DayFastBar: View {
    let date: Date
    let fastRecords: [FastRecord]
    let isToday: Bool
    let isFuture: Bool
    
    private var totalFastingHours: Double {
        fastRecords.reduce(0) { total, record in
            total + (record.duration / 3600)
        }
    }
    
    private var targetHours: Double {
        // Default to 16 hours if no records, otherwise use the most common target
        if let mostCommonType = fastRecords.map({ $0.type }).mostCommon() {
            return Double(mostCommonType.targetHours)
        }
        return 16.0
    }
    
    private var progressRatio: Double {
        guard !isFuture else { return 0.0 }
        return min(totalFastingHours / targetHours, 1.0)
    }
    
    var body: some View {
        VStack(spacing: 4) {
            // Day number
            Text("\(Calendar.current.component(.day, from: date))")
                .font(.caption2)
                .fontWeight(isToday ? .bold : .medium)
                .foregroundColor(isFuture ? .secondary : (isToday ? Color(red: 0.31, green: 0.275, blue: 0.918) : .primary))
            
            // Progress bar
            ZStack(alignment: .bottom) {
                // Background bar
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(red: 0.31, green: 0.275, blue: 0.918).opacity(0.1))
                    .frame(height: 40)
                
                // Progress bar
                if !isFuture && progressRatio > 0 {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 0.31, green: 0.275, blue: 0.918),
                                    Color(red: 0.4, green: 0.35, blue: 0.95)
                                ]),
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                        .frame(height: 40 * progressRatio)
                        .animation(.easeInOut(duration: 0.5), value: progressRatio)
                }
                
                // Fast indicator dots
                if !isFuture && !fastRecords.isEmpty {
                    HStack(spacing: 2) {
                        ForEach(0..<min(fastRecords.count, 3), id: \.self) { index in
                            Circle()
                                .fill(Color.white)
                                .frame(width: 4, height: 4)
                        }
                    }
                    .padding(.bottom, 4)
                }
            }
            .frame(height: 40)
            
            // Hours text
            if !isFuture && totalFastingHours > 0 {
                Text("\(Int(totalFastingHours))h")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(Color(red: 0.31, green: 0.275, blue: 0.918))
            } else if isFuture {
                Text("-")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            } else {
                Text("0h")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(height: 70)
        .opacity(isFuture ? 0.5 : 1.0)
    }
}

// MARK: - TallDayFastBar View
struct TallDayFastBar: View {
    let date: Date
    let fastRecords: [FastRecord]
    let isToday: Bool
    let isFuture: Bool
    let onTap: () -> Void
    
    private var totalFastingHours: Double {
        fastRecords.reduce(0) { total, record in
            total + (record.duration / 3600)
        }
    }
    
    private var targetHours: Double {
        // Default to 16 hours if no records, otherwise use the most common target
        if let mostCommonType = fastRecords.map({ $0.type }).mostCommon() {
            return Double(mostCommonType.targetHours)
        }
        return 16.0
    }
    
    private var progressRatio: Double {
        guard !isFuture else { return 0.0 }
        return min(totalFastingHours / targetHours, 1.0)
    }
    
    private var dayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // Day name and number
            VStack(spacing: 2) {
                Text(dayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isFuture ? .secondary : .primary)
                
                Text("\(Calendar.current.component(.day, from: date))")
                    .font(.title2)
                    .fontWeight(isToday ? .bold : .semibold)
                    .foregroundColor(isFuture ? .secondary : (isToday ? Color(red: 0.31, green: 0.275, blue: 0.918) : .primary))
            }
            
            // Tall progress bar
            ZStack(alignment: .bottom) {
                // Background bar
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(red: 0.31, green: 0.275, blue: 0.918).opacity(0.1))
                    .frame(width: 50, height: 120)
                
                // Progress bar
                if !isFuture && progressRatio > 0 {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 0.31, green: 0.275, blue: 0.918),
                                    Color(red: 0.4, green: 0.35, blue: 0.95)
                                ]),
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                        .frame(width: 50, height: 120 * progressRatio)
                        .animation(.easeInOut(duration: 0.5), value: progressRatio)
                }
                
                // Fast indicator dots
                if !isFuture && !fastRecords.isEmpty {
                    VStack(spacing: 2) {
                        ForEach(0..<min(fastRecords.count, 4), id: \.self) { index in
                            Circle()
                                .fill(Color.white)
                                .frame(width: 6, height: 6)
                        }
                    }
                    .padding(.bottom, 8)
                }
            }
            .frame(width: 50, height: 120)
            
            // Hours text
            if !isFuture && totalFastingHours > 0 {
                Text("\(Int(totalFastingHours))h")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(red: 0.31, green: 0.275, blue: 0.918))
            } else if isFuture {
                Text("-")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Text("0h")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Target indicator
            if !isFuture {
                Text("\(Int(targetHours))h goal")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: 60, height: 200)
        .opacity(isFuture ? 0.5 : 1.0)
        .onTapGesture {
            onTap()
        }
    }
}

// MARK: - Array Extension
extension Array where Element: Hashable {
    func mostCommon() -> Element? {
        let counts = self.reduce(into: [:]) { counts, element in
            counts[element, default: 0] += 1
        }
        return counts.max(by: { $0.value < $1.value })?.key
    }
}

// MARK: - EditFastSheet View
struct EditFastSheet: View {
    let date: Date
    @Binding var hours: String
    @Binding var minutes: String
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text("Edit Fast Duration")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text(dateString)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top)
                
                // Duration Input
                VStack(spacing: 16) {
                    Text("Fast Duration")
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    HStack(spacing: 20) {
                        // Hours
                        VStack(spacing: 8) {
                            Text("Hours")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            TextField("0", text: $hours)
                                .keyboardType(.numberPad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .frame(width: 80)
                                .multilineTextAlignment(.center)
                        }
                        
                        // Minutes
                        VStack(spacing: 8) {
                            Text("Minutes")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            TextField("0", text: $minutes)
                                .keyboardType(.numberPad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .frame(width: 80)
                                .multilineTextAlignment(.center)
                        }
                    }
                }
                
                // Info
                VStack(spacing: 8) {
                    Image(systemName: "info.circle")
                        .foregroundColor(.blue)
                    
                    Text("This will update the fasting duration for this day. The start time will remain unchanged.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                },
                trailing: Button("Save") {
                    onSave()
                    dismiss()
                }
                .fontWeight(.semibold)
                .foregroundColor(Color(red: 0.31, green: 0.275, blue: 0.918))
            )
        }
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
                    .foregroundColor(Color(red: 0.31, green: 0.275, blue: 0.918))
                
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
    @EnvironmentObject var healthKitManager: HealthKitManager
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
                
                // Refresh Button (now optional since auto-sync is enabled)
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
