//
//  HealthKitManager.swift
//  iFast
//
//  Created by Kalaiselvan Ulaganathan on 8/6/25.
//

import Foundation
import HealthKit
import Combine

class HealthKitManager: ObservableObject {
    private let healthStore = HKHealthStore()
    
    @Published var todaySteps: Int = 0
    @Published var isAuthorized = false
    @Published var isLoading = false
    
    init() {
        requestAuthorization()
    }
    
    func requestAuthorization() {
        // Check if HealthKit is available
        guard HKHealthStore.isHealthDataAvailable() else {
            print("HealthKit is not available on this device")
            return
        }
        
        // Define the types of data we want to read
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        
        // Request authorization
        healthStore.requestAuthorization(toShare: nil, read: [stepType]) { [weak self] success, error in
            DispatchQueue.main.async {
                self?.isAuthorized = success
                if success {
                    self?.fetchTodaySteps()
                } else {
                    print("HealthKit authorization failed: \(error?.localizedDescription ?? "Unknown error")")
                }
            }
        }
    }
    
    func fetchTodaySteps() {
        guard isAuthorized else {
            requestAuthorization()
            return
        }
        
        isLoading = true
        
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        
        // Get today's date range
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        // Create the predicate for today's data
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)
        
        // Create the query
        let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { [weak self] _, result, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    print("Error fetching steps: \(error.localizedDescription)")
                    return
                }
                
                if let result = result, let sum = result.sumQuantity() {
                    let steps = Int(sum.doubleValue(for: HKUnit.count()))
                    self?.todaySteps = steps
                } else {
                    self?.todaySteps = 0
                }
            }
        }
        
        healthStore.execute(query)
    }
    
    func refreshSteps() {
        fetchTodaySteps()
    }
    
    // Calculate calories burned from steps (rough estimate)
    func calculateCalories(from steps: Int) -> Int {
        // Rough estimate: 1 step = 0.04 calories
        return Int(Double(steps) * 0.04)
    }
    
    // Calculate distance from steps (rough estimate)
    func calculateDistance(from steps: Int) -> Double {
        // Rough estimate: 1 step = 0.0005 miles
        return Double(steps) * 0.0005
    }
    
    // Get step goal (default 10,000, but can be customized)
    func getStepGoal() -> Int {
        // You could store this in UserDefaults for customization
        return 10000
    }
    
    // Calculate progress percentage
    func getStepProgress() -> Double {
        let goal = getStepGoal()
        return min(Double(todaySteps) / Double(goal), 1.0)
    }
}
