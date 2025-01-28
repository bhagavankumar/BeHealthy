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
    @StateObject private var authViewModel = AuthViewModel()
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

    func signUp(firstName: String, lastName: String, email: String, password: String, dateOfBirth: Date, referralCode: String?, completion: @escaping (Bool, User?) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = "❌ Signup failed: \(error.localizedDescription)"
                }
                print("❌ Firebase Auth Error: \(error.localizedDescription)")
                completion(false,nil)
                return
            }

            guard let user = result?.user else {
                DispatchQueue.main.async {
                    self.errorMessage = "❌ User creation failed. Try again."
                }
                completion(false,nil)
                return
            }
            self.saveUserToFirestore(uid: user.uid, firstName: firstName, lastName: lastName, email: email, dateOfBirth: dateOfBirth, referralCode: referralCode)

                    let newUser = User(firstName: firstName, lastName: lastName, email: email, password: "")
                    completion(true, newUser)

            print("✅ User created with UID: \(user.uid)")

            let userData: [String: Any] = [
                "firstName": firstName,
                "lastName": lastName,
                "email": email,
                "dateOfBirth": dateOfBirth.timeIntervalSince1970,
                "referralCode": referralCode ?? ""
            ]

            let db = Firestore.firestore()

            db.collection("users").document(user.uid).setData(userData) { error in
                if let error = error {
                    DispatchQueue.main.async {
                        self.errorMessage = "❌ Failed to save user data: \(error.localizedDescription)"
                    }
                    print("❌ Firestore Error: \(error.localizedDescription)")

                    // **Rollback: Delete the user from FirebaseAuth if Firestore write fails**
                    user.delete { deleteError in
                        if let deleteError = deleteError {
                            print("⚠️ Failed to delete user from Auth: \(deleteError.localizedDescription)")
                        } else {
                            print("🗑 User deleted from Auth due to Firestore failure")
                        }
                    }
                    completion(false,nil)
                } else {
                    print("✅ User data saved to Firestore successfully!")
                    completion(true,nil)
                }
            }
            
        }
    }
    private func saveUserToFirestore(uid: String, firstName: String, lastName: String, email: String, dateOfBirth: Date, referralCode: String?) {
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(uid)
        
        let userData: [String: Any] = [
            "firstName": firstName,
            "lastName": lastName,
            "email": email,
            "dateOfBirth": Timestamp(date: dateOfBirth),
            "referralCode": referralCode ?? "",
            "createdAt": Timestamp(date: Date())
        ]
        
        userRef.setData(userData) { error in
            if let error = error {
                print("❌ Failed to save user data: \(error.localizedDescription)")
            } else {
                print("✅ User data successfully saved in Firestore!")
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
                print("❌ Login failed: \(error.localizedDescription)")
                self.errorMessage = "❌ Login failed: \(error.localizedDescription)"
                completion(false, nil)
                return
            }

            guard let userId = authResult?.user.uid else {
                print("❌ Failed to retrieve user UID")
                self.errorMessage = "❌ User ID not found"
                completion(false, nil)
                return
            }

            print("✅ User signed in with UID: \(userId)")

            // Retrieve user details from Firestore
            let db = Firestore.firestore()
            db.collection("users").document(userId).getDocument { document, error in
                if let error = error {
                    print("❌ Failed to retrieve user details: \(error.localizedDescription)")
                    completion(false, nil)
                    return
                }

                if let document = document, document.exists {
                    let data = document.data()
                    print("✅ User details fetched: \(data ?? [:])")

                    let firstName = data?["firstName"] as? String ?? ""
                    let lastName = data?["lastName"] as? String ?? ""
                    let email = data?["email"] as? String ?? ""

                    let user = User(firstName: firstName, lastName: lastName, email: email, password: "")
                    completion(true, user)
                } else {
                    print("❌ User document does not exist in Firestore!")
                    self.errorMessage = "❌ Failed to retrieve user details"
                    completion(false, nil)
                }
            }
        }
    }
}

