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

    func signUp(firstName: String, lastName: String, username: String, email: String, password: String, dateOfBirth: Date, referralCode: String?, completion: @escaping (Bool, AppUser?) -> Void) {
        let usernameLower = username.lowercased()
        let db = Firestore.firestore()

        // ✅ Check if username already exists
        db.collection("usernames").document(usernameLower).getDocument { document, error in
            if let error = error {
                print("❌ Firestore error checking username: \(error.localizedDescription)")
                completion(false, nil)
                return
            }

            if let document = document, document.exists {
                print("❌ Username already taken")
                completion(false, nil)
                return
            }

            // ✅ Username is available, proceed with account creation
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
                    
                    // ✅ Save user data to Firestore
                    self.saveUserToFirestore(
                        uid: user.uid,
                        firstName: firstName,
                        lastName: lastName,
                        username: username,
                        email: email,
                        dateOfBirth: dateOfBirth,
                        referralCode: referralCode
                    ) { success in
                        if success {
                            // ✅ Store the username in `usernames` collection
                            db.collection("usernames").document(usernameLower).setData(["uid": user.uid]) { error in
                                if let error = error {
                                    print("❌ Failed to save username: \(error.localizedDescription)")
                                    user.delete { _ in
                                        self.handleError(message: "❌ Username save failed. Account removed.")
                                        completion(false, nil)
                                    }
                                } else {
                                    print("✅ Username stored successfully in Firestore")
                                    let newUser = AppUser(firstName: firstName, lastName: lastName, email: email)
                                    completion(true, newUser)
                                }
                            }
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
    }
    
    private func saveUserToFirestore(uid: String, firstName: String, lastName: String, username: String, email: String, dateOfBirth: Date, referralCode: String?, completion: @escaping (Bool) -> Void) {
        let db = Firestore.firestore()
        let userData: [String: Any] = [
            "firstName": firstName,
            "lastName": lastName,
            "username": username,  // ✅ Store username
            "username_lowercase": username.lowercased(),  // ✅ Store lowercase for easy search
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

    func login(emailOrUsername: String, password: String, completion: @escaping (Bool, AppUser?) -> Void) {
        let db = Firestore.firestore()
        
        if emailOrUsername.contains("@") {
            // ✅ Login using email
            Auth.auth().signIn(withEmail: emailOrUsername, password: password) { [weak self] authResult, error in
                self?.handleLoginResponse(authResult: authResult, error: error, completion: completion)
            }
        } else {
            // ✅ Login using username → Find email first
            let usernameLower = emailOrUsername.lowercased()
            db.collection("usernames").document(usernameLower).getDocument { document, error in
                if let error = error {
                    print("❌ Firestore error checking username: \(error.localizedDescription)")
                    completion(false, nil)
                    return
                }
                
                guard let document = document, document.exists,
                      let uid = document.data()?["uid"] as? String else {
                    print("❌ Username not found")
                    completion(false, nil)
                    return
                }
                
                // ✅ Get email from Firestore
                db.collection("users").document(uid).getDocument { userDoc, userError in
                    if let userError = userError {
                        print("❌ Error fetching user email: \(userError.localizedDescription)")
                        completion(false, nil)
                        return
                    }
                    
                    if let userDoc = userDoc, userDoc.exists,
                       let email = userDoc.data()?["email"] as? String {
                        print("✅ Found email for username: \(email)")
                        
                        // ✅ Login using retrieved email
                        Auth.auth().signIn(withEmail: email, password: password) { [weak self] authResult, error in
                            self?.handleLoginResponse(authResult: authResult, error: error, completion: completion)
                        }
                    } else {
                        print("❌ Email not found for username")
                        completion(false, nil)
                    }
                }
            }
        }
    }

    private func handleLoginResponse(authResult: AuthDataResult?, error: Error?, completion: @escaping (Bool, AppUser?) -> Void) {
        if let error = error {
            print("❌ Login failed: \(error.localizedDescription)")
            completion(false, nil)
            return
        }
        
        guard let user = authResult?.user else {
            print("❌ User not found")
            completion(false, nil)
            return
        }
        
        if !user.isEmailVerified {
            print("❌ Please verify your email first")
            completion(false, nil)
            return
        }
        
        fetchUserDetails(uid: user.uid, completion: completion)
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
