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
            ScrollView{
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
                    ProgressRingView(progress: Double(steps)/10000, color: .blue)
                        .frame(width: 200, height: 200)
                    
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
                    
                    Button(action: shareAchievement) {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                    .shadow(radius: 5)
                }
                .padding()
                .frame(maxWidth: .infinity)
            }
        }
        .background(Color(.systemBackground).opacity(0.2))
        .onAppear(perform: fetchSteps) // Automatically fetch steps when the view appears
    }
    // Sharing function
    private func shareAchievement() {
        let activityVC = UIActivityViewController(
            activityItems: ["I just walked \(steps) steps today! 🚶♂️ #StepRewards"],
            applicationActivities: nil
        )
        if let windowScene = UIApplication.shared.connectedScenes.first(where: {
            $0.activationState == .foregroundActive && $0 is UIWindowScene
        }) as? UIWindowScene {
            windowScene.windows.first(where: \.isKeyWindow)?.rootViewController?.present(activityVC, animated: true)
        }
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
// Progress Ring View Component
struct ProgressRingView: View {
    let progress: Double
    let color: Color
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: 20)
                .opacity(0.3)
                .foregroundColor(color)
            
            Circle()
                .trim(from: 0, to: CGFloat(min(progress, 1.0)))
                .stroke(style: StrokeStyle(lineWidth: 20, lineCap: .round))
                .foregroundColor(color)
                .rotationEffect(Angle(degrees: 270))
            
            Text("\(Int(progress * 100))%")
                .font(.title)
                .bold()
                .foregroundColor(.white)
        }
    }
}
