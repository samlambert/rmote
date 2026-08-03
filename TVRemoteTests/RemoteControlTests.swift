import XCTest
@testable import TVRemote
import ItsytvCore

final class RemoteControlTests: XCTestCase {

    func testRemoteActionMapsToCompanionButton() {
        let expectations: [(RemoteAction, CompanionButton)] = [
            (.up, .up),
            (.down, .down),
            (.left, .left),
            (.right, .right),
            (.select, .select),
            (.menu, .menu),
            (.home, .home),
            (.playPause, .playPause),
            (.volumeUp, .volumeUp),
            (.volumeDown, .volumeDown),
            (.power, .sleep),
        ]

        for (action, expected) in expectations {
            XCTAssertEqual(action.companionButton, expected)
        }
    }
}
