import SwiftUI

struct CustomCategoryInputView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 32) {
                    Spacer()
                    
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "pencil.and.list.clipboard")
                            .font(.system(size: 60))
                            .foregroundColor(.marketingPrimary)
                        
                        Text("What's your business category?")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        
                        Text("Enter a category that best describes your business")
                            .font(.body)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .padding(.top, 60)
                    
                    // Text Input
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Business Category")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        TextField("e.g., Photography, Consulting, Art Studio", text: $viewModel.customCategory)
                            .font(.body)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(isTextFieldFocused ? Color.marketingPrimary : Color.gray.opacity(0.3), lineWidth: 1)
                            )
                            .focused($isTextFieldFocused)
                            .autocapitalization(.words)
                            .autocorrectionDisabled()
                    }
                    .padding(.horizontal, 32)
                    
                    // Continue Button
                    Button(action: {
                        viewModel.saveCustomCategory()
                    }) {
                        Text("Continue")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [Color.marketingPrimary, Color.marketingSecondary],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 32)
                    .disabled(viewModel.customCategory.trimmingCharacters(in: .whitespaces).isEmpty)
                    .opacity(viewModel.customCategory.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1.0)
                    
                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") {
                        viewModel.currentStep = .categorySelection
                        viewModel.customCategory = ""
                    }
                    .foregroundColor(.marketingPrimary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Sign Out") {
                        Task {
                            do {
                                try await authViewModel.signOut()
                            } catch {
                                print("Error signing out: \(error)")
                            }
                        }
                    }
                    .foregroundColor(.marketingPrimary)
                }
            }
            .onAppear {
                // Focus the text field when view appears
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isTextFieldFocused = true
                }
            }
        }
    }
}

#Preview {
    CustomCategoryInputView(viewModel: OnboardingViewModel())
        .environmentObject(AuthenticationViewModel())
}

