import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @State private var showingSignIn = false
    @State private var showingSignUp = false
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.marketingPrimary.opacity(0.8), Color.marketingSecondary.opacity(0.6)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Spacer()
                
                // Logo and title
                VStack(spacing: 20) {
                    Image(systemName: "sparkles.rectangle.stack.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 10)
                    
                    Text("AI Marketer")
                        .font(.system(size: 42, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Automate your social media content with AI")
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                Spacer()
                
                // Action buttons
                VStack(spacing: 16) {
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
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                    }
                    .disabled(authViewModel.isLoading)
                    .opacity(authViewModel.isLoading ? 0.6 : 1)
                    
                    if authViewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 50)
            }
        }
        .sheet(isPresented: $showingSignIn) {
            SignInView()
        }
        .sheet(isPresented: $showingSignUp) {
            SignUpView()
        }
    }
    
    private func signInWithGoogle() {
        Task {
            await authViewModel.signInWithGoogle()
        }
    }
}

#Preview {
    WelcomeView()
        .environmentObject(AuthenticationViewModel())
}

