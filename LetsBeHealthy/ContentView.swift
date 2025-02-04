import SwiftUI
import FirebaseAuth
import GoogleSignIn
struct ContentView: View {
    
    @State private var isLoggedIn: Bool = false
    @Binding var user: AppUser?
    @State private var selectedTab: String = "Steps"
    @State private var isMenuOpen: Bool = false

    var body: some View {
        NavigationView {
            if let user {
                VStack {
                    if isLoggedIn {
                        Text("Hi there, \(user.lastName)")
                            .font(.largeTitle)
                            .padding()
                    }
                    Button {
                        GIDSignIn.sharedInstance.signOut()
                        self.user=nil
                    } label: {
                    Text("Log out")
                    }
                    TabView(selection: $selectedTab) {
                        StepTrackerView(selectedTab: $selectedTab)
                            .tag("Steps")
                            .tabItem {
                                Label("Steps", systemImage: "figure.walk")
                            }

                        RewardsView()
                            .tag("Rewards")
                            .tabItem {
                                Label("Rewards", systemImage: "gift.fill")
                            }

                        AnalyticsView()
                            .tag("Analytics")
                            .tabItem {
                                Label("Analytics", systemImage: "chart.bar.fill")
                            }
                        ProfileView()
                               .tag("Profile")
                               .tabItem {
                                   Label("Profile", systemImage: "person.crop.circle.fill")
                               }
                    }
                }
            }
            else {
                LoginView(isLoggedIn: $isLoggedIn, user: $user)
            }
        }
        .background(Color(.systemBackground).opacity(0.2))
    }
}

