import AppKit
import SwiftUI

struct RemoteTrackpadMotion {
    private(set) var translation: CGPoint = .zero
    private(set) var velocity: CGPoint = .zero
    private var lastTimestamp: TimeInterval?

    static func physicalTranslationDelta(
        scrollingDeltaX: CGFloat,
        scrollingDeltaY: CGFloat,
        isDirectionInvertedFromDevice: Bool
    ) -> CGPoint {
        let deviceMultiplier: CGFloat = isDirectionInvertedFromDevice ? -1 : 1
        return CGPoint(
            x: -scrollingDeltaX * deviceMultiplier,
            y: -scrollingDeltaY * deviceMultiplier
        )
    }

    mutating func begin(at timestamp: TimeInterval) {
        translation = .zero
        velocity = .zero
        lastTimestamp = timestamp
    }

    mutating func append(delta: CGPoint, at timestamp: TimeInterval) {
        translation.x += delta.x
        translation.y += delta.y

        guard let previousTimestamp = lastTimestamp else {
            lastTimestamp = timestamp
            return
        }

        let elapsed = timestamp - previousTimestamp
        guard elapsed > 0 else { return }

        lastTimestamp = timestamp
        guard delta != .zero else { return }
        velocity = CGPoint(x: delta.x / elapsed, y: delta.y / elapsed)
    }
}

struct RemoteTrackpadGestureView: NSViewRepresentable {
    let isEnabled: Bool
    let onTouchBegan: (CGSize) -> Void
    let onTouchMoved: (CGPoint) -> Void
    let onTouchEnded: (CGPoint, CGPoint) -> Void
    let onTwoFingerTap: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> NSView {
        let view = CaptureView()
        context.coordinator.attach(to: view)
        context.coordinator.update(from: self)
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        context.coordinator.attach(to: nsView)
        context.coordinator.update(from: self)
    }

    static func dismantleNSView(_ nsView: NSView, coordinator: Coordinator) {
        coordinator.teardown()
    }

    final class Coordinator {
        weak var captureView: NSView?
        var isEnabled = false
        var onTouchBegan: (CGSize) -> Void = { _ in }
        var onTouchMoved: (CGPoint) -> Void = { _ in }
        var onTouchEnded: (CGPoint, CGPoint) -> Void = { _, _ in }
        var onTwoFingerTap: () -> Void = {}

        private var monitor: Any?
        private var motion = RemoteTrackpadMotion()
        private var isTouchActive = false
        private var ignoreMomentum = false

        func attach(to view: NSView) {
            captureView = view
            installMonitorIfNeeded()
        }

        func update(from view: RemoteTrackpadGestureView) {
            let wasEnabled = isEnabled
            isEnabled = view.isEnabled
            onTouchBegan = view.onTouchBegan
            onTouchMoved = view.onTouchMoved
            onTouchEnded = view.onTouchEnded
            onTwoFingerTap = view.onTwoFingerTap

            if wasEnabled && !isEnabled {
                finishActiveTouchIfNeeded()
            }
        }

        func teardown() {
            finishActiveTouchIfNeeded()
            removeMonitor()
            captureView = nil
        }

        deinit {
            teardown()
        }

        private func installMonitorIfNeeded() {
            guard monitor == nil else { return }
            monitor = NSEvent.addLocalMonitorForEvents(matching: [.scrollWheel, .rightMouseDown]) { [weak self] event in
                self?.handle(event) ?? event
            }
        }

        private func removeMonitor() {
            if let monitor {
                NSEvent.removeMonitor(monitor)
                self.monitor = nil
            }
        }

        private func handle(_ event: NSEvent) -> NSEvent? {
            guard belongsToCaptureSession(event) else { return event }

            if event.type == .scrollWheel, event.hasPreciseScrollingDeltas {
                let directPhase = event.phase
                let momentumPhase = event.momentumPhase
                let hasDirect = !directPhase.isEmpty
                let hasMomentum = !momentumPhase.isEmpty

                if hasDirect, isTouchActive {
                    return handleDirect(event, phase: directPhase)
                }

                // Careful swipes end with no momentum sequence, so a post-touch
                // claim must not stay sticky across later window scroll gestures.
                if hasDirect {
                    ignoreMomentum = false
                }

                if hasMomentum, !hasDirect, ignoreMomentum {
                    return handleMomentum(event, phase: momentumPhase)
                }
            }

            guard isLocationInsideCapture(event) else { return event }

            if event.type == .rightMouseDown {
                onTwoFingerTap()
                return nil
            }

            if event.type == .scrollWheel {
                return handleScroll(event)
            }

            return event
        }

