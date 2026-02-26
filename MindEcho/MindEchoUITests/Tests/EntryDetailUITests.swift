import XCTest

final class EntryDetailUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--seed-today-with-recordings", "--mock-player"]
    }

    @MainActor
    func testHomeView_showsDateAndRecordingsList() throws {
        app.launch()

        let dateLabel = app.staticTexts["home.dateLabel"]
        XCTAssertTrue(dateLabel.waitForExistence(timeout: 5))

        // Seeded today has 3 recordings
        let recordingRow1 = app.descendants(matching: .any)["home.recordingRow.1"]
        XCTAssertTrue(recordingRow1.waitForExistence(timeout: 5))

        let recordingNumber = app.staticTexts["#1"]
        XCTAssertTrue(recordingNumber.exists)
    }

    @MainActor
    func testPlayButton_togglesPlaybackState() throws {
        app.launch()

        // Verify recording row exists
        let recordingRow = app.descendants(matching: .any)["home.recordingRow.1"]
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
        app.launch()

        let shareBtn = app.buttons["home.shareButton"]
        XCTAssertTrue(shareBtn.waitForExistence(timeout: 5))
        shareBtn.tap()

        // Share type menu should appear — tap "音声を共有"
        let audioBtn = app.buttons["音声を共有"]
        XCTAssertTrue(audioBtn.waitForExistence(timeout: 5))
        audioBtn.tap()

        // UIActivityViewController should appear after audio export & merge
        let activityList = app.otherElements["ActivityListView"]
        XCTAssertTrue(activityList.waitForExistence(timeout: 15))
    }

    @MainActor
    func testShareTranscriptButton_presentsActivitySheet() throws {
        app.launch()

        let shareBtn = app.buttons["home.shareButton"]
        XCTAssertTrue(shareBtn.waitForExistence(timeout: 5))
        shareBtn.tap()

        // Share type menu should appear — tap "テキストを共有"
        let transcriptBtn = app.buttons["テキストを共有"]
        XCTAssertTrue(transcriptBtn.waitForExistence(timeout: 5))
        transcriptBtn.tap()

        // UIActivityViewController should appear after transcript export
        let activityList = app.otherElements["ActivityListView"]
        XCTAssertTrue(activityList.waitForExistence(timeout: 15))
    }

    @MainActor
    func testSwipeToDelete_removesRecording() throws {
        app.launch()

        // Verify recording row exists
        let recordingRow = app.descendants(matching: .any)["home.recordingRow.1"]
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
    }
}
