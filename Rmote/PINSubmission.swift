import Foundation

enum PINSubmission {
    static func sanitizedPIN(_ raw: String) -> String {
        String(raw.filter(\.isNumber).prefix(4))
    }
}
