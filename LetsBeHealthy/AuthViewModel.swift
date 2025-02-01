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
    @Published var users: [AppUser] = [] {
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
           let decodedUsers = try? JSONDecoder().decode([AppUser].self, from: data) {
            users = decodedUsers
        }
    }

    func signUp(firstName: String, lastName: String, email: String, password: String, dateOfBirth: Date, referralCode: String?, completion: @escaping (Bool, AppUser?) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            guard let self = self else { return }
            
            if let error = error {
                self.handleError(error: error, message: "❌ Signup failed: \(error.localizedDescription)")
                completion(false, nil)
                return
            }
            
            guard let user = result?.user else {
                self.handleError(message: "❌ User creation failed. Try again.")
                completion(false, nil)
                return
            }
            user.sendEmailVerification { error in
                if let error = error {
                    self.errorMessage = "Failed to send verification email: \(error.localizedDescription)"
                    completion(false, nil)
                    return
                }
                do {
                    try Auth.auth().signOut()
                    self.errorMessage = ""
                    completion(true, AppUser(firstName: firstName, lastName: lastName, email: email))
                } catch {
                    self.errorMessage = "Failed to sign out: \(error.localizedDescription)"
                    completion(false, nil)
                }
                
                
                self.saveUserToFirestore(
                    uid: user.uid,
                    firstName: firstName,
                    lastName: lastName,
                    email: email,
                    dateOfBirth: dateOfBirth,
                    referralCode: referralCode
                ) { success in
                    if success {
                        let newUser = AppUser(firstName: firstName, lastName: lastName, email: email)
                        completion(true, newUser)
                        print("✅ User created with UID: \(user.uid)")
                    } else {
                        user.delete { _ in
                            self.handleError(message: "❌ Failed to save user data. Account removed.")
                            completion(false, nil)
                        }
                    }
                }
            }
        }
    }
    
    private func saveUserToFirestore(uid: String, firstName: String, lastName: String, email: String, dateOfBirth: Date, referralCode: String?, completion: @escaping (Bool) -> Void) {
        let db = Firestore.firestore()
        let userData: [String: Any] = [
            "firstName": firstName,
            "lastName": lastName,
            "email": email,
            "dateOfBirth": Timestamp(date: dateOfBirth),
            "referralCode": referralCode ?? "",
            "createdAt": Timestamp(date: Date())
        ]
        
        db.collection("users").document(uid).setData(userData) { error in
            if let error = error {
                print("❌ Firestore save error: \(error.localizedDescription)")
                completion(false)
            } else {
                print("✅ Firestore save successful")
                completion(true)
            }
        }
    }

    func resendEmailVerification(completion: @escaping (Bool) -> Void) {
        if let user = Auth.auth().currentUser {
            user.sendEmailVerification { [weak self] error in
                guard let self = self else { return }
                
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

    func checkEmailVerification(completion: @escaping (Bool) -> Void) {
        if let user = Auth.auth().currentUser {
            user.reload { [weak self] error in
                guard let self = self else { return }
                
                if let error = error {
                    self.errorMessage = "❌ Error checking email verification: \(error.localizedDescription)"
                    completion(false)
                    return
                }
                print("✅ Email Verified: \(user.isEmailVerified)")
                completion(user.isEmailVerified)
            }
        } else {
            completion(false)
        }
    }

    func login(email: String, password: String, completion: @escaping (Bool, AppUser?) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] authResult, error in
            guard let self = self else { return }
            
            if let error = error {
                self.handleError(error: error, message: "❌ Login failed: \(error.localizedDescription)")
                completion(false, nil)
                return
            }
            
            guard let user = authResult?.user else {
                self.handleError(message: "❌ User not found")
                completion(false, nil)
                return
            }
            
            if !user.isEmailVerified {
                self.handleError(message: "❌ Please verify your email first")
                completion(false, nil)
                return
            }
            
            self.fetchUserDetails(uid: user.uid, completion: completion)
        }
    }
    
    private func fetchUserDetails(uid: String, completion: @escaping (Bool, AppUser?) -> Void) {
        let db = Firestore.firestore()
        db.collection("users").document(uid).getDocument { document, error in
            if let error = error {
                print("❌ Firestore fetch error: \(error.localizedDescription)")
                completion(false, nil)
                return
            }
            
            guard let document = document, document.exists else {
                print("❌ User document missing")
                completion(false, nil)
                return
            }
            
            if let data = document.data() {
                let firstName = data["firstName"] as? String ?? ""
                let lastName = data["lastName"] as? String ?? ""
                let email = data["email"] as? String ?? ""
                
                let user = AppUser(firstName: firstName, lastName: lastName, email: email)
                completion(true, user)
            } else {
                completion(false, nil)
            }
        }
    }
    
    // MARK: - Helper Methods
    private func handleError(error: Error? = nil, message: String) {
        DispatchQueue.main.async {
            self.errorMessage = message
            if let error = error {
                print("Error: \(error.localizedDescription)")
            }
        }
    }
    
    func handleSocialSignIn(user: AppUser, uid: String, completion: @escaping (Bool) -> Void) {
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(uid)
        
        userRef.getDocument { document, _ in
            if let document = document, document.exists {
                completion(true)
            } else {
                let userData: [String: Any] = [
                    "firstName": user.firstName,
                    "lastName": user.lastName,
                    "email": user.email,
                    "createdAt": Timestamp(date: Date())
                ]
                
                userRef.setData(userData) { error in
                    completion(error == nil)
                }
            }
        }
    }
}
