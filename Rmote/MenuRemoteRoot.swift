import AppKit
import SwiftUI
import ItsytvCore

struct MenuRemoteRoot: View {
    var manager: AppleTVManager

    var body: some View {
        VStack(spacing: 16) {
            header
            RemotePanelView(manager: manager) { action in
                manager.pressButton(action.companionButton)
            }
            footer
        }
        .padding(20)
        .frame(width: 240)
        .background(Color(white: 0.12))
    }

    private var header: some View {
        VStack(spacing: 8) {
            Text(connectionStatusLabel)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            devicePicker
        }
    }

    private var connectionStatusLabel: String {
        switch manager.connectionStatus {
        case .disconnected: "Disconnected"
        case .connecting: "Connecting…"
        case .pairing: "Pairing — enter PIN below"
        case .connected: "Connected"
        case .error(let message): "Error: \(message)"
        }
    }

    private var devicePicker: some View {
        Menu {
            if manager.discoveredDevices.isEmpty {
                Text("No Apple TVs found")
            } else {
                ForEach(manager.discoveredDevices, id: \.id) { device in
                    Button {
                        manager.connect(to: device)
                    } label: {
                        let selected = device.id == manager.lastConnectedDeviceID
                            || device.id == manager.connectedDeviceID
                        Text(selected ? "✓ \(device.name)" : device.name)
                    }
                }
            }
        } label: {
            Label(
                manager.connectedDeviceName ?? "Select Apple TV",
                systemImage: "tv"
            )
            .frame(maxWidth: .infinity)
        }
        .menuStyle(.borderlessButton)
    }

    private var footer: some View {
        HStack {
            Button("Rescan") {
                manager.refreshScanning()
            }
            Spacer()
            Button("Quit") {
                NSApp.terminate(nil)
            }
        }
        .buttonStyle(.plain)
        .font(.caption)
        .foregroundStyle(.secondary)
    }
}
