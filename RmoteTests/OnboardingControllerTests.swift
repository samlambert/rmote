import XCTest
@testable import Rmote

final class MemoryOnboardingStore: OnboardingStore {
    var hasCompletedOnboarding: Bool

    init(hasCompletedOnboarding: Bool = false) {
        self.hasCompletedOnboarding = hasCompletedOnboarding
    }
}

@MainActor
final class OnboardingControllerTests: XCTestCase {

    func testStartIfNeededActivatesWhenIncomplete() {
        let store = MemoryOnboardingStore(hasCompletedOnboarding: false)
        let controller = OnboardingController(store: store)

        controller.startIfNeeded()

        XCTAssertTrue(controller.isActive)
        XCTAssertEqual(controller.currentStep, .devicePicker)
        XCTAssertTrue(controller.overlayVisible(isPairing: false))
    }

    func testStartIfNeededDoesNothingWhenCompleted() {
        let store = MemoryOnboardingStore(hasCompletedOnboarding: true)
        let controller = OnboardingController(store: store)

        controller.startIfNeeded()

        XCTAssertFalse(controller.isActive)
        XCTAssertFalse(controller.overlayVisible(isPairing: false))
    }

    func testNextWalksAllStepsThenCompletes() {
        let store = MemoryOnboardingStore()
        let controller = OnboardingController(store: store)
        controller.startIfNeeded()

        XCTAssertEqual(controller.currentStep, .devicePicker)
        controller.next()
        XCTAssertEqual(controller.currentStep, .gestures)
        controller.next()
        XCTAssertEqual(controller.currentStep, .buttons)
        controller.next()
        XCTAssertEqual(controller.currentStep, .keyboard)
        controller.next()

        XCTAssertFalse(controller.isActive)
        XCTAssertTrue(store.hasCompletedOnboarding)
    }

    func testSkipFromAnyStepCompletes() {
        let store = MemoryOnboardingStore()
        let controller = OnboardingController(store: store)
        controller.startIfNeeded()
        controller.next()

        controller.skip()

        XCTAssertFalse(controller.isActive)
        XCTAssertTrue(store.hasCompletedOnboarding)
    }

    func testReplayActivatesFromFirstStepWhenCompleted() {
        let store = MemoryOnboardingStore(hasCompletedOnboarding: true)
        let controller = OnboardingController(store: store)

        controller.replay()

        XCTAssertTrue(controller.isActive)
        XCTAssertEqual(controller.currentStep, .devicePicker)
        XCTAssertTrue(store.hasCompletedOnboarding)
    }

    func testOverlayHidesWhilePairingAndReturnsAfter() {
        let store = MemoryOnboardingStore()
        let controller = OnboardingController(store: store)
        controller.startIfNeeded()
        controller.next()

        XCTAssertFalse(controller.overlayVisible(isPairing: true))
        XCTAssertTrue(controller.isActive)
        XCTAssertEqual(controller.currentStep, .gestures)
        XCTAssertTrue(controller.overlayVisible(isPairing: false))
    }
}
