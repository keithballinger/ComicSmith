import Foundation

public final class RealGeminiClient: GeminiClient {
    private let apiKey: String
    private let urlSession: URLSession
    private let modelName: String
    
    private var endpointURL: URL {
        URL(string: "https://generativelanguage.googleapis.com/v1beta/models/\(modelName):generateContent?key=\(apiKey)")!
    }

    public init(apiKey: String, modelName: String = "gemini-1.5-flash-latest", urlSession: URLSession = .shared) {
        self.apiKey = apiKey
        self.modelName = modelName
        self.urlSession = urlSession
    }

    public func generate(messages: [ChatMessage], tools: [APIFunctionDeclaration]) async throws -> GeminiResponse {
        // 1. Construct the request body
        let apiContents = messages.map { APIContent(role: $0.role.rawValue, parts: [APIPart(text: $0.content)]) }
        let apiTools = [APITool(functionDeclarations: tools)]
        let requestBody = APIRequest(contents: apiContents, tools: apiTools)
        let requestData = try JSONEncoder().encode(requestBody)

        // 2. Create the URLRequest
        var request = URLRequest(url: endpointURL)
        request.httpMethod = "POST"
        request.httpBody = requestData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // 3. Send the request
        let (data, response) = try await urlSession.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let errorBody = String(data: data, encoding: .utf8) ?? "(could not decode error body)"
            throw ToolError(code: "http_error", message: "HTTP Error: \(String(describing: response)) - Body: \(errorBody)")
        }

        // 4. Decode and map the response
        let apiResponse = try JSONDecoder().decode(APIResponse.self, from: data)
        
        guard let candidate = apiResponse.candidates?.first, let content = candidate.content, let parts = content.parts else {
            return GeminiResponse(assistantText: "No response from model.")
        }
        
        var toolCalls: [ToolCall] = []
        var assistantText: String? = nil
        
        for part in parts {
            if let call = part.functionCall {
                let argsJSON = try encodeArgs(call.args)
                toolCalls.append(ToolCall(name: call.name, argumentsJSON: argsJSON))
            } else if let text = part.text {
                assistantText = (assistantText ?? "") + text
            }
        }
        
        if !toolCalls.isEmpty {
            return GeminiResponse(toolCalls: toolCalls)
        } else {
            return GeminiResponse(assistantText: assistantText)
        }
    }
    
    private func encodeArgs(_ args: [String: String]?) throws -> String {
        guard let args = args, !args.isEmpty else { return "{}" }
        let data = try JSONSerialization.data(withJSONObject: args, options: [])
        return String(data: data, encoding: .utf8) ?? "{}"
    }
}
