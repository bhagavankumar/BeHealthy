//
//  StepManager.swift
//  LetsBeHealthy
//
//  Created by Bhagavan Kumar V on 2025-01-27.
//
import SwiftUI
import HealthKit

class StepManager {
    static let shared = StepManager()
    private let healthStore = HKHealthStore()
    
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        let stepType = HKObjectType.quantityType(forIdentifier: .stepCount)!
        healthStore.requestAuthorization(toShare: nil, read: [stepType]) { success, _ in
            completion(success)
        }
    }
    
    func getDailySteps(completion: @escaping (Double) -> Void) {
        // Existing step fetching logic here
    }
}
