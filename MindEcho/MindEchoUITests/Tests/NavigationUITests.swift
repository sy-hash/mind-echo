import XCTest

final class NavigationUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
    }

    @MainActor
    func testAppLaunch_showsHomeScreen() throws {
        app.launch()
        let dateLabel = app.staticTexts["home.dateLabel"]
        XCTAssertTrue(dateLabel.waitForExistence(timeout: 5))
    }

    @MainActor
    func testAppLaunch_showsTodayEmptyState() throws {
        app.launch()
        let emptyState = app.staticTexts["home.emptyState"]
        XCTAssertTrue(emptyState.waitForExistence(timeout: 5))
    }

    @MainActor
    func testSeededHistory_showsPastSections() throws {
        app.launchArguments.append("--seed-history")
        app.launch()

        // Today section should exist
        let dateLabel = app.staticTexts["home.dateLabel"]
        XCTAssertTrue(dateLabel.waitForExistence(timeout: 5))

        // Past entry recordings should be visible in the list
        let entryList = app.collectionViews["home.entryList"]
        XCTAssertTrue(entryList.waitForExistence(timeout: 5))
        // Should have at least today section + past sections
        XCTAssertTrue(entryList.cells.count >= 1)
    }
}
