import SwiftUI

struct ProfileView: View {
    @State private var isEditing = false
    @State private var name: String = "John Doe"
    @State private var email: String = "john.doe@example.com"

    var body: some View {
        NavigationView {
            GeometryReader { geometry in  // GeometryReader at the root for full control
                ZStack {
                    // Background Gradient Matching Other Tabs
                    LinearGradient(
                        gradient: Gradient(colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.8)]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea(edges: .all)

                    ScrollView {
                        VStack(spacing: 20) {
                            // Profile Picture
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .frame(width: 120, height: 120)
                                .foregroundColor(.white)
                                .padding(.top, 40)

                            // User Info
                            Text(name)
                                .font(.title)
                                .bold()
                                .foregroundColor(.white)

                            Text(email)
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))

                            // Edit Button
                            Button(action: {
                                isEditing.toggle()
                            }) {
                                Text(isEditing ? "Done Editing" : "Edit Profile")
                                    .font(.headline)
                                    .padding()
                                    .frame(maxWidth: 200)
                                    .background(Color.white.opacity(0.2))
                                    .cornerRadius(10)
                                    .foregroundColor(.white)
                                    .shadow(radius: 5)
                            }
                            .padding(.top, 10)

                            // Editable Fields
                            if isEditing {
                                TextField("Name", text: $name)
                                    .padding()
                                    .background(Color.white.opacity(0.2))
                                    .cornerRadius(10)
                                    .foregroundColor(.white)
                                    .padding(.horizontal)

                                TextField("Email", text: $email)
                                    .padding()
                                    .background(Color.white.opacity(0.2))
                                    .cornerRadius(10)
                                    .foregroundColor(.white)
                                    .padding(.horizontal)
                            }

                            Spacer()
                        }
                        .padding()
                        .frame(minHeight: geometry.size.height)  // Ensure the content fills the screen
                        .frame(maxWidth: .infinity)  // Allow scrolling from edges
                    }
                }
                .navigationTitle("Profile")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
    }
}
