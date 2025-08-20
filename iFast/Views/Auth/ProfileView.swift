import SwiftUI
import AuthAPI

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var showingLogoutAlert = false
    
    var body: some View {
        NavigationView {
            List {
                // User Info Section
                Section {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(Color(red: 0.31, green: 0.275, blue: 0.918))
                        
                        VStack(alignment: .leading, spacing: 4) {
                            if let user = authManager.currentUser {
                                Text("\(user.firstName ?? "") \(user.lastName ?? "")")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                
                                Text(user.email ?? "")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Text("@\(user.username ?? "")")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            } else {
                                Text("Loading...")
                                    .font(.title2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
                
                // Account Settings Section
                Section("Account Settings") {
                    NavigationLink(destination: AccountSettingsView()) {
                        Label("Account Settings", systemImage: "person.circle")
                    }
                    
                    NavigationLink(destination: PrivacySettingsView()) {
                        Label("Privacy & Security", systemImage: "lock.shield")
                    }
                    
                    NavigationLink(destination: NotificationSettingsView()) {
                        Label("Notifications", systemImage: "bell")
                    }
                }
                
                // App Settings Section
                Section("App Settings") {
                    NavigationLink(destination: FastingPreferencesView()) {
                        Label("Fasting Preferences", systemImage: "timer")
                    }
                    
                    NavigationLink(destination: HealthKitSettingsView()) {
                        Label("Health Integration", systemImage: "heart")
                    }
                    
                    NavigationLink(destination: AppearanceSettingsView()) {
                        Label("Appearance", systemImage: "paintbrush")
                    }
                    
                    NavigationLink(destination: FastingAPIExampleView()) {
                        Label("API Examples", systemImage: "network")
                    }
                }
                
                // Support Section
                Section("Support") {
                    NavigationLink(destination: HelpCenterView()) {
                        Label("Help Center", systemImage: "questionmark.circle")
                    }
                    
                    NavigationLink(destination: ContactSupportView()) {
                        Label("Contact Support", systemImage: "envelope")
                    }
                    
                    NavigationLink(destination: AboutView()) {
                        Label("About iFast", systemImage: "info.circle")
                    }
                }
                
                // Logout Section
                Section {
                    Button(action: {
                        showingLogoutAlert = true
                    }) {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                await authManager.fetchCurrentUser()
            }
            .alert("Sign Out", isPresented: $showingLogoutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    Task {
                        await authManager.logout()
                    }
                }
            } message: {
                Text("Are you sure you want to sign out? You'll need to sign in again to access your data.")
            }
        }
    }
}

// MARK: - Placeholder Views for Navigation

struct AccountSettingsView: View {
    var body: some View {
        Text("Account Settings")
            .navigationTitle("Account Settings")
    }
}

struct PrivacySettingsView: View {
    var body: some View {
        Text("Privacy & Security")
            .navigationTitle("Privacy & Security")
    }
}

struct NotificationSettingsView: View {
    var body: some View {
        Text("Notifications")
            .navigationTitle("Notifications")
    }
}

struct FastingPreferencesView: View {
    var body: some View {
        Text("Fasting Preferences")
            .navigationTitle("Fasting Preferences")
    }
}

struct HealthKitSettingsView: View {
    var body: some View {
        Text("Health Integration")
            .navigationTitle("Health Integration")
    }
}

struct AppearanceSettingsView: View {
    var body: some View {
        Text("Appearance")
            .navigationTitle("Appearance")
    }
}

struct HelpCenterView: View {
    var body: some View {
        Text("Help Center")
            .navigationTitle("Help Center")
    }
}

struct ContactSupportView: View {
    var body: some View {
        Text("Contact Support")
            .navigationTitle("Contact Support")
    }
}

struct AboutView: View {
    var body: some View {
        Text("About iFast")
            .navigationTitle("About iFast")
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthManager())
}
