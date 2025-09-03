import SwiftUI
import ComicSmithCore

struct RootSplitView: View {
    @EnvironmentObject var c: AppContainer

    var body: some View {
        HStack(spacing: 0) {
            ChatView()
                .frame(width: 340)
                .overlay(Divider(), alignment: .trailing)
            Group {
                switch c.mode {
                case .issue:
                    IssueView()
                case .page:
                    PageView()
                case .panel:
                    PanelView()
                case .referencesAll:
                    ReferencesAllView()
                case .referenceDetail:
                    ReferenceDetailView()
                }
            }
            .frame(minWidth: 420)
            .overlay(Divider(), alignment: .trailing)
            ScriptView()
                .frame(minWidth: 340)
        }
        .toolbar {
            ToolbarItemGroup {
                if c.totalImagesInProgress > 0 {
                    Text("Images: \(c.totalImagesInProgress) in progress").foregroundColor(.secondary)
                }
                Picker("Mode", selection: $c.mode) {
                    Text("Issue").tag(Mode.issue)
                    Text("Page").tag(Mode.page)
                    Text("Panel").tag(Mode.panel)
                    Text("Refs").tag(Mode.referencesAll)
                }
                .pickerStyle(.segmented)
            }
        }
        .onChange(of: c.mode) { _ in
            c.controller.mode = c.mode
            c.refresh()
        }
    }
}
