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
    private var lastDeviceReconnect: LastDeviceReconnect?

    func applicationDidFinishLaunching(_ notification: Notification) {
        manager.startScanning()
        guard NSClassFromString("XCTestCase") == nil else { return }
        let reconnect = LastDeviceReconnect(manager: manager)
        lastDeviceReconnect = reconnect
        reconnect.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        lastDeviceReconnect?.stop()
        manager.stopScanning()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}
