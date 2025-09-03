import SwiftUI
import ComicSmithCore

struct ReferencesAllView: View {
    @EnvironmentObject var c: AppContainer
    @State private var newName: String = ""
    @State private var newKind: String = "character"

    var characters: [ReferenceEntry] { c.controller.references.filter { $0.kind == "character" && (c.referencesSearch.isEmpty || $0.name.lowercased().contains(c.referencesSearch.lowercased())) } }
    var locations:  [ReferenceEntry] { c.controller.references.filter { $0.kind == "location" && (c.referencesSearch.isEmpty || $0.name.lowercased().contains(c.referencesSearch.lowercased())) } }
    var props:      [ReferenceEntry] { c.controller.references.filter { $0.kind == "prop" && (c.referencesSearch.isEmpty || $0.name.lowercased().contains(c.referencesSearch.lowercased())) } }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("References — All").font(.headline)
                Spacer()
                Picker("Kind", selection: $newKind) {
                    Text("Character").tag("character")
                    Text("Location").tag("location")
                    Text("Prop").tag("prop")
                }.pickerStyle(.menu)
                TextField("New \(newKind.capitalized) name…", text: $newName)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 260)
                Button("Add") {
                    let name = newName.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !name.isEmpty else { return }
                    let ref = c.controller.createReference(kind: newKind, name: name, aliases: [], traits: [], voiceNotes: nil, visualCues: [])
                    c.controller.mode = .referenceDetail
                    c.controller.focus.referenceID = ref.id
                    c.refresh()
                    newName = ""
                }
            }
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    ReferenceSection(title: "Characters", items: characters) { ref in
                        ReferenceRow(ref: ref, usage: c.usageCount(for: ref)) {
                            c.selectReference(ref.id)
                        }
                    }
                    ReferenceSection(title: "Locations", items: locations) { ref in
                        ReferenceRow(ref: ref, usage: c.usageCount(for: ref)) {
                            c.selectReference(ref.id)
                        }
                    }
                    ReferenceSection(title: "Props", items: props) { ref in
                        ReferenceRow(ref: ref, usage: c.usageCount(for: ref)) {
                            c.selectReference(ref.id)
                        }
                    }
                }
                .padding(.vertical, 6)
            }
        }
        .padding(10)
    }
}

private struct ReferenceSection<Content: View>: View {
    let title: String
    let items: [ReferenceEntry]
    @ViewBuilder var row: (ReferenceEntry) -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.subheadline).bold()
            if items.isEmpty {
                Text("— none —").font(.caption).foregroundColor(.secondary)
            } else {
                ForEach(items) { item in row(item) }
            }
        }
    }
}

private struct ReferenceRow: View {
    let ref: ReferenceEntry
    let usage: Int
    let open: () -> Void
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(ref.name).bold()
                if !ref.traits.isEmpty {
                    Text(ref.traits.joined(separator: ", ")).font(.caption).foregroundColor(.secondary)
                }
            }
            Spacer()
            Text("\(usage) use\(usage == 1 ? "" : "s")")
                .font(.caption)
                .foregroundColor(.secondary)
            Button("Open") { open() }
        }
        .padding(8)
        .background(Color.gray.opacity(0.06))
        .cornerRadius(8)
    }
}
