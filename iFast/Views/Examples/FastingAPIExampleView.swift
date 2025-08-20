import SwiftUI
import AuthAPI

struct FastingAPIExampleView: View {
    @StateObject private var fastingService = FastingAPIService()
    @State private var fastingRecords: [FastRecord] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingCreateForm = false
    
    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView("Loading fasting data...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let errorMessage = errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(.orange)
                        
                        Text("Error Loading Data")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text(errorMessage)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button("Retry") {
                            loadFastingData()
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                    }
                    .padding()
                } else {
                    List {
                        Section("Fasting Records") {
                            ForEach(fastingRecords, id: \.id) { record in
                                FastingRecordRow(record: record)
                            }
                            .onDelete(perform: deleteRecord)
                        }
                        
                        Section("Statistics") {
                            if !fastingRecords.isEmpty {
                                StatisticsView(records: fastingRecords)
                            } else {
                                Text("No fasting data available")
                                    .foregroundColor(.secondary)
                                    .italic()
                            }
                        }
                    }
                }
            }
            .navigationTitle("Fasting API Example")
            .navigationBarTitleDisplayMode(.large)
            .navigationBarItems(
                leading: Button("Refresh") {
                    loadFastingData()
                },
                trailing: Button("Add Record") {
                    showingCreateForm = true
                }
            )
            .sheet(isPresented: $showingCreateForm) {
                CreateFastingRecordView(fastingService: fastingService) {
                    loadFastingData()
                }
            }
            .onAppear {
                loadFastingData()
            }
        }
    }
    
    private func loadFastingData() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let records = try await fastingService.fetchUserFastingData()
                await MainActor.run {
                    fastingRecords = records
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to load fasting data: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }
    
    private func deleteRecord(at offsets: IndexSet) {
        for index in offsets {
            let record = fastingRecords[index]
            Task {
                do {
                    _ = try await fastingService.deleteFastingRecord(id: record.id)
                    await MainActor.run {
                        fastingRecords.remove(at: index)
                    }
                } catch {
                    print("Failed to delete record: \(error)")
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct FastingRecordRow: View {
    let record: FastRecord
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(record.type.displayName)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text(formatDuration(record.duration))
                    .font(.subheadline)
                    .foregroundColor(.blue)
            }
            
            Text("Started: \(formatDate(record.startTime))")
                .font(.caption)
                .foregroundColor(.secondary)
            
            if let notes = record.notes, !notes.isEmpty {
                Text(notes)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        return String(format: "%02d:%02d", hours, minutes)
    }
}

struct StatisticsView: View {
    let records: [FastRecord]
    
    private var totalHours: Double {
        records.reduce(0) { $0 + ($1.duration / 3600) }
    }
    
    private var averageHours: Double {
        guard !records.isEmpty else { return 0 }
        return totalHours / Double(records.count)
    }
    
    private var longestFast: Double {
        records.map { $0.duration / 3600 }.max() ?? 0
    }
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 20) {
                StatCard(
                    title: "Total Hours",
                    value: String(format: "%.1f", totalHours),
                    subtitle: "Fasted",
                    color: .blue
                )
                
                StatCard(
                    title: "Average",
                    value: String(format: "%.1f", averageHours),
                    subtitle: "Hours per fast",
                    color: .green
                )
            }
            
            HStack(spacing: 20) {
                StatCard(
                    title: "Longest Fast",
                    value: String(format: "%.1f", longestFast),
                    subtitle: "Hours",
                    color: .orange
                )
                
                StatCard(
                    title: "Total Fasts",
                    value: "\(records.count)",
                    subtitle: "Completed",
                    color: .purple
                )
            }
        }
    }
}

struct CreateFastingRecordView: View {
    let fastingService: FastingAPIService
    let onRecordCreated: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var startTime = Date()
    @State private var selectedType = FastType.sixteenEight
    @State private var notes = ""
    @State private var isLoading = false
    
    private let fastTypes = [
        FastType.sixteenEight,
        FastType.eighteenSix,
        FastType.fourteenTen,
        FastType.twentyFour
    ]
    
    var body: some View {
        NavigationView {
            Form {
                Section("Fast Details") {
                    DatePicker("Start Time", selection: $startTime, displayedComponents: [.date, .hourAndMinute])
                    
                    Picker("Fast Type", selection: $selectedType) {
                        ForEach(fastTypes, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Fast Type Info") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(selectedType.displayName)
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("Target: \(selectedType.targetHours) hours")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("New Fast")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                },
                trailing: Button("Create") {
                    createRecord()
                }
                .disabled(isLoading)
            )
        }
    }
    
    private func createRecord() {
        isLoading = true
        
        let newRecord = FastRecord(
            startTime: startTime,
            type: selectedType,
            notes: notes.isEmpty ? nil : notes
        )
        
        Task {
            do {
                _ = try await fastingService.createFastingRecord(newRecord)
                await MainActor.run {
                    isLoading = false
                    onRecordCreated()
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    // Handle error
                    print("Failed to create record: \(error)")
                }
            }
        }
    }
}

#Preview {
    FastingAPIExampleView()
}