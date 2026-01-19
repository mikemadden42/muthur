import AppKit
import SwiftUI

// Delegate ensures the process ends when you close the window
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_: NSApplication) -> Bool {
        true
    }

    func applicationDidFinishLaunching(_: Notification) {
        // Modern macOS 14+ focus grab:
        // We find the window and make it 'Key' (ready for keyboard input)
        // and 'Front' (visible on top of the terminal)
        DispatchQueue.main.async {
            if let window = NSApplication.shared.windows.first {
                window.makeKeyAndOrderFront(nil)
            }
            // Request activation without the deprecated 'ignoringOtherApps'
            NSApp.activate()
        }
    }
}

@main
struct MuthurApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            MuthurTerminal()
                .frame(minWidth: 900, minHeight: 700)
                .background(Color.black)
                .onAppear {
                    // Set to a regular UI app to show in Dock and accept focus
                    NSApp.setActivationPolicy(.regular)
                }
        }
        .windowStyle(.hiddenTitleBar)
    }
}
