# UIテスト設計

メインシナリオを選定し XCTest で UIテストを記述する（5カテゴリ・19テストケース）。

## テストデータセットアップ（Launch Arguments）

UIテストプロセスはアプリと別プロセスで動作するため、launch arguments でアプリの動作を制御する。

| Launch Argument | 用途 |
|---|---|
| `--uitesting` | SwiftData を in-memory ストアに切り替え、テスト毎にクリーンな状態を保証 |
| `--seed-history` | サンプル JournalEntry データを事前投入（履歴セクションテスト用） |
| `--seed-today-with-recordings` | 今日のエントリ + モック録音データを事前投入 |
| `--mock-recorder` | MockAudioRecorderService を注入（マイク不要で録音UI状態遷移をテスト） |
| `--mock-player` | MockAudioPlayerService を注入（実音声ファイル不要で再生UI状態遷移をテスト） |
| `--mock-transcription` | TranscriptionView 内の書き起こしクロージャを mock に差し替え（Speech フレームワーク不要でテスト） |
| `--mock-summarization` | TranscriptionView 内の要約クロージャを mock に差し替え（FoundationModels 不要でテスト） |
| `--mock-ai-prompt` | TranscriptionView 内の AI プロンプト適用クロージャを mock に差し替え（FoundationModels 不要でテスト） |

## マイク非依存のテスト方式

シミュレータにはマイクがないため、`--mock-recorder` 引数で `MockAudioRecorderService`（`AudioRecording` protocol 準拠）を注入する。モックは:
- `isRecording`/`isPaused` フラグの状態遷移のみ行う
- `AVAudioEngine` を一切使わない
- 停止時にダミーの `Recording` エントリを作成

UIテストは **UI状態遷移**（ボタンの表示/非表示、有効/無効）を検証し、実際の音声キャプチャは検証対象外とする。

## Accessibility Identifier 一覧

全テスト対象要素に `.accessibilityIdentifier()` を付与する:

### HomeView（統合ビュー）

TabView を廃止し、今日のセクションと過去の履歴セクションを1画面に統合。

**リスト全体**

- `home.entryList` — 日付セクション付きのリスト全体

**今日のセクション**

- `home.dateLabel` — 今日の日付表示（セクションヘッダー）
- `home.emptyState` — 録音がない場合の空状態テキスト
- `home.addButton` — 今日のセクションヘッダー内の追加メニューボタン（➕アイコン）
- `home.recordMenuItem` — 追加メニュー内の「音声を録音」ボタン
- `home.recordButton` — 録音開始ボタン（画面下部固定）
- `home.recordingRow.{n}` — 今日の録音行（n = sequenceNumber）。タップで TranscriptionView へ遷移
- `home.playButton.{n}` — 今日の録音の再生ボタン（セル右端、非再生時に表示）
- `home.pauseButton.{n}` — 今日の録音の一時停止ボタン（セル右端、再生中に表示）
- `home.moreButton.{n}` — 今日の録音のメニューボタン（…アイコン、セル右端）
- `home.deleteMenuItem.{n}` — メニュー内の削除ボタン（destructive スタイル）
- `home.transcription.{n}` — 今日の録音セル内の書き起こしテキストプレビュー
- `home.summary.{n}` — 今日の録音セル内の要約テキストプレビュー（要約がある場合、書き起こしプレビューより優先表示）
- `home.transcriptionSheet` — 書き起こしシート
- `home.shareButton` — 共有メニューボタン（今日のセクションヘッダー内、録音が存在する場合のみ表示）
- `home.shareAudioButton` — 共有メニュー内の「音声を共有」ボタン
- `home.shareTranscriptButton` — 共有メニュー内の「テキストを共有」ボタン

**過去のセクション**

- `home.sectionHeader.{date}` — 過去の日付セクションヘッダー（date = yyyyMMdd）
- `past.addButton.{date}` — 過去のセクションヘッダー内の追加メニューボタン（➕アイコン）
- `past.recordMenuItem.{date}` — 過去の追加メニュー内の「音声を録音」ボタン
- `past.shareButton.{date}` — 過去のセクションヘッダー内の共有メニューボタン
- `past.shareAudioButton.{date}` — 過去の共有メニュー内の「音声を共有」ボタン
- `past.shareTranscriptButton.{date}` — 過去の共有メニュー内の「テキストを共有」ボタン
- `past.recordingRow.{date}.{n}` — 過去の録音行。タップで TranscriptionView へ遷移
- `past.playButton.{date}.{n}` — 過去の録音の再生ボタン（セル右端、非再生時に表示）
- `past.pauseButton.{date}.{n}` — 過去の録音の一時停止ボタン（セル右端、再生中に表示）
- `past.moreButton.{date}.{n}` — 過去の録音のメニューボタン（…アイコン、セル右端）
- `past.deleteMenuItem.{date}.{n}` — メニュー内の削除ボタン（destructive スタイル）
- `past.transcription.{date}.{n}` — 過去の録音セル内の書き起こしテキストプレビュー
- `past.summary.{date}.{n}` — 過去の録音セル内の要約テキストプレビュー

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

### TranscriptionView

- `transcription.closeButton` — シートを閉じるボタン（×アイコン、ナビゲーションバー左端）
- `transcription.loading`
- `transcription.resultText`
- `transcription.error`
- `transcription.summaryLoading` — 要約生成中のプログレス表示
- `transcription.summaryText` — 要約結果テキスト
- `transcription.summaryError` — 要約エラーメッセージ
- `transcription.tabPicker` — 原文/AI結果セグメントコントロール
- `transcription.promptField` — プロンプト入力フィールド
- `transcription.applyButton` — 「適用」ボタン
- `transcription.aiResultText` — AI処理結果テキスト
- `transcription.aiResultLoading` — AI処理中プログレス表示
- `transcription.aiResultError` — AI処理エラーメッセージ

