import XCTest

final class NavigationUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
    }

    @MainActor
    func testAppLaunch_showsHomeTab() throws {
        app.launch()
        let dateLabel = app.staticTexts["home.dateLabel"]
        XCTAssertTrue(dateLabel.waitForExistence(timeout: 5))
    }

    @MainActor
    func testTabSwitching_navigatesBetweenTodayAndHistory() throws {
        app.launchArguments.append("--seed-history")
        app.launch()

        // Switch to history tab
        app.buttons["tab.history"].tap()
        let historyList = app.collectionViews["history.entryList"]
        XCTAssertTrue(historyList.waitForExistence(timeout: 5))

        // Switch back to today tab
        app.buttons["tab.today"].tap()
        let dateLabel = app.staticTexts["home.dateLabel"]
        XCTAssertTrue(dateLabel.waitForExistence(timeout: 5))
    }

    @MainActor
    func testHistoryToDetail_pushesAndPops() throws {
        app.launchArguments.append("--seed-history")
        app.launch()

        // Go to history
        app.buttons["tab.history"].tap()
        let historyList = app.collectionViews["history.entryList"]
        XCTAssertTrue(historyList.waitForExistence(timeout: 5))

        // Tap first entry to push detail
        let firstCell = historyList.cells.firstMatch
        XCTAssertTrue(firstCell.waitForExistence(timeout: 5))
        firstCell.tap()

        // Verify detail view
        let dateHeader = app.staticTexts["detail.dateHeader"]
        XCTAssertTrue(dateHeader.waitForExistence(timeout: 5))

        // Pop back
        app.navigationBars.buttons.firstMatch.tap()
        XCTAssertTrue(historyList.waitForExistence(timeout: 5))
    }
}
