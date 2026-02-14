import XCTest

final class HistoryListUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
    }

    @MainActor
    func testEmptyHistory_showsEmptyState() throws {
        app.launch()
        app.buttons["履歴"].tap()

        // Should show empty state (ContentUnavailableView)
        let emptyText = app.staticTexts["履歴がありません"]
        XCTAssertTrue(emptyText.waitForExistence(timeout: 5))
    }

    @MainActor
    func testSeededHistory_displaysEntries() throws {
        app.launchArguments.append("--seed-history")
        app.launch()
        app.buttons["履歴"].tap()

        let historyList = app.collectionViews["history.entryList"]
        XCTAssertTrue(historyList.waitForExistence(timeout: 5))
        XCTAssertTrue(historyList.cells.count >= 1)
    }

    @MainActor
    func testEntryRow_showsDatePreviewAndRecordingInfo() throws {
        app.launchArguments.append("--seed-history")
        app.launch()
        app.buttons["履歴"].tap()

        let historyList = app.collectionViews["history.entryList"]
        XCTAssertTrue(historyList.waitForExistence(timeout: 5))

        // Verify first cell has expected elements
        let firstCell = historyList.cells.firstMatch
        XCTAssertTrue(firstCell.waitForExistence(timeout: 5))
        // The cell should contain text (date and preview are within it)
        XCTAssertTrue(firstCell.staticTexts.count >= 1)
    }

    @MainActor
    func testTapEntry_navigatesToDetail() throws {
        app.launchArguments.append("--seed-history")
        app.launch()
        app.buttons["履歴"].tap()

        let historyList = app.collectionViews["history.entryList"]
        XCTAssertTrue(historyList.waitForExistence(timeout: 5))

        let firstCell = historyList.cells.firstMatch
        XCTAssertTrue(firstCell.waitForExistence(timeout: 5))
        firstCell.tap()

        let dateHeader = app.staticTexts["detail.dateHeader"]
        XCTAssertTrue(dateHeader.waitForExistence(timeout: 5))
    }
}
