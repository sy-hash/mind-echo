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

        // With sparse seed data (1, 3, 5 days ago) and all-dates display,
        // we should have 5 past sections (1-5 days ago) + today section.
        // Today empty state + 3 recording cells + 2 empty state cells = 6 cells total
        XCTAssertTrue(entryList.cells.count >= 6)

        // Verify empty state exists for a date without recordings (2 days ago)
        let calendar = Calendar.current
        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: Date())!
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyyMMdd"
        let twoDaysAgoTag = formatter.string(from: twoDaysAgo)
        let emptyState = app.staticTexts["past.emptyState.\(twoDaysAgoTag)"]
        XCTAssertTrue(emptyState.waitForExistence(timeout: 5))
    }
}
