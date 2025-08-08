//
//  FastDatabase.swift
//  iFast
//
//  Created by Kalaiselvan Ulaganathan on 8/6/25.
//

import Foundation
import SQLite3

class FastDatabase: ObservableObject {
    private var db: OpaquePointer?
    @Published var fastRecords: [FastRecord] = []
    
    init() {
        setupDatabase()
        loadFastRecords()
    }
    
    deinit {
        sqlite3_close(db)
    }
    
    private func setupDatabase() {
        let fileURL = try! FileManager.default
            .url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            .appendingPathComponent("fasts.sqlite")
        
        if sqlite3_open(fileURL.path, &db) != SQLITE_OK {
            print("Error opening database")
            return
        }
        
        createTable()
    }
    
    private func createTable() {
        let createTableString = """
            CREATE TABLE IF NOT EXISTS fast_records(
                id TEXT PRIMARY KEY,
                start_time TEXT NOT NULL,
                end_time TEXT,
                duration REAL NOT NULL,
                type TEXT NOT NULL,
                notes TEXT,
                created_at TEXT NOT NULL
            );
        """
        
        var createTableStatement: OpaquePointer?
        if sqlite3_prepare_v2(db, createTableString, -1, &createTableStatement, nil) == SQLITE_OK {
            if sqlite3_step(createTableStatement) == SQLITE_DONE {
                print("Fast records table created successfully")
            } else {
                print("Could not create table")
            }
        } else {
            print("CREATE TABLE statement could not be prepared")
        }
        sqlite3_finalize(createTableStatement)
    }
    
    func saveFastRecord(_ record: FastRecord) {
        let insertString = """
            INSERT INTO fast_records (id, start_time, end_time, duration, type, notes, created_at)
            VALUES (?, ?, ?, ?, ?, ?, ?);
        """
        
        var insertStatement: OpaquePointer?
        if sqlite3_prepare_v2(db, insertString, -1, &insertStatement, nil) == SQLITE_OK {
            sqlite3_bind_text(insertStatement, 1, (record.id.uuidString as NSString).utf8String, -1, nil)
            sqlite3_bind_text(insertStatement, 2, (record.startTime.ISO8601String() as NSString).utf8String, -1, nil)
            sqlite3_bind_text(insertStatement, 3, (record.endTime?.ISO8601String() as NSString?)?.utf8String, -1, nil)
            sqlite3_bind_double(insertStatement, 4, record.duration)
            sqlite3_bind_text(insertStatement, 5, (record.type.rawValue as NSString).utf8String, -1, nil)
            sqlite3_bind_text(insertStatement, 6, (record.notes as NSString?)?.utf8String, -1, nil)
            sqlite3_bind_text(insertStatement, 7, (record.createdAt.ISO8601String() as NSString).utf8String, -1, nil)
            
            if sqlite3_step(insertStatement) == SQLITE_DONE {
                print("Fast record saved successfully")
                loadFastRecords()
            } else {
                print("Could not save fast record")
            }
        } else {
            print("INSERT statement could not be prepared")
        }
        sqlite3_finalize(insertStatement)
    }
    
    func updateFastRecord(_ record: FastRecord) {
        // Find the existing record first
        guard let existingRecord = fastRecords.first(where: { $0.id == record.id }) else {
            print("Could not find existing record to update")
            return
        }
        
        let updatedRecord = FastRecord(
            id: existingRecord.id,
            startTime: existingRecord.startTime,
            endTime: record.endTime,
            duration: record.endTime?.timeIntervalSince(existingRecord.startTime) ?? existingRecord.duration,
            type: existingRecord.type,
            notes: record.notes,
            createdAt: existingRecord.createdAt
        )
        
        let updateString = """
            UPDATE fast_records 
            SET end_time = ?, duration = ?, notes = ?
            WHERE id = ?;
        """
        
        var updateStatement: OpaquePointer?
        if sqlite3_prepare_v2(db, updateString, -1, &updateStatement, nil) == SQLITE_OK {
            sqlite3_bind_text(updateStatement, 1, (updatedRecord.endTime?.ISO8601String() as NSString?)?.utf8String, -1, nil)
            sqlite3_bind_double(updateStatement, 2, updatedRecord.duration)
            sqlite3_bind_text(updateStatement, 3, (updatedRecord.notes as NSString?)?.utf8String, -1, nil)
            sqlite3_bind_text(updateStatement, 4, (updatedRecord.id.uuidString as NSString).utf8String, -1, nil)
            
            if sqlite3_step(updateStatement) == SQLITE_DONE {
                print("Fast record updated successfully")
                loadFastRecords()
            } else {
                print("Could not update fast record")
            }
        } else {
            print("UPDATE statement could not be prepared")
        }
        sqlite3_finalize(updateStatement)
    }
    
