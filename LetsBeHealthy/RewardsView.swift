import SwiftUI
import HealthKit
import UIKit

struct RewardsView: View {
    @State private var totalStepCoins: Int = UserDefaults.standard.integer(forKey: "totalStepCoins") // Persistent StepCoins
    @State private var totalSteps: Int = UserDefaults.standard.integer(forKey: "totalSteps")
    @State private var stepCount: Double = 0.0
    @State private var rewardTier: String = "Bronze"
    @State private var showNotification: Bool = false
    @State private var notificationMessage: String = ""
    
    let rewardThresholds = [(1000, "Bronze"), (5000, "Silver"), (10000, "Gold")]
    let rewardItems = [
        (name: "10% Discount Coupon", cost: 500),
        (name: "Free Gym Pass", cost: 1000),
        (name: "Fitness Band Giveaway Entry", cost: 5000)
    ]
    let achievements = [
        (name: "First 1K", image: "1k-badge", threshold: 1000),
        (name: "Marathoner", image: "marathon-badge", threshold: 10000),
        (name: "100K Club", image: "100k-badge", threshold: 100_000),
        (name: "1 Million Steps", image: "1m-badge", threshold: 1_000_000)
    ]
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(gradient: Gradient(colors: [Color.orange.opacity(0.6), Color.red.opacity(0.8)]),
                           startPoint: .top,
                           endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(spacing: 20) {
                    Text("Your Rewards")
                        .font(.largeTitle)
                        .foregroundColor(.white)
                        .padding()
                    
                    // Total StepCoins Earned (Automatically Updated)
                    VStack {
                        Text("Total StepCoins Earned")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text("\(totalStepCoins) 💰")
                            .font(.system(size: 50, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.top, 5)
                    }
                    .padding()
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(20)
                    .shadow(radius: 10)
                    
                    // Reward Tier Indicator (Bronze, Silver, Gold)
                    VStack {
                        Text("Reward Tier")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text("\(rewardTier)")
                            .font(.title)
                            .bold()
                            .foregroundColor(.yellow)
                            .padding(.top, 5)
                    }
                    .padding()
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(20)
                    .shadow(radius: 10)
                    
                    // Step Count View (Today's Steps)
                    StepCountView(stepCount: $stepCount)
                        .onChange(of: stepCount) { newValue, oldValue in
                            print("Step count changed from \(oldValue) to \(newValue)")
                            updateTotalStepCoins()
                        }
                    
                    // Weekly & Monthly Challenges
                    VStack {
                        Text("Challenges")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text("Walk 50,000 Steps This Week: Earn 500 StepCoins!")
                            .font(.caption)
                            .foregroundColor(totalStepCoins >= 500 ? .green : .white)
                            .padding()
                        
                        Text("Walk 200,000 Steps This Month: Earn 2000 StepCoins!")
                            .font(.caption)
                            .foregroundColor(totalStepCoins >= 2000 ? .green : .white)
                            .padding()
                    }
                    .padding()
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(20)
                    .shadow(radius: 10)
                    
                    //Achievements
                    VStack {
                                            Text("Achievements 🏆")
                                                .font(.title2)
                                                .foregroundColor(.white)
                                            
                                            ScrollView(.horizontal) {
                                                HStack {
                                                    ForEach(achievements.filter { totalSteps >= $0.threshold }, id: \.name) { achievement in
                                                        VStack {
                                                            Image(achievement.image)
                                                                .resizable()
                                                                .frame(width: 80, height: 80)
                                                            Text(achievement.name)
                                                                .foregroundColor(.white)
                                                        }
                                                    }
                                                }
                                            }
                                        }
                    .padding()
                    
                    // 🔹 Reward Store Section
                    VStack {
                        Text("Reward Store 🎁")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.8))
                        
                        ForEach(rewardItems, id: \.name) { item in
                            HStack {
                                Text(item.name)
                                    .foregroundColor(.white)
                                Spacer()
                                Text("\(item.cost) 💰")
                                    .foregroundColor(.yellow)
                                Button("Redeem") {
                                    redeemReward(itemCost: item.cost)
                                }
                                .padding(.horizontal, 10)
                                .background(totalStepCoins >= item.cost ? Color.green : Color.gray)
                                .foregroundColor(.white)
                                .cornerRadius(5)
                                .disabled(totalStepCoins < item.cost)
                            }
                            .padding()
                        }
                    }
                    .padding()
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(20)
                    .shadow(radius: 10)
                    
                    // 🔹 Achievement Notifications
                    if showNotification {
                        Text(notificationMessage)
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.green.opacity(0.8))
                            .cornerRadius(10)
                            .transition(.slide)
                    }
                }
                .padding()
            }
        }
        .onAppear {
            fetchDailySteps()
            fetchTotalStepsSinceInstallation()
        }
        .background(Color(.systemBackground).opacity(0.2))
    }
    
    private func updateTotalStepCoins() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let lastUpdateDate = UserDefaults.standard.object(forKey: UserDefaults.lastCoinUpdateDateKey) as? Date ?? Date.distantPast
        
        // Only update once per day
        if !calendar.isDate(today, inSameDayAs: lastUpdateDate) {
            let newStepCoins = Int(stepCount / 100)
            totalStepCoins += newStepCoins
            UserDefaults.standard.set(today, forKey: UserDefaults.lastCoinUpdateDateKey)
            UserDefaults.standard.set(totalStepCoins, forKey: "totalStepCoins")
            print("🎉 Daily StepCoins added: \(newStepCoins)")
        }
    }
    
    // 🔹 Reward Redemption Logic
    private func redeemReward(itemCost: Int) {
        if totalStepCoins >= itemCost {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            totalStepCoins -= itemCost
            UserDefaults.standard.set(totalStepCoins, forKey: "totalStepCoins")
            showNotificationMessage("Reward Redeemed Successfully! 🎉")
        }
    }
    
    // 🔹 Achievement Notification
    private func showNotificationMessage(_ message: String) {
        notificationMessage = message
        showNotification = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            showNotification = false
        }
    }
    
    
    // 🔹 Fetch Today's Steps from HealthKit
    private func fetchDailySteps() {
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
            guard let sum = result?.sumQuantity() else {
                print("❌ Failed to fetch steps: \(error?.localizedDescription ?? "Unknown Error")")
                return
            }
            
            DispatchQueue.main.async {
                self.stepCount = sum.doubleValue(for: HKUnit.count()) // ✅ Update stepCount in RewardsView
                self.updateTotalStepCoins() // ✅ Update total StepCoins
            }
        }
        HKHealthStore().execute(query)
    }
    // New HealthKit query for total steps since first launch
      private func fetchTotalStepsSinceInstallation() {
          guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount),
                let firstLaunchDate = UserDefaults.standard.object(forKey: "firstLaunchDate") as? Date else {
              return
          }

          let predicate = HKQuery.predicateForSamples(withStart: firstLaunchDate, end: Date(), options: .strictStartDate)
          
          let query = HKStatisticsQuery(quantityType: stepType,
                                      quantitySamplePredicate: predicate,
                                      options: .cumulativeSum) { _, result, error in
              guard let sum = result?.sumQuantity() else {
                  print("Total steps error: \(error?.localizedDescription ?? "N/A")")
                  return
              }
              
              let steps = Int(sum.doubleValue(for: HKUnit.count()))
              DispatchQueue.main.async {
                  self.totalSteps = steps
                  UserDefaults.standard.set(steps, forKey: "totalSteps")
              }
          }
          HKHealthStore().execute(query)
      }
}
extension UserDefaults {
    static let lastCoinUpdateDateKey = "lastCoinUpdateDate"
    static let todaysStepCoinKey = "todaysStepCoin"
}
