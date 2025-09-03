import SwiftUI
import ComicSmithCore

struct ReferenceDetailView: View {
    @EnvironmentObject var c: AppContainer
    @State private var name: String = ""
    @State private var aliasesCSV: String = ""
    @State private var traitsCSV: String = ""
    @State private var voiceNotes: String = ""
    @State private var visualsCSV: String = ""
    @State private var introPage: String = ""

    var ref: ReferenceEntry? {
        guard let rid = c.focus.referenceID else { return nil }
        return c.controller.references.first(where: { $0.id == rid })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Button("← All References") {
                    c.controller.mode = .referencesAll
                    c.controller.focus.referenceID = nil
                    c.refresh()
                }
                .buttonStyle(.link)
                Spacer()
            }
            HStack { Text("Reference Detail").font(.headline); Spacer(); if let rid = c.focus.referenceID { Button("Generate Portrait") { c.enqueueReferenceImage(referenceID: rid) } } }
            if let ref = ref {
                Form {
                    HStack {
                        Text("Kind").frame(width: 120, alignment: .trailing)
                        Text(ref.kind.capitalized)
                    }
                    HStack {
                        Text("Name").frame(width: 120, alignment: .trailing)
                        TextField("Name", text: Binding(
                            get: { name.isEmpty ? ref.name : name },
                            set: { name = $0 }
                        ))
                    }
                    HStack(alignment: .top) {
                        Text("Aliases").frame(width: 120, alignment: .trailing)
                        TextField("comma,separated,aliases", text: Binding(
                            get: { aliasesCSV.isEmpty ? ref.aliases.joined(separator: ", ") : aliasesCSV },
                            set: { aliasesCSV = $0 }
                        ))
                    }
                    HStack(alignment: .top) {
                        Text("Traits").frame(width: 120, alignment: .trailing)
                        TextField("comma,separated,traits", text: Binding(
                            get: { traitsCSV.isEmpty ? ref.traits.joined(separator: ", ") : traitsCSV },
                            set: { traitsCSV = $0 }
                        ))
                    }
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Voice Notes").frame(width: 120, alignment: .trailing)
                            TextEditor(text: Binding(
                                get: { voiceNotes.isEmpty ? (ref.voiceNotes ?? "") : voiceNotes },
                                set: { voiceNotes = $0 }
                            ))
                            .frame(height: 120)
                        }
                    }
                    HStack(alignment: .top) {
                        Text("Visual Cues").frame(width: 120, alignment: .trailing)
                        TextField("comma,separated,cues", text: Binding(
                            get: { visualsCSV.isEmpty ? ref.visualCues.joined(separator: ", ") : visualsCSV },
                            set: { visualsCSV = $0 }
                        ))
                    }
                    HStack {
                        Text("Introduced on Page").frame(width: 120, alignment: .trailing)
                        TextField("e.g., 3", text: Binding(
                            get: { introPage.isEmpty ? ((ref.introducedPageIndex != nil) ? String((ref.introducedPageIndex ?? 0) + 1) : "") : introPage },
                            set: { introPage = $0 }
                        ))
                        .frame(width: 80)
                        .textFieldStyle(.roundedBorder)
                        Text("(optional)")
                            .font(.caption).foregroundColor(.secondary)
                    }
                    HStack {
                        Spacer()
                        Button("Save") {
                            var patch: [String:String] = [:]
                            if !name.isEmpty { patch["name"] = name }
                            if !voiceNotes.isEmpty { patch["voice_notes"] = voiceNotes }
                            if !aliasesCSV.isEmpty { patch["aliases_csv"] = aliasesCSV }
                            if !traitsCSV.isEmpty { patch["traits_csv"] = traitsCSV }
                            if !visualsCSV.isEmpty { patch["visual_cues_csv"] = visualsCSV }
                            if !introPage.isEmpty { patch["introduced_page"] = introPage }
                            try? c.controller.updateReference(id: ref.id, patch: patch)
                            name = ""; aliasesCSV = ""; traitsCSV = ""; voiceNotes = ""; visualsCSV = ""
                            c.refresh()
                        }
                    }
                }
                .formStyle(.grouped)
                .scrollContentBackground(.hidden)
            } else {
                Text("No reference selected").foregroundColor(.secondary)
            }
        }
        .padding(10)
    }
}
