import XCTest
@testable import TVRemote

final class RemoteTrackpadGestureTests: XCTestCase {

    func testPhysicalTranslationDeltaNonInverted() {
        let delta = RemoteTrackpadMotion.physicalTranslationDelta(
            scrollingDeltaX: 3,
            scrollingDeltaY: 4,
            isDirectionInvertedFromDevice: false
        )

        XCTAssertEqual(delta.x, -3)
        XCTAssertEqual(delta.y, -4)
    }

    func testPhysicalTranslationDeltaInverted() {
        let delta = RemoteTrackpadMotion.physicalTranslationDelta(
            scrollingDeltaX: 3,
            scrollingDeltaY: 4,
            isDirectionInvertedFromDevice: true
        )

        XCTAssertEqual(delta.x, 3)
        XCTAssertEqual(delta.y, 4)
    }

    func testAppendAccumulatesTranslation() {
        var motion = RemoteTrackpadMotion()
        motion.begin(at: 1)
        motion.append(delta: CGPoint(x: 3, y: 4), at: 1.1)
        motion.append(delta: CGPoint(x: 1, y: -2), at: 1.2)

        XCTAssertEqual(motion.translation.x, 4)
        XCTAssertEqual(motion.translation.y, 2)
    }

    func testAppendCalculatesVelocityFromTimestamps() {
        var motion = RemoteTrackpadMotion()
        motion.begin(at: 1)
        motion.append(delta: CGPoint(x: 10, y: 20), at: 1.5)

        XCTAssertEqual(motion.velocity.x, 20, accuracy: 0.0001)
        XCTAssertEqual(motion.velocity.y, 40, accuracy: 0.0001)
    }

    func testVelocityIsZeroBeforeValidElapsedInterval() {
        var motion = RemoteTrackpadMotion()
        XCTAssertEqual(motion.velocity, .zero)

        motion.begin(at: 1)
        XCTAssertEqual(motion.velocity, .zero)

        motion.append(delta: CGPoint(x: 10, y: -4), at: 1)
        XCTAssertEqual(motion.velocity, .zero)

        motion.append(delta: CGPoint(x: 8, y: 2), at: 0.5)
        XCTAssertEqual(motion.velocity, .zero)
    }
}
