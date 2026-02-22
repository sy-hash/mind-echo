# 音声書き起こし機能 実装計画

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** HomeView の録音セルに書き起こしボタンを追加し、SpeechAnalyzer でオンデバイス書き起こしを行うモーダルを実装する。

**Architecture:** TranscriptionView が Recording を受け取り、内部で TranscriptionViewModel を生成して書き起こしを自己完結的に実行する。TranscriptionService が SpeechAnalyzer をラップし、ViewModel はクロージャ注入で mock 差し替え可能にする。

**Tech Stack:** SwiftUI, Speech framework (SpeechAnalyzer, SpeechTranscriber), AVFAudio, Swift Testing

**Design Doc:** `docs/plans/2026-02-22-speech-transcription-design.md`

---

### Task 1: TranscriptionService を作成

**Files:**
- Create: `MindEcho/MindEcho/Services/TranscriptionService.swift`

**Step 1: TranscriptionService を実装**

```swift
import AVFAudio
import Speech

struct TranscriptionService {
    func transcribe(audioFileURL: URL, locale: Locale) async throws -> String {
        let transcriber = SpeechTranscriber(locale: locale, preset: .offlineTranscription)

        async let transcriptionFuture = try transcriber.results.reduce("") { partialResult, result in
            partialResult + result.text + " "
        }

        let analyzer = SpeechAnalyzer(modules: [transcriber])

        if let lastSample = try await analyzer.analyzeSequence(
            from: AVAudioFile(forReading: audioFileURL)
        ) {
            try await analyzer.finalizeAndFinish(through: lastSample)
        } else {
            await analyzer.cancelAndFinishNow()
        }

        let resultText = try await transcriptionFuture
        return resultText.trimmingCharacters(in: .whitespaces)
    }
}
```

**Step 2: ビルド確認**

Run: `xcodebuild build -project MindEcho/MindEcho.xcodeproj -scheme MindEcho -destination 'platform=iOS Simulator,name=iPhone 17'`
Expected: BUILD SUCCEEDED

> Note: `SpeechAnalyzer` は iOS 26+ API のため、Xcode 26 + iOS 26 SDK が必要。ビルドエラーが出た場合は API の可用性を確認する。

**Step 3: コミット**

```bash
git add MindEcho/MindEcho/Services/TranscriptionService.swift
git commit -m "feat: add TranscriptionService wrapping SpeechAnalyzer"
```

---

### Task 2: TranscriptionViewModel を作成

**Files:**
- Create: `MindEcho/MindEcho/ViewModels/TranscriptionViewModel.swift`

**Step 1: TranscriptionViewModel を実装**

```swift
import Foundation
import MindEchoCore
import Observation
import Speech

@Observable
final class TranscriptionViewModel {
    enum State: Equatable {
        case idle
        case loading
        case success(String)
        case failure(String)
    }

    private(set) var state: State = .idle

    var transcribe: (URL, Locale) async throws -> String = TranscriptionService().transcribe

    func startTranscription(recording: Recording) async {
        state = .loading

        let status = SFSpeechRecognizer.authorizationStatus()
        if status == .notDetermined {
            let granted = await withCheckedContinuation { continuation in
                SFSpeechRecognizer.requestAuthorization { status in
                    continuation.resume(returning: status == .authorized)
                }
            }
            if !granted {
                state = .failure("音声認識の権限が許可されていません。設定アプリから許可してください。")
                return
            }
        } else if status != .authorized {
            state = .failure("音声認識の権限が許可されていません。設定アプリから許可してください。")
            return
        }

        let fileURL = FilePathManager.recordingsDirectory
            .appendingPathComponent(recording.audioFileName)

        do {
            let text = try await transcribe(fileURL, Locale(identifier: "ja-JP"))
            state = text.isEmpty ? .failure("書き起こし結果が空でした。") : .success(text)
        } catch {
            state = .failure("書き起こしに失敗しました: \(error.localizedDescription)")
        }
    }
}
```

**Step 2: ビルド確認**

Run: `xcodebuild build -project MindEcho/MindEcho.xcodeproj -scheme MindEcho -destination 'platform=iOS Simulator,name=iPhone 17'`
Expected: BUILD SUCCEEDED

**Step 3: コミット**

```bash
git add MindEcho/MindEcho/ViewModels/TranscriptionViewModel.swift
git commit -m "feat: add TranscriptionViewModel with state management and DI"
```

---

### Task 3: TranscriptionViewModel のユニットテスト

