import XCTest

final class TranscriptionUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--seed-today-with-recordings", "--mock-transcription"]
    }

    @MainActor
    func testTranscribeButton_opensTranscriptionSheet() throws {
        app.launch()

        let transcribeButton = app.buttons["home.transcribeButton.1"]
        XCTAssertTrue(transcribeButton.waitForExistence(timeout: 5))
        transcribeButton.tap()

        // Sheet should open and eventually show result text
        let resultText = app.staticTexts["transcription.resultText"]
        XCTAssertTrue(resultText.waitForExistence(timeout: 10))
    }

    @MainActor
    func testTranscription_showsResultText() throws {
        app.launch()

        let transcribeButton = app.buttons["home.transcribeButton.1"]
        XCTAssertTrue(transcribeButton.waitForExistence(timeout: 5))
        transcribeButton.tap()

        let resultText = app.staticTexts["transcription.resultText"]
        XCTAssertTrue(resultText.waitForExistence(timeout: 10))
        XCTAssertTrue(resultText.label.contains("モックの書き起こし結果"))
    }

    @MainActor
    func testTranscription_dismissSheet() throws {
        app.launch()

        let transcribeButton = app.buttons["home.transcribeButton.1"]
        XCTAssertTrue(transcribeButton.waitForExistence(timeout: 5))
        transcribeButton.tap()

        let resultText = app.staticTexts["transcription.resultText"]
        XCTAssertTrue(resultText.waitForExistence(timeout: 10))

        // Swipe down on the result text to dismiss the sheet
        resultText.swipeDown(velocity: .fast)

        // After transcription completes, the text is persisted to the Recording model.
        // The transcribe button should be replaced by a transcription preview.
        let transcriptionPreview = app.staticTexts["home.transcriptionPreview.1"]
        XCTAssertTrue(transcriptionPreview.waitForExistence(timeout: 5))
    }
}
