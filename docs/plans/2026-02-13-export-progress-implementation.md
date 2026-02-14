# 音声エクスポート進捗表示の実装計画

## Context

共有ボタン → 音声ファイルを押下後、TTS生成・録音ファイル結合・書き出しに5〜15秒以上かかるが、UIフィードバックが一切ない。`isExporting` フラグは存在するが未使用。ステップベースの進捗表示を追加し、処理中であることとその進捗をユーザーに示す。

## 進捗モデル

録音N件のエントリの場合、totalSteps = N + 3:

| Step | 内容 |
|------|------|
| 1 | TTS音声生成完了 |
| 2〜N+1 | 各録音ファイルの読み込み・変換 |
| N+2 | マージ済み.m4aの書き込み |
| N+3 | エクスポートディレクトリへコピー |

## UI デザイン

```
┌─────────────────────────┐
│   ░░░░░░░░░░░░░░░░░░░   │  <- 半透明背景 (Color.black.opacity(0.4))
│  ┌───────────────────┐  │
│  │  ━━━━━━━━━░░░░░░  │  │  <- ProgressView(value:total:) linear determinate
│  │  音声を結合中… 3/6  │  │
│  └───────────────────┘  │  <- .regularMaterial カード (RoundedRectangle cornerRadius: 16)
│                         │
└─────────────────────────┘
```

- `ProgressView(value:total:)` で確定的な線形プログレスバー
- テキスト「音声を結合中… X/N」でステップ数を表示
- オーバーレイは `allowsHitTesting(true)` で背面タップをブロック
- 共有ボタンは `isExporting` 中に `.disabled` 化

## 実装手順（依存順）

### Step 1: AudioMerger に onProgress コールバック追加

**File**: `Packages/MindEchoAudio/Sources/MindEchoAudio/AudioMerger.swift`

`merge()` メソッドに `onProgress: (@Sendable (Int, Int) -> Void)? = nil` パラメータを追加する。デフォルト `nil` で後方互換性を維持。

```swift
public static func merge(
    ttsBuffer: AVAudioPCMBuffer?,
    recordingURLs: [URL],
    silenceDuration: TimeInterval = 0.75,
    outputURL: URL,
    onProgress: (@Sendable (Int, Int) -> Void)? = nil  // (completedSteps, totalSteps)
) async throws -> URL
```

コールバック呼び出しポイント:
- TTS バッファ処理完了後（既存 `if let tts` ブロック終了後）
- 各録音ファイル読み込み・変換後（`for url in recordingURLs` ループ内末尾）
- 出力ファイル書き込み完了後（write ループ終了後）

AudioMerger 内の totalSteps = (TTSあり ? 1 : 0) + recordingURLs.count + 1

### Step 2: Exporting プロトコルに進捗付きメソッド追加

**File**: `Packages/MindEchoCore/Sources/MindEchoCore/Exporting.swift`

```swift
public protocol Exporting {
    // 既存（変更なし）
    func exportTextJournal(entry: JournalEntry, to directory: URL) async throws -> URL
    func exportMergedAudio(entry: JournalEntry, to directory: URL) async throws -> URL

    // 新規
    func exportMergedAudio(
        entry: JournalEntry,
        to directory: URL,
        onProgress: @escaping @Sendable (Int, Int) -> Void
    ) async throws -> URL
}

// デフォルト実装: 既存メソッドにデリゲート
public extension Exporting {
    func exportMergedAudio(
        entry: JournalEntry,
        to directory: URL,
        onProgress: @escaping @Sendable (Int, Int) -> Void
    ) async throws -> URL {
        try await exportMergedAudio(entry: entry, to: directory)
    }
}
```

デフォルト extension により既存の適合型が壊れない。

### Step 3: ExportServiceImpl に進捗付きメソッド実装

**File**: `MindEcho/MindEcho/Services/ExportService.swift`

