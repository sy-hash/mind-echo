# SpeechAnalyzer を使った音声書き起こし機能の設計

## 概要

今日の音声記録に対して、Apple Speech フレームワーク（`SpeechAnalyzer`）を使ったオンデバイス書き起こし機能を追加する。

## 背景

HomeView では今日の音声記録のリストが表示されるが、録音内容をテキストとして確認する手段がない。
`SpeechAnalyzer`（iOS 26+）を利用して、完全オンデバイスでの音声書き起こしを提供する。

## 要件

### UI

- 今日の各録音セル（`home.recordingRow`）に書き起こしボタンを追加
- ボタン押下で書き起こし結果モーダル（`.sheet`）を表示
- モーダル内で処理の進行状態と完了後の結果テキストを表示

### 書き起こし処理

- `Speech` フレームワークの `SpeechAnalyzer` + `SpeechTranscriber` を使用
- 対象の `Recording` の音声ファイル（`FilePathManager.recordingsDirectory` 配下）を入力
- ロケール: `ja-JP` 固定
- 書き起こし結果はモーダル内での表示のみ（データモデルへの永続化は行わない）

### 状態遷移

```
ボタン押下 → モーダル表示 → 書き起こし処理開始（ローディング表示）
  → 完了: 書き起こしテキストを表示
  → 失敗: エラーメッセージを表示
```

### 権限

- 書き起こしボタン押下時に音声認識の権限を確認・リクエスト
- `Info.plist` に `NSSpeechRecognitionUsageDescription` を追加

## アーキテクチャ

### ファイル構成

```
MindEchoApp
├── Services/
│   └── TranscriptionService.swift    ← NEW: SpeechAnalyzer ラッパー
├── ViewModels/
│   └── TranscriptionViewModel.swift  ← NEW: モーダルの状態管理
└── Views/
    ├── HomeView.swift                ← MODIFY: 書き起こしボタン追加
    └── TranscriptionView.swift       ← NEW: 結果表示モーダル（自己完結）
```

### 設計判断

| 判断 | 決定 | 理由 |
|------|------|------|
| モジュール配置 | MindEchoApp のみ | 永続化しないため Core に protocol を置く必要なし |
| ViewModel | 専用 TranscriptionViewModel 新設 | HomeViewModel の肥大化を避ける |
| Service 方式 | シンプルな `async throws -> String` | 短い録音メモにストリーミングは不要 |
| ロケール | `ja-JP` 固定 | 日本語ユーザー向けアプリ |
| 権限タイミング | ボタン押下時 | 必要になるまで権限を求めない |
| View の責務 | TranscriptionView が自己完結 | Recording を受け取り、内部で ViewModel 生成・書き起こし実行 |

### データフロー

```
HomeView (ボタン押下)
  → .sheet { TranscriptionView(recording:) }
    → @State で TranscriptionViewModel を生成
    → .task で startTranscription() を実行
      → 権限チェック → TranscriptionService.transcribe(audioFileURL:)
        → SpeechTranscriber + SpeechAnalyzer
      → 結果 or エラーを @Observable プロパティに反映
    → UI に表示
```

## コンポーネント詳細

### TranscriptionService

```swift
struct TranscriptionService {
    func transcribe(audioFileURL: URL, locale: Locale) async throws -> String
}
```

実装:
1. `SpeechTranscriber(locale: locale, preset: .offlineTranscription)` を生成
2. `SpeechAnalyzer(modules: [transcriber])` を生成
3. `async let` で `transcriber.results` を収集開始
4. `analyzer.analyzeSequence(from: AVAudioFile)` で音声を処理
5. `analyzer.finalizeAndFinish(through:)` で完了
6. 収集した results の `.text` を結合して返却

### TranscriptionViewModel

```swift
@Observable
final class TranscriptionViewModel {
    enum State {
        case idle
        case loading
        case success(String)
        case failure(String)
    }

    private(set) var state: State = .idle

    // DI 用クロージャ（テスト時に mock 差し替え可能）
    var transcribe: (URL, Locale) async throws -> String = TranscriptionService().transcribe

    func startTranscription(recording: Recording) async { ... }
}
```

`startTranscription` の流れ:
1. `state = .loading`
2. 音声認識の権限チェック（未許可ならリクエスト → 拒否なら `.failure`）
3. `FilePathManager.recordingsDirectory` + `recording.audioFileName` でファイル URL を構築
4. `transcribe(fileURL, Locale(identifier: "ja-JP"))` を呼び出し
5. 成功 → `.success(text)` / 失敗 → `.failure(message)`

### TranscriptionView

- `init(recording: Recording)` で Recording を受け取り
- `@State private var viewModel = TranscriptionViewModel()`
- `.task { await viewModel.startTranscription(recording:) }` で即座に開始
- `viewModel.state` に応じて ProgressView / テキスト / エラーを切り替え表示

### HomeView の変更

- 録音セルに書き起こしボタン（`doc.text` アイコン）を追加
- タップ時に `.sheet { TranscriptionView(recording:) }` を表示

## 影響範囲

- `HomeView.swift` — 録音セルに書き起こしボタンを追加
- 新規: `TranscriptionView.swift` — 書き起こし結果モーダル
- 新規: `TranscriptionViewModel.swift` — 書き起こし状態管理
- 新規: `TranscriptionService.swift` — SpeechAnalyzer ラッパー
- `Info.plist` — `NSSpeechRecognitionUsageDescription` 追加

## テスト計画

### ユニットテスト

遅延付き mock を注入し、状態遷移を検証する。

- `testStartTranscription_showsLoadingThenSuccess`: 遅延 mock → `.loading` を経て `.success(text)` に遷移
- `testStartTranscription_showsLoadingThenFailure`: 遅延 mock（エラー）→ `.loading` を経て `.failure` に遷移
- `testStartTranscription_authorizationDenied`: 権限拒否 mock → `.failure`

DI 方式:
```swift
// テスト時
let vm = TranscriptionViewModel()
vm.transcribe = { _, _ in
    try await Task.sleep(for: .seconds(1))
    return "テスト結果テキスト"
}
```

### UI テスト

遅延付き mock を使用し、SpeechAnalyzer のシミュレータ制約を回避。

- `testTranscriptionFlow_showsLoadingThenResult`: 書き起こしボタンタップ → ローディング表示 → 結果テキスト表示まで確認

## 対象 OS

- iOS 26.0+（`SpeechAnalyzer` は iOS 26 で導入）

## SpeechAnalyzer API リファレンス

```swift
import Speech
import AVFAudio

let locale = Locale(identifier: "ja-JP")
let transcriber = SpeechTranscriber(locale: locale, preset: .offlineTranscription)

async let transcriptionFuture = try transcriber.results.reduce("") {
    $0 + $1.text + " "
}

let analyzer = SpeechAnalyzer(modules: [transcriber])

if let lastSample = try await analyzer.analyzeSequence(from: AVAudioFile(forReading: audioFileURL)) {
    try await analyzer.finalizeAndFinish(through: lastSample)
} else {
    await analyzer.cancelAndFinishNow()
}

let resultText = try await transcriptionFuture
```
