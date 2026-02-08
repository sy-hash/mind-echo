# iOS ジャーナリングアプリ 設計プロンプト

## アプリ概要

毎日の記録をテキストと音声で残せるジャーナリングアプリ。
音声入力は録音保存に加えて文字起こしも行い、手軽に振り返りができる。

**本アプリの主な目的は、日々の記録を AI アプリに連携・共有し、分析してもらうためのフロントエンドとなること。**
ユーザーは本アプリで手軽に音声やテキストを記録し、
それらのデータを AI アプリに渡して振り返り・要約・傾向分析などを行う。
現時点では主に Google NotebookLM を連携先として想定しているが、
将来的には他の AI アプリ（ChatGPT、Gemini、Claude 等）への連携も視野に入れる。

## 技術スタック

| 項目 | 選定 |
|------|------|
| UI フレームワーク | SwiftUI |
| データ永続化 | SwiftData |
| 音声録音 | AVFoundation (AVAudioRecorder) |
| 音声文字起こし | SpeechAnalyzer / SpeechTranscriber（iOS 26 新API） |
| 波形表示 | OSS ライブラリを使用（後述） |
| 最小対応 OS | iOS 26.0（SpeechAnalyzer + SwiftData） |
| データ保存先 | ローカルのみ |

### 波形表示ライブラリ候補

必要に応じて以下のオープンソースライブラリから選定する。すべて SPM 対応・MIT ライセンス。

