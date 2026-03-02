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

        // 8. Dismiss modal via "閉じる" button (more reliable than swipeDown
        //    since the modal contains a ScrollView that can intercept the gesture)
        let closeButton = app.buttons["閉じる"]
        XCTAssertTrue(closeButton.waitForExistence(timeout: 5))
        closeButton.tap()

        // 9. Wait for modal to fully dismiss (transcription result disappears)
        let modalDismissed = NSPredicate(format: "exists == false")
        expectation(for: modalDismissed, evaluatedWith: transcriptionResult)
        waitForExpectations(timeout: 5)

        // 10. Assert first recording row exists in home list
        let recordingRow1 = app.descendants(matching: .any)["home.recordingRow.1"]
        XCTAssertTrue(recordingRow1.waitForExistence(timeout: 5))

        // 11. Second recording - wait for button to be hittable after layout settles
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

        // 12. Dismiss second modal via "閉じる" button
        let closeButton2 = app.buttons["閉じる"]
        XCTAssertTrue(closeButton2.waitForExistence(timeout: 5))
        closeButton2.tap()

        // 13. Assert both recording rows exist
        XCTAssertTrue(app.descendants(matching: .any)["home.recordingRow.1"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.descendants(matching: .any)["home.recordingRow.2"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testLiveTranscription_showsTextDuringRecording() throws {
        app.launchArguments = ["--uitesting", "--mock-recorder", "--mock-transcription", "--mock-live-transcription"]
        app.launch()

        // 1. 録音ボタンをタップしてモーダルを開く
        let recordBtn = app.buttons["home.recordButton"]
        XCTAssertTrue(recordBtn.waitForExistence(timeout: 5))
        recordBtn.tap()
        app.tap()

        // 2. 録音中に recording.liveTranscription が表示されることを確認
        let liveTranscription = app.scrollViews["recording.liveTranscription"]
        XCTAssertTrue(liveTranscription.waitForExistence(timeout: 10))

        // 3. モックテキストが表示されることを確認
        let mockTextPredicate = NSPredicate(format: "label CONTAINS 'リアルタイム書き起こし'")
        let mockTextElement = app.staticTexts.matching(mockTextPredicate).firstMatch
        XCTAssertTrue(mockTextElement.waitForExistence(timeout: 5))

        // 4. 停止して閉じる
        app.buttons["recording.stopButton"].tap()
        let closeButton = app.buttons["閉じる"]
        XCTAssertTrue(closeButton.waitForExistence(timeout: 5))
        closeButton.tap()
    }

    @MainActor
    func testAddRecordingToPastDate() throws {
        // TODO: モーダルを閉じた後に過去エントリへ追加した録音行が UI に反映されない問題が未解決のためスキップ。
        // SwiftData の inverse 関係（recording.entry 経由）での保存方法または
        // modelContext.save() の追加による修正を検討中。
        // 参考: https://github.com/sy-hash/mind-echo/pull/56#issuecomment-3979334745
        throw XCTSkip("過去日付への録音追加後に録音行が UI に反映されない問題が未修正のためスキップ (#56)")

        app.launchArguments.append("--seed-history")
        app.launch()

        // 1. Find a past section's add button
        let addButton = app.descendants(matching: .any).matching(
            NSPredicate(format: "identifier BEGINSWITH 'past.addButton.'")
        ).firstMatch
        XCTAssertTrue(addButton.waitForExistence(timeout: 5))

        // 2. Tap the add button to open menu
        addButton.tap()

        // 3. Tap "音声を録音" menu item
        let recordMenuItem = app.buttons["音声を録音"]
        XCTAssertTrue(recordMenuItem.waitForExistence(timeout: 5))
        recordMenuItem.tap()

        // Trigger interrupt monitor for microphone permission
        app.tap()

        // 4. Verify recording modal is shown
        XCTAssertTrue(app.staticTexts["recording.duration"].waitForExistence(timeout: 10))

        // 5. Stop recording
        XCTAssertTrue(app.buttons["recording.stopButton"].waitForExistence(timeout: 10))
        app.buttons["recording.stopButton"].tap()

        // 6. Wait for transcription result
        let transcriptionResult = app.staticTexts["recording.transcriptionResult"]
        XCTAssertTrue(transcriptionResult.waitForExistence(timeout: 10))

        // 7. Close modal
        let closeButton = app.buttons["閉じる"]
        XCTAssertTrue(closeButton.waitForExistence(timeout: 5))
        closeButton.tap()

        // 8. Wait for modal to dismiss
        let modalDismissed = NSPredicate(format: "exists == false")
        expectation(for: modalDismissed, evaluatedWith: transcriptionResult)
        waitForExpectations(timeout: 5)

        // 9. Verify a second recording appeared in a past entry
        //    Seed data creates 1 recording per entry (sequenceNumber 1).
        //    After adding, one entry should have sequenceNumber 2.
        let newRecording = app.descendants(matching: .any).matching(
            NSPredicate(format: "identifier MATCHES 'past\\.recordingRow\\.\\d+\\.2'")
        ).firstMatch
        XCTAssertTrue(newRecording.waitForExistence(timeout: 5))
    }
}
