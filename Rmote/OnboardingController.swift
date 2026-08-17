import Combine
import Foundation

protocol OnboardingStore: AnyObject {
    var hasCompletedOnboarding: Bool { get set }
}

final class UserDefaultsOnboardingStore: OnboardingStore {
    static let completedKey = "onboarding.completed"

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var hasCompletedOnboarding: Bool {
        get { defaults.bool(forKey: Self.completedKey) }
        set { defaults.set(newValue, forKey: Self.completedKey) }
    }
}

@MainActor
final class OnboardingController: ObservableObject {
    @Published private(set) var isActive = false
    @Published private(set) var currentStep: OnboardingStep = .devicePicker

    private let store: OnboardingStore

    init(store: OnboardingStore = UserDefaultsOnboardingStore()) {
        self.store = store
    }

    func overlayVisible(isPairing: Bool) -> Bool {
        isActive && !isPairing
    }

    func startIfNeeded() {
        guard !isActive else { return }
        guard !store.hasCompletedOnboarding else { return }
        currentStep = .devicePicker
        isActive = true
    }

    func next() {
        guard isActive else { return }
        if let nextStep = currentStep.next {
            currentStep = nextStep
        } else {
            complete()
        }
    }

    func skip() {
        guard isActive else { return }
        complete()
    }

    func replay() {
        currentStep = .devicePicker
        isActive = true
    }

    private func complete() {
        isActive = false
        store.hasCompletedOnboarding = true
    }
}
