import Foundation
import ComicSmithCore

/// Applies a mutation plan to the model.
enum ScriptApplier {
    static func applyEdits(_ script: String, controller: ModelController) {
        let plan = ScriptParser.parse(script: script, currentIssue: controller.model)
        
        for mutation in plan.mutations {
            switch mutation {
            // Page Mutations
            case .createPage(let atIndex, let panelCount, let title):
                _ = controller.addPage(index: atIndex, panelCount: panelCount, layoutPreset: nil, title: title, beatPrompt: nil)
            case .deletePage(let pageID):
                try? controller.removePage(id: pageID)
            case .movePage(let pageID, _, let toIndex):
                try? controller.movePage(id: pageID, toIndex: toIndex)
            case .updatePageTitle(let pageID, let newTitle):
                try? controller.updatePageTitle(id: pageID, newTitle: newTitle)
            
            // Panel Mutations
            case .createPanel(let onPageID, let atIndex, let description):
                _ = try? controller.addPanel(pageID: onPageID, index: atIndex, description: description)
            case .deletePanel(let fromPageID, let panelID):
                try? controller.removePanel(pageID: fromPageID, panelID: panelID)
            case .updatePanelDescription(let pageID, let panelID, let newDescription):
                try? controller.updatePanelDescription(pageID: pageID, panelID: panelID, description: newDescription)
            
            // Balloon Mutations
            case .createBalloon(let pageID, let panelID, let kind, let speaker, let text):
                _ = try? controller.addBalloon(pageID: pageID, panelID: panelID, kind: kind, speaker: speaker, text: text, order: nil)
            case .deleteBalloon(let pageID, let panelID, let balloonID):
                try? controller.removeBalloon(pageID: pageID, panelID: panelID, balloonID: balloonID)
            
            default:
                print("Skipping unhandled mutation: \(mutation)")
            }
        }
    }
}
