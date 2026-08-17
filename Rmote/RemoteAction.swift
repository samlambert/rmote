import ItsytvCore

enum RemoteAction: Equatable {
    case up
    case down
    case left
    case right
    case select
    case menu
    case home
    case playPause
    case volumeUp
    case volumeDown
    case power

    var companionButton: CompanionButton {
        switch self {
        case .up: .up
        case .down: .down
        case .left: .left
        case .right: .right
        case .select: .select
        case .menu: .menu
        case .home: .home
        case .playPause: .playPause
        case .volumeUp: .volumeUp
        case .volumeDown: .volumeDown
        case .power: .sleep
        }
    }
}
