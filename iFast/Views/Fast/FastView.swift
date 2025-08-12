//
//  FastView.swift
//  iFast
//
//  Created by Kalaiselvan Ulaganathan on 8/11/25.
//
import SwiftUI

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
                                
                                FastActionButton(currentFast: currentFast,
                                                 showingStopConfirmation: $showingStopConfirmation,
                                                 startFasting: startFasting,
                                                 stopFasting: stopFasting)
                            } else {
                                Text("00:00:00")
                                    .font(.system(size: 48, weight: .thin, design: .monospaced))
                                    .foregroundColor(.secondary)
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
                                FastActionButton(currentFast: currentFast,
                                                 showingStopConfirmation: $showingStopConfirmation,
                                                 startFasting: startFasting,
                                                 stopFasting: stopFasting)
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
                                HStack(spacing: 10) {
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
                                .padding()
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
        for i in -3..<7 {
            if let day = calendar.date(byAdding: .day, value: i, to: today) {
                days.append(day)
            }
        }
        
        return days
    }
}
