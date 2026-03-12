## Project Overview

**MindEcho** は、日々の記録を音声で保存できる iOS ジャーナリングアプリです。

- **目的**: AI アプリ（Google NotebookLM など）との連携を前提とした記録のフロントエンド
- **技術スタック**: SwiftUI, SwiftData, AVFoundation
- **対応 OS**: iOS 26.0+

## Architecture

### Module Structure

マルチモジュール構成を採用しています：

```
MindEchoApp (App Target)
├── MindEchoCore   (local Swift Package)
└── MindEchoAudio  (local Swift Package)
```

| モジュール | 責務 | 主な型 |
|-----------|------|--------|
| **MindEchoCore** | ドメインモデル, 日付ロジック, ファイル管理, エクスポート protocol | `JournalEntry`, `Recording`, `DateHelper`, `FilePathManager`, `Exporting` |
| **MindEchoAudio** | 録音・再生・音声結合・TTS 生成 | `AudioRecorderService`, `AudioPlayerService`, `AudioMerger`, `TTSGenerator` |
| **MindEchoApp** | Views, ViewModels, ExportService 実装, SummarizationService, VocabularyStore, TranscriberPreference, SummaryPromptStore, WhisperAPIService, SummarizerPreference, OpenAISummarizationService, Mocks | `HomeView`, `HomeViewModel`, `RecordingModalView`, `TranscriptionView`, `SettingsView`, `ExportServiceImpl`, `SummarizationService`, `OpenAISummarizationService`, `VocabularyStore`, `TranscriberPreference`, `TranscriberType`, `SummarizerPreference`, `SummarizerType`, `OpenAIAPIKeyStore`, `SummaryPromptStore`, `WhisperAPIService`, `VocabularyView` 等 |

### Design Principles

- **MindEchoAudio は MindEchoCore に依存しない**: コンパイル時に強制。基本型のみで動作。
- **ExportServiceImpl は App Target に配置**: 両パッケージに依存するブリッジ層。
- **Observation チェーン**: `@Observable` マクロを活用。protocol には付与できないため、具体型で実装。

## File Structure

```
mind-echo/
├── .swift-format               # swift-format 設定ファイル
├── docs/                       # 設計ドキュメント
├── Packages/
│   ├── MindEchoCore/          # ドメインモデル、日付、ファイル管理
│   └── MindEchoAudio/         # 録音・再生・音声処理
└── MindEcho/
    ├── MindEcho.xcodeproj
    ├── MindEcho/              # App Target (Views, ViewModels, Services)
    ├── MindEchoTests/         # Unit Tests
    └── MindEchoUITests/       # UI Tests
```

## Development Setup

### Requirements

- Xcode 16.2+
- Swift 6.2

### Build

```bash
# Workspace を開く
open /Users/sy-hash/Projects/mind-echo/MindEcho.xcworkspace

# または CLI でビルド
xcodebuild build \
  -project /Users/sy-hash/Projects/mind-echo/MindEcho/MindEcho.xcodeproj \
  -scheme MindEcho \
  -destination 'platform=iOS Simulator,name=iPhone 17'
```

## Test Execution

> **重要**: テストの実行は必ず Task ツール（サブエージェント）を使って行うこと。メインのコンテキストで直接 `xcodebuild test` を実行してはならない。`xcodebuild test` の出力は非常に大きく、メインのコンテキストウィンドウを圧迫するため。

### Step 1: Get available devices

```bash
xcrun simctl list devices available
```

### Step 2: Select a device

Step 1 の結果から利用するデバイスを決定する。

1. 起動中（Booted）のデバイスを優先
2. 最新の iOS バージョン（iOS 26.1）かつ `iPhone XX` 形式のモデルを優先
3. 決定したら利用する DeviceID とモデル名をユーザーに伝える

### Step 3: Run tests with the selected DeviceID

```bash
xcodebuild test \
  -project /Users/sy-hash/Projects/mind-echo/MindEcho/MindEcho.xcodeproj \
  -scheme MindEcho \
  -destination 'platform=iOS Simulator,id=<DeviceID>' \
  -only-testing:<TestTarget>/<TestSuite>/<TestCase>
```

Example:

```bash
xcodebuild test \
  -project /Users/sy-hash/Projects/mind-echo/MindEcho/MindEcho.xcodeproj \
  -scheme MindEcho \
  -destination 'platform=iOS Simulator,id=9906E265-2958-4953-88D8-19195F2739A7' \
  -only-testing:MindEchoUITests/EntryDetailUITests/testPlayButton_togglesPlaybackState
```

