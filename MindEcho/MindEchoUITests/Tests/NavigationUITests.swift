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
    func testHomeScreen_showsPastEntrySections() throws {
        app.launchArguments.append("--seed-history")
        app.launch()

        // Should show the today section header
        let dateLabel = app.staticTexts["home.dateLabel"]
        XCTAssertTrue(dateLabel.waitForExistence(timeout: 5))

        // Past entries should appear as sections in the same list
        // Seeded history has 5 past entries with recordings
        let list = app.collectionViews.firstMatch
        XCTAssertTrue(list.waitForExistence(timeout: 5))
        // At least one recording row from past entries should be visible
        XCTAssertTrue(list.cells.count >= 1)
    }
}
