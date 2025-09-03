import Foundation

public final class RealGeminiClient: GeminiClient {
    private let apiKey: String
    private let urlSession: URLSession
    private let modelName: String
    private let temperature: Double
    private let maxRetries: Int
    
    private var endpointURL: URL {
        URL(string: "https://generativelanguage.googleapis.com/v1beta/models/\(modelName):generateContent?key=\(apiKey)")!
    }

    public init(
        apiKey: String,
        modelName: String = "gemini-2.0-flash-exp", // Updated to Flash 2.5/2.0
        temperature: Double = 0.7,
        maxRetries: Int = 3,
        urlSession: URLSession = .shared
    ) {
        self.apiKey = apiKey
        self.modelName = modelName
        self.temperature = temperature
        self.maxRetries = maxRetries
        self.urlSession = urlSession
    }

    public func generate(messages: [ChatMessage], tools: [APIFunctionDeclaration]) async throws -> GeminiResponse {
        var lastError: Error?
        
        for attempt in 1...maxRetries {
            do {
                return try await attemptGenerate(messages: messages, tools: tools)
            } catch {
                lastError = error
                
                // Check if error is retryable
                if isRetryableError(error) && attempt < maxRetries {
                    // Exponential backoff: 1s, 2s, 4s
                    let delay = UInt64(pow(2.0, Double(attempt - 1)) * 1_000_000_000)
                    try await Task.sleep(nanoseconds: delay)
                    continue
                }
                
                throw error
            }
        }
        
        throw lastError ?? ToolError(code: "max_retries", message: "Failed after \(maxRetries) attempts")
    }
    
    private func isRetryableError(_ error: Error) -> Bool {
        // Retry on network errors and 5xx status codes
        if let toolError = error as? ToolError {
            return toolError.code == "http_error" && 
                   (toolError.message.contains("500") ||
                    toolError.message.contains("502") ||
                    toolError.message.contains("503") ||
                    toolError.message.contains("504"))
        }
        
        // Retry on URLSession errors
        if (error as NSError).domain == NSURLErrorDomain {
            let code = (error as NSError).code
            return code == NSURLErrorTimedOut ||
                   code == NSURLErrorNetworkConnectionLost ||
                   code == NSURLErrorNotConnectedToInternet
        }
        
        return false
    }
    
    private func attemptGenerate(messages: [ChatMessage], tools: [APIFunctionDeclaration]) async throws -> GeminiResponse {
        // 1. Construct the request body
        // Map roles: system/assistant -> "model", user -> "user"
        let apiContents = messages.map { msg in
            let apiRole = msg.role == .user ? "user" : "model"
            return APIContent(role: apiRole, parts: [APIPart(text: msg.content)])
        }
        let apiTools = tools.isEmpty ? [] : [APITool(functionDeclarations: tools)]
        let requestBody = APIRequestWithConfig(
            contents: apiContents, 
            tools: apiTools,
            generationConfig: GenerationConfig(temperature: temperature)
        )
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
