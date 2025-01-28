import SwiftUI
import GoogleSignIn
import GoogleSignInSwift
import AuthenticationServices
import FirebaseAuth
import FirebaseFirestore

struct LoginView: View {
    @Binding var isLoggedIn: Bool
    @Binding var user: User?
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
    @Binding var user: User?
    @StateObject private var authViewModel = AuthViewModel()
    @Binding var isForgotPasswordPresented: Bool
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var appleAuthDelegate: AppleSignInDelegate?
    
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

                Button(action: {
                    authViewModel.login(email: email, password: password) { success, userDetails in
                        if success, let userDetails = userDetails {
                            DispatchQueue.main.async {
                                self.user = User(
                                    firstName: userDetails.firstName,
                                    lastName: userDetails.lastName,
                                    email: userDetails.email,
                                    password: ""
                                )
                                isLoggedIn = true
                            }
                        }
                    }
                }) {
                    Text("Login")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(width: 200, height: 50) // Square-like shape
                        .background(Color.blue) // Change color to match theme
                        .cornerRadius(10) // Slight rounded edges like major apps
                        .shadow(radius: 5) // Adds subtle shadow for depth
                }
                .padding()

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
              let rootViewController = windowScene.windows.first?.rootViewController else { return }
        
        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { [self] signInResult, error in
            
            if let error = error {
                print("Google Sign-In failed: \(error.localizedDescription)")
                return
            }
            
            guard let gUser = signInResult?.user,
                  let idToken = gUser.idToken?.tokenString else { return }
            
            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: gUser.accessToken.tokenString
            )
            
            Auth.auth().signIn(with: credential) { authResult, error in
                if let error = error {
                    print("Firebase auth error: \(error.localizedDescription)")
                    return
                }
                
                guard let uid = authResult?.user.uid else { return }
                
                let newUser = User(
                    firstName: gUser.profile?.givenName ?? "",
                    lastName: gUser.profile?.familyName ?? "",
                    email: gUser.profile?.email ?? "",
                    password: ""
                )
                
                self.authViewModel.handleSocialSignIn(user: newUser, uid: uid) { success in
                    if success {
                        DispatchQueue.main.async {
                            self.user = newUser
                            self.isLoggedIn = true
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
    weak var parentController: UIViewController?
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            let userIdentifier = appleIDCredential.user
            let fullName = appleIDCredential.fullName
            let email = appleIDCredential.email

            print("Apple Sign-In Successful!")
            print("User ID: \(userIdentifier)")
            print("Full Name: \(fullName?.givenName ?? "No name") \(fullName?.familyName ?? "")")
            print("Email: \(email ?? "No email")")
        }
    }
}

// ✅ Fully Fixed SignupView
struct SignupView: View {
    @Binding var isLoggedIn: Bool
    @Binding var user: User?
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
                                authViewModel.signUp(
                                    firstName: firstName,
                                    lastName: lastName,
                                    email: email,
                                    password: password,
                                    dateOfBirth: dateOfBirth,
                                    referralCode: referralCode
                                ) { signUpSuccess, userDetails in
                                    if signUpSuccess, let userDetails = userDetails {
                                        user = User(
                                            firstName: userDetails.firstName,
                                            lastName: userDetails.lastName,
                                            email: userDetails.email,
                                            password: ""
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
                                referralCode: referralCode
                            ) { success, userDetails in
                                if success, let userDetails = userDetails {
                                    DispatchQueue.main.async {
                                        self.user = User(
                                            firstName: userDetails.firstName,
                                            lastName: userDetails.lastName,
                                            email: userDetails.email,
                                            password: ""
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
