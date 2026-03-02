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

        // 1. Tap home.recordButton → modal opens and recording starts
        let recordBtn = app.buttons["home.recordButton"]
        XCTAssertTrue(recordBtn.waitForExistence(timeout: 5))
        recordBtn.tap()
        app.tap()

        // 2. Confirm placeholder is shown (initial state)
        let placeholder = app.staticTexts["recording.liveTranscriptionPlaceholder"]
        XCTAssertTrue(placeholder.waitForExistence(timeout: 5))

        // 3. Wait for transcription text to appear (mock yields text after ~300ms each)
        let liveText = app.staticTexts["recording.liveTranscriptionText"]
        XCTAssertTrue(liveText.waitForExistence(timeout: 5))

        // 4. Confirm placeholder has disappeared
        XCTAssertFalse(placeholder.exists)

        // 5. Tap stop button → recording stops
        let stopButton = app.buttons["recording.stopButton"]
        XCTAssertTrue(stopButton.waitForExistence(timeout: 5))
        stopButton.tap()

        // 6. Confirm live transcription area is gone after recording stops
        let liveTranscriptionContainer = app.scrollViews["recording.liveTranscription"]
        let containerGone = NSPredicate(format: "exists == false")
        expectation(for: containerGone, evaluatedWith: liveTranscriptionContainer)
        waitForExpectations(timeout: 5)

        // 7. Confirm post-recording transcription result is shown
        let transcriptionResult = app.staticTexts["recording.transcriptionResult"]
        XCTAssertTrue(transcriptionResult.waitForExistence(timeout: 10))
    }
}
