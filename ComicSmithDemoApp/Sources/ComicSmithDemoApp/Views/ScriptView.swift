import SwiftUI
import ComicSmithCore

struct ScriptView: View {
    @EnvironmentObject var c: AppContainer
    @State private var draft: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Script").font(.headline)
                Spacer()
                Button("Apply Edits to Current Page") {
                    ScriptApplier.applyEdits(draft, controller: c.controller)
                    c.refresh()
                    draft = ScriptFormatter.render(issue: c.issue) // re-render
                }
            }
            TextEditor(text: Binding(
                get: {
                    if draft.isEmpty { draft = ScriptFormatter.render(issue: c.issue) }
                    return draft
                },
                set: { draft = $0 }
            ))
            .font(.system(.body, design: .monospaced))
            .frame(minHeight: 300)
        }
        .padding(10)
        .onChange(of: c.issue.pages.count) { _ in
            draft = ScriptFormatter.render(issue: c.issue)
        }
    }
}
