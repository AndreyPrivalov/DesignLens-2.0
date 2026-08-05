import SwiftUI

@main
struct DesignLensApp: App {
    var body: some Scene {
        WindowGroup("DesignLens - macOS Visual QA", id: "main") {
            ContentView()
                .frame(minWidth: 1100, minHeight: 740)
        }
        .windowStyle(.titleBar)
    }
}


