import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @State private var showingSignOutAlert = false
    @State private var showInstagramAuth = false
    @State private var showDisconnectAlert = false
    @State private var isLoadingConnection = false
    @State private var instagramConnection: InstagramConnection?
    @State private var connectionError: String?
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Profile header
                        VStack(spacing: 16) {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.marketingPrimary, Color.marketingSecondary],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 100, height: 100)
                                .overlay(
                                    Text(initials)
                                        .font(.system(size: 40, weight: .bold))
                                        .foregroundColor(.white)
                                )
                            
                            VStack(spacing: 4) {
                                Text(authViewModel.currentUser?.name ?? "User")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                
                                Text(authViewModel.currentUser?.email ?? "")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.top, 32)
                        
                        // Instagram connection
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Integrations")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal)
                            
                            VStack(spacing: 0) {
                                // Instagram connection row
                                HStack(spacing: 16) {
                                    // Icon
                                    ZStack {
                                        Circle()
                                            .fill(
                                                LinearGradient(
                                                    colors: [Color.pink, Color.purple, Color.orange],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                            .frame(width: 44, height: 44)
                                        
                                        Image(systemName: "camera.fill")
                                            .foregroundColor(.white)
                                            .font(.system(size: 20))
                                    }
                                    
                                    // Connection info
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Instagram")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                        
                                        if let connection = instagramConnection, connection.isConnected {
                                            Text("@\(connection.instagramUsername)")
                                                .font(.subheadline)
                                                .foregroundColor(.marketingPrimary)
                                        } else {
                                            Text("Not connected")
                                                .font(.subheadline)
                                                .foregroundColor(.gray)
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    // Action button
                                    if isLoadingConnection {
                                        ProgressView()
                                            .tint(.marketingPrimary)
                                    } else if let connection = instagramConnection, connection.isConnected {
                                        Button(action: { showDisconnectAlert = true }) {
                                            Text("Disconnect")
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                                .foregroundColor(.marketingError)
                                        }
                                    } else {
                                        Button(action: { showInstagramAuth = true }) {
                                            Text("Connect")
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                                .foregroundColor(.marketingPrimary)
                                        }
                                    }
                                }
                                .padding()
                                
                                // Token expiration warning
                                if let connection = instagramConnection, connection.needsTokenRefresh {
                                    VStack(spacing: 8) {
                                        Divider()
                                            .background(Color.gray.opacity(0.3))
                                        
                                        HStack(spacing: 12) {
                                            Image(systemName: "exclamationmark.triangle.fill")
                                                .foregroundColor(.yellow)
                                                .font(.system(size: 16))
                                            
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text("Token Expiring Soon")
                                                    .font(.subheadline)
                                                    .fontWeight(.medium)
                                                    .foregroundColor(.white)
                                                
                                                Text("Reconnect to continue scheduling posts")
                                                    .font(.caption)
                                                    .foregroundColor(.gray)
                                            }
                                            
                                            Spacer()
                                            
                                            Button(action: { showInstagramAuth = true }) {
                                                Text("Refresh")
                                                    .font(.caption)
                                                    .fontWeight(.medium)
                                                    .foregroundColor(.marketingPrimary)
                                            }
                                        }
                                        .padding(.horizontal)
                                        .padding(.bottom)
                                    }
                                }
                                
                                // Connection info
                                if instagramConnection != nil {
                                    VStack(spacing: 8) {
                                        Divider()
                                            .background(Color.gray.opacity(0.3))
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            HStack {
                                                Image(systemName: "info.circle")
                                                    .foregroundColor(.gray)
                                                    .font(.caption)
                                                
                                                Text("Your Instagram Business account is connected and ready to schedule posts.")
                                                    .font(.caption)
                                                    .foregroundColor(.gray)
                                                    .fixedSize(horizontal: false, vertical: true)
                                            }
                                        }
                                        .padding(.horizontal)
                                        .padding(.bottom)
                                    }
                                }
                            }
                            .background(Color.marketingCardBackground)
                            .cornerRadius(12)
                            .padding(.horizontal)
                            
                            // Error message
                            if let error = connectionError {
                                HStack(spacing: 12) {
                                    Image(systemName: "exclamationmark.circle.fill")
                                        .foregroundColor(.marketingError)
                                    
                                    Text(error)
                                        .font(.caption)
                                        .foregroundColor(.marketingError)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .padding(.horizontal)
                            }
                        }
                        
                        // Settings sections
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Settings")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal)
                            
                            VStack(spacing: 1) {
                                SettingsRow(icon: "bell.fill", title: "Notifications", action: {})
                                
                                NavigationLink(destination: PrivacyView()) {
                                    SettingsRowContent(icon: "lock.fill", title: "Privacy")
                                }
                                
                                NavigationLink(destination: HelpSupportView()) {
                                    SettingsRowContent(icon: "questionmark.circle.fill", title: "Help & Support")
                                }
                                
                                NavigationLink(destination: TermsOfServiceView()) {
                                    SettingsRowContent(icon: "doc.text.fill", title: "Terms of Service")
                                }
                            }
                            .background(Color.marketingCardBackground)
                            .cornerRadius(12)
                            .padding(.horizontal)
                        }
                        
                        // Sign out button
                        Button(action: { showingSignOutAlert = true }) {
                            Text("Sign Out")
                                .font(.headline)
                                .foregroundColor(.marketingError)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.marketingError.opacity(0.1))
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        .padding(.top, 16)
                        
                        // Version
                        Text("Version 1.0.0")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.top, 8)
                        
                        Spacer(minLength: 50)
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Sign Out", isPresented: $showingSignOutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    Task {
                        await authViewModel.signOut()
                    }
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
            .alert("Disconnect Instagram", isPresented: $showDisconnectAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Disconnect", role: .destructive) {
                    Task {
                        await disconnectInstagram()
                    }
                }
            } message: {
                Text("Are you sure you want to disconnect your Instagram account? You won't be able to schedule new posts until you reconnect.")
            }
            .sheet(isPresented: $showInstagramAuth) {
                InstagramAuthView { connection in
                    Task {
                        await saveInstagramConnection(connection)
                    }
                }
            }
            .task {
                await loadInstagramConnection()
            }
        }
    }
    
    private var initials: String {
        guard let name = authViewModel.currentUser?.name else { return "U" }
        let components = name.split(separator: " ")
        if components.count >= 2 {
            return String(components[0].prefix(1) + components[1].prefix(1)).uppercased()
        } else if let first = components.first {
            return String(first.prefix(1)).uppercased()
        }
        return "U"
    }
    
    // MARK: - Instagram Connection Methods
    
    private func loadInstagramConnection() async {
        do {
            instagramConnection = try await SupabaseService.shared.fetchInstagramConnection()
        } catch {
            print("Error loading Instagram connection: \(error)")
        }
    }
    
    private func saveInstagramConnection(_ connection: InstagramConnection) async {
        isLoadingConnection = true
        connectionError = nil
        
        do {
            let savedConnection = try await SupabaseService.shared.saveInstagramConnection(connection)
            await MainActor.run {
                instagramConnection = savedConnection
                isLoadingConnection = false
            }
        } catch {
            await MainActor.run {
                connectionError = "Failed to save Instagram connection: \(error.localizedDescription)"
                isLoadingConnection = false
            }
        }
    }
    
    private func disconnectInstagram() async {
        isLoadingConnection = true
        connectionError = nil
        
        do {
            try await SupabaseService.shared.disconnectInstagram()
            await MainActor.run {
                instagramConnection = nil
                isLoadingConnection = false
            }
        } catch {
            await MainActor.run {
                connectionError = "Failed to disconnect Instagram: \(error.localizedDescription)"
                isLoadingConnection = false
            }
        }
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            SettingsRowContent(icon: icon, title: title)
        }
    }
}

struct SettingsRowContent: View {
    let icon: String
    let title: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.marketingPrimary)
                .frame(width: 32)
            
            Text(title)
                .foregroundColor(.white)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
                .font(.caption)
        }
        .padding()
        .background(Color.clear)
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthenticationViewModel())
}

