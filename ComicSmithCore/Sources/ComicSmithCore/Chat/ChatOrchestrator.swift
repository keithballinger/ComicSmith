import Foundation

public final class ChatOrchestrator {
    public private(set) var history: [ChatMessage] = []
    public var maxVisibleTurns: Int = 12

    private let client: GeminiClient
    private let registry: ToolRegistry
    private let controller: ModelController

    public init(client: GeminiClient, registry: ToolRegistry, controller: ModelController) {
        self.client = client
        self.registry = registry
        self.controller = controller
    }

    public func handleUser(_ text: String) async {
        // 1. Build the tool declarations from the registry
        let toolDeclarations = registry.allTools().map {
            APIFunctionDeclaration(name: $0.name, description: $0.description)
        }

        // 2. Build the message history
        let state = StateSummaryBuilder.build(model: controller.model, mode: controller.mode, focus: controller.focus)
        let stateMsg = ChatMessage(role: .system, content: state)
        let primer = ChatMessage(role: .system, content: SystemPrimer.text)
        let visibleHistory = history.suffix(maxVisibleTurns)
        let userMsg = ChatMessage(role: .user, content: text)
        
        let messages = [stateMsg, primer] + Array(visibleHistory) + [userMsg]

        // 3. Generate content
        do {
            let resp = try await client.generate(messages: messages, tools: toolDeclarations)
            if let calls = resp.toolCalls, !calls.isEmpty {
                // In a real app, you might want to show the tool calls to the user.
                // Here, we just apply them and add a summary message.
                for call in calls {
                    let result = await registry.invoke(call, controller: controller)
                    apply(result: result)
                }
                history.append(ChatMessage(role: .assistant, content: "Applied \(calls.count) tool(s)."))
            } else if let reply = resp.assistantText {
                history.append(ChatMessage(role: .assistant, content: reply))
            }
        } catch {
            history.append(ChatMessage(role: .assistant, content: "Error: \(error.localizedDescription)"))
        }
    }

    private func apply(result: ToolResult) {
        // In a real app, you'd map events to UI effects, diffs in Script, etc.
        // Here we only update the chat history minimally if needed.
        if let err = result.error {
            history.append(ChatMessage(role: .assistant, content: "Tool error [\(err.code)]: \(err.message)"))
        }
    }
}