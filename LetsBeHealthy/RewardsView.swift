import SwiftUI
import Firebase
//import FirebaseFirestore

struct RewardsView: View {
    @State private var totalStepCoins: Int = UserDefaults.standard.integer(forKey: "totalStepCoins") // Persistent StepCoins
    @State private var todayStepCoins: Int = 0
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

                    // StepCoins Display (Total Lifetime StepCoins)
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

                    // StepCoins Earned Today
                    VStack {
                        Text("StepCoins Earned Today")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.8))

                        Text("\(todayStepCoins) 💰")
                            .font(.system(size: 50, weight: .bold))
                            .foregroundColor(.yellow)
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
                        .onChange(of: stepCount) { _ in
                            updateTodayStepCoins()
                        }

                    // Weekly & Monthly Challenges
                    VStack {
                        Text("Challenges")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.8))

                        Text("Walk 50,000 Steps This Week: Earn 500 StepCoins!")
                            .font(.caption)
                            .foregroundColor(todayStepCoins >= 500 ? .green : .white)
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
                    
                    // Redeem Button
                    Button(action: redeemStepCoins) {
                        Text("Redeem StepCoins")
                            .font(.headline)
                            .padding()
                            .frame(maxWidth: 200)
                            .background(Color.white)
                            .foregroundColor(.red)
                            .cornerRadius(10)
                            .shadow(radius: 5)
                    }
                    .padding(.top, 10)
                }
                .padding()
            }
        }
        .onAppear {
            updateTodayStepCoins()
            
        }
    }
    private func getCurrentDateString() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd" // 📌 Format: "2025-01-12"
        return dateFormatter.string(from: Date())
    }
    // 🔹 Updates today's StepCoins based on step count
    private func updateTodayStepCoins() {
        let currentDate = getCurrentDateString() // 📌 Get today's date as a string

        let lastUpdatedDate = UserDefaults.standard.string(forKey: "lastStepCoinUpdateDate")

        // ✅ Check if StepCoins were already updated today
        if lastUpdatedDate == currentDate {
            print("✅ StepCoins already updated today. No duplicate earnings.")
            return
        }

        // ✅ Calculate StepCoins and update only once per day
        let newStepCoins = Int(stepCount / 100) // Example: 100 steps = 1 StepCoin
        todayStepCoins = newStepCoins

        // ✅ Save today's StepCoins & update the last update date
        UserDefaults.standard.set(todayStepCoins, forKey: "todayStepCoins")
        UserDefaults.standard.set(currentDate, forKey: "lastStepCoinUpdateDate")

        print("🎉 StepCoins updated successfully: \(todayStepCoins) StepCoins earned today!")
    }
    // 🔹 Function to Redeem Today's StepCoins and Add to Total
    private func redeemStepCoins() {
        if todayStepCoins > 0 {
            totalStepCoins += todayStepCoins // Move today's StepCoins to total
            todayStepCoins = 0 // Reset today's StepCoins
            
            // Save the updated total in persistent storage
            UserDefaults.standard.set(totalStepCoins, forKey: "totalStepCoins")
            
            showNotificationMessage("StepCoins redeemed! 🎉")
        } else {
            showNotificationMessage("No StepCoins to redeem! ❌")
        }
    }


    // 🔹 Reward Redemption Logic
    private func redeemReward(itemCost: Int) {
        if totalStepCoins >= itemCost {
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
}
