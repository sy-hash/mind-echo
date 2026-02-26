import XCTest

final class HistoryListUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
    }

    @MainActor
    func testEmptyState_showsTodaySectionOnly() throws {
        app.launch()

        // Today section header should be visible
        let dateLabel = app.staticTexts["home.dateLabel"]
        XCTAssertTrue(dateLabel.waitForExistence(timeout: 5))

        // Record button should be present
        let recordBtn = app.buttons["home.recordButton"]
        XCTAssertTrue(recordBtn.waitForExistence(timeout: 5))
    }

    @MainActor
    func testSeededHistory_displaysPastRecordings() throws {
        app.launchArguments.append("--seed-history")
        app.launch()

        // Today section header should exist
        let dateLabel = app.staticTexts["home.dateLabel"]
        XCTAssertTrue(dateLabel.waitForExistence(timeout: 5))

        // Past entries should be displayed as sections with recordings
        // Seeded data has recordings with #1 sequence number
        let recordingRow = app.descendants(matching: .any)["home.recordingRow.1"]
        XCTAssertTrue(recordingRow.waitForExistence(timeout: 5))
    }

    @MainActor
    func testSeededHistory_showsDateSectionHeaders() throws {
        app.launchArguments.append("--seed-history")
        app.launch()

        let dateLabel = app.staticTexts["home.dateLabel"]
        XCTAssertTrue(dateLabel.waitForExistence(timeout: 5))

        // The list should have cells from seeded past entries
        let list = app.collectionViews.firstMatch
        XCTAssertTrue(list.waitForExistence(timeout: 5))
        XCTAssertTrue(list.cells.count >= 1)
    }

    @MainActor
    func testSwipeToDelete_removesRecording() throws {
        app.launchArguments.append("--seed-history")
        app.launch()

        // Find a recording row from the seeded data
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
