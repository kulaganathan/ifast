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



#Preview {
    ContentView()
}
