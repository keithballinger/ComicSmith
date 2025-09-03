import SwiftUI
import ComicSmithCore

struct IssueView: View {
    @EnvironmentObject var c: AppContainer

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Issue Mode — Pages").font(.headline)
                Spacer()
                Button("＋ New Page") { c.addPage() }
                Button("Regenerate Thumbnails") {
                    for p in c.issue.pages { c.enqueuePageThumbnails(pageID: p.id) }
                }
            }
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(c.issue.pages.enumerated()), id: \.1.id) { idx, page in
                        HStack {
                            if c.isPageGenerating(page.id) {
                                Text("Generating…").font(.caption).foregroundColor(.secondary)
                            }
                            Button(action: { c.selectPage(page.id) }) {
                                VStack(alignment: .leading) {
                                    Text("Page \(idx + 1) — \(page.title.isEmpty ? "Untitled" : page.title)")
                                        .font(.subheadline).bold()
                                    Text("\(page.panels.count) panels").font(.caption).foregroundColor(.secondary)
                                }
                            }
                            Spacer()
                            Button("↑") {
                                try? c.controller.movePage(id: page.id, toIndex: max(0, idx - 1)); c.refresh()
                            }.disabled(idx == 0)
                            Button("↓") {
                                try? c.controller.movePage(id: page.id, toIndex: min(c.issue.pages.count - 1, idx + 1)); c.refresh()
                            }.disabled(idx >= c.issue.pages.count - 1)
                            Button(role: .destructive, action: { try? c.controller.removePage(id: page.id); c.refresh() }) { Text("Delete") }
                        }
                        .padding(8)
                        .background(Color.gray.opacity(0.06))
                        .cornerRadius(8)
                    }
                }.padding(.vertical, 6)
            }
        }
        .padding(10)
    }
}
