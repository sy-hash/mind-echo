## Project Overview

**MindEcho** は、日々の記録をテキストと音声で保存できる iOS ジャーナリングアプリです。

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
| **MindEchoCore** | ドメインモデル, 日付ロジック, ファイル管理, エクスポート protocol | `JournalEntry`, `Recording`, `TextEntry`, `DateHelper`, `FilePathManager`, `Exporting` |
| **MindEchoAudio** | 録音・再生・音声結合・TTS 生成 | `AudioRecorderService`, `AudioPlayerService`, `AudioMerger`, `TTSGenerator` |
| **MindEchoApp** | Views, ViewModels, ExportService 実装, Mocks | `HomeView`, `HomeViewModel`, `ExportServiceImpl` 等 |

### Design Principles

- **MindEchoAudio は MindEchoCore に依存しない**: コンパイル時に強制。基本型のみで動作。
- **ExportServiceImpl は App Target に配置**: 両パッケージに依存するブリッジ層。
- **Observation チェーン**: `@Observable` マクロを活用。protocol には付与できないため、具体型で実装。

## File Structure

```
mind-echo/
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

### Data Model Relationships

```
JournalEntry (1日1エントリ)
├── recordings: [Recording]      (音声記録、連番管理)
└── textEntries: [TextEntry]     (テキスト記録、連番管理)
```

## Important Notes for Claude

- **設計ドキュメント**: `/docs/design-prompt.md` に詳細仕様あり
- **テスト実行**: 必ずサブエージェント（Task ツール）経由で実行
- **モジュール境界**: MindEchoAudio は MindEchoCore に依存しないこと
- **Observation**: protocol は `@Observable` にできない。具体型で実装する
- **日付処理**: 必ず `DateHelper` を使用。午前3時境界を考慮
