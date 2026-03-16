import XCTest

final class MonthlyShareUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--seed-multi-month-history"]
    }

    // MARK: - Tests

    /// 月間共有ボタンをタップするとシートが表示される
    @MainActor
    func testMonthlyShareButton_opensSheet() throws {
        app.launch()

        let monthlyShareButton = app.buttons["home.monthlyShareButton"]
        XCTAssertTrue(monthlyShareButton.waitForExistence(timeout: 5))
        monthlyShareButton.tap()

        // シートの閉じるボタンが表示されることを確認
        let closeButton = app.buttons["monthlyShare.closeButton"]
        XCTAssertTrue(closeButton.waitForExistence(timeout: 5))
    }

    /// シートに月リストが表示される
    @MainActor
    func testMonthlyShareSheet_showsAvailableMonths() throws {
        app.launch()

        let monthlyShareButton = app.buttons["home.monthlyShareButton"]
        XCTAssertTrue(monthlyShareButton.waitForExistence(timeout: 5))
        monthlyShareButton.tap()

        // 月行が少なくとも1件表示されること
        let monthRows = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH 'monthlyShare.monthRow.'")
        )
        XCTAssertTrue(monthRows.firstMatch.waitForExistence(timeout: 5))
        XCTAssertGreaterThanOrEqual(monthRows.count, 1)
    }

    /// シートに形式選択行が3件表示される
    @MainActor
    func testMonthlyShareSheet_showsFormatOptions() throws {
        app.launch()

        let monthlyShareButton = app.buttons["home.monthlyShareButton"]
        XCTAssertTrue(monthlyShareButton.waitForExistence(timeout: 5))
        monthlyShareButton.tap()

        // 3つの形式行が表示されること
        let pdfRow = app.buttons["monthlyShare.formatRow.pdf"]
        let audioRow = app.buttons["monthlyShare.formatRow.audio"]
        let textRow = app.buttons["monthlyShare.formatRow.text"]
        XCTAssertTrue(pdfRow.waitForExistence(timeout: 5))
        XCTAssertTrue(audioRow.exists)
        XCTAssertTrue(textRow.exists)
    }

    /// 月を選択すると共有ボタンが有効になる
    @MainActor
    func testMonthlyShare_selectMonth_enablesExportButton() throws {
        app.launch()

        let monthlyShareButton = app.buttons["home.monthlyShareButton"]
        XCTAssertTrue(monthlyShareButton.waitForExistence(timeout: 5))
        monthlyShareButton.tap()

        // 月行が表示されるのを待ってから最初の月を選択
        let monthRows = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH 'monthlyShare.monthRow.'")
        )
        XCTAssertTrue(monthRows.firstMatch.waitForExistence(timeout: 5))
        monthRows.firstMatch.tap()

        // 共有ボタンが有効になること
        let exportButton = app.buttons["monthlyShare.exportButton"]
        XCTAssertTrue(exportButton.waitForExistence(timeout: 5))
        XCTAssertTrue(exportButton.isEnabled)
    }

    /// 閉じるボタンでシートが閉じる
    @MainActor
    func testMonthlyShareSheet_closeButton_dismissesSheet() throws {
        app.launch()

        let monthlyShareButton = app.buttons["home.monthlyShareButton"]
        XCTAssertTrue(monthlyShareButton.waitForExistence(timeout: 5))
        monthlyShareButton.tap()

        let closeButton = app.buttons["monthlyShare.closeButton"]
        XCTAssertTrue(closeButton.waitForExistence(timeout: 5))
        closeButton.tap()

        // シートが閉じてホーム画面に戻ること
        let homeList = app.collectionViews["home.entryList"]
        XCTAssertTrue(homeList.waitForExistence(timeout: 5))
        XCTAssertFalse(closeButton.exists)
    }

    /// 月を選択せずに共有ボタンは無効
    @MainActor
    func testMonthlyShare_noMonthSelected_exportButtonDisabled() throws {
        app.launch()

        let monthlyShareButton = app.buttons["home.monthlyShareButton"]
        XCTAssertTrue(monthlyShareButton.waitForExistence(timeout: 5))
        monthlyShareButton.tap()

        let exportButton = app.buttons["monthlyShare.exportButton"]
        XCTAssertTrue(exportButton.waitForExistence(timeout: 5))
        XCTAssertFalse(exportButton.isEnabled)
    }
}
