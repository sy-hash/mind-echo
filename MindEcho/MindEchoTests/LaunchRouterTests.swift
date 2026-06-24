import Foundation
import Testing

@testable import MindEcho

@MainActor
struct LaunchRouterTests {
    @Test func handleRecordURL_setsPendingStartRecording() {
        let router = LaunchRouter()

        router.handle(url: URL(string: "mindecho://record")!)

        #expect(router.pendingAction == .startRecording)
    }

    @Test func consumePendingAction_clearsAction() {
        let router = LaunchRouter()
        router.request(.startRecording)

        router.consumePendingAction()

        #expect(router.pendingAction == nil)
    }

    @Test func unrelatedURL_isIgnored() {
        let router = LaunchRouter()

        router.handle(url: URL(string: "https://example.com")!)

        #expect(router.pendingAction == nil)
    }
}
