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

        // Verify recording row is displayed
        XCTAssertTrue(recordingRow.exists)
    }

    @MainActor
    func testShareButton_presentsActivitySheet() throws {
        app.launch()

        // Share button is now in the section header, use descendants query
        let shareBtn = app.descendants(matching: .any).matching(
            NSPredicate(format: "identifier == 'home.shareButton'")
        ).firstMatch
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

        // Share button is now in the section header, use descendants query
        let shareBtn = app.descendants(matching: .any).matching(
            NSPredicate(format: "identifier == 'home.shareButton'")
        ).firstMatch
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
    func testSharePDFButton_presentsActivitySheet() throws {
        app.launch()

        let shareBtn = app.descendants(matching: .any).matching(
            NSPredicate(format: "identifier == 'home.shareButton'")
        ).firstMatch
        XCTAssertTrue(shareBtn.waitForExistence(timeout: 5))
        shareBtn.tap()

        // Share type menu should appear — tap "PDFで共有"
        let pdfBtn = app.buttons["PDFで共有"]
        XCTAssertTrue(pdfBtn.waitForExistence(timeout: 5))
        pdfBtn.tap()

        // UIActivityViewController should appear after PDF export
        let activityList = app.otherElements["ActivityListView"]
        XCTAssertTrue(activityList.waitForExistence(timeout: 15))
    }

    @MainActor
    func testMenuDelete_removesRecording() throws {
        app.launch()

        let recordingRow = app.descendants(matching: .any).matching(
            NSPredicate(format: "identifier == 'home.recordingRow.1'")
        ).firstMatch
        XCTAssertTrue(recordingRow.waitForExistence(timeout: 5))

        // Tap the more button to open context menu
        let moreButton = app.descendants(matching: .any).matching(
            NSPredicate(format: "identifier == 'home.moreButton.1'")
        ).firstMatch
        XCTAssertTrue(moreButton.waitForExistence(timeout: 5))
        moreButton.tap()

        // Tap delete menu item (use identifier predicate for robustness)
        let deleteMenuItem = app.descendants(matching: .any).matching(
            NSPredicate(format: "identifier == 'home.deleteMenuItem.1'")
        ).firstMatch
        XCTAssertTrue(deleteMenuItem.waitForExistence(timeout: 5))
        deleteMenuItem.tap()

        // Recording row should disappear
        let rowGone = NSPredicate(format: "exists == false")
        expectation(for: rowGone, evaluatedWith: recordingRow)
        waitForExpectations(timeout: 5)
    }

    @MainActor
    func testPlayButton_togglesPlaybackState() throws {
        app.launch()

        // Play button should exist
        let playButton = app.descendants(matching: .any).matching(
            NSPredicate(format: "identifier == 'home.playButton.1'")
        ).firstMatch
        XCTAssertTrue(playButton.waitForExistence(timeout: 5))

        // Tap play → should switch to pause button
        playButton.tap()
        let pauseButton = app.descendants(matching: .any).matching(
            NSPredicate(format: "identifier == 'home.pauseButton.1'")
        ).firstMatch
        XCTAssertTrue(pauseButton.waitForExistence(timeout: 5))

        // Tap pause → should switch back to play button
        pauseButton.tap()
        XCTAssertTrue(playButton.waitForExistence(timeout: 5))
    }
}
