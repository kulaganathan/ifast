import SwiftUI

struct SignupView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var username = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    
    private var isFormValid: Bool {
        !firstName.isEmpty &&
        !lastName.isEmpty &&
        !email.isEmpty &&
        !username.isEmpty &&
        !password.isEmpty &&
        password == confirmPassword &&
        password.count >= 8
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 25) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 60))
                            .foregroundColor(Color(red: 0.31, green: 0.275, blue: 0.918))
                        
                        Text("Create Account")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Join iFast to start your fasting journey")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)
                    
                    // Signup Form
                    VStack(spacing: 20) {
                        HStack(spacing: 15) {
                            AuthTextField(
                                title: "First Name",
                                placeholder: "Enter first name",
                                text: $firstName
                            )
                            
                            AuthTextField(
                                title: "Last Name",
                                placeholder: "Enter last name",
                                text: $lastName
                            )
                        }
                        
                        AuthTextField(
                            title: "Email",
                            placeholder: "Enter your email",
                            text: $email,
                            keyboardType: .emailAddress
                        )
                        
                        AuthTextField(
                            title: "Username",
                            placeholder: "Choose a username",
                            text: $username
                        )
                        
                        AuthTextField(
                            title: "Password",
                            placeholder: "Create a password",
                            text: $password,
                            isSecure: true
                        )
                        
                        AuthTextField(
                            title: "Confirm Password",
                            placeholder: "Confirm your password",
                            text: $confirmPassword,
                            isSecure: true
                        )
                        
                        // Password requirements
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Password must be at least 8 characters long")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            if !password.isEmpty && password != confirmPassword {
                                Text("Passwords don't match")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal)
                    
                    // Error Message
                    if let errorMessage = authManager.errorMessage {
                        VStack(spacing: 12) {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .font(.caption)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            
                            // Show troubleshooting steps for keychain issues
                            if errorMessage.contains("Keychain") || errorMessage.contains("secure storage") {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Troubleshooting Steps:")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.orange)
                                    
                                    ForEach(authManager.getKeychainTroubleshootingSteps(), id: \.self) { step in
                                        Text(step)
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                                .background(Color.orange.opacity(0.1))
                                .cornerRadius(8)
                            }
                        }
                    }
                    
                    // Sign Up Button
                    Button(action: {
                        Task {
                            let success = await authManager.signup(
                                firstName: firstName,
                                lastName: lastName,
                                email: email,
                                username: username,
                                password: password
                            )
                            if success {
                                dismiss()
                            }
                        }
                    }) {
                        HStack {
                            if authManager.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "person.badge.plus")
                            }
                            
                            Text(authManager.isLoading ? "Creating Account..." : "Create Account")
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
                    .disabled(authManager.isLoading || !isFormValid)
                    .opacity(isFormValid ? 1.0 : 0.6)
                    .padding(.horizontal)
                    
                    // Login Link
                    HStack {
                        Text("Already have an account?")
                            .foregroundColor(.secondary)
                        
                        Button("Sign In") {
                            dismiss()
                        }
                        .foregroundColor(Color(red: 0.31, green: 0.275, blue: 0.918))
                        .fontWeight(.semibold)
                    }
                    .font(.subheadline)
                    
                    Spacer(minLength: 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                }
            )
        }
    }
}

#Preview {
    SignupView()
        .environmentObject(AuthManager())
}
