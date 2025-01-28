//
//  LetsBeHealthyApp.swift
//  LetsBeHealthy
//
//  Created by Bhagavan Kumar V on 2025-01-09.
//

import SwiftUI
import GoogleSignIn
import Firebase
import FirebaseAppCheck
import FirebaseCore
@main
struct LetsBeHealthyApp: App {
    @State private var isLoggedIn: Bool = false
    @State var user: User?
    //@StateObject private var firestoreManager = FirestoreManager()
    init() {
        AppCheck.setAppCheckProviderFactory(nil)
        FirebaseApp.configure()
        print("🚀 Firebase Successfully Configured Without App Check!")
//        AppCheck.appCheck().isTokenAutoRefreshEnabled = false // 🔥 Disable App Check
//            
    }

    var body: some Scene {
        WindowGroup {
            ContentView(user: self.$user)
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url) // ✅ FIX: Correct URL handling
                }
                .onAppear {
                    GIDSignIn.sharedInstance.restorePreviousSignIn { user, error in
                        if let user = user {
                            self.user = User(
                                firstName: user.profile?.givenName ?? "",
                                lastName: user.profile?.familyName ?? "",
                                email: user.profile?.email ?? "",
                                password: ""
                            )
                            isLoggedIn = true
                        }
                    }
                }
        }
    }
}

// 🔹 Firestore Manager for Global Use
//class FirestoreManager: ObservableObject {
//    @Published var db = Firestore.firestore() // ✅ FIX: Firestore instance is @Published
//
//    func setupFirestore() {
//        print("🔥 Firestore Initialized: \(db)")
//    }
//}

// 🔹 User Model
struct User: Codable {
    var firstName: String
    var lastName: String
    var email: String
    var password: String
}
