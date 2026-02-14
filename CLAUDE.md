# CLAUDE.md

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
