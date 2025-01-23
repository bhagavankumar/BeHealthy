import SwiftUI
import GoogleSignIn
import GoogleSignInSwift
import AuthenticationServices

struct LoginView: View {
    
    @Binding var isLoggedIn: Bool
    @Binding var user: User?
    @State private var isLogin: Bool = true // Toggle between login and signup
    
    
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
                    LoginOnlyView(isLoggedIn: $isLoggedIn, user: $user)
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
    }
    }
    
struct LoginOnlyView: View {
    @Binding var isLoggedIn: Bool
    @Binding var user: User?
    @StateObject private var authViewModel = AuthViewModel()
    
    @State private var email: String = ""
    @State private var password: String = ""
    
    var body: some View {
        VStack(spacing: 20) {
            TextField("Email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                .autocapitalization(.none)
                .keyboardType(.emailAddress)
            
            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            Button("Login") {
                if authViewModel.login(email: email, password: password) {
                    user = authViewModel.users.first(where: { $0.email == email })
                    isLoggedIn = true
                }
            }
            .padding()
            
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
                
                if !authViewModel.errorMessage.isEmpty {
                    Text(authViewModel.errorMessage)
                        .foregroundColor(.red)
                }
            }
            .padding()
        }
    }
    struct AppleSignInButton: UIViewRepresentable {
        func makeUIView(context: Context) -> ASAuthorizationAppleIDButton {
            return ASAuthorizationAppleIDButton()
        }
        func updateUIView(_ uiView: ASAuthorizationAppleIDButton, context: Context) {}
    }
    
    func handleGoogleSignIn() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            print("No root view controller found.")
            return
        }
        
        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { signInResult, error in
            if let error = error {
                print("Google Sign-In failed: \(error.localizedDescription)")
                return
            }
            
            guard let user = signInResult?.user else { return }
            print("Google User Signed In: \(user.profile?.name ?? "Unknown")")
            self.user = .init(name: user.profile?.name ?? "", email: user.profile?.email ?? "",password: "")
            isLoggedIn = true
        }
    }
    
    func handleAppleSignIn() {
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName, .email]
        
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = AppleSignInDelegate()
        controller.performRequests()
    }
    
    class AppleSignInDelegate: NSObject, ASAuthorizationControllerDelegate {
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
        
        func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
            print("Apple Sign-In Failed: \(error.localizedDescription)")
        }
    }
}
        
        struct SignupView: View {
            @Binding var isLoggedIn: Bool
            @Binding var user: User?
            @StateObject private var authViewModel = AuthViewModel()
            
            @State private var name: String = ""
            @State private var email: String = ""
            @State private var password: String = ""
            
            var body: some View {
                VStack(spacing: 20) {
                    TextField("Name", text: $name)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                    
                    TextField("Email", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                    
                    SecureField("Password", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                    
                    Button("Sign Up") {
                        if authViewModel.signUp(name: name, email: email, password: password) {
                            user = User(name: name, email: email, password: password)
                            isLoggedIn = true
                        }
                    }
                    .padding()
                    
                    if !authViewModel.errorMessage.isEmpty {
                        Text(authViewModel.errorMessage)
                            .foregroundColor(.red)
                    }
                }
                .padding()
            }
        }

        
        struct LoginSignupView_Previews: PreviewProvider {
            static var previews: some View {
                LoginView(isLoggedIn: .constant(false), user: .constant(nil))
            }
        }
    
    

