import Foundation

public enum ScriptFormatter {
    public static func render(issue: Issue) -> String {
        var out: [String] = []
        for (pi, page) in issue.pages.enumerated() {
            out.append("Page \(pi + 1) (\(page.panels.count) Panels)")
            for (i, p) in page.panels.enumerated() {
                out.append("Panel \(i + 1): \(p.description)")
                for b in p.balloons.sorted(by: { $0.order < $1.order }) {
                    switch b.kind {
                    case "speech":
                        out.append("Dialogue (\(b.speaker ?? "")): \(b.text)")
                    case "thought":
                        out.append("Thought (\(b.speaker ?? "")): \(b.text)")
                    case "caption":
                        out.append("Caption: \(b.text)")
                    case "sfx":
                        out.append("SFX: \(b.text)")
                    default:
                        break
                    }
                }
            }
            out.append("")
        }
        return out.joined(separator: "\n")
    }
}
