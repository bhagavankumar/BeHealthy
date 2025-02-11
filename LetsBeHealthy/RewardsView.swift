import SwiftUI
import HealthKit
import UIKit
import MessageUI
import FirebaseAuth
import FirebaseFirestore

struct RewardsView: View {
    
    @State private var totalSteps: Int = UserDefaults.standard.integer(forKey: "totalSteps")
    @State private var stepCount: Double = 0.0
    @State private var rewardTier: String = "Bronze"
    @State private var showNotification: Bool = false
    @State private var notificationMessage: String = ""
    @State private var showMailComposer: Bool = false
    @State private var mailMessage: String = ""
    @State private var selectedReward: String = ""
    @State private var showSuccessAlert = false
    @State private var showHistory = false
    @State private var coinHistory: [CoinHistoryEntry] = []
    @AppStorage("stepCoinsFromSteps") private var stepCoinsFromSteps: Int = 0
    @AppStorage("stepCoinsFromMeditation") private var stepCoinsFromMeditation: Int = 0

    var totalStepCoins: Int {
        stepCoinsFromSteps + stepCoinsFromMeditation
    }
    private let healthStore = HKHealthStore()
    
let rewardThresholds = [(1000, "Bronze"), (5000, "Silver"), (10000, "Gold")]
let rewardItems: [(name: String, cost: Int)] = [
        (name: "5$ McDonald's gift card", cost: 2500),
        (name: "10$ Amazon's gift card", cost: 4000),
        (name: "25$ Walmart's gift card", cost: 8000)
    ]

let achievements: [(name: String, image: String, threshold: Int)] = [
        (name: "First 1K", image: "1k-badge", threshold: 1000),
        (name: "Marathoner", image: "marathon-badge", threshold: 10_000),
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
                    
                    VStack {
                        HStack {
                            Text("Total StepCoins Earned")
                                .font(.title2)
                                .foregroundColor(.white.opacity(0.8))
                            Spacer()
                            Button(action: {
                                showHistory.toggle()
                            }) {
                                Image(systemName: "clock.arrow.circlepath") // History icon
                                    .foregroundColor(.white)
                                    .padding(5)
                            }
                        }

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
                            updateStepCoins()
                        }
                    
                    // Weekly & Monthly Challenges
                    VStack {
                        Text("Earn 1 Step coin for every 100 steps.")
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding()
                    }
                    .padding()
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(20)
                    .shadow(radius: 10)
                    
                    let unlockedAchievements = achievements.filter { totalSteps >= $0.threshold }
                    //Achievements
                    VStack {
                        Text("Lifetime Achievements 🏆")
                            .font(.title2)
                            .foregroundColor(.white)
                        ScrollView(.horizontal) {
                            HStack {
                                ForEach(unlockedAchievements, id: \.name) { achievement in
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
                            RewardItemView(item: item, totalStepCoins: totalStepCoins) {
                                redeemReward(item)
                            }
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
        .alert(isPresented: $showSuccessAlert) { // ✅ Alert here
            Alert(
                title: Text("🎉 Reward Redeemed"),
                message: Text("You have successfully redeemed \(selectedReward). Your reward details will be sent to your email."),
                dismissButton: .default(Text("OK"))
            )
        }
        .onAppear {
            resetStepTrackingIfNeeded()
            fetchTotalStepsSinceInstallation()
            fetchStepCount()
            loadCoinHistory()
        }
        .sheet(isPresented: $showHistory) {
            CoinHistoryView(coinHistory: coinHistory)
                .onAppear {
                            loadCoinHistory() // ✅ Ensure history is updated when sheet appears
                        }
        }
        .background(Color(.systemBackground).opacity(0.2))
    }
    
    private func fetchStepCount() {
            let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
            let now = Date()
            let startOfDay = Calendar.current.startOfDay(for: now)
        
            
            let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
            
            let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
                guard let result = result, let sum = result.sumQuantity() else {
                    print("Failed to fetch steps")
                    return
                }
                stepCount = sum.doubleValue(for: HKUnit.count())
                updateStepCoins()
            }
            
            healthStore.execute(query)
        }
    private func updateStepCoins() {
        let lastTotalSteps = UserDefaults.standard.integer(forKey: "lastTotalSteps")
            let newSteps = Int(stepCount) - lastTotalSteps

            
            if newSteps > 0 {
                let newStepCoins = newSteps / 100
                stepCoinsFromSteps += newStepCoins
                totalSteps += newSteps
                
                let stepCoinEntry = CoinHistoryEntry(date: Date(), amount: newStepCoins, source: "Steps")
                        coinHistory.append(stepCoinEntry)
                        saveCoinHistory()
                // ✅ Ensure the latest total steps are stored
                UserDefaults.standard.set(Int(stepCount), forKey: "lastTotalSteps")
                UserDefaults.standard.set(totalStepCoins, forKey: "totalStepCoins")

                print("🎉 StepCoins added: \(newStepCoins), Total Steps: \(totalSteps)")
            } else {
                print("No new steps to add.")
            }
        }
    // 🔹 Define a Codable struct for Coin History Entry
    struct CoinHistoryEntry: Codable {
        let date: Date
        let amount: Int
        let source: String
    }

    // 🔹 Save Coin History to UserDefaults
    private func saveCoinHistory() {
        do {
            // ✅ Load previous history first
            var savedHistory: [CoinHistoryEntry] = []
            if let savedData = UserDefaults.standard.data(forKey: "coinHistory") {
                savedHistory = try JSONDecoder().decode([CoinHistoryEntry].self, from: savedData)
            }
            
            // ✅ Append new records
            savedHistory.append(contentsOf: coinHistory)

            let encodedData = try JSONEncoder().encode(savedHistory)
            UserDefaults.standard.set(encodedData, forKey: "coinHistory")
            
            print("✅ Coin history saved successfully: \(savedHistory.count) entries")
        } catch {
            print("❌ Failed to save coin history: \(error.localizedDescription)")
        }
    }

    private func loadCoinHistory() {
        DispatchQueue.global(qos: .userInitiated).async {
            if let savedData = UserDefaults.standard.data(forKey: "coinHistory") {
                do {
                    var decodedHistory = try JSONDecoder().decode([CoinHistoryEntry].self, from: savedData)
                    
                    DispatchQueue.main.async {
                        self.coinHistory = decodedHistory

                        // ✅ Ensure Meditation Coins are Added to History without Duplicates
                        if self.stepCoinsFromMeditation > 0 {
                            let meditationEntry = CoinHistoryEntry(date: Date(), amount: self.stepCoinsFromMeditation, source: "Meditation")

                            if !self.coinHistory.contains(where: { $0.source == "Meditation" }) {
                                self.coinHistory.append(meditationEntry)
                                self.saveCoinHistory()  // Save updated history
                            }
                        }

                        print("✅ Coin history loaded successfully: \(self.coinHistory)")
                    }
                } catch {
                    print("❌ Failed to load coin history: \(error.localizedDescription)")
                }
            } else {
                print("⚠️ No saved coin history found")
            }
        }
    }
    private func resetStepTrackingIfNeeded() {
        let calendar = Calendar.current
        let lastUpdateDate = UserDefaults.standard.object(forKey: "lastCoinUpdateDate") as? Date ?? Date.distantPast
        let today = Date()

        if !calendar.isDate(lastUpdateDate, inSameDayAs: today) {
            print("🔄 Resetting lastTotalSteps for the new day.")

            // Reset lastTotalSteps to the current step count
            UserDefaults.standard.set(Int(stepCount), forKey: "lastTotalSteps")

            // Save today’s date to track when we last reset
            UserDefaults.standard.set(today, forKey: "lastCoinUpdateDate")
            
            // Reset today's StepCoins (if needed)
            UserDefaults.standard.set(0, forKey: "todaysStepCoin")
            
            // Force update UI
            DispatchQueue.main.async {
                self.stepCoinsFromSteps = UserDefaults.standard.integer(forKey: "totalStepCoins")
            }
        }
    }

    private func redeemReward(_ reward: (name: String, cost: Int)) {
        guard totalStepCoins >= reward.cost else { return }
        
        var remainingCost = reward.cost

        // Deduct from meditation coins first if available
        if stepCoinsFromMeditation >= remainingCost {
            stepCoinsFromMeditation -= remainingCost
            remainingCost = 0
        } else {
            remainingCost -= stepCoinsFromMeditation
            stepCoinsFromMeditation = 0
        }

        // Deduct remaining cost from step coins if needed
        if remainingCost > 0 {
            stepCoinsFromSteps -= remainingCost
        }

        selectedReward = reward.name
        UserDefaults.standard.set(stepCoinsFromSteps, forKey: "stepCoinsFromSteps")
        UserDefaults.standard.set(stepCoinsFromMeditation, forKey: "stepCoinsFromMeditation")

        // Show success message
        showSuccessAlert = true
        

        showNotificationMessage("🎉 You have successfully redeemed \(reward.name). Your reward will be sent to your mail!")

        // Save reward redemption to Firestore (Firebase will handle sending the email)
        let db = Firestore.firestore()
        let userEmail = Auth.auth().currentUser?.email ?? "unknown@example.com"

        db.collection("mail").addDocument(data: [
            "to": userEmail,
            "message": [
                        "subject": "Your Reward Has Been Redeemed!",
                        "text": "Congratulations! You have successfully redeemed \(reward.name). Enjoy your reward!"
                    ],
             "redeemedAt": Timestamp(date: Date())
        ]) { error in
            if let error = error {
                print("Error saving redemption: \(error.localizedDescription)")
            } else {
                print("🎉 Reward redemption saved, email will be sent automatically!")
            }
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
    struct CoinHistoryView: View {
        let coinHistory: [CoinHistoryEntry]
        
        var body: some View {
            NavigationView {
                if coinHistory.isEmpty {
                    VStack {
                        Text("No StepCoins history yet")
                            .font(.headline)
                            .foregroundColor(.gray)
                            .padding()
                        Image(systemName: "list.bullet")
                            .resizable()
                            .frame(width: 50, height: 50)
                            .foregroundColor(.gray.opacity(0.5))
                    }
                } else {
                    List(coinHistory.reversed(), id: \.date) { entry in
                        HStack {
                            VStack(alignment: .leading) {
                                Text("+\(entry.amount) 💰 (\(entry.source))")
                                    .font(.headline)
                                    .foregroundColor(entry.source == "Steps" ? .green : .blue)
                                Text("\(entry.date.formatted(date: .abbreviated, time: .shortened))")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 5)
                    }
                }
            }
        }
    }
    struct RewardItemView: View {
        let item: (name: String, cost: Int)
        let totalStepCoins: Int
        let redeemAction: () -> Void

        var body: some View {
            let canRedeem = totalStepCoins >= item.cost
            let buttonColor = canRedeem ? Color.green : Color.gray
            
            HStack {
                Text(item.name)
                    .foregroundColor(.white)
                Spacer()
                Text("\(item.cost) 💰")
                    .foregroundColor(.yellow)
                Button("Redeem", action: redeemAction)
                    .padding(.horizontal, 10)
                    .background(buttonColor)
                    .foregroundColor(.white)
                    .cornerRadius(5)
                    .disabled(!canRedeem)
            }
            .padding()
        }
    }
    struct MailView: UIViewControllerRepresentable {
            @Binding var isShowing: Bool
            let messageBody: String
            
            func makeCoordinator() -> Coordinator {
                Coordinator(isShowing: $isShowing)
            }
            
            func makeUIViewController(context: Context) -> MFMailComposeViewController {
                let mail = MFMailComposeViewController()
                mail.mailComposeDelegate = context.coordinator
                mail.setToRecipients(["rewards@yourcompany.com"]) // Set your email here
                mail.setSubject("🎉 Reward Redemption Confirmation")
                mail.setMessageBody(messageBody, isHTML: false)
                return mail
            }
            
            func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}
            
            class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
                @Binding var isShowing: Bool
                
                init(isShowing: Binding<Bool>) {
                    _isShowing = isShowing
                }
                
                func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
                    isShowing = false
                }
            }
        }
    }
extension UserDefaults {
    static let lastCoinUpdateDateKey = "lastCoinUpdateDate"
    static let todaysStepCoinKey = "todaysStepCoin"
}
