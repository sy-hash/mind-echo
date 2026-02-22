import XCTest

final class HomeTranscriptionUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = [
            "--uitesting",
            "--mock-recorder",
            "--seed-today-with-recordings",
        ]
        addUIInterruptionMonitor(withDescription: "Speech Recognition Permission") { alert in
            let allowButton = alert.buttons["Allow"]
            if allowButton.exists {
                allowButton.tap()
                return true
            }
            let allowButtonJa = alert.buttons["許可"]
            if allowButtonJa.exists {
                allowButtonJa.tap()
                return true
            }
            return false
        }
    }

    // MARK: - Tests

    /// 録音セルごとに書き起こしボタン（text.bubble）が表示される
    @MainActor
    func testTranscribeButton_appearsForEachRecording() throws {
        app.launchArguments.append("--mock-transcription-success")
        app.launch()

        let recordingsList = app.descendants(matching: .any)["home.recordingsList"]
        XCTAssertTrue(recordingsList.waitForExistence(timeout: 5))

        // シードデータは3件の録音を含む
        for n in 1...3 {
            let transcribeBtn = app.buttons["home.transcribeButton.\(n)"]
            XCTAssertTrue(transcribeBtn.waitForExistence(timeout: 5), "録音 #\(n) の書き起こしボタンが見つかりません")
        }
    }

    /// 書き起こしボタンをタップすると TranscriptionSheet が表示される
    @MainActor
    func testTapTranscribeButton_opensTranscriptionSheet() throws {
        app.launchArguments.append("--mock-transcription-success")
        app.launch()

        let transcribeBtn = app.buttons["home.transcribeButton.1"]
        XCTAssertTrue(transcribeBtn.waitForExistence(timeout: 5))
        transcribeBtn.tap()
        app.tap()

        let sheet = app.otherElements["home.transcriptionSheet"]
        XCTAssertTrue(sheet.waitForExistence(timeout: 5))
    }

    /// シートのナビゲーションタイトルに録音の連番が含まれる
    @MainActor
    func testTranscriptionSheet_showsSequenceNumberInTitle() throws {
        app.launchArguments.append("--mock-transcription-success")
        app.launch()

        let transcribeBtn = app.buttons["home.transcribeButton.1"]
        XCTAssertTrue(transcribeBtn.waitForExistence(timeout: 5))
        transcribeBtn.tap()
        app.tap()

        // NavigationTitle "書き起こし #1" が表示される
        let titleLabel = app.staticTexts["書き起こし #1"]
        XCTAssertTrue(titleLabel.waitForExistence(timeout: 5))
    }

    /// 成功時に書き起こし結果テキストが表示される
    @MainActor
    func testTranscriptionSuccess_showsResultText() throws {
        app.launchArguments.append("--mock-transcription-success")
        app.launch()

        let transcribeBtn = app.buttons["home.transcribeButton.1"]
        XCTAssertTrue(transcribeBtn.waitForExistence(timeout: 5))
        transcribeBtn.tap()
        app.tap()

        // 成功後に resultText ビューが表示される（モックは 0.3s 後に成功を返す）
        let resultText = app.scrollViews["transcription.resultText"]
        XCTAssertTrue(resultText.waitForExistence(timeout: 10))
    }

    /// 失敗時にエラービューが表示される
    @MainActor
    func testTranscriptionFailure_showsErrorView() throws {
        app.launchArguments.append("--mock-transcription-failure")
        app.launch()

        let transcribeBtn = app.buttons["home.transcribeButton.1"]
        XCTAssertTrue(transcribeBtn.waitForExistence(timeout: 5))
        transcribeBtn.tap()
        app.tap()

        // 失敗後にエラービューが表示される
        let errorView = app.otherElements["transcription.errorView"]
        XCTAssertTrue(errorView.waitForExistence(timeout: 10))
    }

    /// 閉じるボタンをタップするとシートが閉じる
    @MainActor
    func testTranscriptionSheet_closeButton_dismissesSheet() throws {
        app.launchArguments.append("--mock-transcription-success")
        app.launch()

        let transcribeBtn = app.buttons["home.transcribeButton.1"]
        XCTAssertTrue(transcribeBtn.waitForExistence(timeout: 5))
        transcribeBtn.tap()
        app.tap()

        let closeBtn = app.buttons["transcription.closeButton"]
        XCTAssertTrue(closeBtn.waitForExistence(timeout: 5))
        closeBtn.tap()

        // シートが閉じ、書き起こしボタンが再び表示される
        XCTAssertTrue(transcribeBtn.waitForExistence(timeout: 5))
        let sheet = app.otherElements["home.transcriptionSheet"]
        XCTAssertFalse(sheet.exists)
    }
}
