import XCTest

final class HomeRecordingUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
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
    func testInitialState_showsRecordButtonOnly() throws {
        app.launch()
        let recordBtn = app.buttons["home.recordButton"]
        XCTAssertTrue(recordBtn.waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["home.pauseButton"].exists)
        XCTAssertFalse(app.buttons["home.stopButton"].exists)
        XCTAssertFalse(app.buttons["home.resumeButton"].exists)
    }

    @MainActor
    func testStartRecording_showsPauseAndStopButtons() throws {
        app.launch()
        app.buttons["home.recordButton"].tap()
        // Trigger interrupt monitor for permission alert
        app.tap()

        let pauseBtn = app.buttons["home.pauseButton"]
        XCTAssertTrue(pauseBtn.waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["home.stopButton"].exists)
        XCTAssertFalse(app.buttons["home.recordButton"].exists)
    }

    @MainActor
    func testPauseRecording_showsResumeButton() throws {
        app.launch()
        app.buttons["home.recordButton"].tap()
        app.tap()

        let pauseBtn = app.buttons["home.pauseButton"]
        XCTAssertTrue(pauseBtn.waitForExistence(timeout: 10))
        pauseBtn.tap()

        let resumeBtn = app.buttons["home.resumeButton"]
        XCTAssertTrue(resumeBtn.waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["home.stopButton"].exists)
        XCTAssertFalse(app.buttons["home.pauseButton"].exists)
    }

    @MainActor
    func testStopRecording_addsRecordingToList() throws {
        app.launch()
        app.buttons["home.recordButton"].tap()
        app.tap()

        let stopBtn = app.buttons["home.stopButton"]
        XCTAssertTrue(stopBtn.waitForExistence(timeout: 10))
        stopBtn.tap()

        // After stopping, record button should reappear
        let recordBtn = app.buttons["home.recordButton"]
        XCTAssertTrue(recordBtn.waitForExistence(timeout: 5))

        // A recording should be added to the list
        let recordingRow = app.descendants(matching: .any)["home.recordingRow.1"]
        XCTAssertTrue(recordingRow.waitForExistence(timeout: 5))
    }

    @MainActor
    func testMultipleRecordings_appearInOrder() throws {
        app.launch()

        // First recording
        app.buttons["home.recordButton"].tap()
        app.tap()
        let stopBtn1 = app.buttons["home.stopButton"]
        XCTAssertTrue(stopBtn1.waitForExistence(timeout: 10))
        stopBtn1.tap()

        // Wait for record button to reappear
        let recordBtn = app.buttons["home.recordButton"]
        XCTAssertTrue(recordBtn.waitForExistence(timeout: 5))

        // Second recording
        recordBtn.tap()
        let stopBtn2 = app.buttons["home.stopButton"]
        XCTAssertTrue(stopBtn2.waitForExistence(timeout: 5))
        stopBtn2.tap()

        // Both recordings should be in the list
        XCTAssertTrue(app.buttons["home.recordButton"].waitForExistence(timeout: 5))
        let row1 = app.descendants(matching: .any)["home.recordingRow.1"]
        let row2 = app.descendants(matching: .any)["home.recordingRow.2"]
        XCTAssertTrue(row1.waitForExistence(timeout: 5))
        XCTAssertTrue(row2.waitForExistence(timeout: 5))
    }
}
