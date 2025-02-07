import SwiftUI
import GoogleSignIn
import GoogleSignInSwift
import AuthenticationServices
import FirebaseAuth
import FirebaseFirestore
import CryptoKit

struct LoginView: View {
    @Binding var isLoggedIn: Bool
    @Binding var user: AppUser?
    @State private var isLogin: Bool = true
    @State private var isForgotPasswordPresented = false

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.8)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all)

            VStack {
                Text(isLogin ? "Welcome to StepRewards" : "Create an Account")
                    .font(.largeTitle)
                    .foregroundColor(.white)
                    .padding()

                if isLogin {
                    LoginOnlyView(isLoggedIn: $isLoggedIn, user: $user, isForgotPasswordPresented: $isForgotPasswordPresented)
                } else {
                    SignupView(isLoggedIn: $isLoggedIn, user: $user)
                }

                Spacer()

                Button(action: {
                    isLogin.toggle()
                }) {
                    Text(isLogin ? "Don't have an account? Sign Up" : "Already have an account? Log In")
                        .foregroundColor(.white)
                        .underline()
                }
                .padding()
            }
        }
        .sheet(isPresented: $isForgotPasswordPresented) {
            ForgotPasswordView()
        }
    }
}

struct LoginOnlyView: View {
    @Binding var isLoggedIn: Bool
    @Binding var user: AppUser?
    @StateObject private var authViewModel = AuthViewModel()
    @Binding var isForgotPasswordPresented: Bool
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var appleAuthDelegate: AppleSignInDelegate?
    @State private var errorMessage: String?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                TextField("Email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                
                SecureField("Password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                Button(action:
                        {
                    AuthManager.shared.signIn(email: email, password: password) { error in
                        if let error = error {
                            errorMessage = error.localizedDescription
                            print("❌ Login failed: \(error.localizedDescription)")
                        } else {
                            isLoggedIn = true
                        }
                    }
                }) {
                    Text("Login")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(width: 200, height: 50)
                        .background(Color.blue)
                        .cornerRadius(10)
                        .shadow(radius: 5)
                }
                .padding()
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                }
                
                Button(action: {
                    isForgotPasswordPresented = true
                }) {
                    Text("Forgot Password?")
                        .foregroundColor(.blue)
                        .underline()
                }
                .padding()
                
                if !authViewModel.errorMessage.isEmpty {
                    Text(authViewModel.errorMessage)
                        .foregroundColor(.red)
                }
                
                VStack(spacing: 20) {
                    GoogleSignInButton {
                        handleGoogleSignIn()
                    }
                    .padding()
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .padding()
                    }
                    AppleSignInButton()
                        .frame(height: 50)
                        .onTapGesture {
                            handleAppleSignIn()
                        }
                        .padding()
                }
                .padding()
            }
            .padding()
            
        }
    }
    func handleAppleSignIn() {
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName, .email]
        
        let controller = ASAuthorizationController(authorizationRequests: [request])
        
        // Create and retain the delegate within LoginOnlyView's scope
        appleAuthDelegate = AppleSignInDelegate()
        controller.delegate = appleAuthDelegate
        
        controller.performRequests()
    }
    func handleGoogleSignIn() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            errorMessage = "Unable to get root view controller."
            return
        }
        
        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { signInResult, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = "Google Sign-In failed: \(error.localizedDescription)"
                }
                return
            }
            
            guard let gUser = signInResult?.user,
                  let idToken = gUser.idToken?.tokenString else {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to retrieve user credentials."
                }
                return
            }
            
            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: gUser.accessToken.tokenString
            )
            
            Auth.auth().signIn(with: credential) { authResult, error in
                if let error = error {
                    DispatchQueue.main.async {
                        self.errorMessage = "Firebase auth error: \(error.localizedDescription)"
                    }
                    return
                }
                
                guard let uid = authResult?.user.uid else {
                    DispatchQueue.main.async {
                        self.errorMessage = "User ID not found."
                    }
                    return
                }
                
                let newUser = AppUser(
                    firstName: gUser.profile?.givenName ?? "",
                    lastName: gUser.profile?.familyName ?? "",
                    email: gUser.profile?.email ?? ""
                )
                
                self.authViewModel.handleSocialSignIn(user: newUser, uid: uid) { success in
                    DispatchQueue.main.async {
                        if success {
                            self.user = newUser
                            self.isLoggedIn = true
                            self.errorMessage = nil // Clear error on success
                        } else {
                            self.errorMessage = "Failed to complete sign-in process."
                        }
                    }
                }
            }
        }
    }
}


struct AppleSignInButton: UIViewRepresentable {
    func makeUIView(context: Context) -> ASAuthorizationAppleIDButton {
        return ASAuthorizationAppleIDButton(type: .signIn, style: .black)
    }

    func updateUIView(_ uiView: ASAuthorizationAppleIDButton, context: Context) {}
}

