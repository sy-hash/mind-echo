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
        // Past entries should appear as recording rows + empty state rows
        XCTAssertTrue(entryList.cells.count >= 1)

        // Dates without entries should still have an addButton
        let calendar = Calendar.current
        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: Date())!
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyyMMdd"
        let twoDaysAgoTag = formatter.string(from: twoDaysAgo)
        let addButton = app.buttons["past.addButton.\(twoDaysAgoTag)"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 5))
    }

    @MainActor
    func testEntryRow_showsDatePreviewAndRecordingInfo() throws {
        app.launchArguments.append("--seed-history")
        app.launch()

        let entryList = app.collectionViews["home.entryList"]
        XCTAssertTrue(entryList.waitForExistence(timeout: 5))

        // Past recording rows should contain recording info (sequence number, etc.)
        let firstPastCell = entryList.cells.firstMatch
        XCTAssertTrue(firstPastCell.waitForExistence(timeout: 5))
        XCTAssertTrue(firstPastCell.staticTexts.count >= 1)
    }

}
