//
//  ChangePasswordView.swift
//  LetsBeHealthy
//
//  Created by Bhagavan Kumar V on 2025-02-03.
//


import SwiftUI

struct ChangePasswordView: View {
    @State private var currentPassword: String = ""
    @State private var newPassword: String = ""
    @State private var confirmPassword: String = ""
    @State private var showPasswordMismatchAlert = false
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        Form {
            Section(header: Text("Current Password")) {
                SecureField("Enter current password", text: $currentPassword)
            }

            Section(header: Text("New Password")) {
                SecureField("Enter new password", text: $newPassword)
                SecureField("Confirm new password", text: $confirmPassword)
            }

            Section {
                Button("Change Password") {
                    if newPassword == confirmPassword {
                        // Logic to update password
                        presentationMode.wrappedValue.dismiss()
                    } else {
                        showPasswordMismatchAlert = true
                    }
                }
                .disabled(currentPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty)
                .alert(isPresented: $showPasswordMismatchAlert) {
                    Alert(title: Text("Error"),
                          message: Text("New passwords do not match."),
                          dismissButton: .default(Text("OK")))
                }
            }
        }
        .navigationTitle("Change Password")
    }
}

struct ChangePasswordView_Previews: PreviewProvider {
    static var previews: some View {
        ChangePasswordView()
    }
}
