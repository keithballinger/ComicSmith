import Foundation

public struct ToolResult: Codable {
    public var ok: Bool
    public var issueVersion: String
    public var events: [ToolEvent]
    public var error: ToolError?
    public init(ok: Bool, issueVersion: String, events: [ToolEvent] = [], error: ToolError? = nil) {
        self.ok = ok
        self.issueVersion = issueVersion
        self.events = events
        self.error = error
    }
}

public struct ToolEvent: Codable {
    public var type: String
    public var payload: [String: String]
    public init(type: String, payload: [String: String]) {
        self.type = type
        self.payload = payload
    }
}

public struct ToolError: Codable, Error {
    public var code: String
    public var message: String
    public init(code: String, message: String) {
        self.code = code
        self.message = message
    }
}

public struct ToolCall: Codable {
    public var name: String
    public var argumentsJSON: String
    public init(name: String, argumentsJSON: String) {
        self.name = name
        self.argumentsJSON = argumentsJSON
    }
}

public protocol Tool {
    var name: String { get }
    var description: String { get }
    func invoke(argumentsJSON: String, controller: ModelController) async throws -> ToolResult
}

public final class ToolRegistry {
    private var tools: [String: any Tool] = [:]
    public init() {}
    public func register(_ tool: any Tool) {
        tools[tool.name] = tool
    }
    public func allTools() -> [any Tool] {
        return Array(tools.values)
    }
    public func invoke(_ call: ToolCall, controller: ModelController) async -> ToolResult {
        guard let tool = tools[call.name] else {
            return ToolResult(ok: false, issueVersion: controller.issueVersion, events: [], error: ToolError(code: "unknown_tool", message: call.name))
        }
        do {
            return try await tool.invoke(argumentsJSON: call.argumentsJSON, controller: controller)
        } catch let e as ToolError {
            return ToolResult(ok: false, issueVersion: controller.issueVersion, events: [], error: e)
        } catch {
            return ToolResult(ok: false, issueVersion: controller.issueVersion, events: [], error: ToolError(code: "exception", message: String(describing: error)))
        }
    }
}

public enum Mode: String, Codable {
    case issue, page, panel, referencesAll, referenceDetail
}