| ライブラリ | 用途 | 特徴 |
|-----------|------|------|
| [DSWaveformImage](https://github.com/dmrschmidt/DSWaveformImage) | 録音中のリアルタイム波形 + ファイル波形表示 | SwiftUI ネイティブ対応、ライブ録音用 `WaveformLiveView` とファイル用 `WaveformView` の両方あり。依存ゼロ、Stars 1,200+、活発にメンテナンス中 |
| [AudioKit/Waveform](https://github.com/AudioKit/Waveform) | ファイル波形表示 | GPU アクセラレーション（Metal）、SwiftUI 対応。AudioKit エコシステム |
| [FDWaveformView](https://github.com/fulldecent/FDWaveformView) | ファイル波形表示 + スクラブ | ズーム・スクロール・スクラブ操作対応。UIKit ベース |

**推奨: DSWaveformImage** — 録音中のリアルタイム波形（`WaveformLiveView`）と再生時のファイル波形（`WaveformView`）の両方をカバーでき、依存ライブラリもゼロ、SwiftUI にネイティブ対応している。

## データモデル

SwiftData の `@Model` マクロはすでに Observable に準拠しているため、
モデル層はそのまま SwiftUI のリアクティブ更新に対応する。
ViewModel 層では `@Observable` マクロ（Observation フレームワーク）を使用する。

### ER図

```mermaid
erDiagram
    JournalEntry {
        UUID id PK
        Date date UK "論理日付（日単位で一意、午前3時区切り）"
        Date createdAt
        Date updatedAt
        String textContent "テキスト入力の内容（nullable）"
        String audioFileName "音声ファイル名（nullable）"
        TimeInterval audioDuration "録音の合計時間（秒）"
        String transcription "文字起こし結果（nullable）"
        Bool isTranscribing "文字起こし処理中フラグ"
    }

    JournalEntry ||--o| AudioFile : "1日1ファイル"
    JournalEntry ||--o| TextFile : "1日1ファイル"

    AudioFile {
        String fileName "例: 20250207_a1b2c3d4.m4a"
        String directory "Application Support/Recordings/"
        String format "AAC (.m4a)"
    }

    TextFile {
        String fileName "例: 20250207_journal.txt"
        String directory "Application Support/Journals/"
        String format "UTF-8 (.txt)"
    }

    ExportedFile {
        String fileName "例: 20250207_merged.m4a or 20250207_journal.txt"
        String directory "Documents/Exports/"
        String format "AAC (.m4a) または UTF-8 (.txt)"
    }
```

- `JournalEntry` は SwiftData で管理されるエンティティ
- `AudioFile` / `TextFile` は物理ファイル（DB 外）を表す概念エンティティ
- `JournalEntry.audioFileName` と `AudioFile.fileName` が対応する
- `JournalEntry.textContent` の内容が `TextFile` に同期書き出しされる
- 1日1エントリに対して、音声ファイル・テキストファイルはそれぞれ最大1つ（0 or 1）

### JournalEntry（日記エントリ）

1日1エントリ。録音ファイルもテキストファイルも1日1ファイルのみ。
録音は何度でも中断・再開でき、すべて同一ファイルに追記される。

**日付変更のしきい値は午前3:00。**
0:00〜2:59 の操作は前日のエントリに記録される。
例: 2月8日 午前1:30 の録音 → 2月7日のエントリに追記。

```swift
@Model
class JournalEntry {
    var id: UUID
    var date: Date                    // エントリの日付（日単位で一意）
    var createdAt: Date
    var updatedAt: Date
    var textContent: String?          // テキスト入力の内容
    var audioFileName: String?        // 音声ファイル名（nil = 録音なし）
    var audioDuration: TimeInterval   // 録音の合計時間（秒）
    var transcription: String?        // 文字起こし結果
    var isTranscribing: Bool          // 文字起こし処理中フラグ
}
```

### ViewModel 層（@Observable）

```swift
import Observation
import SwiftData

@Observable
class HomeViewModel {
    var isRecording = false
    var isPaused = false              // 録音一時停止中
    var recordingDuration: TimeInterval = 0
    var todayEntry: JournalEntry?
    var errorMessage: String?

    private let modelContext: ModelContext
    private let audioRecorder: AudioRecorderService
    private let transcriptionService: TranscriptionService

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.audioRecorder = AudioRecorderService()
        self.transcriptionService = TranscriptionService()
    }

    func startOrResumeRecording() { /* ... */ }
    func pauseRecording() { /* ... */ }
    func finishRecording() async { /* ... */ }
    func fetchTodayEntry() { /* ... */ }
}

@Observable
class HistoryViewModel {
    var entries: [JournalEntry] = []
    var searchText = ""
    var filteredEntries: [JournalEntry] {
        guard !searchText.isEmpty else { return entries }
        return entries.filter { /* テキスト・文字起こし内容をフィルタ */ }
    }

    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetchEntries() { /* ... */ }
    func deleteEntry(_ entry: JournalEntry) { /* ... */ }
}

@Observable
class EntryDetailViewModel {
    var entry: JournalEntry
    var isEditing = false
    var isPlaying = false

    private let modelContext: ModelContext
    private let audioPlayer: AudioPlayerService
    private let shareService: ShareService

    init(entry: JournalEntry, modelContext: ModelContext) {
        self.entry = entry
        self.modelContext = modelContext
        self.audioPlayer = AudioPlayerService()
        self.shareService = ShareService()
    }

    func togglePlayback() { /* ... */ }
    func exportForSharing(options: ShareOptions) -> [any Transferable] { /* ... */ }
}
```

### View での利用パターン

```swift
struct HomeView: View {
    @State private var viewModel: HomeViewModel

    init(modelContext: ModelContext) {
        _viewModel = State(initialValue: HomeViewModel(modelContext: modelContext))
    }

    var body: some View {
        // @Observable により viewModel のプロパティ変更で自動再描画
        // @ObservedObject や @Published は不要
    }
}
```

### SwiftData クエリとの使い分け

- **単純な一覧取得**: View 内で `@Query` マクロを直接使用
- **複雑なロジックを伴う操作**: `@Observable` な ViewModel 経由で `ModelContext` を操作

```swift
// @Query を直接使うパターン（シンプルな一覧）
struct HistoryListView: View {
    @Query(sort: \JournalEntry.date, order: .reverse)
    private var entries: [JournalEntry]
    // ...
}

// ViewModel を使うパターン（複雑な操作）
struct HomeView: View {
    @State private var viewModel: HomeViewModel
    // ...
}
```

## 画面構成

### 画面 1: ホーム画面（メイン入力画面）

アプリ起動時に表示される画面。今日の記録を素早く開始できることを最優先にする。

**レイアウト要素:**

- **日付表示（上部）** — 論理日付を「2025年2月7日（金）」のようなフォーマットで表示。午前3時より前は前日の日付を表示する
- **録音ボタン（中央・目立つ配置）** — 3つの状態を持つ:
  - 停止中 → タップで録音開始（or 既存録音への追記再開）
  - 録音中 → タップで一時停止。録音中はリアルタイム波形を表示（DSWaveformImage の `WaveformLiveView` 等を使用）
  - 一時停止中 → タップで録音再開
- **録音完了ボタン** — 録音中 or 一時停止中に表示。タップで録音を確定し、文字起こしを開始
- **テキスト入力ボタン（録音ボタンの近く）** — タップでテキスト入力モードに遷移 or シートを表示。既にテキストがある場合は編集モードで開く
- **今日のエントリプレビュー（下部、任意）** — 今日既に記録がある場合、録音時間やテキストの先頭部分を簡易表示

**動作フロー（録音）:**

1. 録音ボタンをタップ → AVAudioRecorder で録音開始
2. 一時停止ボタンをタップ → 録音を一時停止（`AVAudioRecorder.pause()`）
3. 再度録音ボタンをタップ → 録音を再開（同一ファイルに追記）
4. 手順 2〜3 を何度でも繰り返し可能
5. 録音完了ボタンをタップ → 録音を確定し、ファイルを保存
6. バックグラウンドで SpeechAnalyzer による文字起こしを実行
7. 文字起こし完了後、JournalEntry の transcription を更新
8. 同日中に再度録音ボタンを押した場合 → 既存ファイルは保持し、新しいセッション分を追記

※ 30分の上限は累計録音時間に対して適用。上限に達したら自動で録音を完了する。

**動作フロー（テキスト）:**

1. テキスト入力ボタンをタップ → テキストエディタを表示
2. 保存 → JournalEntry の textContent を更新し、`Journals/{date}_journal.txt` も同期更新

### 画面 2: 履歴一覧画面

過去の日記エントリを日付ごとに一覧表示する画面。

**レイアウト要素:**

- **日付ごとのリスト** — 新しい日付が上に来る降順表示。各セルに以下を表示:
  - 日付（例: 2月6日 木）
  - テキストの先頭数行（プレビュー）
  - 録音時間の表示（例: 🎤 12m30s）、録音なしの場合は非表示
- **検索バー（上部）** — テキスト内容・文字起こし内容をフルテキスト検索

**タップ時の遷移:**

- セルをタップ → エントリ詳細画面へ遷移

### 画面 3: エントリ詳細画面（履歴からの遷移先）

特定の日のエントリを閲覧・編集する画面。

**表示要素:**

- 日付ヘッダー
- テキスト内容（編集可能）
- 録音セクション（録音がある場合）:
  - 再生ボタン / 一時停止
  - 合計録音時間の表示
  - 文字起こしテキスト（展開/折りたたみ可能）
  - 録音削除ボタン

## ナビゲーション構成

```
TabView {
    Tab("今日", systemImage: "mic.circle.fill") {
        HomeView()           // 画面 1
    }
    Tab("履歴", systemImage: "calendar") {
        HistoryListView()    // 画面 2
            → EntryDetailView()  // 画面 3（NavigationStack で push）
    }
}
```

## 必要なパーミッション（Info.plist）

| キー | 用途 |
|------|------|
| `NSMicrophoneUsageDescription` | 音声録音のためにマイクを使用します |
| `NSSpeechRecognitionUsageDescription` | 録音した音声をテキストに変換するために使用します |

※ iOS 26 の SpeechAnalyzer ではユーザーが設定で言語を追加する必要がなくなった。
言語モデルは自動的にダウンロード・管理される。

## 音声ファイルの管理方針

### 保存先

アプリ内部で管理するファイルは `Application Support/` ディレクトリに保存し、ファイルアプリから不可視にする。
エクスポート（AI に共有）したファイルのみを `Documents/Exports/` に保存し、ファイルアプリから閲覧可能にする。
**1日につき音声ファイル1つ、テキストファイル1つのみ生成する。**

```
Application Support/
├── Recordings/          # 音声ファイル（1日1ファイル、ファイルアプリから不可視）
│   ├── 20250207_a1b2c3d4.m4a
│   └── 20250208_e5f6g7h8.m4a
├── Merged/              # 共有用の結合済み音声ファイル（一時生成、ファイルアプリから不可視）
│   └── 20250207_merged.m4a
└── Journals/            # テキスト日記（1日1ファイル、ファイルアプリから不可視）
    ├── 20250207_journal.txt
    └── 20250208_journal.txt

Documents/
└── Exports/             # エクスポート済みファイル（ファイルアプリに公開）
    ├── 20250207_merged.m4a
    ├── 20250207_journal.txt
    └── ...
```

### ファイルアプリからのアクセス

iOS のファイルアプリ（「このiPhone内」→「（アプリ名）」）から
**エクスポート済みファイル（AI に共有したファイル）だけ** を閲覧・共有できるようにする。
アプリ内部で管理する録音ファイル・テキストファイルは `Application Support/` に保存され、ファイルアプリからは不可視となる。

**Info.plist に以下を追加:**

```xml
<key>UIFileSharingEnabled</key>
<true/>
<key>LSSupportsOpeningDocumentsInPlace</key>
<true/>
```

| キー | Xcode 表示名 | 値 |
|------|-------------|-----|
| `UIFileSharingEnabled` | Application supports iTunes file sharing | YES |
| `LSSupportsOpeningDocumentsInPlace` | Supports opening documents in place | YES |

これにより、`Documents/` ディレクトリのみがファイルアプリに公開される。
`Application Support/` のファイルは公開されないため、ユーザーが誤って削除することを防げる。

※ SwiftData のストアファイルは `Application Support` に保存されるため、データベースファイルは露出しない。

### ファイル命名規則

**重要: ファイル名は半角英数字・ハイフン・アンダースコアのみを使用する。**
日本語を含めると NotebookLM へのインポート時に文字化けが発生するため禁止。
**すべてのファイルは日付（`YYYYMMDD`）をプリフィックスとし、ファイルアプリでの日付順ソートを保証する。**

**音声ファイル（1日1ファイル）:**

```
Recordings/{date}_{short-id}.m4a
```

| 要素 | 内容 | 例 |
|------|------|-----|
| `{date}` | 録音日（`YYYYMMDD`） | `20250207` |
| `{short-id}` | UUID の先頭8文字（衝突回避用） | `a1b2c3d4` |

例: `20250207_a1b2c3d4.m4a`（`Application Support/Recordings/` に保存）

- その日の初回録音時にファイルを生成
- 中断→再開のたびに同一ファイルに追記される
- 1日の中で何度中断・再開しても、生成されるファイルは1つだけ

**テキスト日記ファイル:**

```
Journals/{date}_journal.txt
```

例: `20250207_journal.txt`（`Application Support/Journals/` に保存）

- エントリ保存時に自動で生成・上書き更新される
- アプリ内でテキストを編集するたびにファイルも同期更新

### ファイルの同期タイミング

| イベント | 更新されるファイル |
|---------|-----------------|
| テキスト入力を保存 | `Application Support/Journals/{date}_journal.txt` を生成 or 上書き |
| 初回録音開始 | `Application Support/Recordings/{date}_{id}.m4a` を生成 |
| 録音の中断・再開 | 同一の `.m4a` ファイルに追記 |
| 録音完了 | `.m4a` ファイルを確定 |
| 文字起こし完了 | SwiftData（`JournalEntry.transcription`）に保存 |
| 音声共有時 | `Application Support/Merged/` に結合ファイル生成 + `Documents/Exports/` にコピー |
| テキスト共有時 | `Documents/Exports/` にテキストファイルをコピー |
| エントリ削除 | 対応する `Application Support/` 内の `.m4a` と `_journal.txt` を削除 |
| アプリ起動時（一時ファイル） | `Application Support/Merged/` 内の24時間経過ファイルを削除 |
| アプリ起動時（エクスポート） | `Documents/Exports/` 内の7日以上経過ファイルを削除 |

### フォーマット

- 音声: AAC（`.m4a`）
- 録音の最大時間: 30分（1日の累計。上限に達したら自動停止し、ユーザーに通知）
- テキスト: UTF-8（`.txt`）
- 容量表示機能は将来的に追加を検討

## 文字起こしの仕様（SpeechAnalyzer — iOS 26 新API）

iOS 26 で導入された `SpeechAnalyzer` + `SpeechTranscriber` を使用する。
従来の `SFSpeechRecognizer` に比べ、長時間音声への対応、高速処理、完全オフライン動作が大幅に改善されている。

### 基本実装パターン

```swift
import Speech
import AVFoundation

let locale = Locale(identifier: "ja_JP")
let transcriber = SpeechTranscriber(locale: locale, preset: .offlineTranscription)
let analyzer = SpeechAnalyzer(modules: [transcriber])

// 録音済みファイルから文字起こし
let audioFile = try AVAudioFile(forReading: fileURL)
if let lastSample = try await analyzer.analyzeSequence(from: audioFile) {
    try await analyzer.finalizeAndFinish(through: lastSample)
}

// 結果の取得（AsyncSequence）
for await result in transcriber.results {
    let text = result.text  // AttributedString
    let isFinal = result.isFinal
    if isFinal {
        // 確定テキストを保存
    }
}
```

### 主要コンポーネント

| クラス | 役割 |
|--------|------|
| `SpeechAnalyzer` | 分析セッションを管理。モジュールを追加して使用 |
| `SpeechTranscriber` | 音声→テキスト変換モジュール |
| `SpeechDetector` | 音声区間の検出（VAD）。フルの文字起こしなしで音声有無を判定 |

### プリセット

- `.offlineTranscription` — オフライン専用。録音済みファイルの一括処理に最適
- `.transcription` — 汎用的な文字起こし

### 仕様詳細

- 完全オンデバイス処理（ネットワーク不要、プライバシー確保）
- 言語モデルの自動ダウンロード・管理（ユーザーが設定で言語追加する必要なし）
- `ja_JP` はサポート対象ロケールに含まれる
- 結果は `AttributedString` で返却され、タイミングデータも含まれる
- volatile（暫定）と finalized（確定）の2段階で結果がストリーム配信される
- 録音停止後にバックグラウンドで非同期実行
- 処理中は `isTranscribing = true` でインジケータ表示
- 文字起こし失敗時はエラーメッセージを表示し、リトライボタンを提供

### デバイスサポートのフォールバック

```swift
if SpeechTranscriber.supportsDevice() {
    // SpeechTranscriber を使用
} else {
    // DictationTranscriber にフォールバック（旧 SFSpeechRecognizer の改良版）
    let dictationTranscriber = DictationTranscriber(locale: locale)
}
```

## 共有機能（NotebookLM 連携）

ジャーナルデータを NotebookLM にソースとして送り、AI による分析・振り返りを行う。

### 共有方式

NotebookLM には直接的な iOS URL Scheme やモバイル API は提供されていないため、
iOS 標準の共有機能（`ShareLink` / `UIActivityViewController`）を活用し、
NotebookLM が受け取れる形式でデータをエクスポートする。

### 共有対象データと形式

| 共有タイプ | 形式 | NotebookLM での扱い |
|-----------|------|-------------------|
| テキスト日記 | `.txt` ファイル（Documents に常時保存） | テキストソースとして読み込み |
| 文字起こしテキスト | 共有時にDBから取得し `.txt` として一時生成 | テキストソースとして読み込み |
| 音声ファイル | `.m4a`（Documents に常時保存） | 音声ソースとして読み込み（自動文字起こし） |

※ NotebookLM は m4a, mp3, wav, aac 等の音声ファイルを直接ソースとしてインポート可能。
音声をアップロードすると NotebookLM 側でも自動で文字起こしが行われる。

### 共有ボタンの配置

1. **エントリ詳細画面** — ナビゲーションバーに共有ボタン（`square.and.arrow.up`）

### 共有フロー

```
共有ボタンタップ
  ↓
共有内容の選択シート表示:
  □ テキスト日記
  □ 文字起こしテキスト
  □ 音声ファイル（元データ）
  ↓
選択に応じてエクスポートデータを生成
  ↓
生成したファイルを Documents/Exports/ にコピー（ファイルアプリから後からアクセス可能にする）
  ↓
iOS Share Sheet を表示
  ↓
ユーザーが共有先を選択:
  - 「ファイルに保存」→ Google Drive に保存 → NotebookLM からインポート
  - AirDrop → Mac/iPad → NotebookLM Web で直接アップロード
  - その他の共有先（メール、メッセージ等）
```

**エクスポート処理の詳細:**
- 音声ファイル結合後 → `Application Support/Merged/` に一時生成 → `Documents/Exports/` にコピー
- テキストファイル生成後 → `Documents/Exports/` にコピー
- これにより、エクスポートしたファイルはファイルアプリからも後からアクセス可能

### エクスポートフォーマット例（テキスト）

ファイル名: `20250207_journal.txt`

```
# Journal: 2025-02-07 (Fri)

## Text Entry
今日は朝からプロジェクトの打ち合わせがあった。
新機能の方向性について議論し、良い結論が出た。

## Recording 01 (14:30 / 3m24s)
### Transcription
打ち合わせ後に思ったことをメモ。
来週までにプロトタイプを作成する必要がある...

## Recording 02 (21:15 / 1m52s)
### Transcription
今日の振り返り。全体的に生産的な一日だった...
```

※ ファイル名とヘッダーラベルは半角英数字のみ。本文は日本語を含んでよい。

## 実装時の注意事項

- **SpeechAnalyzer の言語モデル**: 初回起動時に日本語モデルがまだダウンロードされていない可能性がある。初回起動時にモデルの準備状況をチェックし、未ダウンロードならプログレス表示付きでダウンロードを促すオンボーディングを入れる
- **Exports ディレクトリのクリーンアップ**: アプリ起動時に `Documents/Exports/` 内の作成から7日以上経過したファイルを自動削除する。エクスポート済みファイルはユーザーが削除しても問題ないが、定期的なクリーンアップで容量を節約する
- **Merged ディレクトリのクリーンアップ**: `Application Support/Merged/` 内の作成から24時間以上経過したファイルを自動削除する（共有用の一時ファイルのため）
- **NotebookLM の制約**: ソース1つあたり 500,000語 / 200MB の上限がある。共有時にファイルサイズを表示してユーザーに判断材料を提供する

## 考慮事項・将来の拡張

- **iCloud 同期**: SwiftData の CloudKit 連携で将来対応可能
- **一括エクスポート**: 期間を指定して複数日分のジャーナルをまとめてエクスポート
- **NotebookLM Enterprise API 連携**: Google Cloud の NotebookLM Enterprise API が利用可能になれば、アプリから直接ノートブックにソースを追加する自動化が可能
- **ウィジェット**: ホーム画面から直接録音を開始するウィジェット
- **リマインダー通知**: 毎日の記録を促すローカル通知
- **エクスポート機能**: テキスト + 文字起こしをまとめて PDF 出力
- **タグ / カテゴリ**: エントリにタグを付けて分類
- **気分トラッキング**: エントリに気分アイコンを付与
- **Foundation Models 連携**: iOS 26 のオンデバイス Foundation Models を使い、ジャーナルの要約やタイトル自動生成
