# 文字起こし機能 — Phase 2 仕様

> **ステータス**: Phase 2（未実装）
> **元の仕様**: `design-prompt.md` から分離（Phase 1 ではスコープ外）
> **前提**: Phase 1 の録音・再生・エクスポート基盤が完成していること

## 概要

録音中にリアルタイムで音声をテキストに変換し、`Recording.transcription` に保存する。
iOS 26 の `SpeechAnalyzer` / `SpeechTranscriber` を使用（完全オンデバイス処理）。

## Phase 2 で必要な変更一覧

### データモデル

- `Recording` に `transcription: String?` フィールドを追加
- ER 図を更新

```swift
@Model
class Recording {
    // ... 既存フィールド ...
    var transcription: String?        // 文字起こし結果（リアルタイム文字起こしの確定テキスト）
}
```

### モジュール構成

- **Transcription** モジュールを新設（4→5モジュール）
  - 責務: SpeechAnalyzer/SpeechTranscriber ラッパー, リアルタイム文字起こしストリーム
  - 主な型: `TranscriptionService`
  - 依存先: Speech
  - MindEchoCore には依存しない

依存関係図に `Transcription` を追加:

```
MindEchoApp (App Target)
├── MindEchoCore
├── AudioService
├── AudioMerger
├── Transcription        ← 追加
└── ExportService
    ├── MindEchoCore
    └── AudioMerger
```

### AudioService の変更

- `AudioRecording` protocol に `onBuffer` コールバックを追加:

```swift
protocol AudioRecording {
    // ... 既存プロパティ ...
    var onBuffer: ((AVAudioPCMBuffer) -> Void)? { get set }  // 追加
    // ... 既存メソッド ...
}
```

- tap コールバック内で、ファイル書き出しに加えて外部へのバッファ転送を行う
- 事前確保バッファプール（後述）を導入し、リアルタイムスレッド安全性を確保する

### ViewModel の変更

**HomeViewModel:**

```swift
// 追加するプロパティ
var liveTranscription = ""        // 録音中のリアルタイム文字起こしテキスト（暫定）
var isTranscribing = false        // 文字起こし処理中

// 追加する依存
private let transcriptionService: any Transcribing

// init に transcriptionService パラメータを追加
init(modelContext: ModelContext,
     audioRecorder: any AudioRecording,
     audioPlayer: any AudioPlaying = AudioPlayerService(),
     transcriptionService: any Transcribing = TranscriptionService()) { ... }
```

- `startRecording()` でリアルタイム文字起こしも同時開始
- `stopRecording()` で確定テキストを `Recording.transcription` に保存

### ExportService の変更

- `ShareType` に `.transcription` ケースを追加
- `Exporting` protocol に `exportTranscription` メソッドを追加:

```swift
enum ShareType {
    case textJournal
    case transcription      // 追加: 文字起こしテキスト（全 Recording の transcription を結合した .txt）
    case audio
}

protocol Exporting {
    // ... 既存メソッド ...
    func exportTranscription(entry: JournalEntry, to directory: URL) async throws -> URL  // 追加
}
```

**エクスポートフォーマット** — ファイル名: `20250207_transcription.txt`

```
# Transcription: 2025-02-07 (Fri)

## Recording 01 (14:30 / 3m24s)
打ち合わせ後に思ったことをメモ。
来週までにプロトタイプを作成する必要がある...

## Recording 02 (21:15 / 1m52s)
今日の振り返り。全体的に生産的な一日だった...
```

### UI の変更

- ホーム画面: 録音中にリアルタイム文字起こしテキストを表示（暫定/確定を視覚的に区別）
- ホーム画面: 録音リストに文字起こしテキストのプレビューを追加
- エントリ詳細画面: 録音ごとに文字起こしテキスト（展開/折りたたみ可能）を表示
- 履歴画面: 検索対象に `Recording.transcription` を追加
- 共有シート: 「文字起こしテキスト」選択肢を追加

