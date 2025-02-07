//
//  AuthManager.swift
//  LetsBeHealthy
//
//  Created by Bhagavan Kumar V on 2025-01-29.
//


import Foundation
import FirebaseAuth
import GoogleSignIn
import FirebaseFirestore

class AuthManager: ObservableObject {
    static let shared = AuthManager()
    
    @Published var appUser: AppUser?
        private var authStateListenerHandle: AuthStateDidChangeListenerHandle?
        
        private init() {
            setupAuthListener()
        }
    
    private func setupAuthListener() {
        authStateListenerHandle = Auth.auth().addStateDidChangeListener { [weak self] (_, firebaseUser) in
            guard let self = self else { return }
            self.updateUser(from: firebaseUser)
        }
    }
    
    deinit {
        if let handle = authStateListenerHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
    
    private func updateUser(from firebaseUser: FirebaseAuth.User?) {
        guard let firebaseUser = firebaseUser else {
            appUser = nil
            return
        }
        
        let nameComponents = firebaseUser.displayName?.components(separatedBy: " ") ?? []
        appUser = AppUser(
            firstName: nameComponents.first ?? "",
            lastName: nameComponents.dropFirst().joined(separator: " "),
            email: firebaseUser.email ?? ""
        )
    }
    
    // MARK: - Google Sign-In
    func handleGoogleURL(_ url: URL) {
        GIDSignIn.sharedInstance.handle(url)
    }
    
    func restoreGoogleSignIn() {
        GIDSignIn.sharedInstance.restorePreviousSignIn { user, error in
            guard error == nil, let gidUser = user else { return }
            
            let credential = GoogleAuthProvider.credential(
                withIDToken: gidUser.idToken!.tokenString,
                accessToken: gidUser.accessToken.tokenString
            )
            
            Auth.auth().signIn(with: credential) { _, error in
                if let error = error {
                    print("Google Firebase auth error: \(error)")
                }
            }
        }
    }
    
    // MARK: - Email/Password Auth
    func signIn(email: String, password: String, completion: @escaping (Error?) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            if let error = error {
                completion(error)
                return
            }
            self.updateUser(from: authResult?.user)
            completion(nil)
        }
    }
    
        func signUp(email: String, password: String, firstName: String, lastName: String, dateOfBirth: Date , referralCode: String?, completion: @escaping (Error?) -> Void) { // Added referralCode parameter
                Auth.auth().createUser(withEmail: email, password: password) { result, error in
                    if let error = error {
                        completion(error)
                        return
                    }
                    
                    guard let user = result?.user else {
                        completion(NSError(domain: "AuthError", code: -1, userInfo: [NSLocalizedDescriptionKey: "User creation failed"]))
                        return
                    }
                    user.sendEmailVerification { error in
                            if let error = error {
                                print("Error sending verification email: \(error.localizedDescription)")
                            }
                        }
                    
                    let changeRequest = user.createProfileChangeRequest()
                    changeRequest.displayName = "\(firstName) \(lastName)"
                    changeRequest.commitChanges { error in
                        self.updateUser(from: user)
                        
                        // Generate new user's referral code
                        let newReferralCode = UUID().uuidString.components(separatedBy: "-").first!.lowercased()
                        let db = Firestore.firestore()
                        let userRef = db.collection("users").document(user.uid)
                        
                        // Set user data
                        userRef.setData([
                            "firstName": firstName,
                            "lastName": lastName,
                            "email": email,
                            "dateOfBirth": Timestamp(date: dateOfBirth),
                            "referralCode": newReferralCode,
                            "stepcoins": 0
                        ]) { error in
                            if let error = error {
                                print("Error writing user document: \(error)")
                            }
                        }
                        
                        // Handle referral code if exists
                        if let referralCode = referralCode, !referralCode.isEmpty {
                            let usersRef = db.collection("users")
                            usersRef.whereField("referralCode", isEqualTo: referralCode).getDocuments { snapshot, _ in
                                guard let inviterDoc = snapshot?.documents.first else { return }
                                
                                usersRef.document(inviterDoc.documentID).updateData([
                                    "stepcoins": FieldValue.increment(Int64(200))
                                ])
                                
                                usersRef.document(user.uid).updateData([
                                    "stepcoins": FieldValue.increment(Int64(200))
                                ])
                            }
                        }
                        
                        completion(error)
                    }
                }
            }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            GIDSignIn.sharedInstance.signOut()
            self.appUser = nil
        } catch {
            print("Sign out error: \(error)")
        }
    }
}

// 🔹 User Model
struct AppUser: Codable {
    var firstName: String
    var lastName: String
    var email: String
}
