import AppKit
import SwiftUI
import ItsytvCore

@main
struct TVRemoteApp: App {
    @NSApplicationDelegateAdaptor(AppLifecycle.self) private var lifecycle

    var body: some Scene {
        MenuBarExtra {
            MenuRemoteRoot(manager: lifecycle.manager)
        } label: {
            Label("TV", systemImage: "appletvremote.gen4.fill")
        }
        .menuBarExtraStyle(.window)

        Settings {
            EmptyView()
        }
    }
}

final class AppLifecycle: NSObject, NSApplicationDelegate {
    let manager = AppleTVManager()

    func applicationDidFinishLaunching(_ notification: Notification) {
        manager.startScanning()
        _ = manager.connectToLastConnectedDevice()
    }

    func applicationWillTerminate(_ notification: Notification) {
        manager.stopScanning()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}
