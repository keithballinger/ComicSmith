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
    private var persistenceService: PersistenceService
    private let autosaveDebouncer = Debouncer(delay: 2.0)
    private var currentProjectURL: URL
    private let keychainService = KeychainService()

    init() {
        // --- Persistence Setup ---
        let fileManager = FileManager.default
        let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let projectURL = appSupportURL.appendingPathComponent("ComicSmithDemoProject")
        self.currentProjectURL = projectURL
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
        // Try to load API key from Keychain, fall back to placeholder
        let apiKey: String
        do {
            apiKey = try keychainService.getAPIKey(for: "gemini")
            print("Loaded Gemini API key from Keychain")
        } catch {
            apiKey = "YOUR_GEMINI_API_KEY" // Placeholder - user needs to set this
            print("No API key in Keychain, using placeholder")
        }
        
        self.registry = ToolRegistry()
        registerAllTools(into: registry)
        let textClient = RealGeminiClient(apiKey: apiKey, temperature: 0.7)
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
    
    // MARK: - File Management
    
    func newProject() {
        // Create new empty project
        controller.replaceModel(Issue(title: "New Issue"))
        controller.references = []
        controller.mode = .issue
        controller.focus = Focus()
        
        // Update UI
        refresh()
        
        // Trigger save to new location
        autosaveDebouncer.debounce { [weak self] in
            self?.saveCurrentProject()
        }
    }
    
    func openProject(at url: URL) {
        do {
            // Update persistence service to new location
            let newPersistence = PersistenceService(projectRoot: url)
            let (loadedIssue, loadedReferences) = try newPersistence.load()
            
            // Update model
            controller.replaceModel(loadedIssue)
            controller.references = loadedReferences
            controller.mode = .issue
            controller.focus = Focus()
            
            // Update persistence
            self.persistenceService = newPersistence
            self.currentProjectURL = url
            
            // Update UI
            refresh()
            
            print("Opened project from \(url.path)")
        } catch {
            print("Failed to open project: \(error)")
        }
    }
    
    func saveProject() {
        saveCurrentProject()
    }
    
    func saveProjectAs(to url: URL) {
        do {
            // Create new persistence service at new location
            let newPersistence = PersistenceService(projectRoot: url)
            try newPersistence.save(issue: controller.model, references: controller.references)
            
            // Update to use new location
            self.persistenceService = newPersistence
            self.currentProjectURL = url
            
            print("Saved project to new location: \(url.path)")
        } catch {
            print("Failed to save project as: \(error)")
        }
    }
    
    private func saveCurrentProject() {
        do {
            try persistenceService.save(issue: controller.model, references: controller.references)
            print("Saved project to \(currentProjectURL.path)")
        } catch {
            print("Failed to save project: \(error)")
        }
    }
    
    // MARK: - API Key Management
    
    func setAPIKey(_ apiKey: String, for service: String = "gemini") throws {
        try keychainService.saveAPIKey(apiKey, for: service)
        
        // Reinitialize services with new API key
        let textClient = RealGeminiClient(apiKey: apiKey, temperature: 0.7)
        // Note: We'd need to make orchestrator mutable or recreate it
        // For now, this requires app restart to take effect
    }
    
    func getAPIKey(for service: String = "gemini") throws -> String {
        return try keychainService.getAPIKey(for: service)
    }
    
    func hasAPIKey(for service: String = "gemini") -> Bool {
        return keychainService.hasAPIKey(for: service)
    }
}
