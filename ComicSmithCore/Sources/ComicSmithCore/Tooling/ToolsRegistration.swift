import Foundation

// MARK: - Helpers

fileprivate func decode<T: Decodable>(_ type: T.Type, from json: String) throws -> T {
    let data = Data(json.utf8)
    return try JSONDecoder().decode(T.self, from: data)
}

// MARK: - Tool Stubs

public func registerAllTools(into registry: ToolRegistry) {
    registry.register(FocusIssueTool())
    registry.register(FocusPageTool())
    registry.register(FocusPanelTool())
    registry.register(FocusReferenceTool())
    registry.register(AddPageTool())
    registry.register(RemovePageTool())
    registry.register(MovePageTool())
    registry.register(SetPageLayoutTool())
    registry.register(RegenerateIssueThumbnailsTool())
    registry.register(AddPanelTool())
    registry.register(RemovePanelTool())
    registry.register(MovePanelTool())
    registry.register(RegeneratePageThumbnailsTool())
    registry.register(UpdatePanelDescriptionTool())
    registry.register(SetPanelRoleTool())
    registry.register(AddBalloonTool())
    registry.register(UpdateBalloonTool())
    registry.register(RemoveBalloonTool())
    registry.register(ReorderBalloonsTool())
    registry.register(SplitPanelTool())
    registry.register(SetPanelReferencesTool())
    registry.register(GeneratePanelVisualTool())
    registry.register(CreateReferenceTool())
    registry.register(UpdateReferenceTool())
    registry.register(GenerateReferenceImageTool())
    registry.register(RunConsistencySweepTool())
    registry.register(ExportScriptTool())
    registry.register(ExportBibleTool())
}

// Non-mutating focus tools
struct FocusIssueTool: Tool {
    let name = "focus_issue"
    let description = "Set the application focus to the overall issue view."
    func invoke(argumentsJSON: String, controller: ModelController) async throws -> ToolResult {
        controller.mode = .issue
        return ToolResult(ok: true, issueVersion: controller.issueVersion, events: [ToolEvent(type: "focus_issue", payload: [:])])
    }
}
struct FocusPageTool: Tool {
    struct Args: Decodable { let page_id: String }
    let name = "focus_page"
    let description = "Set the application focus to a specific page."
    func invoke(argumentsJSON: String, controller: ModelController) async throws -> ToolResult {
        let args = try decode(Args.self, from: argumentsJSON)
        controller.mode = .page
        controller.focus.pageID = args.page_id
        controller.focus.panelID = nil
        return ToolResult(ok: true, issueVersion: controller.issueVersion, events: [ToolEvent(type: "focus_page", payload: ["page_id": args.page_id])])
    }
}
struct FocusPanelTool: Tool {
    struct Args: Decodable { let page_id: String; let panel_id: String }
    let name = "focus_panel"
    let description = "Set the application focus to a specific panel on a specific page."
    func invoke(argumentsJSON: String, controller: ModelController) async throws -> ToolResult {
        let args = try decode(Args.self, from: argumentsJSON)
        controller.mode = .panel
        controller.focus.pageID = args.page_id
        controller.focus.panelID = args.panel_id
        return ToolResult(ok: true, issueVersion: controller.issueVersion, events: [ToolEvent(type: "focus_panel", payload: ["page_id": args.page_id, "panel_id": args.panel_id])])
    }
}
struct FocusReferenceTool: Tool {
    struct Args: Decodable { let reference_id: String }
    let name = "focus_reference"
    let description = "Set the application focus to a specific reference entry."
    func invoke(argumentsJSON: String, controller: ModelController) async throws -> ToolResult {
        let args = try decode(Args.self, from: argumentsJSON)
        controller.mode = .referenceDetail
        controller.focus.referenceID = args.reference_id
        return ToolResult(ok: true, issueVersion: controller.issueVersion, events: [ToolEvent(type: "focus_reference", payload: ["reference_id": args.reference_id])])
    }
}

