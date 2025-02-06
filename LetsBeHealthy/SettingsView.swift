import SwiftUI
import FirebaseAuth
import FirebaseStorage
import UserNotifications

struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var stepGoal: Int = UserDefaults.standard.integer(forKey: "stepGoal") == 0 ? 10000 : UserDefaults.standard.integer(forKey: "stepGoal")
    @State private var isLocationEnabled = true
    @State private var notificationsEnabled = true
    @State private var showLogoutConfirmation = false
    @State private var showSaveConfirmation = false

    // Fetching user info from Firebase
    @State private var name: String = "Loading..."
    @State private var email: String = "Loading..."
    @State private var profileImage: UIImage? = nil
    @State private var isImageLoading = true
    private let storageRef = Storage.storage().reference()

    var body: some View {
        NavigationView {
            ZStack {
                // Background Gradient (similar to other tabs)
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.8)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .edgesIgnoringSafeArea(.all)

                ScrollView {
                    VStack(spacing: 20) {
                        // User Profile Card with Name and Email
                        profileCard
                        
                        // Account Section
                        sectionCard(title: "Account") {
                            VStack {
                                NavigationLink(destination: ChangePasswordView()) {
                                    settingsRow(icon: "lock.fill", title: "Change Password")
                                }
                                
                                // Toggle for Enabling/Disabling Notifications
                                HStack {
                                    Image(systemName: notificationsEnabled ? "bell.fill" : "bell.slash.fill")
                                        .foregroundColor(notificationsEnabled ? .blue : .red)
                                    Text("Notifications")
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                    
                                    Toggle("", isOn: $notificationsEnabled)
                                        .labelsHidden()
                                        .onChange(of: notificationsEnabled) { oldValue, newValue in
                                            if newValue {
                                                enableNotifications()
                                            } else {
                                                disableNotifications()
                                            }
                                        }
                                }
                                .padding(.vertical, 10)
                            }
                        }

                        // Preferences Section
                        sectionCard(title: "Preferences") {
                            VStack {
                                Text("Daily Step Goal: \(stepGoal) steps")
                                    .font(.headline)
                                    .foregroundColor(.white)

                                Slider(value: Binding(
                                    get: { Double(stepGoal) },
                                    set: { stepGoal = Int($0) }
                                ), in: 1000...20000, step: 500)
                                .padding()
                                .background(Color.white.opacity(0.2))
                                .cornerRadius(10)
                                .onChange(of: stepGoal) { _, newValue in
                                    UserDefaults.standard.set(newValue, forKey: "stepGoal") // Auto-save when user stops dragging
                                }
                            
                                
                                toggleRow(isOn: $isLocationEnabled, icon: "location.fill", title: "Enable Location")
                            }
                        }
                        sectionCard(title: "Feedback") {
                            VStack{
                                Button(action: { sendFeedback() }) {
                                    settingsRow(icon: "bubble.left.and.bubble.right.fill", title: "Send Feedback")
                                }
                                
                                Button(action: { rateApp() }) {
                                    settingsRow(icon: "star.fill", title: "Rate Us")
                                }
                            }
                        }

                        // Logout Button
                        Button(action: {
                            showLogoutConfirmation = true
                        }) {
                            Text("Log Out")
                                .foregroundColor(.white)
                                .fontWeight(.bold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red)
                                .cornerRadius(10)
                                .shadow(radius: 5)
                        }
                        .padding(.horizontal)
                        .alert(isPresented: $showLogoutConfirmation) {
                            Alert(
                                title: Text("Confirm Logout"),
                                message: Text("Are you sure you want to log out?"),
                                primaryButton: .destructive(Text("Log Out"), action: logOut),
                                secondaryButton: .cancel()
                            )
                        }
                    }
                    .padding()
                    .onAppear {
                        loadUserData()
                        checkNotificationStatus()
                        fetchProfileImageFromFirebase()
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var profileCard: some View {
            VStack(spacing: 10) {
                ZStack {
                    if let image = profileImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.white, lineWidth: 4))
                            .shadow(radius: 10)
                    } else {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .foregroundColor(.white)
                            .background(Color.blue)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.white, lineWidth: 4))
                            .shadow(radius: 10)
                    }
                }
                .padding(.bottom, 10)

                Text(name)
                    .font(.title2)
                    .foregroundColor(.white)
                
                Text(email)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding()
            .background(Color.white.opacity(0.2))
            .cornerRadius(20)
            .shadow(radius: 10)
        }

    private func fetchProfileImageFromFirebase() {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        
        let profileImageRef = storageRef.child("profile_pictures/\(userID).jpg")

        // Clear any previous fetch tasks (fix for GTMSessionFetcher issue)
        URLSession.shared.invalidateAndCancel()

        profileImageRef.downloadURL { url, error in
            if let error = error {
                print("❌ Error fetching profile image URL: \(error.localizedDescription)")
                return
            }
            if let url = url {
                print("✅ Profile image URL fetched successfully: \(url)")
                loadImageFromURL(url)
            }
        }
    }

    private func loadImageFromURL(_ url: URL) {
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("❌ Error loading image from URL: \(error.localizedDescription)")
                return
            }
            if let data = data, let uiImage = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.profileImage = uiImage
                    print("✅ Profile image successfully loaded in SettingsView.")
                }
            } else {
                print("⚠️ Failed to convert image data.")
            }
        }.resume()
    }
    

    // MARK: - Load User Data from Firebase
    private func loadUserData() {
        if let user = Auth.auth().currentUser {
            name = user.displayName ?? "No Name"
            email = user.email ?? "No Email"
        } else {
            name = "Guest User"
            email = "Not Signed In"
        }
    }

    // MARK: - Manage Notifications
    private func manageNotifications() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                switch settings.authorizationStatus {
                case .authorized:
                    notificationsEnabled.toggle()
                    if notificationsEnabled {
                        enableNotifications()
                        print("✅ Notifications enabled successfully.")
                    } else {
                        disableNotifications()
                        print("🔕 Notifications disabled successfully.")
                    }
                case .denied, .notDetermined:
                    requestNotificationPermission()
                    print("⚠️ Notifications permission needed.")
                default:
                    print("❌ Unknown notification status.")
                }
            }
        }
    }
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                notificationsEnabled = true
                print("✅ Notifications enabled.")
            } else {
                print("❌ Notifications permission denied.")
            }
        }
    }

    private func enableNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    notificationsEnabled = true
                    print("✅ Notifications enabled.")

                    // Send a test notification
                    let content = UNMutableNotificationContent()
                    content.title = "LetsBeHealthy"
                    content.body = "This is a test notification!"
                    content.sound = .default

                    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
                    let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

                    UNUserNotificationCenter.current().add(request) { error in
                        if let error = error {
                            print("❌ Failed to schedule notification: \(error.localizedDescription)")
                        } else {
                            print("✅ Test notification scheduled.")
                        }
                    }
                } else {
                    notificationsEnabled = false
                    print("❌ Notifications permission denied.")
                }
            }
        }
    }

    private func disableNotifications() {
        // Disabling notifications programmatically isn't directly supported,
        // but you can manage in-app notification handling here.
        print("🔕 Notifications are now disabled.")
        // Optionally, show an alert if needed to guide users to system settings.
    }

    private func checkNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                notificationsEnabled = (settings.authorizationStatus == .authorized)
            }
        }
    }
    // MARK: - Feedback and Rating Functions
    private func sendFeedback() {
        let email = "letsbehealthy0@gmail.com"
        if let url = URL(string: "mailto:\(email)") {
            UIApplication.shared.open(url)
        }
    }

    private func rateApp() {
        if let url = URL(string: "itms-apps://itunes.apple.com/app/idYOUR_APP_ID?action=write-review"),
           UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }

    // MARK: - Log Out Function
    private func logOut() {
        do {
            try Auth.auth().signOut()
            print("✅ User successfully logged out.")
            // Handle navigation to login screen if needed
        } catch let signOutError as NSError {
            print("❌ Error signing out: \(signOutError.localizedDescription)")
        }
    }

    // MARK: - Reusable Components
    private func sectionCard(title: String, content: @escaping () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
            
            content()
        }
        .padding()
        .background(Color.white.opacity(0.2))
        .cornerRadius(20)
        .shadow(radius: 10)
    }

    private func settingsRow(icon: String, title: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
            Text(title)
                .foregroundColor(.white)
            Spacer()
        }
        .padding(.vertical, 10)
    }

    private func toggleRow(isOn: Binding<Bool>, icon: String, title: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
            Text(title)
                .foregroundColor(.white)
            Spacer()
            Toggle("", isOn: isOn)
                .labelsHidden()
        }
        .padding(.vertical, 10)
    }
}
