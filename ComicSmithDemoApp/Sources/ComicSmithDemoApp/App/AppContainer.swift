import Foundation
import SwiftUI
import ComicSmithCore

@MainActor
final class AppContainer: ObservableObject {
    // Main observable state
    @Published var images: ImageGenQueue
    @Published var issue: Issue
    @Published var chat: [ChatMessage] = []
    @Published var mode: Mode = .issue
    @Published var focus: Focus = Focus()
    @Published var referencesSearch: String = ""

    // Core services (not observed by UI)
    let controller: ModelController
    let registry: ToolRegistry
    let orchestrator: ChatOrchestrator
    
    // For autosaving
    private let persistenceService: PersistenceService
    private let autosaveDebouncer = Debouncer(delay: 2.0)

    init() {
        // --- Persistence Setup ---
        let fileManager = FileManager.default
        let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let projectURL = appSupportURL.appendingPathComponent("ComicSmithDemoProject")
        self.persistenceService = PersistenceService(projectRoot: projectURL, fileManager: fileManager)

        // --- Model Setup ---
        let loadedModel: (issue: Issue, references: [ReferenceEntry])
        do {
            loadedModel = try persistenceService.load()
            print("Successfully loaded project from \(projectURL.path)")
        } catch {
            print("Could not load project, starting new one. Error: \(error)")
            loadedModel = (Issue(title: "New Issue"), [])
        }
        
        self.controller = ModelController(model: loadedModel.issue)
        self.controller.references = loadedModel.references

        // --- Core Services Setup ---
        let apiKey = "YOUR_GEMINI_API_KEY" // TODO: Replace with a real key
        self.registry = ToolRegistry()
        registerAllTools(into: registry)
        let textClient = RealGeminiClient(apiKey: apiKey)
        self.orchestrator = ChatOrchestrator(client: textClient, registry: registry, controller: controller)
        self.images = ImageGenQueue(modelController: self.controller, apiKey: apiKey)
        
        // --- Initial State Publishing ---
        self.issue = controller.model
        self.chat = orchestrator.history
        
        // --- Autosave Wiring ---
        self.controller.onModelChange = { [weak self] in
            self?.handleModelChange()
        }
    }
    
    private func handleModelChange() {
        autosaveDebouncer.debounce { [weak self] in
            guard let self = self else { return }
            do {
                print("Autosaving project...")
                try self.persistenceService.save(issue: self.controller.model, references: self.controller.references)
                print("Autosave successful.")
            } catch {
                print("Error autosaving project: \(error)")
            }
        }
        self.refresh()
    }

    func refresh() {
        self.issue = controller.model
        self.mode = controller.mode
        self.focus = controller.focus
        self.chat = orchestrator.history
    }

    func sendChat(_ text: String) async {
        await orchestrator.handleUser(text)
    }

    // MARK: - UI Actions (proxied to services)

    func addPage(panelCount: Int = 6) {
        _ = controller.addPage(index: nil, panelCount: panelCount, layoutPreset: "grid-6", title: "Page", beatPrompt: nil)
        controller.mode = .page
    }
    
    func selectPage(_ pageID: String) {
        controller.mode = .page
        controller.focus.pageID = pageID
        controller.focus.panelID = nil
        refresh()
    }
    
    func addPanel(to pageID: String) {
        _ = try? controller.addPanel(pageID: pageID, index: nil, description: "New panel description…")
        controller.mode = .page
    }
    
    func selectPanel(pageID: String, panelID: String) {
        controller.mode = .panel
        controller.focus.pageID = pageID
        controller.focus.panelID = panelID
        refresh()
    }

    func selectReference(_ id: String) {
        controller.mode = .referenceDetail
        controller.focus.referenceID = id
        refresh()
    }
    
    func refName(for id: String) -> String {
        controller.references.first(where: { $0.id == id })?.name ?? "Unknown"
    }

    func usageCount(for ref: ReferenceEntry) -> Int {
        var count = 0
        for page in controller.model.pages {
            for panel in page.panels {
                if ref.kind == "character" && panel.characterIDs.contains(ref.id) { count += 1 }
                if ref.kind == "location", let lid = panel.locationID, lid == ref.id { count += 1 }
                if ref.kind == "prop" && panel.propIDs.contains(ref.id) { count += 1 }
            }
        }
        return count
    }
    
    // MARK: - Image Queue Proxies
    
    var totalImagesInProgress: Int {
        images.totalInProgress
    }
    
    func isPageGenerating(_ id: String) -> Bool {
        images.inProgressPages.contains(id)
    }
    
    func enqueuePageThumbnails(pageID: String) {
        images.enqueuePageThumbnails(pageID: pageID)
    }
    
    func enqueuePanelVisual(pageID: String, panelID: String) {
        images.enqueuePanelVisual(pageID: pageID, panelID: panelID)
    }
    
    func enqueueReferenceImage(referenceID: String) {
        images.enqueueReferenceImage(referenceID: referenceID)
    }
}
