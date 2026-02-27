# UIテスト設計

メインシナリオを選定し XCTest で UIテストを記述する（5カテゴリ・16テストケース）。

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
| `--mock-summarization` | TranscriptionView 内の要約クロージャを mock に差し替え（FoundationModels 不要でテスト） |

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
- `home.recordingsList`
- `home.recordingRow.{n}`
- `home.transcribeButton.{n}`
- `home.transcription.{n}` — 録音セル内の書き起こしテキストプレビュー
- `home.summary.{n}` — 録音セル内の要約テキストプレビュー（要約がある場合、書き起こしプレビューより優先表示）
- `home.transcriptionSheet`
- `home.shareButton` — 共有メニューボタン（録音が存在する場合のみ表示）
- `home.shareAudioButton` — 共有メニュー内の「音声を共有」ボタン
- `home.shareTranscriptButton` — 共有メニュー内の「テキストを共有」ボタン

### RecordingModalView

録音中はモーダルシートとして表示される。録音中と書き起こし後で表示要素が切り替わる。

**録音中（`viewModel.isRecording == true`）**

- `recording.duration` — 録音時間（モノスペースフォント）
- `recording.waveform` — リアルタイム波形表示
- `recording.pauseButton` — 一時停止ボタン（録音中のみ表示）
- `recording.resumeButton` — 再開ボタン（一時停止中のみ表示）
- `recording.stopButton` — 停止ボタン

**書き起こし後（`viewModel.isRecording == false`）**

- `recording.transcriptionResult` — 書き起こし結果テキスト（成功・失敗どちらも同じ識別子）

### HistoryListView

- `history.entryList`
- `history.entryRow.{date}`
- `history.entryDate.{date}`
- `history.entryRecordingInfo.{date}`

### TranscriptionView

- `transcription.loading`
- `transcription.resultText`
- `transcription.error`
- `transcription.summaryLoading` — 要約生成中のプログレス表示
- `transcription.summaryText` — 要約結果テキスト
- `transcription.summaryError` — 要約エラーメッセージ

### EntryDetailView

- `detail.dateHeader`
- `detail.recordingsList`
- `detail.recordingRow.{n}`
- `detail.deleteButton.{n}`
- `detail.shareButton`
- `detail.summary.{n}` — 録音セル内の要約テキストプレビュー
- `detail.shareAudioButton` — 共有メニュー内の「音声を共有」ボタン
- `detail.shareTranscriptButton` — 共有メニュー内の「テキストを共有」ボタン

## テストケース（5カテゴリ・17テスト）

### 1. NavigationUITests（3テスト）

| テスト | 検証内容 |
|-------|---------|
| `testAppLaunch_showsHomeTab` | 起動時にホームタブが表示される |
| `testTabSwitching_navigatesBetweenTodayAndHistory` | タブ切り替えで画面が遷移する |
| `testHistoryToDetail_pushesAndPops` | 履歴→詳細への push/pop ナビゲーション |

### 2. HomeRecordingUITests（1テスト）

録音UIをモーダルに移行したことで、複数の独立したテストケースを1つの統合フローテストに統合した。

| テスト | 検証内容 |
|-------|---------|
| `testRecordingModalFlow` | 録音ボタン → モーダル → 一時停止 → 再開 → 停止 → 書き起こし → 閉じる → 2回目録音 → 行数確認まで12ステップを通しで検証 |

**テストステップ詳細:**

1. `home.recordButton` の存在確認
2. 録音ボタンタップ → モーダルが開き録音開始
3. モーダル要素（`recording.duration` / `recording.waveform` / `recording.pauseButton` / `recording.stopButton`）の存在確認
4. 一時停止ボタンタップ → `recording.resumeButton` に切り替わることを確認
5. 再開ボタンタップ → `recording.pauseButton` に戻ることを確認
6. 停止ボタンタップ → 書き起こし開始
7. `recording.transcriptionResult` が表示されることを確認
8. スワイプダウンでモーダルを閉じる
9. `home.recordingRow.1` がリストに追加されることを確認
10. 2回目の録音開始（`isHittable` predicate で安定待機）
11. 停止 → 書き起こし結果を確認 → スワイプで閉じる
12. `home.recordingRow.1` と `home.recordingRow.2` が両方存在することを確認

### 3. HistoryListUITests（4テスト）

| テスト | 検証内容 |
|-------|---------|
| `testEmptyHistory_showsEmptyState` | データなしで空状態表示 |
| `testSeededHistory_displaysEntries` | シードデータがリスト表示される |
| `testEntryRow_showsDateAndRecordingInfo` | セルに日付・録音情報 |
| `testTapEntry_navigatesToDetail` | セルタップで詳細画面へ遷移 |

### 4. EntryDetailUITests（5テスト）

| テスト | 検証内容 |
|-------|---------|
| `testDetailView_showsDateAndRecordingsList` | 日付と録音リストの表示 |
| `testPlayButton_togglesPlaybackState` | 音声セルタップで再生状態に遷移し、再度タップで停止 |
| `testShareButton_presentsActivitySheet` | 共有ボタンタップで共有タイプ選択メニュー表示 → 「音声を共有」選択で Activity Sheet 表示 |
| `testShareTranscriptButton_presentsActivitySheet` | 共有ボタンタップで共有タイプ選択メニュー表示 → 「テキストを共有」選択で Activity Sheet 表示 |
| `testSwipeToDelete_removesRecording` | スワイプ削除で録音が削除される |

### 5. TranscriptionUITests（4テスト）

| テスト | 検証内容 |
|-------|---------|
| `testTranscribeButton_opensTranscriptionSheet` | 書き起こしボタンタップでモーダル表示・結果テキスト表示 |
| `testTranscription_showsResultText` | 書き起こし完了後にモックテキストが表示される |
| `testTranscription_showsSummaryAboveResultText` | 要約テキストが書き起こしテキストの上に表示される |
| `testTranscription_dismissSheet` | シートをスワイプで閉じてホーム画面に戻る |

## テスト対象外（明示的に除外）

- 実音声の録音・再生品質 → ユニットテスト + 実機テスト
- ファイルシステム操作 → ExportService ユニットテスト
- 日付境界ロジック（午前3時） → DateHelper ユニットテスト
- iOS Share Sheet 操作 → システムUI
- バックグラウンド録音 → 実機テスト
- 実音声の書き起こし精度 → Speech フレームワーク依存、実機テスト
- Apple Foundation Models の要約精度 → FoundationModels 依存、対応デバイスでの実機テスト

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
