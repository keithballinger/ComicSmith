import Foundation

public struct Balloon: Codable, Identifiable, Equatable, Hashable {
    public var id: String = UUID().uuidString
    public var kind: String // "speech","thought","caption","sfx"
    public var speaker: String?
    public var text: String
    public var order: Int
}

public struct Panel: Codable, Identifiable, Equatable, Hashable {
    public var id: String = UUID().uuidString
    public var description: String = ""
    public var role: String = "normal" // normal,splash,inset
    public var balloons: [Balloon] = []
    public var characterIDs: [String] = []
    public var locationID: String?
    public var propIDs: [String] = []
}

public struct Page: Codable, Identifiable, Equatable, Hashable {
    public var id: String = UUID().uuidString
    public var title: String = ""
    public var layoutPreset: String = "grid-6"
    public var panels: [Panel] = []
}

public struct ReferenceEntry: Codable, Identifiable, Equatable, Hashable {
    public var id: String = UUID().uuidString
    public var kind: String // character, location, prop
    public var name: String
    public var aliases: [String] = []
    public var traits: [String] = []
    public var voiceNotes: String? = nil
    public var visualCues: [String] = []
    public var introducedPageIndex: Int? = nil
}

public struct Issue: Codable, Equatable, Hashable {
    public var title: String = "Issue"
    public var pages: [Page] = []

    // Public initializer to be accessible from other modules
    public init(title: String = "Issue", pages: [Page] = []) {
        self.title = title
        self.pages = pages
    }
}

public struct Focus: Codable, Hashable {
    public var pageID: String? = nil
    public var panelID: String? = nil
    public var referenceID: String? = nil
    
    public init(pageID: String? = nil, panelID: String? = nil, referenceID: String? = nil) {
        self.pageID = pageID
        self.panelID = panelID
        self.referenceID = referenceID
    }
}

public final class ModelController {
    public private(set) var model: Issue
    public var mode: Mode = .issue
    public var focus = Focus()
    public private(set) var issueVersion: String = ISO8601DateFormatter().string(from: Date())
    public var onModelChange: (() -> Void)?

    public init(model: Issue = Issue()) {
        self.model = model
    }

    private func bumpVersion() {
        issueVersion = ISO8601DateFormatter().string(from: Date())
        onModelChange?()
    }

    // MARK: - Issue ops
    @discardableResult
    public func addPage(index: Int?, panelCount: Int?, layoutPreset: String?, title: String?, beatPrompt: String?) -> Page {
        var page = Page()
        page.title = title ?? ""
        if let layout = layoutPreset { page.layoutPreset = layout }
        if let count = panelCount {
            page.panels = (0..<max(count,0)).map { _ in Panel() }
        }
        if let idx = index, idx >= 0, idx <= model.pages.count {
            model.pages.insert(page, at: idx)
            focus.pageID = page.id
        } else {
            model.pages.append(page)
            focus.pageID = page.id
        }
        bumpVersion()
        return page
    }
    public func removePage(id: String) throws {
        guard let i = model.pages.firstIndex(where: { $0.id == id }) else {
            throw ToolError(code: "not_found", message: "page_id \(id)")
        }
        model.pages.remove(at: i)
        bumpVersion()
    }
    public func movePage(id: String, toIndex: Int) throws {
        guard let i = model.pages.firstIndex(where: { $0.id == id }) else {
            throw ToolError(code: "not_found", message: "page_id \(id)")
        }
        let page = model.pages.remove(at: i)
        let idx = max(0, min(toIndex, model.pages.count))
        model.pages.insert(page, at: idx)
        bumpVersion()
    }
    public func setPageLayout(id: String, layoutPreset: String) throws {
        guard let i = model.pages.firstIndex(where: { $0.id == id }) else {
            throw ToolError(code: "not_found", message: "page_id \(id)")
        }
        model.pages[i].layoutPreset = layoutPreset
        bumpVersion()
    }
    public func updatePageTitle(id: String, newTitle: String) throws {
        guard let i = model.pages.firstIndex(where: { $0.id == id }) else {
            throw ToolError(code: "not_found", message: "page_id \(id)")
        }
        model.pages[i].title = newTitle
        bumpVersion()
    }
    public func replacePage(at index: Int, with page: Page) {
        guard index >= 0 && index < model.pages.count else { return }
        model.pages[index] = page
        bumpVersion()
    }
    
