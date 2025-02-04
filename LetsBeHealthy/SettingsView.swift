import SwiftUI

struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var isDarkMode = false
    @State private var isLocationEnabled = true
    @State private var notificationsEnabled = true
    @State private var showLogoutConfirmation = false
    
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
                        // User Profile Card
                        profileCard
                        
                        // Account Section
                        sectionCard(title: "Account") {
                            NavigationLink(destination: ChangePasswordView()) {
                                settingsRow(icon: "lock.fill", title: "Change Password")
                            }
                            
                            NavigationLink(destination: NotificationsSettingsView()) {
                                settingsRow(icon: "bell.fill", title: "Manage Notifications")
                            }
                        }
                        
                        // Preferences Section
                        sectionCard(title: "Preferences") {
                            toggleRow(isOn: $isDarkMode, icon: isDarkMode ? "moon.fill" : "sun.max.fill", title: "Dark Mode")
                            
                            toggleRow(isOn: $isLocationEnabled, icon: "location.fill", title: "Enable Location")
                        }
                        
                        // App Settings Section
                        sectionCard(title: "App Settings") {
                            toggleRow(isOn: $notificationsEnabled, icon: "bell.badge.fill", title: "Enable Notifications")
                        }
                        
                        // Feedback Section
                        sectionCard(title: "Feedback") {
                            Button(action: { sendFeedback() }) {
                                settingsRow(icon: "bubble.left.and.bubble.right.fill", title: "Send Feedback")
                            }
                            
                            Button(action: { rateApp() }) {
                                settingsRow(icon: "star.fill", title: "Rate Us")
                            }
                        }
                        
                        // Logout Button
                        Button(action: {
                            showLogoutConfirmation = true
                        }) {
                            settingsRow(icon: "arrow.backward.square.fill", title: "Log Out", isDestructive: true)
                        }
                        .alert(isPresented: $showLogoutConfirmation) {
                            Alert(
                                title: Text("Confirm Logout"),
                                message: Text("Are you sure you want to log out?"),
                                primaryButton: .destructive(Text("Log Out")) {
                                    // Handle logout logic here
                                },
                                secondaryButton: .cancel()
                            )
                        }
                        
                        // App Version Info
                        Text("App Version 1.0.0")
                            .foregroundColor(.white.opacity(0.7))
                            .font(.footnote)
                            .padding(.top, 20)
                    }
                    .padding()
                }
            }
            .navigationTitle("Settings")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    // MARK: - Custom Components
    
    // Profile Card
    private var profileCard: some View {
        HStack {
            Image(systemName: "person.crop.circle.fill")
                .resizable()
                .frame(width: 60, height: 60)
                .foregroundColor(.blue)
                .padding(.trailing, 10)
            
            VStack(alignment: .leading) {
                Text("John Doe")
                    .font(.title2)
                    .bold()
                    .foregroundColor(.white)
                Text("john.doe@example.com")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
            }
            Spacer()
        }
        .padding()
        .background(Color.white.opacity(0.2))
        .cornerRadius(20)
        .shadow(radius: 10)
    }
    
    // Section Card
    private func sectionCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white.opacity(0.9))
                .padding(.bottom, 5)
            
            VStack(spacing: 0) {
                content()
            }
            .background(Color.white.opacity(0.2))
            .cornerRadius(15)
        }
    }
    
    // Settings Row
    private func settingsRow(icon: String, title: String, isDestructive: Bool = false) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(isDestructive ? .red : .white)
                .frame(width: 30)
            
            Text(title)
                .foregroundColor(isDestructive ? .red : .white)
            
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.white.opacity(0.6))
        }
        .padding()
        .background(Color.clear)
    }
    
    // Toggle Row
    private func toggleRow(isOn: Binding<Bool>, icon: String, title: String) -> some View {
        Toggle(isOn: isOn) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.white)
                    .frame(width: 30)
                
                Text(title)
                    .foregroundColor(.white)
            }
        }
        .padding()
        .background(Color.clear)
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
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
