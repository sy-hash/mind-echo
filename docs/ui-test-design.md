# UIテスト設計

メインシナリオを選定し XCTest で UIテストを記述する（5カテゴリ・21テストケース）。

## テストデータセットアップ（Launch Arguments）

UIテストプロセスはアプリと別プロセスで動作するため、launch arguments でアプリの動作を制御する。

| Launch Argument | 用途 |
|---|---|
| `--uitesting` | SwiftData を in-memory ストアに切り替え、テスト毎にクリーンな状態を保証 |
| `--seed-history` | サンプル JournalEntry データを事前投入（履歴テスト用） |
| `--seed-today-with-recordings` | 今日のエントリ + モック録音データを事前投入 |
| `--seed-today-with-text` | 今日のエントリ + テキストデータを事前投入 |
| `--mock-recorder` | MockAudioRecorderService を注入（マイク不要で録音UI状態遷移をテスト） |

## マイク非依存のテスト方式

シミュレータにはマイクがないため、`--mock-recorder` 引数で `MockAudioRecorderService`（`AudioRecording` protocol 準拠）を注入する。モックは:
- `isRecording`/`isPaused` フラグの状態遷移のみ行う
- `AVAudioEngine` を一切使わない
- 停止時にダミーの `Recording` エントリを作成

UIテストは **UI状態遷移**（ボタンの表示/非表示、有効/無効）を検証し、実際の音声キャプチャは検証対象外とする。

## Accessibility Identifier 一覧

全テスト対象要素に `.accessibilityIdentifier()` を付与する:

### TabView

- `tab.today`
- `tab.history`

### HomeView

- `home.dateLabel`
- `home.recordButton`
- `home.pauseButton`
- `home.resumeButton`
- `home.stopButton`
- `home.recordingDuration`
- `home.textInputButton`
- `home.recordingsList`
- `home.recordingRow.{n}`
- `home.recordingPlayButton.{n}`
- `home.textEditorSheet`
- `home.textEditor`
- `home.textSaveButton`
- `home.textCancelButton`

### HistoryListView

- `history.entryList`
- `history.entryRow.{date}`
- `history.entryDate.{date}`
- `history.entryPreview.{date}`
- `history.entryRecordingInfo.{date}`

### EntryDetailView

- `detail.dateHeader`
- `detail.textContent`
- `detail.recordingsList`
- `detail.recordingRow.{n}`
- `detail.playButton.{n}`
- `detail.deleteButton.{n}`
- `detail.shareButton`
- `detail.shareSheet`
- `detail.shareTextOption`
- `detail.shareAudioOption`

## テストケース（5カテゴリ・24テスト）

### 1. NavigationUITests（3テスト）

| テスト | 検証内容 |
|-------|---------|
| `testAppLaunch_showsHomeTab` | 起動時にホームタブが表示される |
| `testTabSwitching_navigatesBetweenTodayAndHistory` | タブ切り替えで画面が遷移する |
| `testHistoryToDetail_pushesAndPops` | 履歴→詳細への push/pop ナビゲーション |

### 2. HomeRecordingUITests（5テスト）

| テスト | 検証内容 |
|-------|---------|
| `testInitialState_showsRecordButtonOnly` | 初期状態で録音ボタンのみ表示 |
| `testStartRecording_showsPauseAndStopButtons` | 録音開始で一時停止・停止ボタン表示 |
| `testPauseRecording_showsResumeButton` | 一時停止で再開ボタン表示 |
| `testStopRecording_addsRecordingToList` | 停止で録音リストにエントリ追加 |
| `testMultipleRecordings_appearInOrder` | 複数録音が連番順に表示 |

### 3. HomeTextInputUITests（4テスト）

| テスト | 検証内容 |
|-------|---------|
| `testTapTextButton_opensTextEditorSheet` | テキスト入力ボタンでシート表示 |
| `testSaveText_dismissesSheet` | 保存でシート閉じる |
| `testCancelText_dismissesWithoutSaving` | キャンセルで保存せずシート閉じる |
| `testEditExistingText_opensWithPreviousContent` | 既存テキストがエディタに表示 |

### 4. HistoryListUITests（4テスト）

| テスト | 検証内容 |
|-------|---------|
| `testEmptyHistory_showsEmptyState` | データなしで空状態表示 |
| `testSeededHistory_displaysEntries` | シードデータがリスト表示される |
| `testEntryRow_showsDatePreviewAndRecordingInfo` | セルに日付・プレビュー・録音情報 |
| `testTapEntry_navigatesToDetail` | セルタップで詳細画面へ遷移 |

### 5. EntryDetailUITests（5テスト）

| テスト | 検証内容 |
|-------|---------|
| `testDetailView_showsDateAndTextContent` | 日付とテキスト内容の表示 |
| `testDetailView_showsRecordingsList` | 録音リストの表示 |
| `testPlayButton_togglesPlaybackState` | 再生ボタンタップで再生状態に遷移し、再度タップで停止 |
| `testShareButton_opensShareTypeSelection` | 共有ボタンで選択シート表示 |
| `testEditText_updatesContent` | テキスト編集が反映される |

## テスト対象外（明示的に除外）

- 実音声の録音・再生品質 → ユニットテスト + 実機テスト
- ファイルシステム操作 → ExportService ユニットテスト
- 日付境界ロジック（午前3時） → DateHelper ユニットテスト
- iOS Share Sheet 操作 → システムUI
- バックグラウンド録音 → 実機テスト

## 実装順序

機能実装との依存関係を考慮し、以下の順序で進める:

1. **テストヘルパー作成** — 即時実行可能
2. **NavigationUITests** — TabView + 画面スタブ実装後
3. **HistoryListUITests + EntryDetailUITests** — 履歴画面・詳細画面実装後
4. **HomeRecordingUITests + HomeTextInputUITests** — ホーム画面 + MockRecorder 実装後

## 検証方法

```bash
xcodebuild test \
  -workspace MindEcho.xcworkspace \
  -scheme MindEcho \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:MindEchoUITests
```

CI (`.github/workflows/test.yml`) は既に `MindEchoUITests` ターゲットを含む `MindEcho` スキームでテスト実行しているため、追加のCI設定変更は不要。
