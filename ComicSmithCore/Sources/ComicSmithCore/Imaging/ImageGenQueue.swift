import Foundation
import Combine

// --- Gemini Image Client (Internal) ---

fileprivate typealias ImageData = Data

// MARK: - API Schemas

fileprivate struct ImageAPIRequest: Codable {
    struct Content: Codable {
        struct Part: Codable {
            let text: String
        }
        let parts: [Part]
    }
    let contents: [Content]
}

fileprivate struct ImageAPIResponse: Codable {
    struct Prediction: Codable {
        let bytesBase64Encoded: String
        let mimeType: String
    }
    let predictions: [Prediction]
}

// MARK: - Client Protocol & Implementation

fileprivate protocol GeminiImageClient {
    func generateImage(prompt: String) async throws -> ImageData
}

fileprivate final class RealGeminiImageClient: GeminiImageClient {
    private let apiKey: String
    private let urlSession: URLSession
    private let modelName: String = "gemini-1.5-flash-latest" // Assumes a model capable of image gen
    
    private var endpointURL: URL {
        // NOTE: This endpoint is for Vertex AI. The consumer API might differ.
        // Using a placeholder structure based on the text generation API.
        URL(string: "https://us-central1-aiplatform.googleapis.com/v1/projects/YOUR_PROJECT_ID/locations/us-central1/publishers/google/models/\(modelName):predict?key=\(apiKey)")!
    }
    
    init(apiKey: String, urlSession: URLSession = .shared) {
        self.apiKey = apiKey
        self.urlSession = urlSession
    }
    
    public func generateImage(prompt: String) async throws -> ImageData {
        let requestBody = ImageAPIRequest(contents: [.init(parts: [.init(text: prompt)])])
        let requestData = try JSONEncoder().encode(requestBody)
        
        var request = URLRequest(url: endpointURL)
        request.httpMethod = "POST"
        request.httpBody = requestData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await urlSession.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let errorBody = String(data: data, encoding: .utf8) ?? "(could not decode error body)"
            throw ToolError(code: "http_error", message: "HTTP Error: \(String(describing: response)) - Body: \(errorBody)")
        }
        
        let apiResponse = try JSONDecoder().decode(ImageAPIResponse.self, from: data)
        
        guard let firstPrediction = apiResponse.predictions.first else {
            throw ToolError(code: "no_image_data", message: "No image data received from API.")
        }
        
        guard let imageData = Data(base64Encoded: firstPrediction.bytesBase64Encoded) else {
            throw ToolError(code: "base64_decode_error", message: "Failed to decode Base64 image data.")
        }
        
        return imageData
    }
}

// MARK: - Image Generation Queue

@MainActor
public final class ImageGenQueue: ObservableObject {
    @Published public var inProgressPanels: Set<String> = []
    @Published public var inProgressPages: Set<String> = []
    @Published public var inProgressRefs: Set<String> = []

    public var totalInProgress: Int { inProgressPanels.count + inProgressPages.count + inProgressRefs.count }

    private let modelController: ModelController
    private let imageClient: GeminiImageClient
    
    public init(modelController: ModelController, apiKey: String) {
        self.modelController = modelController
        // NOTE: You would need to replace YOUR_PROJECT_ID in the client's URL.
        self.imageClient = RealGeminiImageClient(apiKey: apiKey)
    }

    public func enqueuePanelVisual(pageID: String, panelID: String) {
        guard let (page, panel) = findPageAndPanel(pageID: pageID, panelID: panelID) else { return }
        
        inProgressPanels.insert(panelID)
        
        Task {
            defer { inProgressPanels.remove(panelID) }
            
            let prompt = buildPanelPrompt(panel: panel, page: page)
            
            do {
                let imageData = try await imageClient.generateImage(prompt: prompt)
                print("Successfully generated image for panel \(panelID), size: \(imageData.count) bytes.")
                // TODO: Handle the returned image data (e.g., save to cache, update UI)
            } catch {
                print("Error generating image for panel \(panelID): \(error)")
            }
        }
    }
    
    public func enqueuePageThumbnails(pageID: String) {
        inProgressPages.insert(pageID)
        Task {
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            inProgressPages.remove(pageID)
        }
    }
    
    public func enqueueReferenceImage(referenceID: String) {
        inProgressRefs.insert(referenceID)
        Task {
            try? await Task.sleep(nanoseconds: 700_000_000)
            inProgressRefs.remove(referenceID)
        }
    }
    
    private func findPageAndPanel(pageID: String, panelID: String) -> (Page, Panel)? {
        guard let page = modelController.model.pages.first(where: { $0.id == pageID }),
              let panel = page.panels.first(where: { $0.id == panelID }) else {
            return nil
        }
        return (page, panel)
    }
    
    private func buildPanelPrompt(panel: Panel, page: Page) -> String {
        let characterNames = panel.characterIDs.map { id in
            modelController.references.first { $0.id == id }?.name ?? "unknown character"
        }.joined(separator: ", ")
        
        let locationName = panel.locationID.flatMap { id in
            modelController.references.first { $0.id == id }?.name
        } ?? "an unknown location"
        
        let propNames = panel.propIDs.map { id in
            modelController.references.first { $0.id == id }?.name ?? "unknown prop"
        }.joined(separator: ", ")

        let prompt = """
        STYLE: panel rough; clear silhouettes; indicate lighting and scale
        SERIES_STYLE: high-contrast ink, dynamic angles
        FOCUS: \(panel.description)
        SUBJECTS: characters=[\(characterNames)]; location=[\(locationName)]; props=[\(propNames)]
        CONSTRAINTS: no speech balloons; allow diegetic signage if specified
        """
        return prompt
    }
}