// Issue
struct AddPageTool: Tool {
    struct Args: Decodable { let index: Int?; let panel_count: Int?; let layout_preset: String?; let title: String?; let beat_prompt: String? }
    let name = "add_page"
    let description = "Adds a new page to the issue at a specified index."
    func invoke(argumentsJSON: String, controller: ModelController) async throws -> ToolResult {
        let args = try decode(Args.self, from: argumentsJSON)
        let page = controller.addPage(index: args.index, panelCount: args.panel_count, layoutPreset: args.layout_preset, title: args.title, beatPrompt: args.beat_prompt)
        return ToolResult(ok: true, issueVersion: controller.issueVersion, events: [ToolEvent(type: "page_added", payload: ["page_id": page.id])])
    }
}
struct RemovePageTool: Tool {
    struct Args: Decodable { let page_id: String }
    let name = "remove_page"
    let description = "Removes a page from the issue."
    func invoke(argumentsJSON: String, controller: ModelController) async throws -> ToolResult {
        let args = try decode(Args.self, from: argumentsJSON)
        try controller.removePage(id: args.page_id)
        return ToolResult(ok: true, issueVersion: controller.issueVersion, events: [ToolEvent(type: "page_removed", payload: ["page_id": args.page_id])])
    }
}
struct MovePageTool: Tool {
    struct Args: Decodable { let page_id: String; let to_index: Int }
    let name = "move_page"
    let description = "Moves a page to a new index in the issue."
    func invoke(argumentsJSON: String, controller: ModelController) async throws -> ToolResult {
        let args = try decode(Args.self, from: argumentsJSON)
        try controller.movePage(id: args.page_id, toIndex: args.to_index)
        return ToolResult(ok: true, issueVersion: controller.issueVersion, events: [ToolEvent(type: "page_moved", payload: ["page_id": args.page_id, "to_index": String(args.to_index)])])
    }
}
struct SetPageLayoutTool: Tool {
    struct Args: Decodable { let page_id: String; let layout_preset: String }
    let name = "set_page_layout"
    let description = "Sets the layout preset for a specific page (e.g., grid-6)."
    func invoke(argumentsJSON: String, controller: ModelController) async throws -> ToolResult {
        let args = try decode(Args.self, from: argumentsJSON)
        try controller.setPageLayout(id: args.page_id, layoutPreset: args.layout_preset)
        return ToolResult(ok: true, issueVersion: controller.issueVersion, events: [ToolEvent(type: "page_layout_set", payload: ["page_id": args.page_id, "layout": args.layout_preset])])
    }
}
struct RegenerateIssueThumbnailsTool: Tool {
    struct Args: Decodable { let page_ids: [String]; let force: Bool? }
    let name = "regenerate_issue_thumbnails"
    let description = "Triggers regeneration of thumbnails for all pages in the issue."
    func invoke(argumentsJSON: String, controller: ModelController) async throws -> ToolResult {
        _ = try decode(Args.self, from: argumentsJSON)
        // Queue generation externally; this tool only signals intent.
        return ToolResult(ok: true, issueVersion: controller.issueVersion, events: [ToolEvent(type: "regen_issue_thumbs", payload: [:])])
    }
}

