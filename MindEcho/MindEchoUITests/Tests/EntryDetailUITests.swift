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
    func testDetailView_showsDateAndRecordingsList() throws {
        navigateToDetail()

        let dateHeader = app.staticTexts["detail.dateHeader"]
        XCTAssertTrue(dateHeader.waitForExistence(timeout: 5))

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
    func testShareButton_presentsActivitySheet() throws {
        navigateToDetail()

        let shareBtn = app.buttons["detail.shareButton"]
        XCTAssertTrue(shareBtn.waitForExistence(timeout: 5))
        shareBtn.tap()

        // UIActivityViewController should appear after audio export & merge
        let activityList = app.otherElements["ActivityListView"]
        XCTAssertTrue(activityList.waitForExistence(timeout: 15))
    }

    @MainActor
    func testSwipeToDelete_removesRecording() throws {
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

}
