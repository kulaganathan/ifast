//
//  FastRecord.swift
//  iFast
//
//  Created by Kalaiselvan Ulaganathan on 8/6/25.
//

import Foundation

struct FastRecord: Identifiable, Codable {
    let id: UUID
    let startTime: Date
    let endTime: Date?
    let duration: TimeInterval
    let type: FastType
    let notes: String?
    let createdAt: Date
    
    init(startTime: Date, endTime: Date? = nil, type: FastType = .sixteenEight, notes: String? = nil) {
        self.id = UUID()
        self.startTime = startTime
        self.endTime = endTime
        self.duration = endTime?.timeIntervalSince(startTime) ?? 0
        self.type = type
        self.notes = notes
        self.createdAt = Date()
    }
    
    // Custom initializer for database loading
    init(id: UUID, startTime: Date, endTime: Date?, duration: TimeInterval, type: FastType, notes: String?, createdAt: Date) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.duration = duration
        self.type = type
        self.notes = notes
        self.createdAt = createdAt
    }
}

enum FastType: String, CaseIterable, Codable {
    case sixteenEight = "16:8"
    case fourteenTen = "14:10"
    case eighteenSix = "18:6"
    case twentyFour = "24:0"
    case custom = "Custom"
    
    var displayName: String {
        return self.rawValue
    }
    
    var targetHours: Int {
        switch self {
        case .sixteenEight: return 16
        case .fourteenTen: return 14
        case .eighteenSix: return 18
        case .twentyFour: return 24
        case .custom: return 16
        }
    }
}
