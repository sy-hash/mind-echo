import XCTest

final class TranscriptionUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--seed-today-with-recordings", "--mock-transcription"]
    }

    @MainActor
    func testTranscribeButton_showsLoadingIndicator() throws {
        app.launch()

        let transcribeButton = app.buttons["home.transcribeButton.1"]
        XCTAssertTrue(transcribeButton.waitForExistence(timeout: 5))
        transcribeButton.tap()

        let loading = app.activityIndicators["transcription.loading"]
        XCTAssertTrue(loading.waitForExistence(timeout: 5))
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

        // Swipe down to dismiss the sheet
        let sheet = app.otherElements["home.transcriptionSheet"]
        sheet.swipeDown()

        // Verify we're back on the home screen
        XCTAssertTrue(transcribeButton.waitForExistence(timeout: 5))
    }
}
