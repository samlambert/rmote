import XCTest
@testable import TVRemote
import ItsytvCore

@MainActor
final class LastDeviceReconnectTests: XCTestCase {

    func testWaitsUntilLastDeviceIsDiscovered() async {
        let manager = FakeReconnectManager()
        manager.lastConnectedDeviceID = "Living Room"
        manager.discoveredDevices = [Self.device("Bedroom")]
        let reconnect = LastDeviceReconnect(manager: manager, pollInterval: .milliseconds(10))
        defer { reconnect.stop() }

        reconnect.start()
        try? await Task.sleep(for: .milliseconds(40))
        XCTAssertTrue(manager.connectCalls.isEmpty)

        let live = Self.device("Living Room", host: "living.local")
        manager.discoveredDevices = [Self.device("Bedroom"), live]
        await waitUntil { !manager.connectCalls.isEmpty }

        XCTAssertEqual(manager.connectCalls.map(\.id), ["Living Room"])
        XCTAssertEqual(manager.connectCalls.first?.host, "living.local")
    }

    func testConnectsTheLiveDiscoveredDevice() async {
        let manager = FakeReconnectManager()
        manager.lastConnectedDeviceID = "Living Room"
        manager.discoveredDevices = [Self.device("Living Room", host: "awake.local")]
        let reconnect = LastDeviceReconnect(manager: manager, pollInterval: .milliseconds(10))
        defer { reconnect.stop() }

        reconnect.start()
        await waitUntil { !manager.connectCalls.isEmpty }

        XCTAssertEqual(manager.connectCalls.first?.id, "Living Room")
        XCTAssertEqual(manager.connectCalls.first?.host, "awake.local")
    }

    func testPairingOrConnectedStopsTheLaunchTask() async {
        for terminal: ConnectionStatus in [.pairing, .connected] {
            let manager = FakeReconnectManager()
            manager.lastConnectedDeviceID = "Living Room"
            manager.discoveredDevices = [Self.device("Living Room")]
            let reconnect = LastDeviceReconnect(manager: manager, pollInterval: .milliseconds(10))
            defer { reconnect.stop() }

            reconnect.start()
            await waitUntil { manager.connectCalls.count == 1 }
            manager.connectionStatus = terminal
            await waitUntil { !reconnect.isRunning }

            XCTAssertEqual(manager.connectCalls.count, 1)
            XCTAssertEqual(manager.disconnectCount, 0)
        }
    }

    func testUserInitiatedSessionStopsRatherThanAbort() async {
        for status: ConnectionStatus in [.connecting, .pairing, .connected] {
            let manager = FakeReconnectManager()
            manager.lastConnectedDeviceID = "Living Room"
            manager.discoveredDevices = [Self.device("Living Room")]
            manager.connectionStatus = status
            let reconnect = LastDeviceReconnect(manager: manager, pollInterval: .milliseconds(10))
            defer { reconnect.stop() }

            reconnect.start()
            await waitUntil { !reconnect.isRunning }

            XCTAssertTrue(manager.connectCalls.isEmpty)
            XCTAssertEqual(manager.disconnectCount, 0)
        }
    }

    func testHangAbortAppliesOnlyToAttemptThisTaskStarted() async {
        let ours = FakeReconnectManager()
        ours.lastConnectedDeviceID = "Living Room"
        ours.discoveredDevices = [Self.device("Living Room")]
        let ourReconnect = LastDeviceReconnect(
            manager: ours,
            connectTimeout: 0.05,
            pollInterval: .milliseconds(10)
        )
        defer { ourReconnect.stop() }

        ourReconnect.start()
        await waitUntil { ours.connectCalls.count == 1 }
        await waitUntil { ours.disconnectCount == 1 }
        XCTAssertEqual(ours.lastConnectedDeviceID, "Living Room")

        let theirs = FakeReconnectManager()
        theirs.lastConnectedDeviceID = "Living Room"
        theirs.discoveredDevices = [Self.device("Living Room")]
        let theirReconnect = LastDeviceReconnect(
            manager: theirs,
            connectTimeout: 0.05,
            pollInterval: .milliseconds(10)
        )
        defer { theirReconnect.stop() }

        theirReconnect.start()
        await waitUntil { theirs.connectCalls.count == 1 }
        theirs.lastConnectedDeviceID = "Bedroom"
        await waitUntil { !theirReconnect.isRunning }

        XCTAssertEqual(theirs.connectCalls.count, 1)
        XCTAssertEqual(theirs.disconnectCount, 0)
    }

