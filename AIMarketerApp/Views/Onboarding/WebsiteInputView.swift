import SwiftUI

struct WebsiteInputView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @Environment(\.dismiss) var dismiss
    @State private var websiteUrl: String = ""
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 32) {
                    Spacer()
                    
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "globe")
                            .font(.system(size: 60))
                            .foregroundColor(.marketingPrimary)
                        
                        Text("Enter Your Business Website")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        
                        Text("We'll analyze your website to understand your business and automatically extract brand colors, logos, and key information")
                            .font(.body)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    
                    // Website Input
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Website URL")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        TextField("https://example.com", text: $websiteUrl)
                            .textContentType(.URL)
                            .keyboardType(.URL)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                            .focused($isTextFieldFocused)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(12)
                            .foregroundColor(.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(isTextFieldFocused ? Color.marketingPrimary : Color.gray.opacity(0.3), lineWidth: 1)
                            )
                    }
                    .padding(.horizontal, 32)
                    
                    // Error message
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal, 32)
                    }
                    
                    // Analyze Button
                    Button(action: {
                        Task {
                            let url = formatUrl(websiteUrl)
                            do {
                                try await viewModel.analyzeWebsite(url)
                            } catch {
                                // Error is handled in viewModel
                            }
                        }
                    }) {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Analyze Website")
                                    .font(.headline)
                            }
                        }
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
                    .disabled(viewModel.isLoading || websiteUrl.isEmpty)
                    .opacity(viewModel.isLoading || websiteUrl.isEmpty ? 0.6 : 1)
                    .padding(.horizontal, 32)
                    
                    Spacer()
                }
                .padding(.top, 40)
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
    
    private func formatUrl(_ url: String) -> String {
        var formatted = url.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Add https:// if no scheme
        if !formatted.contains("://") {
            formatted = "https://\(formatted)"
        }
        
        return formatted
    }
}

#Preview {
    WebsiteInputView(viewModel: OnboardingViewModel())
}