**Files:**
- Create: `MindEcho/MindEchoTests/TranscriptionViewModelTests.swift`

テストパターンは既存の `HomeViewModelTests.swift` に準拠する:
- Swift Testing フレームワーク（`@Test`, `#expect`）
- `@MainActor struct`
- mock はクロージャで注入

**Step 1: テストファイルを作成**

```swift
import Testing
import Foundation
import MindEchoCore
import SwiftData
@testable import MindEcho

@MainActor
struct TranscriptionViewModelTests {
    private func makeRecording() throws -> Recording {
        Recording(
            sequenceNumber: 1,
            audioFileName: "20260222_120000.m4a",
            duration: 10.0
        )
    }

    @Test func initialState_isIdle() {
        let vm = TranscriptionViewModel()
        #expect(vm.state == .idle)
    }

    @Test func startTranscription_showsLoadingThenSuccess() async throws {
        let vm = TranscriptionViewModel()
        vm.transcribe = { _, _ in
            try await Task.sleep(for: .milliseconds(100))
            return "テスト書き起こし結果"
        }

        let recording = try makeRecording()

        // Start transcription in background task to check intermediate state
        let task = Task {
            await vm.startTranscription(recording: recording)
        }

        // Give time for loading state to be set
        try await Task.sleep(for: .milliseconds(50))
        #expect(vm.state == .loading)

        // Wait for completion
        await task.value
        #expect(vm.state == .success("テスト書き起こし結果"))
    }

    @Test func startTranscription_showsLoadingThenFailure() async throws {
        let vm = TranscriptionViewModel()
        vm.transcribe = { _, _ in
            try await Task.sleep(for: .milliseconds(100))
            throw NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "テストエラー"])
        }

        let recording = try makeRecording()

        let task = Task {
            await vm.startTranscription(recording: recording)
        }

        try await Task.sleep(for: .milliseconds(50))
        #expect(vm.state == .loading)

        await task.value
        if case .failure(let message) = vm.state {
            #expect(message.contains("テストエラー"))
        } else {
            Issue.record("Expected failure state")
        }
    }

    @Test func startTranscription_emptyResult_showsFailure() async throws {
        let vm = TranscriptionViewModel()
        vm.transcribe = { _, _ in "" }

        let recording = try makeRecording()
        await vm.startTranscription(recording: recording)
        #expect(vm.state == .failure("書き起こし結果が空でした。"))
    }
}
```

**Step 2: テストを実行して成功を確認**

Run: `xcodebuild test -project MindEcho/MindEcho.xcodeproj -scheme MindEcho -destination 'platform=iOS Simulator,id=<DeviceID>' -only-testing:MindEchoTests/TranscriptionViewModelTests`
Expected: 4 tests PASSED

> Note: `startTranscription` 内の `SFSpeechRecognizer.authorizationStatus()` はシミュレータ環境で `.authorized` を返さない可能性がある。テストが権限チェックで失敗する場合は、権限チェックもクロージャ注入に変更する必要がある。その場合 TranscriptionViewModel に `var checkAuthorization: () async -> Bool` を追加し、テストでは `{ true }` を注入する。

**Step 3: コミット**

```bash
git add MindEcho/MindEchoTests/TranscriptionViewModelTests.swift
git commit -m "test: add TranscriptionViewModel unit tests with mock transcription"
```

---

### Task 4: TranscriptionView を作成

**Files:**
- Create: `MindEcho/MindEcho/Views/TranscriptionView.swift`

**Step 1: TranscriptionView を実装**

```swift
import MindEchoCore
import SwiftUI

struct TranscriptionView: View {
    let recording: Recording
    @State private var viewModel = TranscriptionViewModel()

    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.state {
                case .idle, .loading:
                    ProgressView("書き起こし中...")
                        .accessibilityIdentifier("transcription.loading")
                case .success(let text):
                    ScrollView {
                        Text(text)
                            .padding()
                            .textSelection(.enabled)
                            .accessibilityIdentifier("transcription.resultText")
                    }
                case .failure(let message):
                    ContentUnavailableView {
                        Label("エラー", systemImage: "exclamationmark.triangle")
                    } description: {
                        Text(message)
                    }
                    .accessibilityIdentifier("transcription.error")
                }
            }
            .navigationTitle("書き起こし #\(recording.sequenceNumber)")
            .navigationBarTitleDisplayMode(.inline)
        }
        .task {
            await viewModel.startTranscription(recording: recording)
        }
    }
}
```

