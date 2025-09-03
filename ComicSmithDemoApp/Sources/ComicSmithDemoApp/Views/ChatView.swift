import SwiftUI
import ComicSmithCore

struct ChatView: View {
    @EnvironmentObject var c: AppContainer
    @State private var draft: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Chat").font(.headline)
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(c.chat.enumerated()), id: \.0) { _, msg in
                        HStack(alignment: .top) {
                            Text(msg.role == .user ? "You:" : (msg.role == .assistant ? "AI:" : "Sys:"))
                                .font(.caption).foregroundColor(.secondary)
                                .frame(width: 32, alignment: .trailing)
                            Text(msg.content).textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(6)
                        .background(msg.role == .assistant ? Color.secondary.opacity(0.08) : Color.clear)
                        .cornerRadius(6)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            HStack {
                TextField("Type to brainstorm… e.g. “New page: 6 panels, chase beat.”", text: $draft, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                Button("Send") {
                    let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !text.isEmpty else { return }
                    Task { await c.sendChat(text); draft = "" }
                }
                .keyboardShortcut(.return, modifiers: [.command])
            }
        }
        .padding(10)
    }
}
