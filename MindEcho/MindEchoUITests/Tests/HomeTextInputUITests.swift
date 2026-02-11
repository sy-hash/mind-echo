import XCTest

final class HomeTextInputUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
    }

    @MainActor
    func testTapTextButton_opensTextEditorSheet() throws {
        app.launch()
        let textBtn = app.buttons["home.textInputButton"]
        XCTAssertTrue(textBtn.waitForExistence(timeout: 5))
        textBtn.tap()

        let editor = app.textViews["home.textEditor"]
        XCTAssertTrue(editor.waitForExistence(timeout: 5))
    }

    @MainActor
    func testSaveText_dismissesSheet() throws {
        app.launch()
        app.buttons["home.textInputButton"].tap()

        let editor = app.textViews["home.textEditor"]
        XCTAssertTrue(editor.waitForExistence(timeout: 5))
        editor.tap()
        editor.typeText("テスト入力")

        app.buttons["home.textSaveButton"].tap()

        // Sheet should dismiss - editor should not exist
        XCTAssertTrue(app.buttons["home.textInputButton"].waitForExistence(timeout: 5))
        XCTAssertFalse(editor.exists)
    }

    @MainActor
    func testCancelText_dismissesWithoutSaving() throws {
        app.launch()
        app.buttons["home.textInputButton"].tap()

        let editor = app.textViews["home.textEditor"]
        XCTAssertTrue(editor.waitForExistence(timeout: 5))
        editor.tap()
        editor.typeText("テスト")

        app.buttons["home.textCancelButton"].tap()

        // Sheet should dismiss
        XCTAssertTrue(app.buttons["home.textInputButton"].waitForExistence(timeout: 5))
        XCTAssertFalse(editor.exists)
    }

    @MainActor
    func testEditExistingText_opensWithPreviousContent() throws {
        app.launchArguments.append("--seed-today-with-text")
        app.launch()

        let textBtn = app.buttons["home.textInputButton"]
        XCTAssertTrue(textBtn.waitForExistence(timeout: 5))
        textBtn.tap()

        let editor = app.textViews["home.textEditor"]
        XCTAssertTrue(editor.waitForExistence(timeout: 5))

        // The editor should contain the seeded text
        let editorValue = editor.value as? String ?? ""
        XCTAssertTrue(editorValue.contains("今日のテストテキスト"))
    }
}
