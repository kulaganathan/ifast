//
//  DayFastBar.swift
//  iFast
//
//  Created by Kalaiselvan Ulaganathan on 8/11/25.
//
import SwiftUI

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
