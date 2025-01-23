import SwiftUI
import HealthKit
import Charts

import SwiftUI
import HealthKit
import Charts

struct AnalyticsView: View {
    @State private var dailySteps: Double = 0.0
    @State private var weeklySteps: Double = 0.0
    @State private var monthlySteps: Double = 0.0
    @State private var averageSteps: Double = 0.0
    @State private var peakActivityHour: Int? = nil
    @State private var isButtonPressed: Bool = false // Track button state
    @State private var weeklyStepData: [(day: String, steps: Double)] = []
    
    private let healthStore = HKHealthStore()

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.8)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all)

            // ScrollView for scrolling analytics content
            ScrollView {
                VStack(spacing: 20) {
                    Text("Step Count Analytics")
                        .font(.largeTitle)
                        .bold()
                        .foregroundColor(.white)
                        .padding(.top, 50)

                    // Step Count Display
                    VStack {
                        analyticsTile(title: "Today's Steps", value: dailySteps)
                        analyticsTile(title: "This Week's Steps", value: weeklySteps)
                        analyticsTile(title: "This Month's Steps", value: monthlySteps)
                        analyticsTile(title: "Average Steps Per Day", value: averageSteps)

                        if let peakHour = peakActivityHour {
                            analyticsTile(title: "Peak Activity Hour", value: Double(peakHour), unit: "hr")
                        }
                    }
                    
                    .padding(.horizontal)

                    // Refresh button
                    
                    Button(action: {
                        isButtonPressed = true  // Change color to grey
                        fetchStepData()          // Call the data refresh function
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { // Reset after 0.2s
                            isButtonPressed = false
                        }
                    }) {
                        Text("Refresh Data")
                            .font(.headline)
                            .padding()
                            .frame(maxWidth: 200)
                            .background(isButtonPressed ? Color.gray : Color.white) // Grey when pressed
                            .foregroundColor(.blue)
                            .cornerRadius(10)
                            .shadow(radius: 5)
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 50) // Adds extra spacing at the bottom
                }
                .padding()
            }
        }
        .onAppear(perform: fetchStepData) // Fetch analytics data when the view appears
    }

    // Custom View for Displaying Each Data Point
    private func analyticsTile(title: String, value: Double, unit: String = "steps") -> some View {
            VStack {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.8))

                Text("\(Int(value)) \(unit)")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.top, 5)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.white.opacity(0.2))
            .cornerRadius(15)
            .shadow(radius: 10)
        }

    // Fetch Step Data for Analytics
    private func fetchStepData() {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("Health data is not available.")
            return
        }

        let stepType = HKObjectType.quantityType(forIdentifier: .stepCount)!

        // Fetch Daily, Weekly, and Monthly Data
        fetchSteps(for: .day, quantityType: stepType) { self.dailySteps = $0 }
        fetchSteps(for: .weekOfYear, quantityType: stepType) { self.weeklySteps = $0 }
        fetchSteps(for: .month, quantityType: stepType) { self.monthlySteps = $0 }

        // Calculate Average Steps Per Day (for last 7 days)
        fetchAverageSteps(quantityType: stepType) { self.averageSteps = $0 }

        // Fetch Peak Activity Hour
        fetchPeakActivityHour(quantityType: stepType) { self.peakActivityHour = $0 }

        // Fetch Weekly Step Data for Bar Chart
        fetchWeeklySteps(quantityType: stepType) { self.weeklyStepData = $0 }
    }

    // Fetch Steps for a Specific Period
    private func fetchSteps(for component: Calendar.Component, quantityType: HKQuantityType, completion: @escaping (Double) -> Void) {
        let now = Date()
        let calendar = Calendar.current
        var startDate: Date?

        switch component {
        case .day:
            startDate = calendar.startOfDay(for: now)
        case .weekOfYear:
            startDate = calendar.date(byAdding: .day, value: -6, to: now)
        case .month:
            startDate = calendar.date(byAdding: .month, value: -1, to: now)
        default:
            startDate = calendar.startOfDay(for: now) // Default to today
        }

        guard let start = startDate else {
            completion(0)
            return
        }

        let predicate = HKQuery.predicateForSamples(withStart: start, end: now, options: .strictStartDate)

        let query = HKStatisticsQuery(quantityType: quantityType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
            guard let sum = result?.sumQuantity() else {
                print("Failed to fetch \(component) steps: \(String(describing: error))")
                completion(0)
                return
            }
            DispatchQueue.main.async {
                completion(sum.doubleValue(for: HKUnit.count()))
            }
        }
        healthStore.execute(query)
    }

    // Fetch Weekly Steps Data for Bar Graph
    private func fetchWeeklySteps(quantityType: HKQuantityType, completion: @escaping ([(day: String, steps: Double)]) -> Void) {
        let now = Date()
        let calendar = Calendar.current
        var stepData: [(day: String, steps: Double)] = []

        let dispatchGroup = DispatchGroup()

        for i in (0...6).reversed() {
            let startDate = calendar.date(byAdding: .day, value: -i, to: now)!
            let dayFormatter = DateFormatter()
            dayFormatter.dateFormat = "EEE"

            dispatchGroup.enter()

            fetchSteps(for: .day, quantityType: quantityType) { stepCount in
                let dayString = dayFormatter.string(from: startDate)
                stepData.append((day: dayString, steps: stepCount))
                dispatchGroup.leave()
            }
        }

        dispatchGroup.notify(queue: .main) {
            completion(stepData.sorted { $0.day < $1.day })
        }
    }
    
    // Fetch Average Steps Per Day
    private func fetchAverageSteps(quantityType: HKQuantityType, completion: @escaping (Double) -> Void) {
        let now = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -7, to: now)! // Last 7 days
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: now, options: .strictStartDate)

        let query = HKStatisticsQuery(quantityType: quantityType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
            guard let sum = result?.sumQuantity() else {
                print("Failed to fetch average steps: \(String(describing: error))")
                completion(0)
                return
            }
            DispatchQueue.main.async {
                completion(sum.doubleValue(for: HKUnit.count()) / 7) // Divide by 7 to get average per day
            }
        }
        healthStore.execute(query)
    }

    // Fetch Peak Activity Hour
    // Fetch Peak Activity Hour (Improved)
    private func fetchPeakActivityHour(quantityType: HKQuantityType, completion: @escaping (Int?) -> Void) {
        let now = Date()
        let startDate = Calendar.current.startOfDay(for: now) // Start from midnight
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: now, options: .strictStartDate)

        let query = HKStatisticsCollectionQuery(
            quantityType: quantityType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum,
            anchorDate: startDate,
            intervalComponents: DateComponents(hour: 1)
        )

        query.initialResultsHandler = { _, results, error in
            guard let statsCollection = results else {
                print("Failed to fetch peak activity hour: \(String(describing: error))")
                completion(nil)
                return
            }

            var hourlyCounts = Array(repeating: 0.0, count: 24)

            // Loop through the hourly data
            statsCollection.enumerateStatistics(from: startDate, to: now) { statistics, _ in
                let hour = Calendar.current.component(.hour, from: statistics.startDate)
                if let sum = statistics.sumQuantity() {
                    hourlyCounts[hour] += sum.doubleValue(for: HKUnit.count())
                }
            }

            // Determine the hour with the highest step count
            if let peakHour = hourlyCounts.enumerated().max(by: { $0.element < $1.element })?.offset {
                DispatchQueue.main.async {
                    completion(peakHour)
                }
            } else {
                completion(nil) // No step data found
            }
        }

        healthStore.execute(query)
    }
}



