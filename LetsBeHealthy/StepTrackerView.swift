//
//  StepTrackerView.swift
//  LetsBeHealthy
//
//  Created by Bhagavan Kumar V on 2025-01-12.
//

import SwiftUI
import HealthKit

struct StepTrackerView: View {
    @State private var steps: Int = 0

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.8)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all) // Covers the entire screen

            VStack(spacing: 20) {
                // App title
                Text("Step Tracker")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.top, 50)

                // Steps display
                VStack {
                    Text("Today's Steps")
                        .font(.title)
                        .foregroundColor(.white.opacity(0.8))

                    Text("\(steps)")
                        .font(.system(size: 80, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.top, 10)
                }
                .padding()
                .background(Color.white.opacity(0.2))
                .cornerRadius(20)
                .shadow(radius: 10)

                // Refresh button
                Button(action: fetchSteps) {
                    Text("Refresh Steps")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: 200)
                        .background(Color.white)
                        .cornerRadius(10)
                        .shadow(radius: 5)
                        .foregroundColor(.blue)
                }
                .padding(.top, 30)

                Spacer()
            }
            .padding()
        }
        .onAppear(perform: fetchSteps) // Automatically fetch steps when the view appears
    }

    func fetchSteps() {
        let healthStore = HKHealthStore()

        guard let stepType = HKObjectType.quantityType(forIdentifier: .stepCount) else {
            print("Step Count is not available.")
            return
        }

        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)

        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)

        let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
            guard let result = result, let sum = result.sumQuantity() else {
                print("Failed to fetch steps: \(String(describing: error))")
                return
            }

            DispatchQueue.main.async {
                self.steps = Int(sum.doubleValue(for: HKUnit.count()))
            }
        }

        healthStore.execute(query)
    }
}
