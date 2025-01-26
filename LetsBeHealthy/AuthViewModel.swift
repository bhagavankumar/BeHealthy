//
//  AuthViewModel.swift
//  LetsBeHealthy
//
//  Created by Bhagavan Kumar V on 2025-01-15.
//

import SwiftUI
import Foundation
import FirebaseAuth
import FirebaseFirestore

class AuthViewModel: ObservableObject {
    @Published var users: [User] = [] {
        didSet {
            saveUsers()
        }
    }
    @Published var errorMessage: String = ""
    
    init() {
        loadUsers()
    }

    private func saveUsers() {
        if let data = try? JSONEncoder().encode(users) {
            UserDefaults.standard.set(data, forKey: "users")
        }
    }
    
    private func loadUsers() {
        if let data = UserDefaults.standard.data(forKey: "users"),
           let decodedUsers = try? JSONDecoder().decode([User].self, from: data) {
            users = decodedUsers
        }
    }

    func signUp(firstName: String, lastName: String, email: String, password: String, dateOfBirth: Date, referralCode: String?, completion: @escaping (Bool) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                self.errorMessage = "❌ Signup failed: \(error.localizedDescription)"
                completion(false)
                return
            }

            guard let user = result?.user else {
                completion(false)
                return
            }

            let userData: [String: Any] = [
                "firstName": firstName,
                "lastName": lastName,
                "email": email,
                "dateOfBirth": dateOfBirth.timeIntervalSince1970, // Store as timestamp
                "referralCode": referralCode ?? ""
            ]

            Firestore.firestore().collection("users").document(user.uid).setData(userData) { error in
                if let error = error {
                    self.errorMessage = "❌ Failed to save user data: \(error.localizedDescription)"
                    completion(false)
                } else {
                    completion(true)
                }
            }
        }
    }

    // 🔹 Resend Email Verification
    func resendEmailVerification(completion: @escaping (Bool) -> Void) {
        if let user = Auth.auth().currentUser {
            user.sendEmailVerification { [weak self] error in
                guard let self = self else { return } // ✅ Fix: Ensure self exists
                
                if let error = error {
                    self.errorMessage = "❌ Error resending verification email: \(error.localizedDescription)"
                    completion(false)
                } else {
                    print("✅ Verification email resent")
                    completion(true)
                }
            }
        } else {
            errorMessage = "❌ No user found"
            completion(false)
        }
    }

    // 🔹 Check if Email is Verified
    func checkEmailVerification(completion: @escaping (Bool) -> Void) {
        if let user = Auth.auth().currentUser {
            user.reload { [weak self] error in
                guard let self = self else { return } // ✅ Fix: Ensure self exists
                
                if let error = error {
                    self.errorMessage = "❌ Error checking email verification: \(error.localizedDescription)"
                    completion(false)
                    return
                }
                print("✅ Email Verified: \(user.isEmailVerified)")
                completion(user.isEmailVerified) // ✅ Returns true if verified
            }
        } else {
            completion(false)
        }
    }


    func login(email: String, password: String, completion: @escaping (Bool, User?) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            if let error = error {
                self.errorMessage = "❌ Login failed: \(error.localizedDescription)"
                completion(false, nil)
                return
            }

            guard let userId = authResult?.user.uid else {
                self.errorMessage = "❌ User ID not found"
                completion(false, nil)
                return
            }

            // Fetch user details from Firestore after login
            let db = Firestore.firestore()
            db.collection("users").document(userId).getDocument { document, error in
                if let document = document, document.exists, let userData = document.data() {
                    let firstName = userData["firstName"] as? String ?? ""
                    let lastName = userData["lastName"] as? String ?? ""
                    
                    let loggedInUser = User(
                        firstName: firstName,
                        lastName: lastName,
                        email: email,
                        password: "" // Password should never be stored in plaintext
                    )
                    completion(true, loggedInUser)
                } else {
                    self.errorMessage = "❌ Failed to retrieve user details"
                    completion(false, nil)
                }
            }
        }
    }
}
