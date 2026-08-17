enum OnboardingHighlightID: Hashable {
    case devicePicker
    case trackpad
    case buttons
    case keyboard
}

enum OnboardingStep: Int, CaseIterable, Equatable {
    case devicePicker
    case gestures
    case buttons
    case keyboard

    var title: String {
        switch self {
        case .devicePicker:
            "Choose your Apple TV"
        case .gestures:
            "Swipe to move"
        case .buttons:
            "Remote buttons"
        case .keyboard:
            "Type from your Mac"
        }
    }

    var body: String {
        switch self {
        case .devicePicker:
            "Pick a device to connect. The first time, enter the PIN shown on the TV."
        case .gestures:
            "Two-finger swipe on the pad to navigate. Two-finger tap to select."
        case .buttons:
            "Menu, Home, Play/Pause, Power, and volume."
        case .keyboard:
            "When a text field is on the TV, tap the keyboard and type. Return closes it."
        }
    }

    var highlight: OnboardingHighlightID {
        switch self {
        case .devicePicker:
            .devicePicker
        case .gestures:
            .trackpad
        case .buttons:
            .buttons
        case .keyboard:
            .keyboard
        }
    }

    var next: OnboardingStep? {
        OnboardingStep(rawValue: rawValue + 1)
    }

    var isLast: Bool {
        next == nil
    }

    var progressLabel: String {
        "\(rawValue + 1)/\(OnboardingStep.allCases.count)"
    }
}
