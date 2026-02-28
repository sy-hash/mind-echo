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

    @MainActor
    func testPastRecording_playToggle() throws {
        app.launchArguments.append(contentsOf: ["--seed-history", "--mock-player"])
        app.launch()

        let entryList = app.collectionViews["home.entryList"]
        XCTAssertTrue(entryList.waitForExistence(timeout: 5))

        // Find a past recording row using a broad descendant search so the query
        // succeeds regardless of which element type (cell vs other) holds the identifier.
        let pastRecordingRow = app.descendants(matching: .any).matching(
            NSPredicate(format: "identifier BEGINSWITH 'past.recordingRow.'")
        ).firstMatch
        XCTAssertTrue(pastRecordingRow.waitForExistence(timeout: 5))
        pastRecordingRow.tap()

        // Row identifier gains a .playing suffix while playback is active
        let playingRow = app.descendants(matching: .any).matching(
            NSPredicate(format: "identifier BEGINSWITH 'past.recordingRow.' AND identifier ENDSWITH '.playing'")
        ).firstMatch
        XCTAssertTrue(playingRow.waitForExistence(timeout: 5))
    }
}