    func loadFastRecords() {
        let queryString = "SELECT * FROM fast_records ORDER BY created_at DESC;"
        
        var queryStatement: OpaquePointer?
        if sqlite3_prepare_v2(db, queryString, -1, &queryStatement, nil) == SQLITE_OK {
            var records: [FastRecord] = []
            
            while sqlite3_step(queryStatement) == SQLITE_ROW {
                let id = String(cString: sqlite3_column_text(queryStatement, 0))
                let startTimeString = String(cString: sqlite3_column_text(queryStatement, 1))
                let endTimeString = sqlite3_column_text(queryStatement, 2) != nil ? String(cString: sqlite3_column_text(queryStatement, 2)) : nil
                let duration = sqlite3_column_double(queryStatement, 3)
                let typeString = String(cString: sqlite3_column_text(queryStatement, 4))
                let notes = sqlite3_column_text(queryStatement, 5) != nil ? String(cString: sqlite3_column_text(queryStatement, 5)) : nil
                let createdAtString = String(cString: sqlite3_column_text(queryStatement, 6))
                
                let startTime = Date.fromISO8601String(startTimeString) ?? Date()
                let endTime = endTimeString != nil ? Date.fromISO8601String(endTimeString!) : nil
                let type = FastType(rawValue: typeString) ?? .sixteenEight
                let createdAt = Date.fromISO8601String(createdAtString) ?? Date()
                let recordId = UUID(uuidString: id) ?? UUID()
                
                // Create FastRecord using the custom database initializer
                let record = FastRecord(
                    id: recordId,
                    startTime: startTime,
                    endTime: endTime,
                    duration: duration,
                    type: type,
                    notes: notes,
                    createdAt: createdAt
                )
                records.append(record)
            }
            
            DispatchQueue.main.async {
                self.fastRecords = records
            }
        } else {
            print("SELECT statement could not be prepared")
        }
        sqlite3_finalize(queryStatement)
    }
    
    func deleteFastRecord(_ record: FastRecord) {
        let deleteString = "DELETE FROM fast_records WHERE id = ?;"
        
        var deleteStatement: OpaquePointer?
        if sqlite3_prepare_v2(db, deleteString, -1, &deleteStatement, nil) == SQLITE_OK {
            sqlite3_bind_text(deleteStatement, 1, (record.id.uuidString as NSString).utf8String, -1, nil)
            
            if sqlite3_step(deleteStatement) == SQLITE_DONE {
                print("Fast record deleted successfully")
                loadFastRecords()
            } else {
                print("Could not delete fast record")
            }
        } else {
            print("DELETE statement could not be prepared")
        }
        sqlite3_finalize(deleteStatement)
    }
    
    func getCurrentFast() -> FastRecord? {
        return fastRecords.first { $0.endTime == nil }
    }
    
    func getFastRecordsForDate(_ date: Date) -> [FastRecord] {
        let calendar = Calendar.current
        return fastRecords.filter { record in
            calendar.isDate(record.startTime, inSameDayAs: date)
        }
    }
    
    func getFastRecordsForWeek() -> [FastRecord] {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return fastRecords.filter { record in
            record.startTime >= weekAgo
        }
    }
}

// MARK: - Date Extensions
extension Date {
    func ISO8601String() -> String {
        let formatter = ISO8601DateFormatter()
        return formatter.string(from: self)
    }
    
    static func fromISO8601String(_ string: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: string)
    }
}