### パーミッション

Info.plist に追加:

```
NSSpeechRecognitionUsageDescription: 録音した音声をテキストに変換するために使用します
```

---

## 文字起こしの仕様（SpeechAnalyzer — iOS 26 新API）

iOS 26 で導入された `SpeechAnalyzer` + `SpeechTranscriber` を使用する。
従来の `SFSpeechRecognizer` に比べ、長時間音声への対応、高速処理、完全オフライン動作が大幅に改善されている。

**本アプリではリアルタイム文字起こしを採用する。** 録音中にマイク入力をストリーミングで `SpeechTranscriber` に渡し、逐次テキストを画面に表示する。録音停止時に確定テキストを `Recording.transcription` に保存する。

### 音声パイプライン構成

録音と文字起こしは `AVAudioEngine` の input node tap を唯一の音声ソースとして共有する。
`AVAudioRecorder` は使用しない（二重キャプチャの回避）。

```
AVAudioEngine (input node tap) — PCM バッファ
  ├── AVAudioFile に書き出し → .m4a ファイル（録音、AAC エンコード）
  ├── SpeechAnalyzer.analyze(buffer:) → SpeechTranscriber（文字起こし）
  └── 振幅レベル計算 → WaveformLiveView（リアルタイム波形表示）
```

**フォーマット変換:**
- `AVAudioEngine` の input node tap は **PCM（Linear PCM）バッファ** を提供する（デバイスネイティブフォーマット、通常 48kHz Float32）
- `AVAudioFile` は初期化時に **出力フォーマット（AAC）** と **処理フォーマット（PCM）** を分けて指定できる。tap から受け取った PCM バッファを `write(from:)` すると、内部で自動的に AAC エンコードされて `.m4a` ファイルに書き出される
- `SpeechAnalyzer` には tap から受け取った PCM バッファをそのまま渡す。`SpeechAnalyzer` が期待するフォーマットと tap のフォーマットが異なる場合は `AVAudioConverter` で変換する（実装時に要確認）

- **AudioService** が `AVAudioEngine` を所有し、tap コールバック内で `AVAudioFile` への書き出しと、外部から注入されたクロージャへのバッファ転送を行う。**tap コールバック内で渡される `AVAudioPCMBuffer` はオーディオエンジンが内部的に再利用するため、コールバック終了後にデータが上書きされる可能性がある。** そのため、外部にバッファを転送する際は **事前確保済みバッファプール** からバッファを取得し、サンプルデータをコピーしてから渡す（tap コールバック内での `AVAudioPCMBuffer` の新規生成（`malloc`）を回避する）。加えて、バッファから振幅レベル（RMS/ピーク値）を計算し、波形表示用に公開する
- **リアルタイムスレッド安全性**: tap コールバックはリアルタイムオーディオスレッドで実行されるため、コールバック内ではメモリ確保・ロック取得・Objective-C メッセージングなどのブロッキング操作を行わない。バッファのコピーには **エンジン起動前に事前確保したバッファプール**（固定数の `AVAudioPCMBuffer`、例: 8個）を使用し、アトミックインデックスでロックフリーに取得する（`memcpy` 相当のコピーのみで `malloc` は発生しない）。コピー後の外部コールバック呼び出しは **専用のシリアルキュー**（`DispatchQueue(label: "audio.processing")`）にディスパッチする。処理キューでの消費完了後にバッファをプールに返却する。メインキューには直接ディスパッチしない（48kHz / 1024フレーム ≈ 毎秒47回の頻度になり UI スレッドを圧迫するため）。振幅レベルの UI 更新のみ、間引き（10〜15Hz 程度）した上でメインキューに転送する
- **ViewModel 層（App Target）** が AudioService のバッファコールバックを TranscriptionService に接続する。これにより AudioService と Transcription の直接依存を避ける

