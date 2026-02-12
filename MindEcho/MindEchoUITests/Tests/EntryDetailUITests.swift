import XCTest

final class EntryDetailUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--seed-history"]
    }

    private func navigateToDetail() {
        app.launch()
        app.buttons["履歴"].tap()
        let historyList = app.collectionViews["history.entryList"]
        XCTAssertTrue(historyList.waitForExistence(timeout: 5))
        let firstCell = historyList.cells.firstMatch
        XCTAssertTrue(firstCell.waitForExistence(timeout: 5))
        firstCell.tap()
    }

    @MainActor
    func testDetailView_showsDateAndTextContent() throws {
        navigateToDetail()

        let dateHeader = app.staticTexts["detail.dateHeader"]
        XCTAssertTrue(dateHeader.waitForExistence(timeout: 5))

        let textContent = app.staticTexts["detail.textContent"]
        XCTAssertTrue(textContent.waitForExistence(timeout: 5))
    }

    @MainActor
    func testDetailView_showsRecordingsList() throws {
        navigateToDetail()

        // Verify recording section and content exist
        let sectionHeader = app.staticTexts["録音"]
        XCTAssertTrue(sectionHeader.waitForExistence(timeout: 5))
        let recordingNumber = app.staticTexts["#1"]
        XCTAssertTrue(recordingNumber.exists)
    }

    @MainActor
    func testPlayButton_togglesPlaybackState() throws {
        navigateToDetail()

        // Verify recording row exists
        let recordingRow = app.buttons["detail.recordingRow.1"]
        XCTAssertTrue(recordingRow.waitForExistence(timeout: 5))

        // Tap the recording cell to start playback — icon should change to pause
        recordingRow.tap()
        let pauseImage = app.images["pause.fill"]
        XCTAssertTrue(pauseImage.waitForExistence(timeout: 5))

        // Tap again to stop — icon should change back to play
        recordingRow.tap()
        let playImage = app.images["play.fill"]
        XCTAssertTrue(playImage.waitForExistence(timeout: 5))
    }

    @MainActor
    func testShareTextOption_presentsActivitySheet() throws {
        navigateToDetail()

        let shareBtn = app.buttons["detail.shareButton"]
        XCTAssertTrue(shareBtn.waitForExistence(timeout: 5))
        shareBtn.tap()

        let textOption = app.buttons["テキスト日記"].firstMatch
        XCTAssertTrue(textOption.waitForExistence(timeout: 5))
        textOption.tap()

        // UIActivityViewController should appear after text export
        let activityList = app.otherElements["ActivityListView"]
        XCTAssertTrue(activityList.waitForExistence(timeout: 10))
    }

    @MainActor
    func testShareAudioOption_presentsActivitySheet() throws {
        navigateToDetail()

        let shareBtn = app.buttons["detail.shareButton"]
        XCTAssertTrue(shareBtn.waitForExistence(timeout: 5))
        shareBtn.tap()

        let audioOption = app.buttons["音声ファイル"].firstMatch
        XCTAssertTrue(audioOption.waitForExistence(timeout: 5))
        audioOption.tap()

        // UIActivityViewController should appear after audio export & merge
        let activityList = app.otherElements["ActivityListView"]
        XCTAssertTrue(activityList.waitForExistence(timeout: 15))
    }

    @MainActor
    func testSwipeToDelete_removesRecordingAndHidesSection() throws {
        navigateToDetail()

        // Verify recording section and row exist
        let sectionHeader = app.staticTexts["録音"]
        XCTAssertTrue(sectionHeader.waitForExistence(timeout: 5))
        let recordingRow = app.buttons["detail.recordingRow.1"]
        XCTAssertTrue(recordingRow.waitForExistence(timeout: 5))

        // Swipe left to reveal delete action
        recordingRow.swipeLeft()
        let deleteButton = app.buttons["削除"]
        XCTAssertTrue(deleteButton.waitForExistence(timeout: 5))
        deleteButton.tap()

        // Recording row should disappear
        let rowGone = NSPredicate(format: "exists == false")
        expectation(for: rowGone, evaluatedWith: recordingRow)
        waitForExpectations(timeout: 5)

        // Section header should also disappear since this was the only recording
        XCTAssertFalse(sectionHeader.exists)
    }

    @MainActor
    func testEditText_updatesContent() throws {
        navigateToDetail()

        // Tap text to enter edit mode
        let textContent = app.staticTexts["detail.textContent"]
        XCTAssertTrue(textContent.waitForExistence(timeout: 5))
        textContent.tap()

        // TextEditor should appear (it has the same identifier in edit mode)
        let editor = app.textViews["detail.textContent"]
        XCTAssertTrue(editor.waitForExistence(timeout: 5))

        // Type some text and save
        editor.tap()
        editor.typeText(" 追加テキスト")

        // Tap save button
        app.buttons["保存"].tap()

        // Text should be displayed (static text mode)
        let updatedText = app.staticTexts["detail.textContent"]
        XCTAssertTrue(updatedText.waitForExistence(timeout: 5))
    }
}
