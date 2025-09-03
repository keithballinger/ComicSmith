# ComicSmithCore (Swift Package)

This is a scaffolded core package for the ComicSmith macOS app.

## How to use
1. Open Xcode ➜ File ➜ Add Packages… ➜ Add Local… ➜ select this folder.
   - Or unzip and `swift build` from Terminal.
2. In your app target, create instances:
   ```swift
   import ComicSmithCore

   let client = MockGeminiClient() // replace with real Gemini client
   let registry = ToolRegistry(); registerAllTools(into: registry)
   let controller = ModelController()
   let orchestrator = ChatOrchestrator(client: client, registry: registry, controller: controller)
   ```
3. Wire your Chat UI to `orchestrator.handleUser(_:)`.
   Wire Content/Script panes to the `ModelController` (mutations happen via tools).

## Structure
- Package.swift
- Sources/ComicSmithCore/
  - Chat/ (Gemini client protocol + orchestrator)
  - Model/ (Issue/Page/Panel/Balloon/Reference + ModelController)
  - Prompts/ (System primer string)
  - StateSummary/ (State summary builder)
  - Tooling/ (Tool protocol, registry, and tool stubs)

This is a scaffold—fill in real persistence, image queues, and UI bindings.
