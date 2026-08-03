import SwiftUI
import ItsytvCore

struct RemotePanelView: View {
    let manager: AppleTVManager
    let onAction: (RemoteAction) -> Void

    @State private var pinDigits = ""
    @State private var pinReady = false
    @State private var pinSubmitted = false
    @State private var prepareTask: Task<Void, Never>?
    @FocusState private var pinFocused: Bool

    var body: some View {
        Group {
            if manager.connectionStatus == .pairing {
                pinEntry
            } else {
                remoteControls
            }
        }
        .onChange(of: manager.connectionStatus) { _, newStatus in
            if newStatus == .pairing {
                pinSubmitted = false
                beginPINPrepare()
            } else {
                cancelPINPrepare()
                pinDigits = ""
                pinReady = false
                pinSubmitted = false
            }
        }
    }

    private var pinEntry: some View {
        VStack(spacing: 12) {
            Text(pinReady ? "Enter the 4-digit PIN shown on your TV" : "Waiting for Apple TV…")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            TextField("0000", text: $pinDigits)
                .textFieldStyle(.roundedBorder)
                .multilineTextAlignment(.center)
                .font(.title2.monospacedDigit())
                .focused($pinFocused)
                .disabled(!pinReady)
                .onChange(of: pinDigits) { _, newValue in
                    let sanitized = PINSubmission.sanitizedPIN(newValue)
                    if sanitized != newValue {
                        pinDigits = sanitized
                        return
                    }
                    if sanitized.count == 4, pinReady {
                        pinReady = false
                        pinSubmitted = true
                        manager.submitPIN(sanitized)
                    }
                }
                .onAppear {
                    beginPINPrepare()
                }
                .onDisappear {
                    cancelPINPrepare()
                }

            Text("Allow the connection on your Apple TV if prompted.")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private func beginPINPrepare() {
        guard manager.connectionStatus == .pairing else { return }
        guard !pinSubmitted else { return }
        guard prepareTask == nil else { return }

        pinReady = false
        pinDigits = ""
        prepareTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.5))
            guard !Task.isCancelled else { return }
            defer { prepareTask = nil }
            guard manager.connectionStatus == .pairing else { return }
            guard !pinSubmitted else { return }
            pinReady = true
            pinFocused = true
        }
    }

    private func cancelPINPrepare() {
        prepareTask?.cancel()
        prepareTask = nil
    }

    private var remoteControls: some View {
        VStack(spacing: 20) {
            dPad
            Grid(horizontalSpacing: 20, verticalSpacing: 20) {
                GridRow {
                    remoteButton("chevron.backward", action: .menu)
                    remoteButton("tv", action: .home)
                    remoteButton("playpause.fill", action: .playPause)
                }
                GridRow {
                    remoteButton("power", action: .power)
                    remoteButton("minus", action: .volumeDown)
                    remoteButton("plus", action: .volumeUp)
                }
            }
        }
        .disabled(manager.connectionStatus != .connected)
        .opacity(manager.connectionStatus == .connected ? 1 : 0.45)
    }

    private var dPad: some View {
        ZStack {
            Circle()
                .fill(Color(white: 0.18))
                .frame(width: 140, height: 140)

            VStack(spacing: 0) {
                dPadButton("chevron.up", action: .up)
                HStack(spacing: 0) {
                    dPadButton("chevron.left", action: .left)
                    Button {
                        onAction(.select)
                    } label: {
                        Circle()
                            .fill(Color(white: 0.28))
                            .frame(width: 46, height: 46)
                            .overlay {
                                Circle()
                                    .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
                            }
                    }
                    .buttonStyle(.plain)
                    dPadButton("chevron.right", action: .right)
                }
                dPadButton("chevron.down", action: .down)
            }
        }
    }

    private func dPadButton(_ symbol: String, action: RemoteAction) -> some View {
        Button {
            onAction(action)
        } label: {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white.opacity(0.9))
                .frame(width: 60, height: 60)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func remoteButton(_ symbol: String, action: RemoteAction) -> some View {
        Button {
            onAction(action)
        } label: {
            Image(systemName: symbol)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(.white.opacity(0.9))
                .frame(width: 44, height: 44)
                .background(Color(white: 0.2))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }
}
