import Foundation
import Observation

@Observable
@MainActor
final class LaunchRouter {
    enum LaunchAction: Equatable {
        case startRecording
    }

    private(set) var pendingAction: LaunchAction?

    func request(_ action: LaunchAction) {
        pendingAction = action
    }

    func consumePendingAction() {
        pendingAction = nil
    }

    func handle(url: URL) {
        guard let action = action(for: url) else { return }
        request(action)
    }

    func action(for url: URL) -> LaunchAction? {
        guard url.scheme?.lowercased() == "mindecho" else { return nil }

        let host = url.host?.lowercased()
        let path = url.path.lowercased()
        if host == "record" || path == "/record" {
            return .startRecording
        }

        return nil
    }
}