    func testStopsAfterThreeFailedAttempts() async {
        let manager = FakeReconnectManager()
        manager.lastConnectedDeviceID = "Living Room"
        manager.discoveredDevices = [Self.device("Living Room")]
        let reconnect = LastDeviceReconnect(
            manager: manager,
            connectTimeout: 0.05,
            pollInterval: .milliseconds(5)
        )
        defer { reconnect.stop() }

        reconnect.start()
        await waitUntil(timeout: 3) { manager.connectCalls.count == 3 }
        await waitUntil(timeout: 3) { !reconnect.isRunning }

        XCTAssertEqual(manager.connectCalls.count, 3)
        XCTAssertEqual(manager.disconnectCount, 3)
        let refreshAfterGiveUp = manager.refreshCount
        try? await Task.sleep(for: .milliseconds(40))
        XCTAssertEqual(manager.refreshCount, refreshAfterGiveUp)
    }

    func testStopCancelsTheTask() async {
        let manager = FakeReconnectManager()
        manager.lastConnectedDeviceID = "Living Room"
        let reconnect = LastDeviceReconnect(manager: manager, pollInterval: .milliseconds(10))

        reconnect.start()
        XCTAssertTrue(reconnect.isRunning)
        manager.discoveredDevices = [Self.device("Living Room")]
        reconnect.stop()
        XCTAssertFalse(reconnect.isRunning)

        try? await Task.sleep(for: .milliseconds(50))
        XCTAssertTrue(manager.connectCalls.isEmpty)
    }

    func testKnocksWhileWaitingForLastDevice() async {
        let manager = FakeReconnectManager()
        manager.lastConnectedDeviceID = "Living Room"
        let reconnect = LastDeviceReconnect(
            manager: manager,
            pollInterval: .milliseconds(10),
            knockInterval: 0.04
        )
        defer { reconnect.stop() }

        reconnect.start()
        XCTAssertEqual(manager.refreshCount, 1)
        await waitUntil { manager.refreshCount >= 2 }
        XCTAssertTrue(manager.connectCalls.isEmpty)
    }

    private func waitUntil(
        timeout: TimeInterval = 2,
        file: StaticString = #file,
        line: UInt = #line,
        _ condition: () -> Bool
    ) async {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if condition() { return }
            try? await Task.sleep(for: .milliseconds(10))
        }
        XCTFail("Condition not met within \(timeout)s", file: file, line: line)
    }

    private static func device(_ name: String, host: String? = nil) -> AppleTVDevice {
        AppleTVDevice(id: name, name: name, host: host ?? "\(name).local", port: 49152, modelName: "AppleTV")
    }
}

@MainActor
private final class FakeReconnectManager: LastDeviceReconnecting {
    var connectionStatus: ConnectionStatus = .disconnected
    var discoveredDevices: [AppleTVDevice] = []
    var lastConnectedDeviceID: String?
    var connectCalls: [AppleTVDevice] = []
    var disconnectCount = 0
    var refreshCount = 0

    func connect(to device: AppleTVDevice) {
        lastConnectedDeviceID = device.id
        connectionStatus = .connecting
        connectCalls.append(device)
    }

    func disconnect() {
        disconnectCount += 1
        connectionStatus = .disconnected
    }

    func refreshScanning() {
        refreshCount += 1
    }
}
