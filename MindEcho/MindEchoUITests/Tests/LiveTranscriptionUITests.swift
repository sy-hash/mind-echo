import XCTest

final class LiveTranscriptionUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = [
            "--uitesting",
            "--mock-recorder",
            "--mock-live-transcription",
            "--mock-transcription",
        ]
        app.resetAuthorizationStatus(for: .microphone)
        addUIInterruptionMonitor(withDescription: "Microphone Permission") { alert in
            let allowButton = alert.buttons["Allow"]
            if allowButton.exists {
                allowButton.tap()
                return true
            }
            let allowButtonJa = alert.buttons["許可"]
            if allowButtonJa.exists {
                allowButtonJa.tap()
                return true
            }
            return false
        }
    }

    @MainActor
    func testLiveTranscription_flowDuringRecording() throws {
        app.launch()

        // 1. Tap record button → modal opens + recording starts
        let recordBtn = app.buttons["home.recordButton"]
        XCTAssertTrue(recordBtn.waitForExistence(timeout: 5))
        recordBtn.tap()
        app.tap()

        // 2. Assert placeholder is shown (initial state)
        let placeholder = app.staticTexts["recording.liveTranscriptionPlaceholder"]
        XCTAssertTrue(placeholder.waitForExistence(timeout: 5))

        // 3. Wait for live transcription text to appear (mock emits after 300ms delays)
        let liveText = app.staticTexts["recording.liveTranscriptionText"]
        XCTAssertTrue(liveText.waitForExistence(timeout: 5))

        // 4. Assert placeholder has disappeared
        XCTAssertFalse(placeholder.exists)

        // 5. Tap stop → recording stops
        app.buttons["recording.stopButton"].tap()

        // 6. Assert live transcription container is gone
        let liveContainer = app.otherElements["recording.liveTranscription"]
        let containerGone = NSPredicate(format: "exists == false")
        expectation(for: containerGone, evaluatedWith: liveContainer)
        waitForExpectations(timeout: 5)

        // 7. Assert post-recording transcription result is shown
        let transcriptionResult = app.staticTexts["recording.transcriptionResult"]
        XCTAssertTrue(transcriptionResult.waitForExistence(timeout: 10))
    }
}