## Coding Guidelines

### swift-format

Apple 公式の [swift-format](https://github.com/swiftlang/swift-format) を使用してコードスタイルを統一しています。設定はプロジェクトルートの `.swift-format` を参照。

- コミット前にフォーマットを適用すること: `xcrun swift-format format --in-place --recursive <対象ディレクトリ>`

### Swift Concurrency

- **MindEchoApp & MindEchoCore**: Swift 6 language mode (strict concurrency)
- **MindEchoAudio**: Swift 5 language mode (AVFoundation callbacks のため)

### Naming Conventions

- **Views**: `<Name>View.swift` (例: `HomeView.swift`)
- **ViewModels**: `<Name>ViewModel.swift` (例: `HomeViewModel.swift`)
- **Services**: `<Name>Service.swift` (例: `AudioRecorderService.swift`)
- **Protocols**: `<Action>ing` (例: `AudioRecording`, `AudioPlaying`, `Exporting`)

## Key Domain Concepts

### Logical Date (論理日付)

午前3時を日付の境界とします。例：

- 2月15日 02:59 → 2月14日の記録
- 2月15日 03:00 → 2月15日の記録

実装: `DateHelper.logicalDate(for:)`, `DateHelper.today()`

### Transcriber Engine Preference

書き起こしエンジンの設定は、リアルタイム書き起こしと事後書き起こしで独立しています。

- `TranscriberPreference.liveType` — 録音中のリアルタイム書き起こしに使用するエンジン（`speechTranscriber`, `dictationTranscriber`）
- `TranscriberPreference.postRecordingType` — 録音完了後の書き起こしに使用するエンジン（`speechTranscriber`, `dictationTranscriber`, `whisperAPI`）
- `OpenAIAPIKeyStore` — OpenAI API キーの管理（UserDefaults に保存）
- `.whisperAPI` はポスト書き起こし専用。リアルタイム書き起こしのリストには表示しない


### Summarizer Engine Preference

要約エンジンの設定です。

- `SummarizerPreference.type` — 要約に使用するエンジン（`onDevice`, `openAI`）
- `.onDevice` — Apple Foundation Models（オンデバイス、デフォルト）
- `.openAI` — OpenAI Chat Completions API（`gpt-4o-mini`、ネットワーク必須）
- `OpenAIAPIKeyStore` の API キーは Whisper API と共有

### Data Model Relationships

```
JournalEntry (1日1エントリ)
└── recordings: [Recording]      (音声記録、連番管理)
    ├── transcription: String?   (書き起こしテキスト、SwiftData で永続化)
    └── summary: String?         (要約テキスト、Apple Foundation Models または OpenAI API で生成、SwiftData で永続化)
```

## Definition of Done

Claude がタスクを「完了」と判断する前に、以下の全項目を満たしていることを確認すること。

### 1. ビルド成功

- `xcodebuild build` がエラーなしで通ること

### 2. テスト通過

- 変更に関連する既存テスト（Unit / UI）が全て通ること
- 新機能を追加した場合は、対応するテストを追加すること

### 3. ドキュメントの更新

- 新しい型・プロトコル・モジュールを追加した場合は、CLAUDE.md の該当セクション（Architecture, File Structure 等）を更新すること
- 設計上の重要な判断を行った場合は、`docs/` 配下のドキュメントに反映すること

### 4. UI 変更時の追加要件

UI に変更を加えた場合は、以下も必須:

- `docs/ui-test-design.md` の更新（Accessibility Identifier 一覧、テストケース一覧）
- 対応する UITest の実装追加・更新（`MindEchoUITests/`）
- 新規 UI 要素には `.accessibilityIdentifier()` を付与すること

## Important Notes for Claude

- **設計ドキュメント**: `/docs/design-prompt.md` に詳細仕様あり
- **テスト実行**: 必ずサブエージェント（Task ツール）経由で実行
- **モジュール境界**: MindEchoAudio は MindEchoCore に依存しないこと
- **Observation**: protocol は `@Observable` にできない。具体型で実装する
- **日付処理**: 必ず `DateHelper` を使用。午前3時境界を考慮
- **gh コマンド**: `gh` コマンド利用時はリポジトリを明示的に指定すること。例: `gh pr list --repo sy-hash/mind-echo`
