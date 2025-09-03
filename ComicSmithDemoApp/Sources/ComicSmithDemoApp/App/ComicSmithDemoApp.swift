import SwiftUI
import AppKit
import ComicSmithCore

@main
struct ComicSmithDemoApp: App {
    @StateObject private var container = AppContainer()
    
    var body: some Scene {
        WindowGroup {
            RootSplitView()
                .environmentObject(container)
                .frame(minWidth: 1100, minHeight: 700)
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Project") {
                    container.newProject()
                }
                .keyboardShortcut("n", modifiers: .command)
            }
            CommandGroup(after: .newItem) {
                Divider()
                Button("Open Project...") {
                    openProject()
                }
                .keyboardShortcut("o", modifiers: .command)
                
                Button("Save Project") {
                    container.saveProject()
                }
                .keyboardShortcut("s", modifiers: .command)
                
                Button("Save Project As...") {
                    saveProjectAs()
                }
                .keyboardShortcut("s", modifiers: [.command, .shift])
            }
        }
    }
    
    private func openProject() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.title = "Select ComicSmith Project Folder"
        panel.prompt = "Open"
        
        if panel.runModal() == .OK, let url = panel.url {
            container.openProject(at: url)
        }
    }
    
    private func saveProjectAs() {
        let panel = NSSavePanel()
        panel.title = "Save Project As"
        panel.prompt = "Save"
        panel.nameFieldStringValue = container.issue.title
        
        if panel.runModal() == .OK, let url = panel.url {
            container.saveProjectAs(to: url)
        }
    }
}