### 基本実装パターン（録音 + リアルタイム文字起こし）

```swift
import Speech
import AVFoundation

// --- AudioService 側（録音） ---
// AVAudioEngine の input node tap でバッファを取得し、
// 1. AVAudioFile に書き出し（録音・AAC エンコード）
// 2. onBuffer コールバックで外部にバッファを提供（文字起こし連携）
// 3. 振幅レベル計算（波形表示用）

let engine = AVAudioEngine()
let inputNode = engine.inputNode
let recordingFormat = inputNode.outputFormat(forBus: 0)  // PCM（デバイスネイティブ）

// AAC (.m4a) 出力用の設定
let outputSettings: [String: Any] = [
    AVFormatIDKey: kAudioFormatMPEG4AAC,
    AVSampleRateKey: recordingFormat.sampleRate,
    AVNumberOfChannelsKey: recordingFormat.channelCount,
    AVEncoderBitRateKey: 128_000
]

// commonFormat で入力の PCM フォーマットを指定し、settings で出力の AAC フォーマットを指定
// AVAudioFile が内部で PCM → AAC の変換を自動的に行う
let audioFile = try AVAudioFile(
    forWriting: fileURL,
    settings: outputSettings,
    commonFormat: .pcmFormatFloat32,
    interleaved: false
)

var isPaused = false  // 一時停止フラグ（後述）

// --- 事前確保バッファプール ---
// エンジン起動前に固定数の AVAudioPCMBuffer を確保しておき、
// tap コールバック内での malloc を回避する（リアルタイムスレッド安全性）
let poolSize = 8
let bufferPool: [AVAudioPCMBuffer] = (0..<poolSize).compactMap { _ in
    guard let buf = AVAudioPCMBuffer(
        pcmFormat: recordingFormat,
        frameCapacity: 1024
    ) else { return nil }
    return buf
}
// アトミックインデックスでロックフリーに取得（OS のロックを使わない）
let poolIndex = OSAtomicInt64(0)

inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, time in
    guard !isPaused else { return }  // 一時停止中はスキップ
    // 録音: ファイルに書き出し（PCM → AAC 自動変換）
    try? audioFile.write(from: buffer)

    // 事前確保済みプールからバッファを取得し、サンプルデータをコピーする
    // （tap コールバックで渡される AVAudioPCMBuffer はコールバック終了後に
    //   オーディオエンジンが再利用するため、そのまま外部に渡すとデータが破損する。
    //   プールから取得することで malloc を回避し、memcpy 相当のコピーのみ行う）
    let idx = Int(OSAtomicIncrement64(&poolIndex) % Int64(poolSize))
    let pooledBuffer = bufferPool[idx]
    pooledBuffer.frameLength = buffer.frameLength
    if let src = buffer.floatChannelData,
       let dst = pooledBuffer.floatChannelData {
        let chCount = Int(buffer.format.channelCount)
        let frames = Int(buffer.frameLength)
        for ch in 0..<chCount {
            dst[ch].update(from: src[ch], count: frames)
        }
    }

    // 専用シリアルキューにディスパッチしてから外部コールバックを呼ぶ
    // （リアルタイムオーディオスレッドで任意のクロージャを実行すると、
    //   メモリ確保やロック取得が発生しグリッチの原因になる）
    // ⚠️ メインキューではなく専用キューを使用する。48kHz / 1024フレーム ≈ 毎秒47回の
    //   ディスパッチが発生するため、メインキューに直接流すと UI スレッドを圧迫する。
    processingQueue.async {
        onBuffer?(pooledBuffer)
        // pooledBuffer は processingQueue での消費完了後、プールに自動的に返却される
        // （次の tap コールバックで同じインデックスが巡ってくるまで再利用されない）
    }

    // 振幅レベルの UI 更新は間引いてメインキューに転送（10〜15Hz 程度）
    let now = CACurrentMediaTime()
    if now - lastAmplitudeUpdate >= amplitudeUpdateInterval {
        lastAmplitudeUpdate = now
        let rms = Self.calculateRMS(buffer)
        DispatchQueue.main.async {
            self.currentAmplitude = rms
        }
    }
}

// --- 専用シリアルキュー（バッファ転送用） ---
private let processingQueue = DispatchQueue(label: "com.mindecho.audio.processing")

// --- 振幅更新の間引き ---
private var lastAmplitudeUpdate: Double = 0
private let amplitudeUpdateInterval: Double = 1.0 / 15  // ~15Hz

engine.prepare()
try engine.start()

// --- Transcription 側（文字起こし） ---
let locale = Locale(identifier: "ja_JP")
let transcriber = SpeechTranscriber(locale: locale, preset: .transcription)
let analyzer = SpeechAnalyzer(modules: [transcriber])

// AudioService の onBuffer コールバック経由でコピー済みバッファを受け取り、
// SpeechAnalyzer に渡す（バッファは AudioService 側でコピー＆ディスパッチ済みのため、
// ここでは安全に使用できる）
audioRecorderService.onBuffer = { copiedBuffer in
    analyzer.analyze(copiedBuffer)
}

// 結果の取得（AsyncSequence）
// SpeechTranscriber は文の区切りごとに isFinal な結果を返すため、
// 録音セッション中に複数の確定結果が得られる。これらを連結して最終的な transcription を構築する。
var finalizedText = ""  // 確定済みテキストの蓄積

Task {
    for await result in transcriber.results {
        // AttributedString → String 変換（タイミングデータ等は不要なためプレーンテキストのみ保持）
        let text = String(result.text.characters)
        if result.isFinal {
            // 確定テキストを蓄積（区切りごとに追記）
            finalizedText += text
        } else {
            // 暫定テキスト → UI にリアルタイム表示（確定済み + 暫定を結合して表示）
            liveTranscription = finalizedText + text
        }
    }
    // 録音停止後、蓄積した finalizedText を Recording.transcription に保存
}
```

