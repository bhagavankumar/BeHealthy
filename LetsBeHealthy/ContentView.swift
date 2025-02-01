import SwiftUI
import FirebaseAuth
import GoogleSignIn
struct ContentView: View {
    
    @State private var isLoggedIn: Bool = false
    @Binding var user: AppUser?

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
                    MainMenuView()
                    
                }
            }
            else {
                LoginView(isLoggedIn: $isLoggedIn, user: $user)
            }
        }
        .background(Color(.systemBackground).opacity(0.2))
    }
}

struct MainMenuView: View {
    var body: some View {
        TabView {
            StepTrackerView()
                .tabItem {
                    Label("Steps", systemImage: "figure.walk")
                }
            RewardsView()
                .tabItem {
                    Label("Rewards", systemImage: "gift")
                }
            AnalyticsView()
                .tabItem {
                    Label("Analytics", systemImage: "chart.bar.fill")
                }
        }
    }
}
