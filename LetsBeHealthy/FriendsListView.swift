//
//  FriendsListView.swift
//  LetsBeHealthy
//
//  Created by Bhagavan Kumar V on 2025-02-06.
//
import SwiftUI
import FirebaseAuth
import FirebaseStorage
import FirebaseFirestore

struct User: Identifiable, Codable {
    var id: String
    var username: String
    var dailySteps: Int
    var uid: String
}

struct FriendsListView: View {
    @State private var friends = [User]()
    
    var body: some View {
        List(friends) { friend in
            HStack {
                Text(friend.username)
                Spacer()
                Text("Steps: \(friend.dailySteps)")
            }
        }
        .onAppear(perform: fetchFriends)
    }
    
    private func fetchFriends() {
        guard let uid = Auth.auth().currentUser?.uid else {
            print("❌ No authenticated user.")
            return
        }

        Firestore.firestore().collection("users").document(uid).collection("friends")
            .getDocuments { snapshot, error in
                if let error = error {
                    print("❌ Error fetching friends: \(error.localizedDescription)")
                    return
                }

                DispatchQueue.main.async {
                    self.friends = snapshot?.documents.compactMap { doc in
                        let data = doc.data()
                        return User(
                            id: doc.documentID,
                            username: data["username"] as? String ?? "Unknown",
                            dailySteps: data["dailySteps"] as? Int ?? 0,
                            uid: doc.documentID
                        )
                    } ?? []
                }
            }
    }
}
