import SwiftUI
import ComicSmithCore

struct PanelView: View {
    @EnvironmentObject var c: AppContainer

    var pageAndPanel: (Page, Panel)? {
        guard let pid = c.focus.pageID, let pnid = c.focus.panelID,
              let page = c.issue.pages.first(where: { $0.id == pid }),
              let panel = page.panels.first(where: { $0.id == pnid }) else { return nil }
        return (page, panel)
    }

    @State private var descDraft: String = ""
    @State private var balloonTextDraft: String = ""
    @State private var balloonSpeakerDraft: String = ""

    // Reference tagging
    @State private var selectedCharacters: Set<String> = []
    @State private var selectedLocation: String? = nil
    @State private var selectedProps: Set<String> = []

    var characters: [ReferenceEntry] { c.controller.references.filter { $0.kind == "character" } }
    var locations:  [ReferenceEntry] { c.controller.references.filter { $0.kind == "location" } }
    var props:      [ReferenceEntry] { c.controller.references.filter { $0.kind == "prop" } }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Panel Mode — Detail").font(.headline)
                Spacer()
                if let (page, panel) = pageAndPanel {
                    Button("Generate Visual Rough") {
                        c.enqueuePanelVisual(pageID: page.id, panelID: panel.id)
                    }
                }
            }
            if let (page, panel) = pageAndPanel {
                Form {
                    // Description
                    Section("Description") {
                        TextEditor(text: Binding(
                            get: { descDraft.isEmpty ? panel.description : descDraft },
                            set: { descDraft = $0 }
                        ))
                        .frame(height: 120)
                        HStack {
                            Spacer()
                            Button("Save Description") {
                                try? c.controller.updatePanelDescription(pageID: page.id, panelID: panel.id, description: descDraft.isEmpty ? panel.description : descDraft)
                                descDraft = ""
                                c.refresh()
                                // Simulate image regen when description changes
                                c.enqueuePanelVisual(pageID: page.id, panelID: panel.id)
                            }
                        }
                    }

                    // Balloons
                    Section("Balloons") {
                        ForEach(panel.balloons.sorted(by: { $0.order < $1.order })) { b in
                            VStack(alignment: .leading) {
                                Text("\(b.kind.uppercased()) \(b.speaker ?? "")").font(.caption).foregroundColor(.secondary)
                                Text(b.text)
                            }
                            .padding(6)
                            .background(Color.gray.opacity(0.06))
                            .cornerRadius(6)
                        }
                        HStack {
                            TextField("Speaker (optional)", text: $balloonSpeakerDraft)
                            TextField("Balloon text", text: $balloonTextDraft, axis: .vertical)
                            Menu("Add") {
                                Button("Speech") {
                                    try? c.controller.addBalloon(pageID: page.id, panelID: panel.id, kind: "speech", speaker: balloonSpeakerDraft.isEmpty ? nil : balloonSpeakerDraft, text: balloonTextDraft, order: nil)
                                    balloonTextDraft = ""; balloonSpeakerDraft = ""; c.refresh()
                                }
                                Button("Thought") {
                                    try? c.controller.addBalloon(pageID: page.id, panelID: panel.id, kind: "thought", speaker: balloonSpeakerDraft.isEmpty ? nil : balloonSpeakerDraft, text: balloonTextDraft, order: nil)
                                    balloonTextDraft = ""; balloonSpeakerDraft = ""; c.refresh()
                                }
                                Button("Caption") {
                                    try? c.controller.addBalloon(pageID: page.id, panelID: panel.id, kind: "caption", speaker: nil, text: balloonTextDraft, order: nil)
                                    balloonTextDraft = ""; c.refresh()
                                }
                                Button("SFX") {
                                    try? c.controller.addBalloon(pageID: page.id, panelID: panel.id, kind: "sfx", speaker: nil, text: balloonTextDraft, order: nil)
                                    balloonTextDraft = ""; c.refresh()
                                }
                            }
                        }
                        Text("Dialogue-only changes do not regenerate images.").font(.caption).foregroundColor(.secondary)
                    }

                    // References
                    Section("References") {
                        // Characters (multi-select)
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Characters").font(.subheadline)
                            if characters.isEmpty {
                                Text("No characters yet. Add some in References → All.")
                                    .font(.caption).foregroundColor(.secondary)
                            } else {
                                FlowLayout(spacing: 6) {
                                    ForEach(characters) { ch in
                                        let isSel = selectedCharacters.contains(ch.id) || (page.panels.first(where: { $0.id == panel.id })?.characterIDs.contains(ch.id) ?? false)
                                        Toggle(isOn: Binding(
                                            get: { isSel },
                                            set: { on in
                                                if on { selectedCharacters.insert(ch.id) } else { selectedCharacters.remove(ch.id) }
                                            })) {
                                                Text(ch.name)
                                            }
                                            .toggleStyle(.button)
                                            .buttonStyle(.bordered)
                                    }
                                }
                            }
                        }
                        // Location (single)
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Location").font(.subheadline)
                            Picker("Location", selection: Binding(
                                get: { selectedLocation ?? panel.locationID },
                                set: { newVal in
                                    selectedLocation = newVal
                                    try? c.controller.setPanelReferences(pageID: page.id, panelID: panel.id, characterIDs: Array(selectedCharacters), locationID: selectedLocation, propIDs: Array(selectedProps))
                                    c.refresh()
                                }
                            )) {
                                Text("—").tag(String?.none)
                                ForEach(locations) { loc in
                                    Text(loc.name).tag(String?.some(loc.id))
                                }
                            }
                            .pickerStyle(.menu)
                        }
                        // Props (multi-select)
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Props").font(.subheadline)
                            if props.isEmpty {
                                Text("No props yet. Add some in References → All.")
                                    .font(.caption).foregroundColor(.secondary)
                            } else {
                                FlowLayout(spacing: 6) {
                                    ForEach(props) { pr in
                                        let isSel = selectedProps.contains(pr.id) || (page.panels.first(where: { $0.id == panel.id })?.propIDs.contains(pr.id) ?? false)
                                        Toggle(isOn: Binding(
                                            get: { isSel },
                                            set: { on in
                                                if on { selectedProps.insert(pr.id) } else { selectedProps.remove(pr.id) }
                                            })) {
                                                Text(pr.name)
                                            }
                                            .toggleStyle(.button)
                                            .buttonStyle(.bordered)
                                    }
                                }
                            }
                        }
                    }
                }
            } else {
                Text("Select a panel from Page Mode.")
                    .foregroundColor(.secondary)
            }
        }
                .padding(10)
                .onAppear {
                    if let (_, panel) = pageAndPanel {
                        if selectedCharacters.isEmpty { selectedCharacters = Set(panel.characterIDs) }
                        if selectedProps.isEmpty { selectedProps = Set(panel.propIDs) }
                        if selectedLocation == nil { selectedLocation = panel.locationID }
                    }
                }
    }
}


// Simple flow layout for tag-like toggles
struct FlowLayout<Content: View>: View {
    var spacing: CGFloat
    @ViewBuilder var content: () -> Content
    init(spacing: CGFloat = 8, @ViewBuilder content: @escaping () -> Content) {
        self.spacing = spacing; self.content = content
    }
    var body: some View {
        let _ = ()
        return _FlowLayout(spacing: spacing, content: content)
    }
}

fileprivate struct _FlowLayout<Content: View>: View {
    var spacing: CGFloat
    let content: () -> Content
    init(spacing: CGFloat, content: @escaping () -> Content) {
        self.spacing = spacing; self.content = content
    }
    var body: some View {
        var size = CGSize.zero
        return GeometryReader { geo in
            self.generateContent(in: geo)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    func generateContent(in geo: GeometryProxy) -> some View {
        var x: CGFloat = 0
        var y: CGFloat = 0
        let maxWidth = geo.size.width
        return ZStack(alignment: .topLeading) {
            content().background(GeometryReader { inner in
                Color.clear
                    .preference(key: SizePreferenceKey.self, value: inner.size)
            })
        }
    }
}

fileprivate struct SizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {}
}
