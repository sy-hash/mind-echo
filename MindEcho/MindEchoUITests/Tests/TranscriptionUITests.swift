import XCTest

final class TranscriptionUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--seed-today-with-recordings", "--mock-transcription", "--mock-summarization"]
    }

    // Helper: find the recording row regardless of its accessibility type.
    // In iOS 26 SwiftUI List cells, elements may not surface as expected types
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
    func testTranscription_dismissSheet() throws {
        app.launch()

        let row = recordingRow()
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.tap()

        let resultText = app.staticTexts["transcription.resultText"]
        XCTAssertTrue(resultText.waitForExistence(timeout: 10))

        // Swipe down on the result text to dismiss the sheet
        resultText.swipeDown(velocity: .fast)

        // Verify we're back on the home screen
        XCTAssertTrue(row.waitForExistence(timeout: 5))
    }
}
