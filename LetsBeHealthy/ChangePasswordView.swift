//
//  ChangePasswordView 2.swift
//  LetsBeHealthy
//
//  Created by Bhagavan Kumar V on 2025-02-05.
//


import SwiftUI
import FirebaseAuth

struct ChangePasswordView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var oldPassword: String = ""
    @State private var newPassword: String = ""
    @State private var confirmPassword: String = ""
    
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.8)]),
                           startPoint: .top,
                           endPoint: .bottom)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                // Title
                Text("Change Password")
                    .font(.largeTitle)
                    .foregroundColor(.white)
                    .padding(.top, 40)
                
                // Old Password
                SecureField("Enter Old Password", text: $oldPassword)
                    .padding()
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(10)
                    .foregroundColor(.white)
                    .padding(.horizontal)
                
                // New Password
                SecureField("Enter New Password", text: $newPassword)
                    .padding()
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(10)
                    .foregroundColor(.white)
                    .padding(.horizontal)
                
                // Confirm New Password
                SecureField("Confirm New Password", text: $confirmPassword)
                    .padding()
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(10)
                    .foregroundColor(.white)
                    .padding(.horizontal)
                
                // Change Password Button
                Button(action: {
                    changePassword()
                }) {
                    Text("Change Password")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .shadow(radius: 5)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding()
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Password Update"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"), action: {
                        if alertMessage == "Password updated successfully. Please log in again." {
                            logOut()
                        }
                    })
                )
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Change Password Logic
    private func changePassword() {
        guard !oldPassword.isEmpty, !newPassword.isEmpty, !confirmPassword.isEmpty else {
            alertMessage = "Please fill in all fields."
            showAlert = true
            return
        }
        
        guard newPassword == confirmPassword else {
            alertMessage = "New passwords do not match."
            showAlert = true
            return
        }
        
        guard newPassword.count >= 6 else {
            alertMessage = "Password should be at least 6 characters long."
            showAlert = true
            return
        }
        
        reAuthenticateAndChangePassword()
    }
    
    // MARK: - Re-authenticate User and Update Password
    private func reAuthenticateAndChangePassword() {
        guard let user = Auth.auth().currentUser, let email = user.email else {
            alertMessage = "No authenticated user found."
            showAlert = true
            return
        }
        
        let credential = EmailAuthProvider.credential(withEmail: email, password: oldPassword)
        
        user.reauthenticate(with: credential) { result, error in
            if let error = error {
                alertMessage = "Re-authentication failed: \(error.localizedDescription)"
                showAlert = true
            } else {
                updatePassword()
            }
        }
    }
    
    // MARK: - Update Password in Firebase
    private func updatePassword() {
        guard let user = Auth.auth().currentUser else { return }
        
        user.updatePassword(to: newPassword) { error in
            if let error = error {
                alertMessage = "Failed to update password: \(error.localizedDescription)"
            } else {
                alertMessage = "Password updated successfully. Please log in again."
            }
            showAlert = true
        }
    }
    
    // MARK: - Log Out User
    private func logOut() {
        do {
            try Auth.auth().signOut()
            presentationMode.wrappedValue.dismiss()  // Navigate back to login screen
        } catch let signOutError as NSError {
            alertMessage = "Error signing out: \(signOutError.localizedDescription)"
            showAlert = true
        }
    }
}