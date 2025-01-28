//
//  StepCountView.swift
//  LetsBeHealthy
//
//  Created by Bhagavan Kumar V on 2025-01-10.
//
import SwiftUI
import HealthKit

struct StepCountView: View {
    @Binding var stepCount: Double
    private let healthStore = HKHealthStore()
    
    var body: some View {
        VStack {
            Text("Your Step Count")
                .font(.largeTitle)
                .padding()
            
            Text("\(Int(stepCount)) steps")
                .font(.title)
                .padding()
            
            Spacer()
        }
        .background(Color(.systemBackground).opacity(0.2))
        .onAppear(perform: fetchStepCount)
    }
    
    private func fetchStepCount() {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("Health data is not available.")
            return
        }
        
        let stepType = HKObjectType.quantityType(forIdentifier: .stepCount)!
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
            guard let result = result, let sum = result.sumQuantity() else {
                print("Failed to fetch steps: \(String(describing: error))")
                return
            }
            
            DispatchQueue.main.async {
                self.stepCount = sum.doubleValue(for: HKUnit.count())
            }
        }
        
        healthStore.execute(query)
    }
}
