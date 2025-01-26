//
//  AuthViewModel.swift
//  LetsBeHealthy
//
//  Created by Bhagavan Kumar V on 2025-01-15.
//

import SwiftUI
import Foundation
import FirebaseAuth

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

    // 🔹 Complete Signup with Email Verification
    func signUp(name: String, email: String, password: String, completion: @escaping (Bool) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            guard let self = self else { return } // ✅ Fix: Ensure self exists
            
            if let error = error {
                self.errorMessage = "❌ Signup failed: \(error.localizedDescription)"
                completion(false)
                return
            }

            // ✅ Send Email Verification
            result?.user.sendEmailVerification { error in
                if let error = error {
                    self.errorMessage = "❌ Verification email not sent: \(error.localizedDescription)"
                    completion(false)
                } else {
                    print("✅ Verification email sent to \(email)")
                    completion(true) // ✅ Signup Successful, Email Verification Pending
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

    // 🔹 Email & Password Login
    func login(email: String, password: String, completion: @escaping (Bool) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            guard let self = self else { return } // ✅ Fix: Ensure self exists
            
            if let error = error {
                self.errorMessage = "❌ Login failed: \(error.localizedDescription)"
                completion(false)
                return
            }

            guard let user = result?.user else {
                self.errorMessage = "❌ User not found"
                completion(false)
                return
            }

            // ✅ Ensure Email is Verified Before Allowing Login
            if user.isEmailVerified {
                print("✅ Login Successful")
                completion(true)
            } else {
                self.errorMessage = "❌ Email not verified. Please check your inbox."
                completion(false)
            }
        }
    }
}
