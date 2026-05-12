import AppIntents
import Foundation
import UIKit

enum QuickRecordDestination: String, AppEnum {
    case quickRecord

    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "MindEcho")
    static let caseDisplayRepresentations: [QuickRecordDestination: DisplayRepresentation] = [
        .quickRecord: DisplayRepresentation(title: "クイック録音", image: .init(systemName: "mic.fill"))
    ]
}

struct QuickRecordIntent: OpenIntent, @preconcurrency UISceneAppIntent {
    static let title: LocalizedStringResource = "クイック録音"
    static let persistentIdentifier = "com.syhash.MindEcho.quickRecordIntent"

    @Parameter(title: "Destination")
    var target: QuickRecordDestination

    init() {
        target = .quickRecord
    }

    init(target: QuickRecordDestination) {
        self.target = target
    }

    @MainActor
    func performNavigation(forScene scene: UIScene) {
        QuickRecordLaunchRouter.shared.requestQuickRecord()
    }
}

@MainActor
final class QuickRecordLaunchRouter {
    static let shared = QuickRecordLaunchRouter()
    private var hasPendingRequest = false

    private init() {}

    func requestQuickRecord() {
        hasPendingRequest = true
        NotificationCenter.default.post(name: .quickRecordRequested, object: nil)
    }

    func consumePendingRequest() -> Bool {
        guard hasPendingRequest else { return false }
        hasPendingRequest = false
        return true
    }
}

extension Notification.Name {
    static let quickRecordRequested = Notification.Name("com.syhash.MindEcho.quickRecordRequested")
}
