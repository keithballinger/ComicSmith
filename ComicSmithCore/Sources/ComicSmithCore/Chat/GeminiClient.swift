import Foundation

// MARK: - Public API Contracts & Schemas

public struct ChatMessage: Codable {
    public enum Role: String, Codable { case system, user, assistant }
    public var role: Role
    public var content: String
    public init(role: Role, content: String) {
        self.role = role
        self.content = content
    }
}

public struct GeminiResponse: Codable {
    public var assistantText: String?
    public var toolCalls: [ToolCall]?
    public init(assistantText: String? = nil, toolCalls: [ToolCall]? = nil) {
        self.assistantText = assistantText
        self.toolCalls = toolCalls
    }
}

// MARK: - Gemini API Request Schemas

public struct APIRequest: Codable {
    public let contents: [APIContent]
    public let tools: [APITool]
}

public struct APIContent: Codable {
    public let role: String // "user" or "model"
    public let parts: [APIPart]
}

public struct APIPart: Codable {
    public let text: String
}

public struct APITool: Codable {
    public let functionDeclarations: [APIFunctionDeclaration]
}

public struct APIFunctionDeclaration: Codable {
    public let name: String
    public let description: String
    public let parameters: [String: String] = [:] // Simplified for now
    
    public init(name: String, description: String) {
        self.name = name
        self.description = description
    }
}

// MARK: - Gemini API Response Schemas

public struct APIResponse: Codable {
    public struct Candidate: Codable {
        public struct Content: Codable {
            public struct Part: Codable {
                public let text: String?
                public let functionCall: APIFunctionCall?
            }
            public let parts: [Part]?
        }
        public let content: Content?
    }
    public let candidates: [Candidate]?
}

public struct APIFunctionCall: Codable {
    public let name: String
    public let args: [String: String]? // Simplified for this implementation
}

// MARK: - Client Protocol

public protocol GeminiClient {
    func generate(messages: [ChatMessage], tools: [APIFunctionDeclaration]) async throws -> GeminiResponse
}

// MARK: - Mock Client

public final class MockGeminiClient: GeminiClient {
    public init() {}
    public func generate(messages: [ChatMessage], tools: [APIFunctionDeclaration]) async throws -> GeminiResponse {
        guard let last = messages.last else { return GeminiResponse(assistantText: "No input.") }
        if last.content.lowercased().contains("new page") {
            let args = ["panel_count": 6] as [String: Any]
            let data = try! JSONSerialization.data(withJSONObject: args, options: [])
            let json = String(data: data, encoding: .utf8)!
            let call = ToolCall(name: "add_page", argumentsJSON: json)
            return GeminiResponse(toolCalls: [call])
        }
        return GeminiResponse(assistantText: "Sure — what beat do you want next?")
    }
}