**Step 2: ビルド確認**

Run: `xcodebuild build -project MindEcho/MindEcho.xcodeproj -scheme MindEcho -destination 'platform=iOS Simulator,name=iPhone 17'`
Expected: BUILD SUCCEEDED

**Step 3: コミット**

```bash
git add MindEcho/MindEcho/Views/TranscriptionView.swift
git commit -m "feat: add TranscriptionView with loading, success, and error states"
```

---

### Task 5: HomeView に書き起こしボタンを追加

**Files:**
- Modify: `MindEcho/MindEcho/Views/HomeView.swift:8-11` (State 追加)
- Modify: `MindEcho/MindEcho/Views/HomeView.swift:96-119` (録音行に書き起こしボタン追加)
- Modify: `MindEcho/MindEcho/Views/HomeView.swift:148` (.sheet 追加)

**Step 1: State プロパティを追加**

`HomeView.swift` の既存 `@State` プロパティ群（10-11行目付近）の後に追加:

```swift
@State private var transcriptionTargetRecording: Recording?
```

**Step 2: 録音行に書き起こしボタンを追加**

`HomeView.swift` の録音行 HStack 内（96-103行目付近）を変更。
既存の `Spacer()` と再生アイコンの間にボタンを追加する:

```swift
HStack {
    Text("#\(recording.sequenceNumber)")
        .font(.headline)
    Text(formatDuration(recording.duration))
        .foregroundStyle(.secondary)
    Spacer()
    Button {
        transcriptionTargetRecording = recording
    } label: {
        Image(systemName: "doc.text")
    }
    .accessibilityIdentifier("home.transcribeButton.\(recording.sequenceNumber)")
    Image(systemName: viewModel.playingRecordingId == recording.id && viewModel.isPlaying ? "pause.fill" : "play.fill")
}
```

**Step 3: .sheet モディファイアを追加**

`HomeView.swift` の既存 `.sheet(isPresented: $showTextEditor)` の後（148行目の `}` の後）に追加:

```swift
.sheet(item: $transcriptionTargetRecording) { recording in
    TranscriptionView(recording: recording)
        .accessibilityIdentifier("home.transcriptionSheet")
}
```

> Note: `Recording` は `@Model` マクロにより `Identifiable` に準拠しているため、`.sheet(item:)` がそのまま使える。

**Step 4: ビルド確認**

Run: `xcodebuild build -project MindEcho/MindEcho.xcodeproj -scheme MindEcho -destination 'platform=iOS Simulator,name=iPhone 17'`
Expected: BUILD SUCCEEDED

**Step 5: コミット**

```bash
git add MindEcho/MindEcho/Views/HomeView.swift
git commit -m "feat: add transcription button to recording rows in HomeView"
```

---

### Task 6: Info.plist に音声認識権限を追加

**Files:**
- Modify: `MindEcho/MindEcho/Info.plist`

**Step 1: NSSpeechRecognitionUsageDescription を追加**

`Info.plist` の `<dict>` 内（12行目 `</array>` の後）に追加:

```xml
	<key>NSSpeechRecognitionUsageDescription</key>
	<string>録音内容の書き起こしに音声認識を使用します。</string>
```

**Step 2: ビルド確認**

Run: `xcodebuild build -project MindEcho/MindEcho.xcodeproj -scheme MindEcho -destination 'platform=iOS Simulator,name=iPhone 17'`
Expected: BUILD SUCCEEDED

**Step 3: コミット**

```bash
git add MindEcho/MindEcho/Info.plist
git commit -m "feat: add speech recognition usage description to Info.plist"
```

---

### Task 7: 全テスト実行と最終確認

**Step 1: 全ユニットテストを実行**

Run: `xcodebuild test -project MindEcho/MindEcho.xcodeproj -scheme MindEcho -destination 'platform=iOS Simulator,id=<DeviceID>' -only-testing:MindEchoTests`
Expected: ALL PASSED

既存テスト（HomeViewModelTests 等）が壊れていないことを確認する。

**Step 2: TranscriptionViewModelTests を個別実行**

Run: `xcodebuild test -project MindEcho/MindEcho.xcodeproj -scheme MindEcho -destination 'platform=iOS Simulator,id=<DeviceID>' -only-testing:MindEchoTests/TranscriptionViewModelTests`
Expected: 4 tests PASSED

**Step 3: テスト結果に問題がなければ完了**

失敗がある場合は修正してコミット。
