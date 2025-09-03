import Foundation

// MARK: - Public Mutation Definitions

public enum Mutation: Equatable, Hashable {
    // Page Mutations
    case createPage(atIndex: Int, panelCount: Int, title: String)
    case updatePageTitle(pageID: String, newTitle: String)
    case movePage(pageID: String, fromIndex: Int, toIndex: Int)
    case deletePage(pageID: String)

    // Panel Mutations
    case createPanel(onPageID: String, atIndex: Int, description: String)
    case updatePanelDescription(pageID: String, panelID: String, newDescription: String)
    case movePanel(panelID: String, toPageID: String, toIndex: Int)
    case deletePanel(fromPageID: String, panelID: String)

    // Balloon Mutations
    case createBalloon(onPageID: String, onPanelID: String, kind: String, speaker: String?, text: String)
    case updateBalloonText(balloonID: String, newText: String)
    case deleteBalloon(onPageID: String, fromPanelID: String, balloonID: String)
}

public struct MutationPlan: Equatable {
    public let mutations: [Mutation]
}

// MARK: - Internal Script Representation

fileprivate struct ScriptBalloon {
    let kind: String
    let speaker: String?
    let text: String
}

fileprivate struct ScriptPanel {
    var description: String
    var balloons: [ScriptBalloon]
}

fileprivate struct ScriptPage {
    var title: String
    var panels: [ScriptPanel]
}

// MARK: - Script Parser

public enum ScriptParser {
    public static func parse(script: String, currentIssue: Issue) -> MutationPlan {
        let scriptPages = parseScriptToIntermediateRepresentation(script: script)
        let mutations = diffPages(scriptPages: scriptPages, modelPages: currentIssue.pages)
        return MutationPlan(mutations: mutations)
    }
    
    // MARK: - Diffing Logic
    
    private static func diffPages(scriptPages: [ScriptPage], modelPages: [Page]) -> [Mutation] {
        var mutations: [Mutation] = []
        // This is a simplified diffing logic. A real implementation would use a more advanced algorithm.
        // For now, we assume pages are matched by index.
        
        let scriptCount = scriptPages.count
        let modelCount = modelPages.count
        let commonCount = min(scriptCount, modelCount)
        
        for i in 0..<commonCount {
            let scriptPage = scriptPages[i]
            let modelPage = modelPages[i]
            
            // Diff page title
            if scriptPage.title != modelPage.title {
                mutations.append(.updatePageTitle(pageID: modelPage.id, newTitle: scriptPage.title))
            }
            
            // Recursively diff panels
            mutations.append(contentsOf: diffPanels(scriptPanels: scriptPage.panels, modelPage: modelPage))
        }
        
        // Handle page additions
        if scriptCount > modelCount {
            for i in modelCount..<scriptCount {
                let newPage = scriptPages[i]
                mutations.append(.createPage(atIndex: i, panelCount: newPage.panels.count, title: newPage.title))
            }
        }
        // Handle page deletions
        else if modelCount > scriptCount {
            for i in scriptCount..<modelCount {
                mutations.append(.deletePage(pageID: modelPages[i].id))
            }
        }
        
        return mutations
    }
    
    private static func diffPanels(scriptPanels: [ScriptPanel], modelPage: Page) -> [Mutation] {
        var mutations: [Mutation] = []
        let modelPanels = modelPage.panels
        let commonCount = min(scriptPanels.count, modelPanels.count)
        
        for i in 0..<commonCount {
            let scriptPanel = scriptPanels[i]
            let modelPanel = modelPanels[i]
            
            if scriptPanel.description != modelPanel.description {
                mutations.append(.updatePanelDescription(pageID: modelPage.id, panelID: modelPanel.id, newDescription: scriptPanel.description))
            }
            
            mutations.append(contentsOf: diffBalloons(scriptBalloons: scriptPanel.balloons, modelPage: modelPage, modelPanel: modelPanel))
        }
        
        if scriptPanels.count > modelPanels.count {
            for i in modelPanels.count..<scriptPanels.count {
                mutations.append(.createPanel(onPageID: modelPage.id, atIndex: i, description: scriptPanels[i].description))
            }
        } else if modelPanels.count > scriptPanels.count {
            for i in scriptPanels.count..<modelPanels.count {
                mutations.append(.deletePanel(fromPageID: modelPage.id, panelID: modelPanels[i].id))
            }
        }
        
        return mutations
    }
    
