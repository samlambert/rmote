import Foundation
import ItsytvCore

@MainActor
protocol LastDeviceReconnecting: AnyObject {
    var connectionStatus: ConnectionStatus { get }
    var discoveredDevices: [AppleTVDevice] { get }
    var lastConnectedDeviceID: String? { get }
    func connect(to device: AppleTVDevice)
    func disconnect()
    func refreshScanning()
}

extension AppleTVManager: LastDeviceReconnecting {}

// Immediate reconnect hangs: Network.framework leaves a Bonjour NWConnection
// in .waiting when the TV is asleep, and ItsytvCore never times that out.
@MainActor
final class LastDeviceReconnect {
    private let manager: any LastDeviceReconnecting
    private let maxAttempts: Int
    private let connectTimeout: TimeInterval
    private let pollInterval: Duration
    private let knockInterval: TimeInterval
    private var runTask: Task<Void, Never>?

    var isRunning: Bool { runTask != nil }

    init(
        manager: any LastDeviceReconnecting,
        maxAttempts: Int = 3,
        connectTimeout: TimeInterval = 10,
        pollInterval: Duration = .milliseconds(250),
        knockInterval: TimeInterval = 5
    ) {
        self.manager = manager
        self.maxAttempts = maxAttempts
        self.connectTimeout = connectTimeout
        self.pollInterval = pollInterval
        self.knockInterval = knockInterval
    }

    func start() {
        stop()
        manager.refreshScanning()
        runTask = Task { [weak self] in
            await self?.run()
            guard let self, !Task.isCancelled else { return }
            self.runTask = nil
        }
    }

    func stop() {
        runTask?.cancel()
        runTask = nil
    }

    private func run() async {
        for attempt in 1...maxAttempts {
            guard !Task.isCancelled else { return }
            guard let device = await waitForLastDevice() else { return }
            guard !Task.isCancelled, stillIdle() else { return }
            manager.connect(to: device)
            if await reachedPairingOrConnected(startedDeviceID: device.id) { return }
            if isOurConnectingAttempt(deviceID: device.id) {
                manager.disconnect()
                // Stale Bonjour hits survive hang abort; knock before retrying
                // so the next waitForLastDevice does not skip wake recovery.
                guard attempt < maxAttempts else { return }
                await knockBeforeRetry()
                if !stillIdle() { return }
            } else if !stillIdle() {
                return
            }
        }
    }

    private func knockBeforeRetry() async {
        manager.refreshScanning()
        let deadline = Date().addingTimeInterval(knockInterval)
        while !Task.isCancelled, Date() < deadline {
            if !stillIdle() { return }
            try? await Task.sleep(for: pollInterval)
        }
    }

    private func stillIdle() -> Bool {
        switch manager.connectionStatus {
        case .disconnected, .error:
            return true
        case .connecting, .pairing, .connected:
            return false
        }
    }

    private func isOurConnectingAttempt(deviceID: String) -> Bool {
        manager.connectionStatus == .connecting
            && manager.lastConnectedDeviceID == deviceID
    }

    private func waitForLastDevice() async -> AppleTVDevice? {
        var lastKnockAt = Date()
        while !Task.isCancelled {
            if !stillIdle() { return nil }
            guard let lastID = manager.lastConnectedDeviceID else { return nil }
            if let device = manager.discoveredDevices.first(where: { $0.id == lastID }) {
                return device
            }
            let now = Date()
            if now.timeIntervalSince(lastKnockAt) >= knockInterval {
                lastKnockAt = now
                manager.refreshScanning()
            }
            try? await Task.sleep(for: pollInterval)
        }
        return nil
    }

    private func reachedPairingOrConnected(startedDeviceID: String) async -> Bool {
        let deadline = Date().addingTimeInterval(connectTimeout)
        while !Task.isCancelled {
            switch manager.connectionStatus {
            case .pairing, .connected:
                return true
            case .connecting:
                if manager.lastConnectedDeviceID != startedDeviceID {
                    return true
                }
                if Date() >= deadline {
                    return false
                }
            case .disconnected, .error:
                return false
            }
            try? await Task.sleep(for: pollInterval)
        }
        return true
    }
}