// Page (panels)
struct AddPanelTool: Tool {
    struct Args: Decodable { let page_id: String; let index: Int?; let description: String?; let character_ids: [String]?; let location_id: String?; let prop_ids: [String]? }
    let name = "add_panel"
    let description = "Adds a new panel to a specific page."
    func invoke(argumentsJSON: String, controller: ModelController) async throws -> ToolResult {
        let args = try decode(Args.self, from: argumentsJSON)
        let panel = try controller.addPanel(pageID: args.page_id, index: args.index, description: args.description)
        return ToolResult(ok: true, issueVersion: controller.issueVersion, events: [ToolEvent(type: "panel_added", payload: ["page_id": args.page_id, "panel_id": panel.id])])
    }
}
struct RemovePanelTool: Tool {
    struct Args: Decodable { let page_id: String; let panel_id: String }
    let name = "remove_panel"
    let description = "Removes a panel from a page."
    func invoke(argumentsJSON: String, controller: ModelController) async throws -> ToolResult {
        let args = try decode(Args.self, from: argumentsJSON)
        try controller.removePanel(pageID: args.page_id, panelID: args.panel_id)
        return ToolResult(ok: true, issueVersion: controller.issueVersion, events: [ToolEvent(type: "panel_removed", payload: ["page_id": args.page_id, "panel_id": args.panel_id])])
    }
}
struct MovePanelTool: Tool {
    struct Args: Decodable { let page_id: String; let panel_id: String; let to_index: Int }
    let name = "move_panel"
    let description = "Moves a panel to a new index on a page."
    func invoke(argumentsJSON: String, controller: ModelController) async throws -> ToolResult {
        let args = try decode(Args.self, from: argumentsJSON)
        try controller.movePanel(pageID: args.page_id, panelID: args.panel_id, toIndex: args.to_index)
        return ToolResult(ok: true, issueVersion: controller.issueVersion, events: [ToolEvent(type: "panel_moved", payload: ["page_id": args.page_id, "panel_id": args.panel_id, "to_index": String(args.to_index)])])
    }
}
struct RegeneratePageThumbnailsTool: Tool {
    struct Args: Decodable { let page_id: String; let force: Bool? }
    let name = "regenerate_page_thumbnails"
    let description = "Triggers regeneration of thumbnails for all panels on a page."
    func invoke(argumentsJSON: String, controller: ModelController) async throws -> ToolResult {
        _ = try decode(Args.self, from: argumentsJSON)
        return ToolResult(ok: true, issueVersion: controller.issueVersion, events: [ToolEvent(type: "regen_page_thumbs", payload: [:])])
    }
}