    public func replaceModel(_ newModel: Issue) {
        model = newModel
        bumpVersion()
    }

    // MARK: - Page ops
    public func addPanel(pageID: String, index: Int?, description: String?) throws -> Panel {
        guard let pIdx = model.pages.firstIndex(where: { $0.id == pageID }) else {
            throw ToolError(code: "not_found", message: "page_id \(pageID)")
        }
        var panel = Panel()
        if let d = description { panel.description = d }
        var panels = model.pages[pIdx].panels
        if let idx = index, idx >= 0, idx <= panels.count {
            panels.insert(panel, at: idx)
        } else {
            panels.append(panel)
        }
        model.pages[pIdx].panels = panels
        focus.pageID = pageID
        focus.panelID = panel.id
        bumpVersion()
        return panel
    }
    public func removePanel(pageID: String, panelID: String) throws {
        guard let pIdx = model.pages.firstIndex(where: { $0.id == pageID }) else {
            throw ToolError(code: "not_found", message: "page_id \(pageID)")
        }
        guard let idx = model.pages[pIdx].panels.firstIndex(where: { $0.id == panelID }) else {
            throw ToolError(code: "not_found", message: "panel_id \(panelID)")
        }
        model.pages[pIdx].panels.remove(at: idx)
        bumpVersion()
    }
    public func movePanel(pageID: String, panelID: String, toIndex: Int) throws {
        guard let pIdx = model.pages.firstIndex(where: { $0.id == pageID }) else { throw ToolError(code: "not_found", message: "page_id \(pageID)") }
        var panels = model.pages[pIdx].panels
        guard let from = panels.firstIndex(where: { $0.id == panelID }) else { throw ToolError(code: "not_found", message: "panel_id \(panelID)") }
        let panel = panels.remove(at: from)
        let idx = max(0, min(toIndex, panels.count))
        panels.insert(panel, at: idx)
        model.pages[pIdx].panels = panels
        bumpVersion()
    }

