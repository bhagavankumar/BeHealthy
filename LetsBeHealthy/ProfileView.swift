import SwiftUI
import FirebaseAuth
import FirebaseStorage
import FirebaseFirestore

struct ProfileView: View {
    @State private var isEditing = false
    @State private var name: String = "Loading..."
    @State private var email: String = "Loading..."
    @State private var bio: String = "Passionate about fitness and healthy living."
    
    @State private var originalEmail: String = ""  // To track if email has changed
    @State private var showEmailVerificationAlert = false
    @State private var showInvalidEmailAlert = false
    @State private var showReAuthPrompt = false  // Show re-authentication prompt
    @State private var password: String = ""  // Store password for re-authentication
    @State private var reAuthErrorMessage: ErrorMessage? = nil  // Store re-auth error message
    @State private var imageErrorMessage: ErrorMessage? = nil
    @State private var selectedImage: UIImage? = nil
    @State private var isImagePickerPresented = false
    @State private var activeAlert: ActiveAlert? = nil
    private let storageRef = Storage.storage().reference()  // Firebase Storage reference
    
    var body: some View {
        ZStack {
            // Gradient Background Matching RewardsView
            LinearGradient(gradient: Gradient(colors: [Color.orange.opacity(0.6), Color.red.opacity(0.8)]),
                           startPoint: .top,
                           endPoint: .bottom)
                .edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(spacing: 20) {
                    // Profile Picture with Edit Option
                    ZStack(alignment: .bottomTrailing) {
                        if let image = selectedImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 120, height: 120)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.white, lineWidth: 4))
                                .shadow(radius: 10)
                        } else {
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .scaledToFill()
                                .frame(width: 120, height: 120)
                                .foregroundColor(.white)
                                .background(Color.blue)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.white, lineWidth: 4))
                                .shadow(radius: 10)
                        }
                        
                        Button(action: {
                            isImagePickerPresented = true
                        }) {
                            Image(systemName: "camera.fill")
                                .foregroundColor(.white)
                                .padding(8)
                                .background(Color.blue)
                                .clipShape(Circle())
                                .shadow(radius: 5)
                        }
                        .offset(x: -10, y: -10)
                    }
                    .padding(.top, 40)
                    .alert(item: $imageErrorMessage) { error in
                        Alert(
                            title: Text("Image Error"),
                            message: Text(error.message),
                            dismissButton: .default(Text("OK"))
                        )
                    }
                    
                    // User Info Section
                    VStack(spacing: 10) {
                        Text(name)
                            .font(.title)
                            .bold()
                            .foregroundColor(.white)
                        
                        Text(email)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                        
                        if !isEditing {
                            Text(bio)
                                .font(.body)
                                .foregroundColor(.white.opacity(0.8))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                    }
                    .padding()
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(20)
                    .shadow(radius: 10)
                    
                    // Edit Profile Button
                    Button(action: {
                        if isEditing {
                            saveChanges()
                        }
                        isEditing.toggle()
                    }) {
                        Text(isEditing ? "Save Changes" : "Edit Profile")
                            .font(.headline)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .shadow(radius: 5)
                    }
                    .padding(.horizontal)
                    .alert(isPresented: $showEmailVerificationAlert) {
                        Alert(
                            title: Text("Verification Email Sent"),
                            message: Text("A verification email has been sent to your new email address. Please verify to complete the update."),
                            dismissButton: .default(Text("OK"))
                        )
                    }
                    
                    NavigationLink(destination: FriendsListView()) {
                        HStack {
                            Image(systemName: "person.3.fill")
                            Text("Friends List")
                        }
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.purple)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .shadow(radius: 5)
                    }
                    .padding(.horizontal)
                    
                    NavigationLink(destination: SearchFriendsView()) {
                        HStack {
                            Image(systemName: "magnifyingglass")
                            Text("Find Friends")
                        }
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .shadow(radius: 5)
                    }
                    .padding(.horizontal)
                   
                        // Invite Friends Section
                        Button(action: shareReferralLink) {
                            HStack {
                                Image(systemName: "person.badge.plus")
                                Text("Invite Friends")
                            }
                            .font(.headline)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .shadow(radius: 5)
                        }
                        .padding(.horizontal)
                    
                    // Editable Fields with Consistent Background and Shadows
                    if isEditing {
                        VStack(spacing: 15) {
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
                            
                            TextField("Bio", text: $bio)
                                .padding()
                                .background(Color.white.opacity(0.2))
                                .cornerRadius(10)
                                .foregroundColor(.white)
                                .padding(.horizontal)
                        }
                        .transition(.opacity)
                        .shadow(radius: 10)
                    }
                    
                    Spacer()
                }
                .padding()
            }
        }
        .onAppear {
                loadUserData()
                fetchProfileImageFromFirebase()
            }
        .sheet(isPresented: $isImagePickerPresented) {
            ImagePicker(selectedImage: $selectedImage)
                .onDisappear {
                    uploadProfileImageToFirebase()
                }
        }
        .alert("Re-authentication Required", isPresented: $showReAuthPrompt) {
            SecureField("Enter your password", text: $password)
            Button("Confirm", action: {
                reAuthenticateUser()
            })
            Button("Cancel", role: .cancel, action: {
                password = ""
                email = originalEmail
            })
        } message: {
            Text("Please enter your password to verify your identity before changing your email.")
        }
        .alert(item: $activeAlert) { alert in
            switch alert {
            case .invalidEmail:
                return Alert(
                    title: Text("Invalid Email"),
                    message: Text("Please enter a valid email address."),
                    dismissButton: .default(Text("OK"))
                )
            case .emailVerificationSent:
                return Alert(
                    title: Text("Verification Email Sent"),
                    message: Text("A verification email has been sent to your new email address. Please verify to complete the update."),
                    dismissButton: .default(Text("OK"))
                )
            case .reAuthRequired(let errorMessage):
                return Alert(
                    title: Text("Re-authentication Failed"),
                    message: Text(errorMessage.message),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
    struct ErrorMessage: Identifiable {
        var id = UUID()  // Unique identifier for the alert
        var message: String
    }
    private func loadUserData() {
        if let user = Auth.auth().currentUser {
            name = user.displayName ?? "No Name"
            email = user.email ?? "No Email"
            originalEmail = user.email ?? ""
            
            // Generate and store referral code if missing
            if UserDefaults.standard.string(forKey: "userReferralCode") == nil {
                let referralCode = generateReferralCode(uid: user.uid)
                UserDefaults.standard.set(referralCode, forKey: "userReferralCode")
            }
        } else {
            name = "Guest User"
            email = "Not Signed In"
        }
    }
    
    private func shareReferralLink() {
        print("✅ Invite Friends button clicked!")

        guard Auth.auth().currentUser != nil else {
            print("❌ No authenticated user found.")
            return
        }

        // Ensure referral code exists
        let storedReferralCode = UserDefaults.standard.string(forKey: "userReferralCode") ?? ""
        guard !storedReferralCode.isEmpty else {
            print("❌ Referral code not found")
            return
        }

        let link = URL(string: "https://yourapp.page.link/?referral=\(storedReferralCode)")!
        let activityVC = UIActivityViewController(activityItems: [link], applicationActivities: nil)

        // Present the share sheet
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(activityVC, animated: true)
        }
    }
private func generateReferralCode(uid: String) -> String {
    let timestamp = Int(Date().timeIntervalSince1970)
    return "\(uid.prefix(4))\(timestamp % 10000)" // Example: Combine UID and timestamp
}
    
    private func saveChanges() {
        guard Auth.auth().currentUser != nil else {
            print("No authenticated user found.")
            return
        }

        // First, check if the email has changed and validate it
        if email != originalEmail {
            print("Email has changed from \(originalEmail) to \(email). Validating...")

            if email.isEmpty {
                print("Email is empty.")
                showInvalidEmailAlert = true
                return
            }

            if !isValidEmail(email) {
                print("Invalid email detected: \(email)")

                DispatchQueue.main.async {
                    print("Triggering invalid email alert.")
                    self.activeAlert = .invalidEmail
                    self.email = self.originalEmail  // Revert to original email
                }
                return
            }

            // If valid, prompt re-authentication
            print("Email is valid. Proceeding to re-authentication.")
            DispatchQueue.main.async {
                self.showReAuthPrompt = true  // Ensure this triggers the prompt
            }
            return  // Wait for re-authentication before making further changes
        }

        // ✅ If email is unchanged, update name and bio without requiring re-authentication
        updateProfileDetails(for: Auth.auth().currentUser)
    }

    private func updateProfileDetails(for user: FirebaseAuth.User?) {
        guard let user = user else {
            print("❌ No authenticated user found.")
            return
        }
        
        let changeRequest = user.createProfileChangeRequest()
        changeRequest.displayName = name
        changeRequest.commitChanges { error in
            if let error = error {
                print("❌ Failed to update name: \(error.localizedDescription)")
            } else {
                print("✅ Name updated successfully.")
            }
        }

        let db = Firestore.firestore()
        db.collection("users").document(user.uid).setData([
            "bio": bio
        ], merge: true) { error in
            if let error = error {
                print("❌ Error updating bio: \(error.localizedDescription)")
            } else {
                print("✅ Bio updated successfully.")
            }
        }
    }
    
    private func reAuthenticateUser() {
        guard let user = Auth.auth().currentUser, let currentEmail = user.email else { return }

        let credential = EmailAuthProvider.credential(withEmail: currentEmail, password: password)
        user.reauthenticate(with: credential) { result, error in
                if let error = error {
                    print("❌ Re-authentication failed: \(error.localizedDescription)")
                    DispatchQueue.main.async {
                        self.activeAlert = .reAuthRequired(ErrorMessage(message: "Re-authentication failed: \(error.localizedDescription)"))
                    }
                    return
                }

            print("✅ Re-authentication successful.")
            DispatchQueue.main.async {
                self.updateEmailAndSendVerification(newEmail: self.email)
            }
        }
    }
    @Environment(\.presentationMode) var presentationMode

    private func updateEmailAndSendVerification(newEmail: String) {
        guard let user = Auth.auth().currentUser else { return }

        // This method updates the email and sends a verification to the new email
        user.sendEmailVerification(beforeUpdatingEmail: newEmail) { error in
            if let error = error {
                print("❌ Failed to send verification email before updating email: \(error.localizedDescription)")
                
                // Show an error alert if verification fails
                DispatchQueue.main.async {
                    self.activeAlert = .reAuthRequired(ErrorMessage(message: "Failed to send verification email: \(error.localizedDescription)"))
                    self.email = self.originalEmail  // Revert to the original email if verification fails
                }
                return
            }

            print("✅ Verification email sent successfully to \(newEmail). Please verify to complete the update.")

            // Show success alert after sending verification
            DispatchQueue.main.async {
                self.activeAlert = .emailVerificationSent
            }
            do {
                        try Auth.auth().signOut()
                        print("✅ Please verify your new email address and login again")
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                               self.presentationMode.wrappedValue.dismiss()
                           }
                    } catch let signOutError as NSError {
                        print("❌ Error signing out: \(signOutError.localizedDescription)")
                    }
        }
    }
    
    // MARK: - Email Validation
    private func isValidEmail(_ email: String) -> Bool {
        print("Validating email format: \(email)")
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let isValid = NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: email)
        print("Email validation result for \(email): \(isValid)")
        return isValid
    }
    
    // MARK: - Upload Profile Image to Firebase Storage
    
    private func uploadProfileImageToFirebase() {
        
        guard let image = selectedImage, let imageData = image.jpegData(compressionQuality: 0.8) else { return }
        
        guard let userID = Auth.auth().currentUser?.uid else { return }
        
        
        
        let profileImageRef = storageRef.child("profile_pictures/\(userID).jpg")
        
        
        
        profileImageRef.putData(imageData, metadata: nil) { metadata, error in
            
            if let error = error {
                
                print("Error uploading profile image: \(error.localizedDescription)")
                
            } else {
                
                print("Profile image uploaded successfully.")
                
            }
            
        }
        
    }
    
    // MARK: - Fetch Profile Image from Firebase Storage
    
    private func fetchProfileImageFromFirebase() {
        
        guard let userID = Auth.auth().currentUser?.uid else { return }
        
        
        
        let profileImageRef = storageRef.child("profile_pictures/\(userID).jpg")
        
        profileImageRef.downloadURL { url, error in
            
            if let error = error {
                
                print("Error fetching profile image: \(error.localizedDescription)")
                
            } else if let url = url {
                
                loadImageFromURL(url)
                
            }
            
        }
        
    }
    
    
    
    // Load Image from URL
    
    private func loadImageFromURL(_ url: URL) {
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            
            if let data = data, let uiImage = UIImage(data: data) {
                
                DispatchQueue.main.async {
                    
                    self.selectedImage = uiImage
                    
                }
                
            } else {
                
                print("Error loading image from URL: \(error?.localizedDescription ?? "Unknown error")")
                
            }
            
        }.resume()
        
    }
    
    enum ActiveAlert: Identifiable {
        case invalidEmail
        case emailVerificationSent
        case reAuthRequired(ErrorMessage)
        
        var id: Int {
            switch self {
            case .invalidEmail:
                return 0
            case .emailVerificationSent:
                return 1
            case .reAuthRequired:
                return 2
            }
        }
    }
}