## テストケース（5カテゴリ・18テスト）

### 1. NavigationUITests（3テスト）

| テスト | 検証内容 |
|-------|---------|
| `testAppLaunch_showsHomeScreen` | 起動時にホーム画面が表示される |
| `testAppLaunch_showsTodayEmptyState` | 録音なしで空状態が表示される |
| `testSeededHistory_showsPastSections` | シードデータで過去のセクションが表示される |

### 2. HomeRecordingUITests（2テスト）

録音UIをモーダルに移行したことで、複数の独立したテストケースを1つの統合フローテストに統合した。

| テスト | 検証内容 |
|-------|---------|
| `testRecordingModalFlow` | 録音ボタン → モーダル → 一時停止 → 再開 → 停止 → 書き起こし → 閉じる → 2回目録音 → 行数確認まで12ステップを通しで検証 |
| `testAddRecordingToPastDate` | 過去の日付セクションの➕ボタン → メニュー「音声を録音」→ モーダル → 停止 → 書き起こし → 閉じる → 過去エントリに録音が追加されることを検証 |

**テストステップ詳細:**

1. `home.recordButton` の存在確認
2. 録音ボタンタップ → モーダルが開き録音開始
3. モーダル要素（`recording.duration` / `recording.waveform` / `recording.pauseButton` / `recording.stopButton`）の存在確認
4. 一時停止ボタンタップ → `recording.resumeButton` に切り替わることを確認
5. 再開ボタンタップ → `recording.pauseButton` に戻ることを確認
6. 停止ボタンタップ → 書き起こし開始
7. `recording.transcriptionResult` が表示されることを確認
8. 「閉じる」ボタンでモーダルを閉じる
9. `home.recordingRow.1` がリストに追加されることを確認
10. 2回目の録音開始（`isHittable` predicate で安定待機）
11. 停止 → 書き起こし結果を確認 → 閉じる
12. `home.recordingRow.1` と `home.recordingRow.2` が両方存在することを確認

**`testAddRecordingToPastDate` テストステップ:**

1. `--seed-history` でシードデータ付きで起動
2. `past.addButton.{date}` の存在確認
3. 追加ボタンタップ → メニュー表示
4. 「音声を録音」タップ → 録音モーダルが開く
5. 停止ボタンタップ → 書き起こし開始
6. `recording.transcriptionResult` が表示されることを確認
7. 「閉じる」ボタンでモーダルを閉じる
8. モーダルが完全に閉じたことを確認
9. 過去のエントリに `sequenceNumber 2` の録音行が追加されたことを確認

### 3. HistoryListUITests（3テスト）

| テスト | 検証内容 |
|-------|---------|
| `testEmptyHistory_showsEmptyState` | データなしで今日のセクションに空状態表示 |
| `testSeededHistory_displaysEntries` | シードデータが統合リストに表示される |
| `testEntryRow_showsDatePreviewAndRecordingInfo` | セルに録音情報が表示される |

### 4. EntryDetailUITests（5テスト）

統合ビュー上で今日の録音に対するテストを実施（旧 EntryDetailView のテストを HomeView に移行）。

| テスト | 検証内容 |
|-------|---------|
| `testHomeView_showsDateAndRecordingsList` | 日付と録音リストの表示 |
| `testShareButton_presentsActivitySheet` | セクションヘッダーの共有ボタンタップで共有タイプ選択メニュー表示 → 「音声を共有」選択で Activity Sheet 表示 |
| `testShareTranscriptButton_presentsActivitySheet` | セクションヘッダーの共有ボタンタップで共有タイプ選択メニュー表示 → 「テキストを共有」選択で Activity Sheet 表示 |
| `testMenuDelete_removesRecording` | メニューボタン（…）タップ → 削除メニューアイテムタップで録音が削除される |
| `testPlayButton_togglesPlaybackState` | 再生ボタンタップで一時停止ボタンに切り替わり、一時停止タップで再生ボタンに戻る |

### 5. TranscriptionUITests（6テスト）

| テスト | 検証内容 |
|-------|---------|
| `testRecordingRowTap_opensTranscriptionSheet` | 録音セルタップで TranscriptionView がモーダル表示され、結果テキストが表示される |
| `testTranscription_showsResultText` | 書き起こし完了後にモックテキストが表示される |
| `testTranscription_showsSummaryAboveResultText` | 要約テキストが書き起こしテキストの上に表示される |
| `testAIPrompt_customPrompt_showsResult` | プロンプト入力+適用で AI 結果が表示される |
| `testAIPrompt_tabSwitching` | セグメント切り替えで原文と AI 結果を行き来できる |
| `testTranscription_dismissSheet` | 閉じるボタン（×）をタップしてシートを閉じ、ホーム画面に戻る |

## テスト対象外（明示的に除外）

- 実音声の録音・再生品質 → ユニットテスト + 実機テスト
- ファイルシステム操作 → ExportService ユニットテスト
- 日付境界ロジック（午前3時） → DateHelper ユニットテスト
- iOS Share Sheet 操作 → システムUI
- バックグラウンド録音 → 実機テスト
- 実音声の書き起こし精度 → Speech フレームワーク依存、実機テスト
- Apple Foundation Models の要約精度 → FoundationModels 依存、対応デバイスでの実機テスト

## 検証方法

```bash
xcodebuild test \
  -workspace MindEcho.xcworkspace \
  -scheme MindEcho \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:MindEchoUITests
```

CI (`.github/workflows/test.yml`) は既に `MindEchoUITests` ターゲットを含む `MindEcho` スキームでテスト実行しているため、追加のCI設定変更は不要。