    // MARK: - Panel ops
    public func updatePanelDescription(pageID: String, panelID: String, description: String) throws {
        guard let pIdx = model.pages.firstIndex(where: { $0.id == pageID }) else { throw ToolError(code: "not_found", message: "page_id \(pageID)") }
        guard let idx = model.pages[pIdx].panels.firstIndex(where: { $0.id == panelID }) else { throw ToolError(code: "not_found", message: "panel_id \(panelID)") }
        model.pages[pIdx].panels[idx].description = description
        bumpVersion()
    }
    public func setPanelRole(pageID: String, panelID: String, role: String) throws {
        guard let pIdx = model.pages.firstIndex(where: { $0.id == pageID }) else { throw ToolError(code: "not_found", message: "page_id \(pageID)") }
        guard let idx = model.pages[pIdx].panels.firstIndex(where: { $0.id == panelID }) else { throw ToolError(code: "not_found", message: "panel_id \(panelID)") }
        model.pages[pIdx].panels[idx].role = role
        bumpVersion()
    }
    public func addBalloon(pageID: String, panelID: String, kind: String, speaker: String?, text: String, order: Int?) throws -> Balloon {
        guard let pIdx = model.pages.firstIndex(where: { $0.id == pageID }) else { throw ToolError(code: "not_found", message: "page_id \(pageID)") }
        guard let idx = model.pages[pIdx].panels.firstIndex(where: { $0.id == panelID }) else { throw ToolError(code: "not_found", message: "panel_id \(panelID)") }
        let b = Balloon(kind: kind, speaker: speaker, text: text, order: order ?? (model.pages[pIdx].panels[idx].balloons.count + 1))
        model.pages[pIdx].panels[idx].balloons.append(b)
        bumpVersion()
        return b
    }
    public func updateBalloon(pageID: String, panelID: String, balloonID: String, text: String?, speaker: String?, order: Int?) throws {
        guard let pIdx = model.pages.firstIndex(where: { $0.id == pageID }) else { throw ToolError(code: "not_found", message: "page_id \(pageID)") }
        guard let idx = model.pages[pIdx].panels.firstIndex(where: { $0.id == panelID }) else { throw ToolError(code: "not_found", message: "panel_id \(panelID)") }
        guard let bIdx = model.pages[pIdx].panels[idx].balloons.firstIndex(where: { $0.id == balloonID }) else { throw ToolError(code: "not_found", message: "balloon_id \(balloonID)") }
        if let t = text { model.pages[pIdx].panels[idx].balloons[bIdx].text = t }
        if let s = speaker { model.pages[pIdx].panels[idx].balloons[bIdx].speaker = s }
        if let o = order { model.pages[pIdx].panels[idx].balloons[bIdx].order = o }
        bumpVersion()
    }
    public func removeBalloon(pageID: String, panelID: String, balloonID: String) throws {
        guard let pIdx = model.pages.firstIndex(where: { $0.id == pageID }) else { throw ToolError(code: "not_found", message: "page_id \(pageID)") }
        guard let idx = model.pages[pIdx].panels.firstIndex(where: { $0.id == panelID }) else { throw ToolError(code: "not_found", message: "panel_id \(panelID)") }
        var arr = model.pages[pIdx].panels[idx].balloons
        guard let bIdx = arr.firstIndex(where: { $0.id == balloonID }) else { throw ToolError(code: "not_found", message: "balloon_id \(balloonID)") }
        arr.remove(at: bIdx)
        model.pages[pIdx].panels[idx].balloons = arr
        bumpVersion()
    }
    public func reorderBalloons(pageID: String, panelID: String, order: [String]) throws {
        guard let pIdx = model.pages.firstIndex(where: { $0.id == pageID }) else { throw ToolError(code: "not_found", message: "page_id \(pageID)") }
        guard let idx = model.pages[pIdx].panels.firstIndex(where: { $0.id == panelID }) else { throw ToolError(code: "not_found", message: "panel_id \(panelID)") }
        var dict = [String: Balloon]()
        for b in model.pages[pIdx].panels[idx].balloons { dict[b.id] = b }
        model.pages[pIdx].panels[idx].balloons = order.compactMap { dict[$0] }
        for (i, _) in model.pages[pIdx].panels[idx].balloons.enumerated() {
            model.pages[pIdx].panels[idx].balloons[i].order = i + 1
        }
        bumpVersion()
    }
    public func splitPanel(pageID: String, panelID: String, axis: String, ratio: Double?) throws {
        // Purely structural placeholder; UI will handle layout specifics.
        // No-op for now; bump version to signal change.
        bumpVersion()
    }
    public func setPanelReferences(pageID: String, panelID: String, characterIDs: [String], locationID: String?, propIDs: [String]) throws {
        guard let pIdx = model.pages.firstIndex(where: { $0.id == pageID }) else { throw ToolError(code: "not_found", message: "page_id \(pageID)") }
        guard let idx = model.pages[pIdx].panels.firstIndex(where: { $0.id == panelID }) else { throw ToolError(code: "not_found", message: "panel_id \(panelID)") }
        model.pages[pIdx].panels[idx].characterIDs = characterIDs
        model.pages[pIdx].panels[idx].locationID = locationID
        model.pages[pIdx].panels[idx].propIDs = propIDs
        bumpVersion()
    }

    // MARK: - References
    @discardableResult
    public func createReference(kind: String, name: String, aliases: [String], traits: [String], voiceNotes: String?, visualCues: [String]) -> ReferenceEntry {
        let ref = ReferenceEntry(kind: kind, name: name, aliases: aliases, traits: traits, voiceNotes: voiceNotes, visualCues: visualCues)
        references.append(ref)
        bumpVersion()
        return ref
    }
    public func updateReference(id: String, patch: [String: String]) throws {
        guard let i = references.firstIndex(where: { $0.id == id }) else { throw ToolError(code: "not_found", message: "reference_id \(id)") }
        if let name = patch["name"] { references[i].name = name }
        if let voice = patch["voice_notes"] { references[i].voiceNotes = voice }
        if let aliasesCSV = patch["aliases_csv"] {
            references[i].aliases = aliasesCSV.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        }
        if let traitsCSV = patch["traits_csv"] {
            references[i].traits = traitsCSV.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        }
        if let visualsCSV = patch["visual_cues_csv"] {
            references[i].visualCues = visualsCSV.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        }
        if let intro = patch["introduced_page"]?.trimmingCharacters(in: .whitespacesAndNewlines), !intro.isEmpty {
            if let n = Int(intro) {
                let idx = max(0, n - 1) // user enters 1-based
                references[i].introducedPageIndex = idx
            }
        }
        bumpVersion()
    }

    // MARK: - Reference storage (simple flat lists for scaffold)
    public var references: [ReferenceEntry] = []
}