    private static func diffBalloons(scriptBalloons: [ScriptBalloon], modelPage: Page, modelPanel: Panel) -> [Mutation] {
        var mutations: [Mutation] = []
        // Using a simple delete-and-recreate strategy for balloons
        for balloon in modelPanel.balloons {
            mutations.append(.deleteBalloon(onPageID: modelPage.id, fromPanelID: modelPanel.id, balloonID: balloon.id))
        }
        for balloon in scriptBalloons {
            mutations.append(.createBalloon(onPageID: modelPage.id, onPanelID: modelPanel.id, kind: balloon.kind, speaker: balloon.speaker, text: balloon.text))
        }
        return mutations
    }
    
    // MARK: - Intermediate Representation Parser
    
    private static func parseScriptToIntermediateRepresentation(script: String) -> [ScriptPage] {
        var pages: [ScriptPage] = []
        let lines = script.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        
        let pageRegex = try! NSRegularExpression(pattern: #"^\s*Page\s+\d+\s*\(([^)]+)\)"#, options: [.caseInsensitive])
        let panelRegex = try! NSRegularExpression(pattern: #"^\s*Panel\s+\d+\s*:\s*(.*)$"#, options: [.caseInsensitive])
        let dialogueRegex = try! NSRegularExpression(pattern: #"^\s*Dialogue\s+\(([^)]+)\)\s*:\s*(.*)$"#, options: [.caseInsensitive])
        let thoughtRegex = try! NSRegularExpression(pattern: #"^\s*Thought\s+\(([^)]+)\)\s*:\s*(.*)$"#, options: [.caseInsensitive])
        let captionRegex = try! NSRegularExpression(pattern: #"^\s*Caption\s*:\s*(.*)$"#, options: [.caseInsensitive])
        let sfxRegex = try! NSRegularExpression(pattern: #"^\s*SFX\s*:\s*(.*)$"#, options: [.caseInsensitive])

        var currentPage: ScriptPage? = nil
        var currentPanel: ScriptPanel? = nil

        for line in lines {
            if let match = pageRegex.firstMatch(in: line, options: [], range: NSRange(location: 0, length: line.utf16.count)) {
                if let panel = currentPanel { currentPage?.panels.append(panel) }
                if let page = currentPage { pages.append(page) }
                currentPanel = nil
                let title = Range(match.range(at: 1), in: line).map { String(line[$0]) } ?? ""
                currentPage = ScriptPage(title: title, panels: [])
            } else if let match = panelRegex.firstMatch(in: line, options: [], range: NSRange(location: 0, length: line.utf16.count)) {
                if let panel = currentPanel { currentPage?.panels.append(panel) }
                let desc = Range(match.range(at: 1), in: line).map { String(line[$0]) } ?? ""
                currentPanel = ScriptPanel(description: desc, balloons: [])
            } else if let match = dialogueRegex.firstMatch(in: line, options: [], range: NSRange(location: 0, length: line.utf16.count)) {
                let speaker = String(line[Range(match.range(at: 1), in: line)!])
                let text = String(line[Range(match.range(at: 2), in: line)!])
                currentPanel?.balloons.append(.init(kind: "speech", speaker: speaker, text: text))
            } else if let match = thoughtRegex.firstMatch(in: line, options: [], range: NSRange(location: 0, length: line.utf16.count)) {
                let speaker = String(line[Range(match.range(at: 1), in: line)!])
                let text = String(line[Range(match.range(at: 2), in: line)!])
                currentPanel?.balloons.append(.init(kind: "thought", speaker: speaker, text: text))
            } else if let match = captionRegex.firstMatch(in: line, options: [], range: NSRange(location: 0, length: line.utf16.count)) {
                let text = String(line[Range(match.range(at: 1), in: line)!])
                currentPanel?.balloons.append(.init(kind: "caption", speaker: nil, text: text))
            } else if let match = sfxRegex.firstMatch(in: line, options: [], range: NSRange(location: 0, length: line.utf16.count)) {
                let text = String(line[Range(match.range(at: 1), in: line)!])
                currentPanel?.balloons.append(.init(kind: "sfx", speaker: nil, text: text))
            }
        }
        
        if let panel = currentPanel { currentPage?.panels.append(panel) }
        if let page = currentPage { pages.append(page) }
        
        return pages
    }
}