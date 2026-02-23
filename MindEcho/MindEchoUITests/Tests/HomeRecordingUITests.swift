import XCTest

final class HomeRecordingUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--mock-recorder", "--mock-transcription"]
        app.resetAuthorizationStatus(for: .microphone)
        addUIInterruptionMonitor(withDescription: "Microphone Permission") { alert in
            let allowButton = alert.buttons["Allow"]
            if allowButton.exists {
                allowButton.tap()
                return true
            }
            // Japanese localized
            let allowButtonJa = alert.buttons["許可"]
            if allowButtonJa.exists {
                allowButtonJa.tap()
                return true
            }
            return false
        }
    }

    @MainActor
    func testRecordingModalFlow() throws {
        app.launch()

        // 1. Assert home.recordButton exists
        let recordBtn = app.buttons["home.recordButton"]
        XCTAssertTrue(recordBtn.waitForExistence(timeout: 5))

        // 2. Tap home.recordButton → modal opens + recording starts
        recordBtn.tap()
        // Trigger interrupt monitor for microphone permission alert
        app.tap()

        // 3. Assert modal recording elements exist
        XCTAssertTrue(app.staticTexts["recording.duration"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.otherElements["recording.waveform"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["recording.pauseButton"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["recording.stopButton"].waitForExistence(timeout: 5))

        // 4. Tap pause
        app.buttons["recording.pauseButton"].tap()
        XCTAssertTrue(app.buttons["recording.resumeButton"].waitForExistence(timeout: 5))

        // 5. Tap resume
        app.buttons["recording.resumeButton"].tap()
        XCTAssertTrue(app.buttons["recording.pauseButton"].waitForExistence(timeout: 5))

        // 6. Tap stop → transcription starts
        app.buttons["recording.stopButton"].tap()

        // 7. Assert transcription result is shown
        let transcriptionResult = app.staticTexts["recording.transcriptionResult"]
        XCTAssertTrue(transcriptionResult.waitForExistence(timeout: 10))

        // 8. Dismiss modal by swiping down
        app.swipeDown()

        // 9. Assert first recording row exists in home list
        let recordingRow1 = app.descendants(matching: .any)["home.recordingRow.1"]
        XCTAssertTrue(recordingRow1.waitForExistence(timeout: 5))

        // 10. Second recording - wait for button to be hittable after layout update from recording row being added
        XCTAssertTrue(recordBtn.waitForExistence(timeout: 5))
        let hittableExpectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "isHittable == true"),
            object: recordBtn
        )
        wait(for: [hittableExpectation], timeout: 5.0)
        recordBtn.tap()

        XCTAssertTrue(app.buttons["recording.stopButton"].waitForExistence(timeout: 10))
        app.buttons["recording.stopButton"].tap()

        XCTAssertTrue(app.staticTexts["recording.transcriptionResult"].waitForExistence(timeout: 10))

        // 11. Dismiss second modal
        app.swipeDown()

        // 12. Assert both recording rows exist
        XCTAssertTrue(app.descendants(matching: .any)["home.recordingRow.1"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.descendants(matching: .any)["home.recordingRow.2"].waitForExistence(timeout: 5))
    }
}
