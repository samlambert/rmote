import SwiftUI

struct OnboardingHighlightKey: PreferenceKey {
    static var defaultValue: [OnboardingHighlightID: Anchor<CGRect>] = [:]

    static func reduce(
        value: inout [OnboardingHighlightID: Anchor<CGRect>],
        nextValue: () -> [OnboardingHighlightID: Anchor<CGRect>]
    ) {
        value.merge(nextValue(), uniquingKeysWith: { _, new in new })
    }
}

extension View {
    func onboardingHighlight(_ id: OnboardingHighlightID) -> some View {
        anchorPreference(key: OnboardingHighlightKey.self, value: .bounds) { anchor in
            [id: anchor]
        }
    }
}
