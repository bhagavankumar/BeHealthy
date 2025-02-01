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
    @StateObject private var authManager = AuthManager.shared
        
        init() {
            AppCheck.setAppCheckProviderFactory(nil)
            FirebaseApp.configure()
            print("🚀 Firebase Successfully Configured Without App Check!")
        }

        var body: some Scene {
            WindowGroup {
                ContentView(user: $authManager.appUser) // ✅ Updated to use shared instance
                    .environmentObject(authManager)
                    .onOpenURL { url in
                        AuthManager.shared.handleGoogleURL(url)
                    }
                    .onAppear {
                        AuthManager.shared.restoreGoogleSignIn()
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

