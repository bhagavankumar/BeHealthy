import UserNotifications
import AVFoundation

class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()
    private var player: AVAudioPlayer?

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        playAlarm() // ✅ Ensure alarm plays when notification is tapped
        completionHandler()
    }

    func playAlarm() {
        guard let path = Bundle.main.path(forResource: "alarm.wav", ofType: nil) else { return }
        let url = URL(fileURLWithPath: path)

        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.numberOfLoops = -1 // ✅ Keep looping the sound
            player?.play()
        } catch {
            print("❌ Error playing alarm sound: \(error.localizedDescription)")
        }
    }

    func stopAlarm() {
        player?.stop()
        player = nil
        print("✅ Alarm stopped.")
    }
}