新メソッド `exportMergedAudio(entry:to:onProgress:)` を追加:
- AudioMerger の onProgress を中継し、totalSteps を N+3（コピーステップ含む）に統一
- AudioMerger からの `completed` 値はそのまま透過、`total` のみ差し替え
- コピー完了後に `onProgress(totalSteps, totalSteps)` で最終ステップ通知

### Step 4: MockExportService 作成

**File**: `MindEcho/MindEcho/Mocks/MockExportService.swift` (新規)

既存の `MockAudioPlayerService` と同じディレクトリ・パターンに従う:
- `exportAudioResult: Result<URL, Error>` で成功/失敗を制御
- `simulatedSteps: Int` でステップ数を制御
- 進捗付きメソッドではループで `onProgress(step, simulatedSteps)` を呼び出し

### Step 5: EntryDetailViewModel に進捗状態を追加

**File**: `MindEcho/MindEcho/ViewModels/EntryDetailViewModel.swift`

新規プロパティ:
```swift
var isExporting = false
var exportCompletedSteps: Int = 0
var exportTotalSteps: Int = 0
```

`exportForSharing(.audio)` の変更:
- 呼び出し前に `isExporting = true`, `exportTotalSteps = N + 3`, `exportCompletedSteps = 0` をセット
- `defer { isExporting = false }` でエラー時もフラグクリア
- onProgress コールバック内で `Task { @MainActor in self?.exportCompletedSteps = completed }` でメインスレッドに転送
- `[weak self]` キャプチャでリテインサイクル防止

### Step 6: EntryDetailView に進捗オーバーレイ追加

**File**: `MindEcho/MindEcho/Views/EntryDetailView.swift`

変更点:
1. `@State private var isExporting = false` を削除 → `viewModel.isExporting` を使用
2. `exportAndShare` から `isExporting` の管理を除去（ViewModel 側で管理）
3. `.sheet(item: $shareURL)` の後に `.overlay { ... }` を追加
4. 共有ボタンに `.disabled(viewModel.isExporting)` 追加
5. `exportProgressOverlay` computed property を追加

## エッジケース

| ケース | 対応 |
|--------|------|
| 録音0件 | AudioMerger が `noInputFiles` をスロー → defer で isExporting クリア → オーバーレイ消失 |
| TTS生成エラー | TTSGenerator がスロー → onProgress 未呼び出し → defer でクリア |
| 録音読み込みエラー | AudioMerger がスロー → 進捗途中で停止 → defer でクリア |
| 高速完了 (< 0.3s) | オーバーレイが一瞬表示 → 許容範囲（最小表示時間は scope 外） |
| 共有ボタン二重タップ | `.disabled(viewModel.isExporting)` + オーバーレイの `allowsHitTesting(true)` で防止 |

## 変更ファイル一覧

| File | 変更内容 |
|------|----------|
| `Packages/MindEchoAudio/Sources/MindEchoAudio/AudioMerger.swift` | onProgress パラメータ追加、各ステップでコールバック |
| `Packages/MindEchoCore/Sources/MindEchoCore/Exporting.swift` | プロトコルに onProgress 付きメソッド追加 + デフォルト実装 |
| `MindEcho/MindEcho/Services/ExportService.swift` | 進捗付きメソッド実装 |
| `MindEcho/MindEcho/Mocks/MockExportService.swift` | 新規: テスト用モック |
| `MindEcho/MindEcho/ViewModels/EntryDetailViewModel.swift` | 進捗プロパティ追加、exportForSharing 変更 |
| `MindEcho/MindEcho/Views/EntryDetailView.swift` | isExporting 削除、進捗オーバーレイ追加 |

## Verification

1. **ビルド確認**: build-verifier サブエージェントで xcodebuild build
2. **既存テスト**: EntryDetailViewModelTests, EntryDetailUITests が引き続きパスすること
3. **手動テスト**: シミュレータで共有 → 音声ファイル → 進捗バーが 0/N から N/N まで進むことを確認