### 主要コンポーネント

| クラス | 役割 |
|--------|------|
| `SpeechAnalyzer` | 分析セッションを管理。モジュールを追加して使用 |
| `SpeechTranscriber` | 音声→テキスト変換モジュール |
| `SpeechDetector` | 音声区間の検出（VAD）。フルの文字起こしなしで音声有無を判定 |

### プリセット

- `.transcription` — リアルタイム文字起こしに使用。本アプリのメインプリセット
- `.offlineTranscription` — オフライン専用。録音済みファイルの一括処理（将来のリトライ処理等で使用可能）

### 仕様詳細

- 完全オンデバイス処理（ネットワーク不要、プライバシー確保）
- 言語モデルの自動ダウンロード・管理（ユーザーが設定で言語追加する必要なし）
- `ja_JP` はサポート対象ロケールに含まれる
- 結果は `AttributedString` で返却され、タイミングデータも含まれる。保存時は `String(result.text.characters)` でプレーンテキストに変換して `Recording.transcription` に格納する
- volatile（暫定）と finalized（確定）の2段階で結果がストリーム配信される
- **録音中にリアルタイムで実行** — 暫定テキストを画面に逐次表示し、確定テキストを `Recording.transcription` に保存
- **一時停止中の挙動**: 録音が一時停止されると `SpeechAnalyzer` へのバッファ供給が中断される。`SpeechAnalyzer` は内部コンテキストを保持しているため、再開後にバッファ供給が再開されればそのまま文字起こしを継続する。一時停止中にそれまでの暫定テキストが確定テキストに遷移する可能性がある
- 文字起こし失敗時はエラーメッセージを表示し、リトライボタンを提供。リトライは保存済み音声ファイルに対して `.offlineTranscription` プリセットで再処理を行う

### デバイスサポートの確認