// Panel (text & details)
struct UpdatePanelDescriptionTool: Tool {
    struct Args: Decodable { let page_id: String; let panel_id: String; let description: String }
    let name = "update_panel_description"
    let description = "Updates the descriptive text of a single panel."
    func invoke(argumentsJSON: String, controller: ModelController) async throws -> ToolResult {
        let args = try decode(Args.self, from: argumentsJSON)
        try controller.updatePanelDescription(pageID: args.page_id, panelID: args.panel_id, description: args.description)
        return ToolResult(ok: true, issueVersion: controller.issueVersion, events: [ToolEvent(type: "panel_desc_updated", payload: ["page_id": args.page_id, "panel_id": args.panel_id])])
    }
}
struct SetPanelRoleTool: Tool {
    struct Args: Decodable { let page_id: String; let panel_id: String; let role: String }
    let name = "set_panel_role"
    let description = "Sets the role of a panel (e.g., normal, splash, inset)."
    func invoke(argumentsJSON: String, controller: ModelController) async throws -> ToolResult {
        let args = try decode(Args.self, from: argumentsJSON)
        try controller.setPanelRole(pageID: args.page_id, panelID: args.panel_id, role: args.role)
        return ToolResult(ok: true, issueVersion: controller.issueVersion, events: [ToolEvent(type: "panel_role_set", payload: ["panel_id": args.panel_id, "role": args.role])])
    }
}
struct AddBalloonTool: Tool {
    struct Args: Decodable { let page_id: String; let panel_id: String; let kind: String; let speaker: String?; let text: String; let order: Int? }
    let name = "add_balloon"
    let description = "Adds a new balloon (speech, thought, etc.) to a panel."
    func invoke(argumentsJSON: String, controller: ModelController) async throws -> ToolResult {
        let args = try decode(Args.self, from: argumentsJSON)
        let balloon = try controller.addBalloon(pageID: args.page_id, panelID: args.panel_id, kind: args.kind, speaker: args.speaker, text: args.text, order: args.order)
        return ToolResult(ok: true, issueVersion: controller.issueVersion, events: [ToolEvent(type: "balloon_added", payload: ["panel_id": args.panel_id, "balloon_id": balloon.id])])
    }
}
struct UpdateBalloonTool: Tool {
    struct Args: Decodable { let page_id: String; let panel_id: String; let balloon_id: String; let text: String?; let speaker: String?; let order: Int? }
    let name = "update_balloon"
    let description = "Updates the text, speaker, or order of an existing balloon."
    func invoke(argumentsJSON: String, controller: ModelController) async throws -> ToolResult {
        let args = try decode(Args.self, from: argumentsJSON)
        try controller.updateBalloon(pageID: args.page_id, panelID: args.panel_id, balloonID: args.balloon_id, text: args.text, speaker: args.speaker, order: args.order)
        return ToolResult(ok: true, issueVersion: controller.issueVersion, events: [ToolEvent(type: "balloon_updated", payload: ["balloon_id": args.balloon_id])])
    }
}
struct RemoveBalloonTool: Tool {
    struct Args: Decodable { let page_id: String; let panel_id: String; let balloon_id: String }
    let name = "remove_balloon"
    let description = "Removes a balloon from a panel."
    func invoke(argumentsJSON: String, controller: ModelController) async throws -> ToolResult {
        let args = try decode(Args.self, from: argumentsJSON)
        try controller.removeBalloon(pageID: args.page_id, panelID: args.panel_id, balloonID: args.balloon_id)
        return ToolResult(ok: true, issueVersion: controller.issueVersion, events: [ToolEvent(type: "balloon_removed", payload: ["balloon_id": args.balloon_id])])
    }
}
struct ReorderBalloonsTool: Tool {
    struct Args: Decodable { let page_id: String; let panel_id: String; let balloon_ids: [String] }
    let name = "reorder_balloons"
    let description = "Changes the reading order of balloons within a panel."
    func invoke(argumentsJSON: String, controller: ModelController) async throws -> ToolResult {
        let args = try decode(Args.self, from: argumentsJSON)
        try controller.reorderBalloons(pageID: args.page_id, panelID: args.panel_id, order: args.balloon_ids)
        return ToolResult(ok: true, issueVersion: controller.issueVersion, events: [ToolEvent(type: "balloons_reordered", payload: ["panel_id": args.panel_id])])
    }
}
struct SplitPanelTool: Tool {
    struct Args: Decodable { let page_id: String; let panel_id: String; let axis: String; let ratio: Double? }
    let name = "split_panel"
    let description = "Splits a panel into two, horizontally or vertically."
    func invoke(argumentsJSON: String, controller: ModelController) async throws -> ToolResult {
        let args = try decode(Args.self, from: argumentsJSON)
        try controller.splitPanel(pageID: args.page_id, panelID: args.panel_id, axis: args.axis, ratio: args.ratio)
        return ToolResult(ok: true, issueVersion: controller.issueVersion, events: [ToolEvent(type: "panel_split", payload: ["panel_id": args.panel_id, "axis": args.axis])])
    }
}
struct SetPanelReferencesTool: Tool {
    struct Args: Decodable { let page_id: String; let panel_id: String; let character_ids: [String]?; let location_id: String?; let prop_ids: [String]? }
    let name = "set_panel_references"
    let description = "Links a panel to character, location, or prop reference entries."
    func invoke(argumentsJSON: String, controller: ModelController) async throws -> ToolResult {
        let args = try decode(Args.self, from: argumentsJSON)
        try controller.setPanelReferences(pageID: args.page_id, panelID: args.panel_id, characterIDs: args.character_ids ?? [], locationID: args.location_id, propIDs: args.prop_ids ?? [])
        return ToolResult(ok: true, issueVersion: controller.issueVersion, events: [ToolEvent(type: "panel_refs_set", payload: ["panel_id": args.panel_id])])
    }
}
struct GeneratePanelVisualTool: Tool {
    struct Args: Decodable { let page_id: String; let panel_id: String; let force: Bool? }
    let name = "generate_panel_visual"
    let description = "Triggers generation of a new visual rough for a panel."
    func invoke(argumentsJSON: String, controller: ModelController) async throws -> ToolResult {
        _ = try decode(Args.self, from: argumentsJSON)
        return ToolResult(ok: true, issueVersion: controller.issueVersion, events: [ToolEvent(type: "gen_panel_visual", payload: [:])])
    }
}

