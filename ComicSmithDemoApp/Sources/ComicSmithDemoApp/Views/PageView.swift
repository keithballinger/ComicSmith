import SwiftUI
import ComicSmithCore

struct PageView: View {
    @EnvironmentObject var c: AppContainer

    var currentPage: Page? {
        guard let pid = c.focus.pageID else { return nil }
        return c.issue.pages.first(where: { $0.id == pid })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Page Mode — Panels").font(.headline)
                Spacer()
                if let pid = c.focus.pageID {
                    Button("＋ Add Panel") { c.addPanel(to: pid) }
                    Button("Regenerate Thumbnails") { c.enqueuePageThumbnails(pageID: pid) }
                }
            }
            if let page = currentPage {
                List {
                    ForEach(Array(page.panels.enumerated()), id: \.1.id) { idx, panel in
                        HStack {
                            if c.isPageGenerating(page.id) {
                                Text("Generating…").font(.caption).foregroundColor(.secondary)
                            }
                            Button(action: { c.selectPanel(pageID: page.id, panelID: panel.id) }) {
                                VStack(alignment: .leading) {
                                    // Reference chips (characters, location, props)
                                    HStack(spacing: 6) {
                                        let chars = panel.characterIDs.map { c.refName(for: $0) }
                                        if let loc = panel.locationID { Tag(text: "📍 " + c.refName(for: loc)) }
                                        if !chars.isEmpty {
                                            ForEach(Array(chars.prefix(3)), id: \.self) { name in Tag(text: "👤 " + name) }
                                            if chars.count > 3 { Tag(text: "+\(chars.count - 3)") }
                                        }
                                        if !panel.propIDs.isEmpty {
                                            let props = panel.propIDs.map { c.refName(for: $0) }
                                            ForEach(Array(props.prefix(2)), id: \.self) { name in Tag(text: "🔧 " + name) }
                                            if props.count > 2 { Tag(text: "+\(props.count - 2)") }
                                        }
                                    }
                                    Text("Panel \(idx + 1)").bold()
                                    Text(panel.description.isEmpty ? "—" : panel.description)
                                        .lineLimit(2)
                                        .font(.caption)
                                }
                            }
                            Spacer()
                            Button("↑") {
                                try? c.controller.movePanel(pageID: page.id, panelID: panel.id, toIndex: max(0, idx - 1)); c.refresh()
                            }.disabled(idx == 0)
                            Button("↓") {
                                try? c.controller.movePanel(pageID: page.id, panelID: panel.id, toIndex: min(page.panels.count - 1, idx + 1)); c.refresh()
                            }.disabled(idx >= page.panels.count - 1)
                            Button(role: .destructive, action: { try? c.controller.removePanel(pageID: page.id, panelID: panel.id); c.refresh() }) { Text("Delete") }
                        }
                    }
                }
            } else {
                Text("Select a page in Issue Mode or via Chat to begin.")
                    .foregroundColor(.secondary)
            }
        }
        .padding(10)
    }
}


struct Tag: View {
    var text: String
    var body: some View {
        Text(text)
            .font(.caption)
            .padding(.horizontal, 6).padding(.vertical, 2)
            .background(Color.gray.opacity(0.15))
            .cornerRadius(6)
    }
}
