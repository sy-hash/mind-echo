import XCTest

final class TranscriptionUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--seed-today-with-recordings", "--mock-transcription", "--mock-summarization", "--mock-ai-prompt"]
    }

    // Helper: find the recording row regardless of its accessibility type.
    // In iOS 26 SwiftUI List cells, elements may not surface as expected type
    // in XCTest; using descendants with an identifier predicate locates them reliably.
    private func recordingRow(index: Int = 1) -> XCUIElement {
        app.descendants(matching: .any).matching(
            NSPredicate(format: "identifier == 'home.recordingRow.\(index)'")
        ).firstMatch
    }

    @MainActor
    func testRecordingRowTap_opensTranscriptionSheet() throws {
        app.launch()

        let row = recordingRow()
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.tap()

        // Sheet should open and eventually show result text
        let resultText = app.staticTexts["transcription.resultText"]
        XCTAssertTrue(resultText.waitForExistence(timeout: 10))
    }

    @MainActor
    func testTranscription_showsResultText() throws {
        app.launch()

        let row = recordingRow()
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.tap()

        let resultText = app.staticTexts["transcription.resultText"]
        XCTAssertTrue(resultText.waitForExistence(timeout: 10))
        XCTAssertTrue(resultText.label.contains("モックの書き起こし結果"))
    }

    @MainActor
    func testTranscription_showsSummaryAboveResultText() throws {
        app.launch()

        let row = recordingRow()
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.tap()

        // Summary text should appear above the transcription result
        let summaryText = app.staticTexts["transcription.summaryText"]
        XCTAssertTrue(summaryText.waitForExistence(timeout: 10))
        XCTAssertTrue(summaryText.label.contains("モックの要約結果"))

        // Result text should also be visible
        let resultText = app.staticTexts["transcription.resultText"]
        XCTAssertTrue(resultText.waitForExistence(timeout: 5))
    }

    @MainActor
    func testAIPrompt_customPrompt_showsResult() throws {
        app.launch()

        let row = recordingRow()
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.tap()

        // Wait for transcription result
        let resultText = app.staticTexts["transcription.resultText"]
        XCTAssertTrue(resultText.waitForExistence(timeout: 10))

        // Enter prompt text
        let promptField = app.textFields["transcription.promptField"]
        XCTAssertTrue(promptField.waitForExistence(timeout: 5))
        promptField.tap()
        promptField.typeText("要約して")

        // Tap apply button
        let applyButton = app.buttons["transcription.applyButton"]
        XCTAssertTrue(applyButton.waitForExistence(timeout: 5))
        applyButton.tap()

        // AI result text should appear
        let aiResultText = app.staticTexts["transcription.aiResultText"]
        XCTAssertTrue(aiResultText.waitForExistence(timeout: 10))
        XCTAssertTrue(aiResultText.label.contains("モックのAI適用結果"))

        // Segmented picker should be visible
        let tabPicker = app.segmentedControls["transcription.tabPicker"]
        XCTAssertTrue(tabPicker.waitForExistence(timeout: 5))
    }

    @MainActor
    func testAIPrompt_tabSwitching() throws {
        app.launch()

        let row = recordingRow()
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.tap()

        // Wait for transcription result
        let resultText = app.staticTexts["transcription.resultText"]
        XCTAssertTrue(resultText.waitForExistence(timeout: 10))

        // Enter prompt and apply
        let promptField = app.textFields["transcription.promptField"]
        XCTAssertTrue(promptField.waitForExistence(timeout: 5))
        promptField.tap()
        promptField.typeText("要約して")

        let applyButton = app.buttons["transcription.applyButton"]
        applyButton.tap()

        // Wait for AI result
        let aiResultText = app.staticTexts["transcription.aiResultText"]
        XCTAssertTrue(aiResultText.waitForExistence(timeout: 10))

        // Switch to original tab
        let tabPicker = app.segmentedControls["transcription.tabPicker"]
        XCTAssertTrue(tabPicker.waitForExistence(timeout: 5))
        tabPicker.buttons["原文"].tap()

        // Original text should be visible
        XCTAssertTrue(resultText.waitForExistence(timeout: 5))

        // Switch back to AI result tab
        tabPicker.buttons["AI結果"].tap()

        // AI result text should be visible again
        XCTAssertTrue(aiResultText.waitForExistence(timeout: 5))

        // Switch to original again to confirm it still works
        tabPicker.buttons["原文"].tap()
        XCTAssertTrue(resultText.waitForExistence(timeout: 5))
    }

    @MainActor
    func testTranscription_dismissSheet() throws {
        app.launch()

        let row = recordingRow()
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.tap()

        let resultText = app.staticTexts["transcription.resultText"]
        XCTAssertTrue(resultText.waitForExistence(timeout: 10))

        // Tap the close button to dismiss the sheet
        let closeButton = app.buttons["transcription.closeButton"]
        XCTAssertTrue(closeButton.waitForExistence(timeout: 5))
        closeButton.tap()

        // Wait until the transcription sheet is actually dismissed
        let doesNotExistPredicate = NSPredicate(format: "exists == false")
        expectation(for: doesNotExistPredicate, evaluatedWith: resultText, handler: nil)
        waitForExpectations(timeout: 5)

        // Verify we're back on the home screen
        XCTAssertTrue(row.waitForExistence(timeout: 5))
    }
}
