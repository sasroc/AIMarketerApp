import SwiftUI
import PhotosUI

struct CustomBusinessInfoView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    
    @State private var businessSummary: String = ""
    @State private var valueProposition: String = ""
    @State private var businessDescription: String = ""
    @State private var brandColors: [String] = []
    @State private var selectedColor: Color = .blue
    @State private var logoImage: UIImage?
    @State private var selectedLogoItem: PhotosPickerItem?
    @State private var brandImages: [UIImage] = []
    @State private var selectedBrandImageItems: [PhotosPickerItem] = []
    @State private var isUploading = false
    
    @FocusState private var focusedField: Field?
    
    enum Field {
        case summary, valueProposition, description
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Header
                        VStack(spacing: 16) {
                            Image(systemName: "pencil.and.list.clipboard")
                                .font(.system(size: 60))
                                .foregroundColor(.marketingPrimary)
                            
                            Text("Tell Us About Your Business")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                            
                            Text("Fill in your business information to help us create better content for you")
                                .font(.body)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                        .padding(.top, 40)
                        
                        // Business Summary
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Business Summary")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            TextEditor(text: $businessSummary)
                                .frame(minHeight: 100)
                                .padding(8)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(12)
                                .foregroundColor(.white)
                                .focused($focusedField, equals: .summary)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(focusedField == .summary ? Color.marketingPrimary : Color.gray.opacity(0.3), lineWidth: 1)
                                )
                            
                            Text("A brief 2-3 sentence overview of your business")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .padding(.horizontal, 32)
                        
                        // Value Proposition
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Value Proposition")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            TextEditor(text: $valueProposition)
                                .frame(minHeight: 100)
                                .padding(8)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(12)
                                .foregroundColor(.white)
                                .focused($focusedField, equals: .valueProposition)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(focusedField == .valueProposition ? Color.marketingPrimary : Color.gray.opacity(0.3), lineWidth: 1)
                                )
                            
                            Text("What makes your business unique? (1-2 sentences)")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .padding(.horizontal, 32)
                        
                        // Business Description
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Business Description")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            TextEditor(text: $businessDescription)
                                .frame(minHeight: 120)
                                .padding(8)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(12)
                                .foregroundColor(.white)
                                .focused($focusedField, equals: .description)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(focusedField == .description ? Color.marketingPrimary : Color.gray.opacity(0.3), lineWidth: 1)
                                )
                            
                            Text("A detailed description of your business (3-4 sentences)")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .padding(.horizontal, 32)
                        
                        // Brand Colors
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Brand Colors")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            HStack(spacing: 16) {
                                ColorPicker("Select Color", selection: $selectedColor, supportsOpacity: false)
                                    .labelsHidden()
                                    .frame(width: 60, height: 60)
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(12)
                                
                                Button(action: {
                                    let hex = selectedColor.toHex()
                                    if !brandColors.contains(hex) {
                                        brandColors.append(hex)
                                    }
                                }) {
                                    Text("Add Color")
                                        .font(.subheadline)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 12)
                                        .background(Color.marketingPrimary)
                                        .cornerRadius(8)
                                }
                            }
                            
                            if !brandColors.isEmpty {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(brandColors, id: \.self) { colorHex in
                                            VStack(spacing: 8) {
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(Color(hex: colorHex) ?? Color.gray)
                                                    .frame(width: 60, height: 60)
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 8)
                                                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                                    )
                                                
                                                Button(action: {
                                                    brandColors.removeAll { $0 == colorHex }
                                                }) {
                                                    Image(systemName: "xmark.circle.fill")
                                                        .foregroundColor(.red)
                                                        .font(.caption)
                                                }
                                                
                                                Text(colorHex.uppercased())
                                                    .font(.caption2)
                                                    .foregroundColor(.gray)
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 4)
                                }
                            }
                        }
                        .padding(.horizontal, 32)
                        
                        // Logo Upload
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Logo")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            PhotosPicker(
                                selection: $selectedLogoItem,
                                matching: .images
                            ) {
                                HStack {
                                    if let logoImage = logoImage {
                                        Image(uiImage: logoImage)
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 100, height: 100)
                                            .cornerRadius(12)
                                    } else {
                                        VStack(spacing: 8) {
                                            Image(systemName: "photo.fill")
                                                .font(.system(size: 40))
                                                .foregroundColor(.marketingPrimary)
                                            Text("Upload Logo")
                                                .font(.subheadline)
                                                .foregroundColor(.white)
                                        }
                                        .frame(width: 100, height: 100)
                                        .background(Color.gray.opacity(0.2))
                                        .cornerRadius(12)
                                    }
                                }
                            }
                            .onChange(of: selectedLogoItem) { newItem in
                                Task {
                                    if let newItem = newItem,
                                       let data = try? await newItem.loadTransferable(type: Data.self),
                                       let image = UIImage(data: data) {
                                        await MainActor.run {
                                            logoImage = image
                                        }
                                    }
                                }
                            }
                            
                            if logoImage != nil {
                                Button(action: {
                                    logoImage = nil
                                    selectedLogoItem = nil
                                }) {
                                    Text("Remove Logo")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                }
                            }
                        }
                        .padding(.horizontal, 32)
                        
                        // Brand Images
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Brand Images")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Text("Upload images that represent your brand (optional)")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            PhotosPicker(
                                selection: $selectedBrandImageItems,
                                maxSelectionCount: 10,
                                matching: .images
                            ) {
                                HStack {
                                    Image(systemName: "photo.on.rectangle.angled")
                                        .font(.title3)
                                    Text("Select Brand Images")
                                        .fontWeight(.medium)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.marketingPrimary.opacity(0.2))
                                .foregroundColor(.marketingPrimary)
                                .cornerRadius(12)
                            }
                            .onChange(of: selectedBrandImageItems) { newItems in
                                Task {
                                    var loadedImages: [UIImage] = []
                                    for item in newItems {
                                        if let data = try? await item.loadTransferable(type: Data.self),
                                           let image = UIImage(data: data) {
                                            loadedImages.append(image)
                                        }
                                    }
                                    await MainActor.run {
                                        brandImages = loadedImages
                                    }
                                }
                            }
                            
                            if !brandImages.isEmpty {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(Array(brandImages.enumerated()), id: \.offset) { index, image in
                                            ZStack(alignment: .topTrailing) {
                                                Image(uiImage: image)
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fill)
                                                    .frame(width: 120, height: 120)
                                                    .cornerRadius(8)
                                                
                                                Button(action: {
                                                    brandImages.remove(at: index)
                                                }) {
                                                    Image(systemName: "xmark.circle.fill")
                                                        .foregroundColor(.red)
                                                        .background(Color.white)
                                                        .clipShape(Circle())
                                                }
                                                .padding(4)
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 4)
                                }
                            }
                        }
                        .padding(.horizontal, 32)
                        
                        // Error message
                        if let errorMessage = viewModel.errorMessage {
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.horizontal, 32)
                        }
                        
                        // Continue Button
                        Button(action: {
                            Task {
                                isUploading = true
                                do {
                                    try await viewModel.saveCustomBusinessInfo(
                                        summary: businessSummary,
                                        valueProposition: valueProposition,
                                        description: businessDescription,
                                        brandColors: brandColors,
                                        logoImage: logoImage,
                                        brandImages: brandImages
                                    )
                                    // Complete onboarding after saving
                                    try await viewModel.completeOnboarding()
                                    NotificationCenter.default.post(name: RootView.onboardingCompletedNotification, object: nil)
                                } catch {
                                    print("Error saving custom business info: \(error)")
                                    viewModel.errorMessage = error.localizedDescription
                                }
                                isUploading = false
                            }
                        }) {
                            HStack {
                                if isUploading || viewModel.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text("Continue")
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
                        .disabled(isUploading || viewModel.isLoading || businessSummary.isEmpty)
                        .opacity(isUploading || viewModel.isLoading || businessSummary.isEmpty ? 0.6 : 1)
                        .padding(.horizontal, 32)
                        .padding(.bottom, 40)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        // Dismiss keyboard when tapping outside text fields
                        focusedField = nil
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        viewModel.currentStep = .welcome
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .foregroundColor(.marketingPrimary)
                    }
                }
            }
        }
    }
}

// Extension to convert Color to hex string
extension Color {
    func toHex() -> String {
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        let rgb: Int = (Int)(red * 255) << 16 | (Int)(green * 255) << 8 | (Int)(blue * 255) << 0
        
        return String(format: "#%06x", rgb)
    }
}

#Preview {
    CustomBusinessInfoView(viewModel: OnboardingViewModel())
        .environmentObject(AuthenticationViewModel())
}

