//
//  LetsBeHealthyApp.swift
//  LetsBeHealthy
//
//  Created by Bhagavan Kumar V on 2025-01-09.
//

import SwiftUI
import GoogleSignIn
//import Firebase
//import FirebaseFirestore

@main
struct LetsBeHealthyApp: App {
    @State private var isLoggedIn: Bool = false
    @State var user: User?
    //@StateObject private var firestoreManager = FirestoreManager() //

//    init() {
//        FirebaseApp.configure() // 🔥 Initialize Firebase
//    }

    var body: some Scene {
        WindowGroup {
            ContentView(user: self.$user)
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
                .onAppear {
                    GIDSignIn.sharedInstance.restorePreviousSignIn { user, error in
                        if let user {
                            self.user = .init(name: user.profile?.name ?? "", email: user.profile?.email ?? "", password: "")
                            LoginView(isLoggedIn: $isLoggedIn, user: $user)
                        }
                    }
                    //                    firestoreManager.setupFirestore() // 🔥 Initialize Firestore when app appears
                    //
                }
        }
    }
}

// 🔹 Firestore Manager for Global Use
//class FirestoreManager: ObservableObject {
//    let db = Firestore.firestore()
//
//    func setupFirestore() {
//        print("🔥 Firestore Initialized: \(db)")
//    }
//}

// 🔹 User Model
struct User: Codable {
    var name: String
    var email: String
    var password: String
}
