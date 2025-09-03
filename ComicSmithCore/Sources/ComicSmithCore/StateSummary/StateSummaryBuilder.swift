import Foundation

public enum StateSummaryBuilder {
    public static func build(model: Issue, mode: Mode, focus: Focus) -> String {
        // Keep it small and deterministic. YAML-like text.
        var lines: [String] = []
        lines.append("# STATE_SUMMARY_DO_NOT_ECHO")
        lines.append("project_id: \"series/demo/issue-01\"")
        lines.append("timestamp_iso: \"\(ISO8601DateFormatter().string(from: Date()))\"")
        lines.append("mode: \"\(mode.rawValue)\"")
        lines.append("focus:")
        lines.append("  page_id: \"\(focus.pageID ?? "null")\"")
        lines.append("  panel_id: \"\(focus.panelID ?? "null")\"")
        lines.append("  reference_id: \"\(focus.referenceID ?? "null")\"")
        lines.append("issue_version: \"\(ISO8601DateFormatter().string(from: Date()))\"")
        lines.append("outline:")
        lines.append("  pages:")
        for (idx, p) in model.pages.enumerated() {
            lines.append("    - id: \"\(p.id)\"")
            lines.append("      index: \(idx)")
            lines.append("      title: \"\(p.title)\"")
            lines.append("      panel_count: \(p.panels.count)")
            if let first = p.panels.first {
                let summary = first.description.prefix(60).replacingOccurrences(of: "\n", with: " ")
                lines.append("      summary: \"\(summary)\"")
            } else {
                lines.append("      summary: \"\"")
            }
        }
        if let pid = focus.pageID, let page = model.pages.first(where: { $0.id == pid }) {
            lines.append("focused_page:")
            lines.append("  id: \"\(page.id)\"")
            lines.append("  layout_preset: \"\(page.layoutPreset)\"")
            lines.append("  panels:")
            for (i, pn) in page.panels.enumerated() {
                lines.append("    - id: \"\(pn.id)\"")
                lines.append("      index: \(i)")
                let desc = pn.description.prefix(120).replacingOccurrences(of: "\n", with: " ")
                lines.append("      desc: \"\(desc)\"")
                if !pn.balloons.isEmpty {
                    lines.append("      balloons:")
                    for b in pn.balloons.sorted(by: { $0.order < $1.order }) {
                        lines.append("        - id: \"\(b.id)\" kind: \"\(b.kind)\" text: \"\(b.text.prefix(60))\"")
                    }
                }
            }
        }
        return lines.joined(separator: "\n")
    }
}
