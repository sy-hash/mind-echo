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

        // Today section should show empty state
        let emptyState = app.staticTexts["home.emptyState"]
        XCTAssertTrue(emptyState.waitForExistence(timeout: 5))
    }

    @MainActor
    func testSeededHistory_displaysEntries() throws {
        app.launchArguments.append("--seed-history")
        app.launch()

        let entryList = app.collectionViews["home.entryList"]
        XCTAssertTrue(entryList.waitForExistence(timeout: 5))
        // Past entries should appear as recording rows
        XCTAssertTrue(entryList.cells.count >= 1)

        // Add button should exist even for dates without recordings (2 days ago in sparse seed)
        let addButtonQuery = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH 'past.addButton.'")
        )
        XCTAssertTrue(addButtonQuery.firstMatch.waitForExistence(timeout: 5))
    }

    @MainActor
    func testEntryRow_showsDatePreviewAndRecordingInfo() throws {
        app.launchArguments.append("--seed-history")
        app.launch()

        let entryList = app.collectionViews["home.entryList"]
        XCTAssertTrue(entryList.waitForExistence(timeout: 5))

        // Past recording rows should contain recording info (time, duration, etc.)
        let firstPastCell = entryList.cells.firstMatch
        XCTAssertTrue(firstPastCell.waitForExistence(timeout: 5))
        XCTAssertTrue(firstPastCell.staticTexts.count >= 1)
    }

}
