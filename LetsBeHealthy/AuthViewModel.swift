//
//  AuthViewModel.swift
//  LetsBeHealthy
//
//  Created by Bhagavan Kumar V on 2025-01-15.
//
import SwiftUI
import Foundation

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
    
    func signUp(name: String, email: String, password: String) -> Bool {
        // Validate input
        guard !name.isEmpty, !email.isEmpty, !password.isEmpty else {
            errorMessage = "All fields are required."
            return false
        }
        
        // Check if the email already exists
        if users.contains(where: { $0.email == email }) {
            errorMessage = "Email is already registered."
            return false
        }
        
        // Save the new user
        let newUser = User(name: name, email: email, password: password)
        users.append(newUser)
        return true
    }
    
    func login(email: String, password: String) -> Bool {
        // Validate input
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "All fields are required."
            return false
        }
        
        // Check if the user exists
        if let user = users.first(where: { $0.email == email && $0.password == password }) {
            print("Welcome \(user.name)!")
            return true
        } else {
            errorMessage = "Invalid email or password."
            return false
        }
    }
}

