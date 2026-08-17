import SwiftUI

struct CoachMarkSpotlight: View {
    let hole: CGRect?

    private let holePadding: CGFloat = 6
    private let holeCornerRadius: CGFloat = 10

    var body: some View {
        let paddedHole = hole.map { $0.insetBy(dx: -holePadding, dy: -holePadding) }

        ZStack(alignment: .topLeading) {
            Canvas { context, size in
                var path = Path(CGRect(origin: .zero, size: size))
                if let paddedHole {
                    path.addRoundedRect(
                        in: paddedHole,
                        cornerSize: CGSize(width: holeCornerRadius, height: holeCornerRadius)
                    )
                }
                context.fill(
                    path,
                    with: .color(.black.opacity(0.55)),
                    style: FillStyle(eoFill: true)
                )
                if let paddedHole {
                    let ring = Path(roundedRect: paddedHole, cornerRadius: holeCornerRadius)
                    context.stroke(ring, with: .color(.white.opacity(0.7)), lineWidth: 1.5)
                }
            }
            .allowsHitTesting(false)

            Color.black.opacity(0.01)
                .contentShape(
                    CoachMarkCutout(hole: paddedHole, cornerRadius: holeCornerRadius),
                    eoFill: true
                )
        }
    }
}

struct OnboardingChrome: View {
    let step: OnboardingStep
    let onNext: () -> Void
    let onSkip: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(step.title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
            Text(step.body)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            HStack {
                Button("Skip", action: onSkip)
                    .foregroundStyle(.white)
                    .accessibilityIdentifier("onboarding-skip")
                Spacer()
                Text(step.progressLabel)
                    .foregroundStyle(.tertiary)
                    .accessibilityIdentifier("onboarding-progress")
                Button(step.isLast ? "Done" : "Next", action: onNext)
                    .foregroundStyle(.white)
                    .accessibilityIdentifier("onboarding-next")
            }
            .font(.caption)
            .buttonStyle(.plain)
        }
        .padding(.top, 8)
    }
}

private struct CoachMarkCutout: Shape {
    var hole: CGRect?
    var cornerRadius: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path(rect)
        if let hole {
            path.addRoundedRect(
                in: hole,
                cornerSize: CGSize(width: cornerRadius, height: cornerRadius)
            )
        }
        return path
    }
}
