import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var username = ""
    @State private var password = ""
    @State private var showingSignup = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "timer.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(Color(red: 0.31, green: 0.275, blue: 0.918))
                    
                    Text("Welcome to iFast")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Track your fasting journey with ease")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 50)
                
                // Login Form
                VStack(spacing: 20) {
                    AuthTextField(
                        title: "Username",
                        placeholder: "Enter your username",
                        text: $username
                    )
                    
                    AuthTextField(
                        title: "Password",
                        placeholder: "Enter your password",
                        text: $password,
                        isSecure: true
                    )
                }
                .padding(.horizontal)
                
                // Error Message
                if let errorMessage = authManager.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                // Login Button
                Button(action: {
                    Task {
                        await authManager.login(username: username, password: password)
                    }
                }) {
                    HStack {
                        if authManager.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "arrow.right")
                        }
                        
                        Text(authManager.isLoading ? "Signing In..." : "Sign In")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.31, green: 0.275, blue: 0.918),
                                Color(red: 0.4, green: 0.35, blue: 0.95)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                }
                .disabled(authManager.isLoading || username.isEmpty || password.isEmpty)
                .opacity((username.isEmpty || password.isEmpty) ? 0.6 : 1.0)
                .padding(.horizontal)
                
                // Sign Up Link
                HStack {
                    Text("Don't have an account?")
                        .foregroundColor(.secondary)
                    
                    Button("Sign Up") {
                        showingSignup = true
                    }
                    .foregroundColor(Color(red: 0.31, green: 0.275, blue: 0.918))
                    .fontWeight(.semibold)
                }
                .font(.subheadline)
                
                Spacer()
            }
            .padding()
            .navigationBarHidden(true)
            .sheet(isPresented: $showingSignup) {
                SignupView()
                    .environmentObject(authManager)
            }
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthManager())
}