本アプリの最小対応 OS は iOS 26.0 であり、iOS 26 対応デバイスはすべて Neural Engine（A12 Bionic 以降）を搭載しているため、`SpeechTranscriber` は全対象デバイスで利用可能である。
そのため `DictationTranscriber` 等へのフォールバックは設けず、`supportsDevice()` は防御的チェックとしてのみ使用し、万一 `false` を返した場合はユーザーにエラーメッセージを表示する。

```swift
guard SpeechTranscriber.supportsDevice() else {
    // 到達しない想定だが、防御的にエラーを表示
    throw TranscriptionError.deviceNotSupported
}
// SpeechTranscriber を使用
let transcriber = SpeechTranscriber(locale: locale, preset: .transcription)
```

## Transcription モジュール（テスト用 DI 設計）

```swift
// Transcription モジュールが公開する型
struct TranscriptionResult: Sendable {
    let text: AttributedString   // 文字起こしテキスト（タイミング情報付き）
    let isFinal: Bool            // true: 確定テキスト, false: 暫定テキスト
}

// Transcription モジュールが公開する protocol
protocol Transcribing {
    func startTranscription(locale: Locale) async throws
    func supplyBuffer(_ buffer: AVAudioPCMBuffer)
    func stopTranscription() async -> String  // 蓄積した確定テキストを返す
    var results: AsyncStream<TranscriptionResult> { get }
}
```

## 実装時の注意事項（文字起こし関連）

- **音声スレッドの並行アクセス**: `isPaused` フラグや `onBuffer` クロージャはメインスレッドから設定されるため、`AudioRecorderService` 内部で適切な同期が必要（`os_unfair_lock` や `Mutex` 等の軽量ロック推奨。音声スレッドでは `DispatchQueue` やアクターは使用不可）
- **AVAudioPCMBuffer の寿命管理と事前確保バッファプール**: tap コールバックで渡される `AVAudioPCMBuffer` はオーディオエンジンが内部バッファプールから貸し出したものであり、コールバック終了後に再利用される可能性がある。外部に渡す場合は必ず tap コールバック内でサンプルデータをコピーすること。コピーせずに非同期処理で消費すると、データ破損や無音・ノイズの混入が発生する。**コピー先のバッファはエンジン起動前に固定数（例: 8個）を事前確保（バッファプール）し、tap コールバック内では `AVAudioPCMBuffer` の新規生成（`malloc`）を行わない。** アトミックインデックスでロックフリーにプールから取得し、`update(from:count:)` でサンプルデータのみコピーする。処理キューでの消費完了後、バッファはプールのローテーションにより自動的に再利用される
- **リアルタイムスレッドからのディスパッチ**: tap コールバック内で直接 `onBuffer` クロージャを呼ぶと、呼び出し先でメモリ確保（`malloc`）、Objective-C のメッセージ送信、ロック取得などのブロッキング操作が発生し、オーディオグリッチ（音飛び・ノイズ）の原因になる。バッファプールからのコピー後は **専用のシリアルキュー**（`processingQueue`）にディスパッチしてから外部コールバックを呼ぶこと。メインキューには直接ディスパッチしない — 48kHz / 1024フレーム ≈ 毎秒47回の頻度になり UI スレッドを圧迫する
- **SpeechAnalyzer の言語モデル**: 初回起動時に日本語モデルがまだダウンロードされていない可能性がある。初回起動時にモデルの準備状況をチェックし、未ダウンロードならプログレス表示付きでダウンロードを促すオンボーディングを入れる

## バックグラウンド動作（文字起こし関連）

- バックグラウンドでも `SpeechAnalyzer` へのバッファ供給、文字起こし結果の蓄積はすべて継続する。UI 更新（文字起こしテキスト表示）のみがバックグラウンドでは反映されない
- フォアグラウンド復帰時に蓄積済みの `finalizedText` と `liveTranscription` を UI に即座に反映する
