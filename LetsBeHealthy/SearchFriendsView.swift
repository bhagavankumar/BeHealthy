//
//  SearchFriendsView.swift
//  LetsBeHealthy
//
//  Created by Bhagavan Kumar V on 2025-02-06.
//

import SwiftUI
import FirebaseAuth
import FirebaseStorage
import FirebaseFirestore

struct SearchFriendsView: View {
    @State private var searchText = ""
    @State private var searchResults = [User]()
    
    var body: some View {
        NavigationView {
            VStack {
                TextField("Search by username", text: $searchText)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding(.horizontal)
                    .onChange(of: searchText) {
                        searchUsers()
                    }
                
                List(searchResults) { user in
                    HStack {
                        Text(user.username)
                        Spacer()
                        Button("Add") { sendFriendRequest(to: user.uid) }
                    }
                }
            }
            .navigationTitle("Find Friends")
        }
    }
    
    private func searchUsers() {
        guard !searchText.isEmpty else { return }
        
        Firestore.firestore().collection("users")
            .whereField("username", isGreaterThanOrEqualTo: searchText)
            .whereField("username", isLessThanOrEqualTo: "\(searchText)\u{f8ff}")
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching users: \(error.localizedDescription)")
                    return
                }
                
                DispatchQueue.main.async {
                    self.searchResults = snapshot?.documents.compactMap { doc in
                        let data = doc.data()
                        return User(
                            id: doc.documentID,
                            username: data["username"] as? String ?? "Unknown", dailySteps: data["dailySteps"] as? Int ?? 0,
                            uid: doc.documentID
                        )
                    } ?? []
                }
            }
    }
    
    private func sendFriendRequest(to friendUID: String) {
        guard let currentUID = Auth.auth().currentUser?.uid else { return }
        
        let requestData: [String: Any] = [
            "from": currentUID,
            "to": friendUID,
            "status": "pending",
            "timestamp": Timestamp()
        ]
        
        Firestore.firestore().collection("friendRequests").addDocument(data: requestData) { error in
            if let error = error {
                print("Error sending friend request: \(error.localizedDescription)")
            } else {
                print("Friend request sent successfully")
            }
        }
    }
}