// References
struct CreateReferenceTool: Tool {
    struct Args: Decodable { let kind: String; let name: String; let aliases: [String]?; let traits: [String]?; let voice_notes: String?; let visual_cues: [String]? }
    let name = "create_reference"
    let description = "Creates a new reference entry (character, location, or prop)."
    func invoke(argumentsJSON: String, controller: ModelController) async throws -> ToolResult {
        let args = try decode(Args.self, from: argumentsJSON)
        let ref = controller.createReference(kind: args.kind, name: args.name, aliases: args.aliases ?? [], traits: args.traits ?? [], voiceNotes: args.voice_notes, visualCues: args.visual_cues ?? [])
        return ToolResult(ok: true, issueVersion: controller.issueVersion, events: [ToolEvent(type: "reference_created", payload: ["reference_id": ref.id])])
    }
}
struct UpdateReferenceTool: Tool {
    struct Args: Decodable { let reference_id: String; let patch: [String: String]? }
    let name = "update_reference"
    let description = "Updates the fields of an existing reference entry."
    func invoke(argumentsJSON: String, controller: ModelController) async throws -> ToolResult {
        let args = try decode(Args.self, from: argumentsJSON)
        try controller.updateReference(id: args.reference_id, patch: args.patch ?? [:])
        return ToolResult(ok: true, issueVersion: controller.issueVersion, events: [ToolEvent(type: "reference_updated", payload: ["reference_id": args.reference_id])])
    }
}
struct GenerateReferenceImageTool: Tool {
    struct Args: Decodable { let reference_id: String; let variant: String; let force: Bool? }
    let name = "generate_reference_image"
    let description = "Triggers generation of a new portrait or thumbnail for a reference entry."
    func invoke(argumentsJSON: String, controller: ModelController) async throws -> ToolResult {
        _ = try decode(Args.self, from: argumentsJSON)
        return ToolResult(ok: true, issueVersion: controller.issueVersion, events: [ToolEvent(type: "gen_reference_image", payload: [:])])
    }
}
struct RunConsistencySweepTool: Tool {
    struct Args: Decodable { let scope: String; let page_id: String?; let panel_id: String?; let reference_id: String? }
    let name = "run_consistency_sweep"
    let description = "Scans the script for continuity errors or inconsistencies."
    func invoke(argumentsJSON: String, controller: ModelController) async throws -> ToolResult {
        _ = try decode(Args.self, from: argumentsJSON)
        return ToolResult(ok: true, issueVersion: controller.issueVersion, events: [ToolEvent(type: "consistency_sweep", payload: [:])])
    }
}

// Exports
struct ExportScriptTool: Tool {
    struct Args: Decodable { let format: String; let include_contact_sheet: Bool? }
    let name = "export_script"
    let description = "Exports the comic script to a specified format (e.g., Markdown, PDF)."
    func invoke(argumentsJSON: String, controller: ModelController) async throws -> ToolResult {
        _ = try decode(Args.self, from: argumentsJSON)
        return ToolResult(ok: true, issueVersion: controller.issueVersion, events: [ToolEvent(type: "export_script", payload: [:])])
    }
}
struct ExportBibleTool: Tool {
    struct Args: Decodable { let format: String }
    let name = "export_bible"
    let description = "Exports the character/location/prop bible to a specified format."
    func invoke(argumentsJSON: String, controller: ModelController) async throws -> ToolResult {
        _ = try decode(Args.self, from: argumentsJSON)
        return ToolResult(ok: true, issueVersion: controller.issueVersion, events: [ToolEvent(type: "export_bible", payload: [:])])
    }
}