import SwiftUI

@main
struct AudioRecorderApp: App {
    var body: some Scene {
        let windowGroup = WindowGroup {
            ContentView()
                .frame(minWidth: 600, minHeight: 500)
        }
        .windowStyle(.hiddenTitleBar)
        
        if #available(macOS 13.0, *) {
            return windowGroup.windowResizability(.contentSize)
        } else {
            return windowGroup
        }
    }
}
