import SwiftUI

struct BusinessCategorySelectionView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Header
                        VStack(spacing: 16) {
                            Image(systemName: "building.2.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.marketingPrimary)
                            
                            Text("Choose your business category")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                            
                            Text("This helps us generate better content for your business")
                                .font(.body)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                        .padding(.top, 60)
                        
                        // Category Grid
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(viewModel.businessCategories, id: \.self) { category in
                                CategoryButton(
                                    title: category,
                                    isSelected: viewModel.selectedCategory == category,
                                    action: {
                                        viewModel.selectCategory(category)
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
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
        }
    }
}

struct CategoryButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(isSelected ? .white : .gray)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? Color.marketingPrimary : Color.gray.opacity(0.2))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? Color.marketingPrimary : Color.gray.opacity(0.3), lineWidth: 1)
                )
        }
    }
}

#Preview {
    BusinessCategorySelectionView(viewModel: OnboardingViewModel())
        .environmentObject(AuthenticationViewModel())
}

