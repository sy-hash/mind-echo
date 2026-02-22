# UIテスト設計

メインシナリオを選定し XCTest で UIテストを記述する（5カテゴリ・19テストケース）。

## テストデータセットアップ（Launch Arguments）

UIテストプロセスはアプリと別プロセスで動作するため、launch arguments でアプリの動作を制御する。

| Launch Argument | 用途 |
|---|---|
| `--uitesting` | SwiftData を in-memory ストアに切り替え、テスト毎にクリーンな状態を保証 |
| `--seed-history` | サンプル JournalEntry データを事前投入（履歴テスト用） |
| `--seed-today-with-recordings` | 今日のエントリ + モック録音データを事前投入 |
| `--mock-recorder` | MockAudioRecorderService を注入（マイク不要で録音UI状態遷移をテスト） |
| `--mock-player` | MockAudioPlayerService を注入（実音声ファイル不要で再生UI状態遷移をテスト） |
| `--mock-transcription` | TranscriptionView 内の書き起こしクロージャを mock に差し替え（Speech フレームワーク不要でテスト） |

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
- `home.recordingsList`
- `home.recordingRow.{n}`
- `home.transcribeButton.{n}`
- `home.transcriptionSheet`

### HistoryListView

- `history.entryList`
- `history.entryRow.{date}`
- `history.entryDate.{date}`
- `history.entryRecordingInfo.{date}`

### TranscriptionView

- `transcription.loading`
- `transcription.resultText`
- `transcription.error`

### EntryDetailView

- `detail.dateHeader`
- `detail.recordingsList`
- `detail.recordingRow.{n}`
- `detail.deleteButton.{n}`
- `detail.shareButton`

## テストケース（5カテゴリ・19テスト）

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

### 3. HistoryListUITests（4テスト）

| テスト | 検証内容 |
|-------|---------|
| `testEmptyHistory_showsEmptyState` | データなしで空状態表示 |
| `testSeededHistory_displaysEntries` | シードデータがリスト表示される |
| `testEntryRow_showsDateAndRecordingInfo` | セルに日付・録音情報 |
| `testTapEntry_navigatesToDetail` | セルタップで詳細画面へ遷移 |

### 4. EntryDetailUITests（4テスト）

| テスト | 検証内容 |
|-------|---------|
| `testDetailView_showsDateAndRecordingsList` | 日付と録音リストの表示 |
| `testPlayButton_togglesPlaybackState` | 音声セルタップで再生状態に遷移し、再度タップで停止 |
| `testShareButton_presentsActivitySheet` | 共有ボタンで Activity Sheet 表示 |
| `testSwipeToDelete_removesRecording` | スワイプ削除で録音が削除される |

### 5. TranscriptionUITests（3テスト）

| テスト | 検証内容 |
|-------|---------|
| `testTranscribeButton_opensTranscriptionSheet` | 書き起こしボタンタップでモーダル表示・結果テキスト表示 |
| `testTranscription_showsResultText` | 書き起こし完了後にモックテキストが表示される |
| `testTranscription_dismissSheet` | シートをスワイプで閉じてホーム画面に戻る |

## テスト対象外（明示的に除外）

- 実音声の録音・再生品質 → ユニットテスト + 実機テスト
- ファイルシステム操作 → ExportService ユニットテスト
- 日付境界ロジック（午前3時） → DateHelper ユニットテスト
- iOS Share Sheet 操作 → システムUI
- バックグラウンド録音 → 実機テスト
- 実音声の書き起こし精度 → Speech フレームワーク依存、実機テスト

## 実装順序

機能実装との依存関係を考慮し、以下の順序で進める:

1. **テストヘルパー作成** — 即時実行可能
2. **NavigationUITests** — TabView + 画面スタブ実装後
3. **HistoryListUITests + EntryDetailUITests** — 履歴画面・詳細画面実装後
4. **HomeRecordingUITests** — ホーム画面 + MockRecorder 実装後
5. **TranscriptionUITests** — 書き起こし機能実装後

## 検証方法

```bash
xcodebuild test \
  -workspace MindEcho.xcworkspace \
  -scheme MindEcho \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:MindEchoUITests
```

CI (`.github/workflows/test.yml`) は既に `MindEchoUITests` ターゲットを含む `MindEcho` スキームでテスト実行しているため、追加のCI設定変更は不要。
