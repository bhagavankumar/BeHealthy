import SwiftUI
import AVFoundation
import UserNotifications

struct MeditationView: View {
    @State private var isMeditationActive = false
    @State private var isMeditationCompleted = false
    @State private var selectedTime: Int? = nil
    @State private var remainingTime: Int = 0
    @State private var timer: Timer? = nil
    @State private var progress: CGFloat = 1.0
    @State private var player: AVAudioPlayer?
    
    @AppStorage("stepCoinsFromMeditation") private var stepCoinsFromMeditation: Int = 0
    @AppStorage("lastMeditationDate") private var lastMeditationDate: String = ""

    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        ZStack {
            // Background
            LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.8)]),
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
                .ignoresSafeArea()

            VStack {
                // Close Button (Only Stops Alarm, Doesn't Exit)
                HStack {
                    Spacer()
                    Button(action: closeMeditation) { // Unified close action
                        Image(systemName: "xmark.circle.fill")
                            .resizable()
                            .frame(width: 30, height: 30)
                            .foregroundColor(.white.opacity(0.8))
                            .padding()
                    }
                }

                // Meditation Symbol
                Image(systemName: "leaf.circle.fill")
                    .resizable()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.green.opacity(0.9))
                    .padding(.bottom, 20)

                if isMeditationCompleted {
                    // **Meditation Completed UI**
                    Text("Session Completed")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding()

                    // **Finish Button - Stops Alarm & Exits UI**
                    Button(action: {
                        player?.stop() // Stop the alarm
                        finishMeditation()
                        // Update lastMeditationDate and coins here
                        let today = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .none)
                        if lastMeditationDate != today {
                            lastMeditationDate = today
                            stepCoinsFromMeditation += rewardForMeditation()
                            // Save to UserDefaults if needed
                            UserDefaults.standard.set(stepCoinsFromMeditation, forKey: "stepCoinsFromMeditation")
                        }

                        presentationMode.wrappedValue.dismiss() // Exit MeditationView
                    }) {
                        Text("Finish Meditation")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(width: 200, height: 50)
                            .background(Color.green)
                            .cornerRadius(12)
                            .shadow(radius: 5)
                    }
                    .padding()
                } else if isMeditationActive {
                    // **Circular Timer Progress**
                    ZStack {
                        Circle()
                            .trim(from: 0, to: progress)
                            .stroke(Color.green.opacity(0.9), style: StrokeStyle(lineWidth: 12, lineCap: .round))
                            .frame(width: 180, height: 180)
                            .rotationEffect(.degrees(-90))

                        Text("\(remainingTime / 60):\(String(format: "%02d", remainingTime % 60))")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .padding()

                    // Stop Meditation Button
                    Button(action: closeMeditation) {
                        Text("Stop Meditation")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(width: 220, height: 50)
                            .background(Color.red)
                            .cornerRadius(12)
                            .shadow(radius: 5)
                    }
                    .padding(.top, 20)
                } else {
                    // **Meditation Time Selection UI**
                    VStack {
                        Text("Choose a Meditation Duration")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.bottom, 10)

                        HStack(spacing: 15) {
                            Button(action: { startMeditation(minutes: 10) }) {
                                Text("10 min")
                                    .padding()
                                    .frame(width: 100, height: 50)
                                    .background(Color.green.opacity(0.8))
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                            }
                            Button(action: { startMeditation(minutes: 20) }) {
                                Text("20 min")
                                    .padding()
                                    .frame(width: 100, height: 50)
                                    .background(Color.green.opacity(0.8))
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                            }
                            Button(action: { startMeditation(minutes: 30) }) {
                                Text("30 min")
                                    .padding()
                                    .frame(width: 100, height: 50)
                                    .background(Color.green.opacity(0.8))
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                            }
                        }
                        .padding(.top, 10)
                    }
                }
            }
            .padding(.top, 20)
        }
        .onAppear {
                requestNotificationPermission() // ✅ Ask for notification permissions when the view appears
            UNUserNotificationCenter.current().delegate = NotificationManager.shared
            }
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if granted {
                print("✅ Notification permission granted.")
            } else {
                print("❌ Notification permission denied: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }
    
    private func closeMeditation() {
        NotificationManager.shared.stopAlarm()
        player?.stop() // Stop alarm
        timer?.invalidate() // Stop timer if running
        isMeditationActive = false
        isMeditationCompleted = false
        presentationMode.wrappedValue.dismiss() // Exit MeditationView
    }
    
    private func startMeditation(minutes: Int) {
        isMeditationActive = true
        selectedTime = minutes
        remainingTime = minutes * 60
        progress = 1.0
        isMeditationCompleted = false // Reset state
        scheduleMeditationNotification(minutes: minutes) // ✅ Schedules a system alarm

            // ✅ Activate Audio Session to keep app active (only for in-app sound)
            do {
                try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: .mixWithOthers)
                try AVAudioSession.sharedInstance().setActive(true)
            } catch {
                print("❌ Failed to activate background audio: \(error.localizedDescription)")
            }
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if remainingTime > 0 {
                remainingTime -= 1
                progress = CGFloat(remainingTime) / CGFloat(minutes * 60)
            } else {
                endMeditation()
            }
        }
    }

    private func endMeditation() {
        isMeditationCompleted = true
        timer?.invalidate()
        playAlarm() // ✅ This will play the in-app sound

            // ✅ Ensure Meditation Alarm Notification is Cleared
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["meditationComplete"])
    }
    private func finishMeditation() {
        let today = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .none)
        
        // ✅ Stop alarm when meditation is finished
        NotificationManager.shared.stopAlarm()
        
        if lastMeditationDate != today {
            lastMeditationDate = today
            stepCoinsFromMeditation += rewardForMeditation()
            UserDefaults.standard.set(stepCoinsFromMeditation, forKey: "stepCoinsFromMeditation")
        }

        presentationMode.wrappedValue.dismiss()
    }
    private func scheduleMeditationNotification(minutes: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Meditation Complete 🎵"
        content.body = "Your meditation session has ended. Tap to return to the app."

        // ✅ Use a custom sound for the notification
        content.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: "alarm.wav"))

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(minutes * 60), repeats: false)

        let request = UNNotificationRequest(identifier: "meditationComplete", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Error scheduling notification: \(error.localizedDescription)")
            } else {
                print("✅ Meditation alarm scheduled for \(minutes) minutes.")
            }
        }
    }
//    private func endMeditation() {
//        isMeditationCompleted = true // UI remains on "Session Completed"
//        timer?.invalidate()
//        playAlarm()
//
//        let today = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .none)
//
//        if lastMeditationDate != today {
//            lastMeditationDate = today
//            stepCoinsFromMeditation += rewardForMeditation()
//            UserDefaults.standard.set(stepCoinsFromMeditation, forKey: "stepCoinsFromMeditation")
//        }
//    }

    private func rewardForMeditation() -> Int {
        switch selectedTime {
        case 10: return 100
        case 20: return 200
        case 30: return 300
        default: return 0
        }
    }

    private func playAlarm() {
        guard let path = Bundle.main.path(forResource: "alarm.wav", ofType: nil) else { return }
        let url = URL(fileURLWithPath: path)

        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.numberOfLoops = -1
            player?.play()
        } catch {
            print("Error playing alarm sound")
        }
    }
}