class AppleSignInDelegate: NSObject, ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let appleIDToken = appleIDCredential.identityToken else {
            return
        }
        
        guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            print("Unable to serialize token string from data")
            return
        }
        
        let nonce = generateNonce() // Generate a secure nonce
        let credential = OAuthProvider.credential(withProviderID: "apple.com",
                                                  idToken: idTokenString,
                                                  rawNonce: nonce)
        
        Auth.auth().signIn(with: credential) { authResult, error in
            if let error = error {
                print("Apple sign in error: \(error.localizedDescription)")
                return
            }
            
            // Handle new user creation in Firestore if needed
            guard let user = authResult?.user else { return }
            
            let db = Firestore.firestore()
            let userRef = db.collection("users").document(user.uid)
            
            userRef.getDocument { document, _ in
                    if let document = document, !document.exists {
                        let firstName = appleIDCredential.fullName?.givenName ?? ""
                        let lastName = appleIDCredential.fullName?.familyName ?? ""
                        let email = user.email ?? "" // Use Firebase user's email

                        // Update Firebase user's displayName
                        let changeRequest = user.createProfileChangeRequest()
                        changeRequest.displayName = "\(firstName) \(lastName)"
                        changeRequest.commitChanges { error in
                            if let error = error {
                                print("Error updating display name: \(error)")
                            }
                        }

                        userRef.setData([
                            "firstName": firstName,
                            "lastName": lastName,
                            "email": email,
                            "referralCode": UUID().uuidString.components(separatedBy: "-").first!.lowercased(),
                            "stepcoins": 0
                        ])
                    }
                }
            }
        }
    func generateNonce(length: Int = 32) -> String {
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length

        while remainingLength > 0 {
            let randoms: [UInt8] = (0 ..< 16).map { _ in UInt8.random(in: 0...255) }
            for random in randoms {
                if remainingLength == 0 {
                    break
                }
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        return result
    }
}

// ✅ Fully Fixed SignupView
struct SignupView: View {
    @Binding var isLoggedIn: Bool
    @Binding var user: AppUser?
    @StateObject private var authViewModel = AuthViewModel()

    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var referralCode: String = ""
    @State private var dateOfBirth = Date()
    @State private var isVerificationStep: Bool = false
    @State private var showPasswordMismatch: Bool = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if isVerificationStep {
                    Text("Check your email for the verification link")
                        .font(.headline)
                        .foregroundColor(.green)
                        .multilineTextAlignment(.center)
                        .padding()

                    Button("I have verified my email") {
                        authViewModel.checkEmailVerification { success in
                            if success {
                                authViewModel.login(email: email, password: password) { loginSuccess, userDetails in
                                    if loginSuccess, let userDetails = userDetails {
                                        self.user = AppUser(
                                            firstName: userDetails.firstName,
                                            lastName: userDetails.lastName,
                                            email: userDetails.email
                                        )
                                        isLoggedIn = true
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                } else {
                    HStack {
                        TextField("First Name", text: $firstName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding()

                        TextField("Last Name", text: $lastName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding()
                    }

                    TextField("Email", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)

                    DatePicker("Date of Birth", selection: $dateOfBirth, displayedComponents: .date)
                        .datePickerStyle(CompactDatePickerStyle())
                        .padding()

                    SecureField("Password", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()

                    SecureField("Confirm Password", text: $confirmPassword)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()

                    if showPasswordMismatch {
                        Text("❌ Passwords do not match")
                            .foregroundColor(.red)
                            .font(.footnote)
                    }

                    TextField("Referral Code (Optional)", text: $referralCode)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                        .autocapitalization(.allCharacters)

                    Button(action: {
                        if password != confirmPassword {
                            showPasswordMismatch = true
                        } else {
                            showPasswordMismatch = false
                            authViewModel.signUp(
                                firstName: firstName,
                                lastName: lastName,
                                email: email,
                                password: password,
                                dateOfBirth: dateOfBirth,
                                referralCode: referralCode.isEmpty ? nil : referralCode
                            ) { success, userDetails in
                                if success, let userDetails = userDetails {
                                    DispatchQueue.main.async {
                                        self.user = AppUser(
                                            firstName: userDetails.firstName,
                                            lastName: userDetails.lastName,
                                            email: userDetails.email
                                        )
                                        isLoggedIn = true
                                    }
                                    print("✅ User signed up successfully: \(userDetails.firstName) \(userDetails.lastName) - \(userDetails.email)")
                                } else {
                                    print("❌ Signup failed: \(authViewModel.errorMessage)")
                                }
                            }
                        }
                    }) {
                        Text("Send Verification Link")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(width: 200, height: 50) // Square-like shape
                            .background(Color.green) // Use green to indicate success/action
                            .cornerRadius(10) // Slight rounded edges like major apps
                            .shadow(radius: 5) // Adds subtle shadow for depth
                    }
                    .padding()
                    .disabled(password.isEmpty || confirmPassword.isEmpty || email.isEmpty)

                    if !authViewModel.errorMessage.isEmpty {
                        Text(authViewModel.errorMessage)
                            .foregroundColor(.red)
                            .font(.footnote)
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground).opacity(0.2))
        }
    }
}
// 🔹 Forgot Password View
struct ForgotPasswordView: View {
    @State private var email: String = ""
    @State private var resetMessage: String = ""
    @State private var isSuccess: Bool = false
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack {
            Text("Reset Password")
                .font(.largeTitle)
                .padding()

            TextField("Enter your email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                .autocapitalization(.none)

            Button("Send Reset Link") {
                sendPasswordReset()
            }
            .padding()
            .disabled(email.isEmpty)

            if !resetMessage.isEmpty {
                Text(resetMessage)
                    .foregroundColor(isSuccess ? .green : .red)
                    .padding()
            }

            Button("Close") {
                presentationMode.wrappedValue.dismiss()
            }
            .padding()
        }
        .padding()
    }

    func sendPasswordReset() {
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            if let error = error {
                resetMessage = "❌ Failed: \(error.localizedDescription)"
                isSuccess = false
            } else {
                resetMessage = "✅ Reset link sent! Check your email."
                isSuccess = true
            }
        }
    }
}
