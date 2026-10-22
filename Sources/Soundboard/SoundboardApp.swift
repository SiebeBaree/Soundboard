import SwiftUI

@main
struct SoundboardApp: App {
    @NSApplicationDelegateAdaptor private var appDelegate: AppDelegate
    @State private var board = Board()

    var body: some Scene {
        // Plain style drops the macOS chrome so ContentView can draw its own Windows 95 frame.
        Window("Soundboard", id: "main") {
            ContentView()
                .environment(board)
        }
        .windowStyle(.plain)
        .windowResizability(.contentMinSize)
        .defaultSize(width: 620, height: 480)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
}