        private func belongsToCaptureSession(_ event: NSEvent) -> Bool {
            guard isEnabled else { return false }
            guard let view = captureView, let window = view.window else { return false }
            return event.window === window
        }

        private func isLocationInsideCapture(_ event: NSEvent) -> Bool {
            guard let view = captureView else { return false }
            let location = view.convert(event.locationInWindow, from: nil)
            return view.bounds.contains(location)
        }

        private func validatedCaptureSize() -> CGSize? {
            guard let view = captureView else { return nil }
            let size = view.bounds.size
            guard size.width > 0, size.height > 0 else { return nil }
            return size
        }

        private func handleScroll(_ event: NSEvent) -> NSEvent? {
            guard event.hasPreciseScrollingDeltas else { return event }

            let directPhase = event.phase
            let momentumPhase = event.momentumPhase
            let hasDirect = !directPhase.isEmpty
            let hasMomentum = !momentumPhase.isEmpty
            guard hasDirect || hasMomentum else { return event }

            if hasMomentum && !hasDirect {
                return handleMomentum(event, phase: momentumPhase)
            }

            return handleDirect(event, phase: directPhase)
        }

        private func handleMomentum(_ event: NSEvent, phase: NSEvent.Phase) -> NSEvent? {
            guard ignoreMomentum else { return event }

            if phase.contains(.ended) || phase.contains(.cancelled) {
                ignoreMomentum = false
            }
            return nil
        }

        private func handleDirect(_ event: NSEvent, phase: NSEvent.Phase) -> NSEvent? {
            if phase.contains(.began) {
                ignoreMomentum = false
                guard let captureSize = validatedCaptureSize() else { return event }
                beginTouch(at: event.timestamp, captureSize: captureSize)
                applyNonzeroDelta(from: event)
                return nil
            }

            if phase.contains(.changed) {
                if !isTouchActive {
                    ignoreMomentum = false
                    guard let captureSize = validatedCaptureSize() else { return event }
                    beginTouch(at: event.timestamp, captureSize: captureSize)
                }
                applyNonzeroDelta(from: event)
                return nil
            }

            if phase.contains(.ended) {
                guard isTouchActive else { return event }
                applyNonzeroDelta(from: event)
                completeDirectTouch(velocity: motion.velocity)
                return nil
            }

            if phase.contains(.cancelled) {
                guard isTouchActive else { return event }
                completeDirectTouch(velocity: .zero)
                return nil
            }

            return event
        }

        private func beginTouch(at timestamp: TimeInterval, captureSize: CGSize) {
            if isTouchActive {
                endTouch(velocity: .zero)
            }
            motion.begin(at: timestamp)
            isTouchActive = true
            onTouchBegan(captureSize)
        }

        private func applyNonzeroDelta(from event: NSEvent) {
            let delta = RemoteTrackpadMotion.physicalTranslationDelta(
                scrollingDeltaX: event.scrollingDeltaX,
                scrollingDeltaY: event.scrollingDeltaY,
                isDirectionInvertedFromDevice: event.isDirectionInvertedFromDevice
            )
            guard delta != .zero else { return }
            motion.append(delta: delta, at: event.timestamp)
            onTouchMoved(motion.translation)
        }

        private func completeDirectTouch(velocity: CGPoint) {
            guard isTouchActive else { return }
            endTouch(velocity: velocity)
            ignoreMomentum = true
        }

        private func endTouch(velocity: CGPoint) {
            guard isTouchActive else { return }
            isTouchActive = false
            onTouchEnded(motion.translation, velocity)
        }

        private func finishActiveTouchIfNeeded() {
            endTouch(velocity: .zero)
            ignoreMomentum = false
        }
    }

    private final class CaptureView: NSView {
        override var isOpaque: Bool { false }
        override var acceptsFirstResponder: Bool { false }

        override func hitTest(_ point: NSPoint) -> NSView? {
            nil
        }
    }
}
