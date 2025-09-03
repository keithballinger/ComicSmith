import SwiftUI
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
    }
}
