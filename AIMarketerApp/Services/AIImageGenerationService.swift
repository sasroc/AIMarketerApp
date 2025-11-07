import Foundation
import UIKit
import Supabase

class AIImageGenerationService {
    static let shared = AIImageGenerationService()
    
    private let supabaseService = SupabaseService.shared
    
    private init() {}
    
    // MARK: - Image Generation
    
    func generateImage(prompt: String, size: ImageSize = .square) async throws -> GeneratedImageResult {
        let request = ImageGenerationRequest(
            prompt: prompt,
            mode: "generate",
            size: size.rawValue
        )
        
        do {
            let response: ImageGenerationResponse = try await supabaseService.client.functions
                .invoke("generate-image", options: FunctionInvokeOptions(body: request))
            
            // Download the image from the URL
            guard let imageURL = URL(string: response.imageUrl) else {
                throw AIImageError.invalidImageURL
            }
            
            let (data, _) = try await URLSession.shared.data(from: imageURL)
            guard let image = UIImage(data: data) else {
                throw AIImageError.invalidImageData
            }
            
            return GeneratedImageResult(
                image: image,
                imageData: data,
                originalPrompt: prompt,
                revisedPrompt: response.revisedPrompt
            )
        } catch {
            // Try to extract error message from response
            if let httpError = error as? any Error {
                print("❌ Image generation HTTP error: \(httpError)")
                
                // Try to get more details from the error
                let errorString = String(describing: httpError)
                print("❌ Error string: \(errorString)")
            }
            
            // Re-throw with more context
            throw AIImageError.generationFailed(error.localizedDescription)
        }
    }
    
    func editImage(prompt: String, sourceImage: UIImage) async throws -> GeneratedImageResult {
        // Convert image to PNG and then to base64
        guard let imageData = sourceImage.pngData() else {
            throw AIImageError.invalidSourceImage
        }
        
        let base64String = imageData.base64EncodedString()
        
        let request = ImageGenerationRequest(
            prompt: prompt,
            mode: "edit",
            imageData: base64String,
            size: "1024x1024"
        )
        
        let response: ImageGenerationResponse = try await supabaseService.client.functions
            .invoke("generate-image", options: FunctionInvokeOptions(body: request))
        
        // Download the edited image
        guard let imageURL = URL(string: response.imageUrl) else {
            throw AIImageError.invalidImageURL
        }
        
        let (data, _) = try await URLSession.shared.data(from: imageURL)
        guard let image = UIImage(data: data) else {
            throw AIImageError.invalidImageData
        }
        
        return GeneratedImageResult(
            image: image,
            imageData: data,
            originalPrompt: prompt,
            revisedPrompt: response.revisedPrompt
        )
    }
}

// MARK: - Models

struct ImageGenerationRequest: Codable {
    let prompt: String
    let mode: String
    let imageData: String?
    let size: String?
    
    init(prompt: String, mode: String, imageData: String? = nil, size: String? = nil) {
        self.prompt = prompt
        self.mode = mode
        self.imageData = imageData
        self.size = size
    }
}

struct ImageGenerationResponse: Codable {
    let imageUrl: String
    let revisedPrompt: String?
}

struct GeneratedImageResult {
    let image: UIImage
    let imageData: Data
    let originalPrompt: String
    let revisedPrompt: String?
}

enum ImageSize: String {
    case square = "1024x1024"
    case portrait = "1024x1792"
    case landscape = "1792x1024"
}

// MARK: - Errors

enum AIImageError: LocalizedError {
    case invalidSourceImage
    case invalidImageURL
    case invalidImageData
    case generationFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidSourceImage:
            return "Unable to process the source image"
        case .invalidImageURL:
            return "Invalid image URL received from server"
        case .invalidImageData:
            return "Unable to load image data"
        case .generationFailed(let message):
            return "Image generation failed: \(message)"
        }
    }
}

