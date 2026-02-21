## Project Overview

**MindEcho**: SwiftUI + SwiftData による iOS ジャーナリングアプリ（iOS 26.0+）

## Architecture

マルチモジュール構成：

- **MindEchoCore**: ドメインモデル・日付ロジック・ファイル管理（`JournalEntry`, `DateHelper` 等）
- **MindEchoAudio**: 録音・再生・音声処理（`AudioRecorderService`, `AudioPlayerService` 等）
- **MindEchoApp**: Views, ViewModels, ExportService 実装

**重要な制約**: MindEchoAudio は MindEchoCore に依存しない。ExportServiceImpl は App Target に配置。

## Development

- Xcode 16.2+, Swift 6.2
- **ビルド**: `xcodebuild build -project MindEcho/MindEcho.xcodeproj -scheme MindEcho -destination 'platform=iOS Simulator,name=iPhone 17'`
- **テスト**: 必ず Task ツール（サブエージェント）経由で実行。直接 `xcodebuild test` を実行しない

## Coding Guidelines

- **Swift Concurrency**: MindEchoApp & MindEchoCore は Swift 6、MindEchoAudio は Swift 5
- **命名**: `<Name>View`, `<Name>ViewModel`, `<Name>Service`, Protocol は `<Action>ing`
- **Observation**: `@Observable` は protocol に付与不可。具体型で実装する

## Key Domain Concepts

- **論理日付**: 午前3時を日付境界とする。必ず `DateHelper.logicalDate(for:)` / `DateHelper.today()` を使用
- **データモデル**: `JournalEntry`（1日1件）→ `recordings[]` + `textEntries[]`

## Notes

- 詳細仕様: `/docs/design-prompt.md`
