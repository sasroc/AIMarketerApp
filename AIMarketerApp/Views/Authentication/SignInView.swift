import SwiftUI

struct SignInView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 40) {
                    Spacer()
                    
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "sparkles.rectangle.stack.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.marketingPrimary)
                        
                        Text("Welcome Back")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Sign in with your Google account to continue")
                            .font(.body)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    
                    // Error message
                    if let errorMessage = authViewModel.errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal)
                    }
                    
                    // Google Sign In Button
                    Button(action: signInWithGoogle) {
                        HStack(spacing: 12) {
                            // Official Google logo
                            Image("GoogleLogo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 20, height: 20)
                            
                            Text("Continue with Google")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(Color(red: 0.25, green: 0.25, blue: 0.25))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.white)
                                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                    .disabled(authViewModel.isLoading)
                    .opacity(authViewModel.isLoading ? 0.6 : 1)
                    .padding(.horizontal, 32)
                    
                    if authViewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .marketingPrimary))
                    }
                    
                    Spacer()
                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.marketingPrimary)
                }
            }
        }
    }
    
    private func signInWithGoogle() {
        Task {
            await authViewModel.signInWithGoogle()
            if authViewModel.isAuthenticated {
                dismiss()
            }
        }
    }
}

#Preview {
    SignInView()
        .environmentObject(AuthenticationViewModel())
}

