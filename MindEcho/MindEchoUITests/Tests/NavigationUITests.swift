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
        // Seed data: 1, 3, 5 days ago → full range shows 5 past sections
        // Should have cells for recordings (3) + empty state rows (2) = at least 5
        XCTAssertTrue(entryList.cells.count >= 5)

        // Verify that dates without entries show empty state
        // Seed data has gaps at 2 and 4 days ago
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
