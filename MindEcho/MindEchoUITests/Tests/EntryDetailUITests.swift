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

        // Use descendants query to find the row regardless of its accessibility type
        // (iOS 26 SwiftUI List may surface the identifier on a non-Cell element)
        let recordingRow = app.descendants(matching: .any).matching(
            NSPredicate(format: "identifier == 'home.recordingRow.1'")
        ).firstMatch
        XCTAssertTrue(recordingRow.waitForExistence(timeout: 5))

        // Verify recording info exists
        let recordingNumber = app.staticTexts["#1"]
        XCTAssertTrue(recordingNumber.exists)
    }

    @MainActor
    func testPlayButton_togglesPlaybackState() throws {
        app.launch()

        // Use descendants query: in iOS 26 SwiftUI List the identifier may appear
        // on a non-Cell element; descendants finds it regardless of type.
        let recordingRow = app.descendants(matching: .any).matching(
            NSPredicate(format: "identifier == 'home.recordingRow.1'")
        ).firstMatch
        XCTAssertTrue(recordingRow.waitForExistence(timeout: 5))
        recordingRow.tap()

        // The button exposes play state via accessibilityValue ("playing" / "paused").
        // Polling the value of the existing element is more reliable than waiting
        // for a new element to appear in iOS 26 SwiftUI List.
        let playingExpectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "value == 'playing'"),
            object: recordingRow
        )
        wait(for: [playingExpectation], timeout: 5)

        // Tap the same row button again to pause.
        recordingRow.tap()

        // accessibilityValue should revert to "paused".
        let pausedExpectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "value == 'paused'"),
            object: recordingRow
        )
        wait(for: [pausedExpectation], timeout: 5)
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

        // Use descendants query: in iOS 26 SwiftUI List the identifier may appear
        // on a non-Cell element; descendants finds it regardless of type.
        let recordingRow = app.descendants(matching: .any).matching(
            NSPredicate(format: "identifier == 'home.recordingRow.1'")
        ).firstMatch
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
