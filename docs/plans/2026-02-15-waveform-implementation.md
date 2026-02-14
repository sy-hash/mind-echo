# Waveform Feedback Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add real-time audio waveform visualization during recording using DSWaveformImage library.

**Architecture:** AudioRecorderService extracts RMS levels from the existing AVAudioEngine tap callback and exposes them as `[Float]`. HomeViewModel forwards this data to HomeView, which renders it via DSWaveformImage's `WaveformLiveCanvas`.

**Tech Stack:** SwiftUI, AVFoundation, DSWaveformImage v14.x (SPM)

**Design Doc:** `docs/plans/2026-02-12-recording-waveform-design.md`

---

### Task 1: Add DSWaveformImage SPM dependency to Xcode project

**Files:**
- Modify: `MindEcho/MindEcho.xcodeproj/project.pbxproj`

**Step 1: Add the SPM package via xcodebuild**

Use `xcodebuild -addPackage` or manually add via Swift Package resolution. Since Xcode project modification via CLI for SPM is limited, use the following approach:

```bash
# Open Xcode and add manually, OR use swift package tools
# The package URL is: https://github.com/dmrschmidt/DSWaveformImage
# Version requirement: from 14.0.0
```

Alternatively, add to the project by editing `project.pbxproj` to include:
- Remote package reference: `https://github.com/dmrschmidt/DSWaveformImage`
- Version: `14.0.0` up to next major
- Products to link: `DSWaveformImage`, `DSWaveformImageViews`

**Step 2: Verify the dependency resolves**

Run:
```bash
xcodebuild -resolvePackageDependencies \
  -project /Users/sy-hash/Projects/mind-echo/MindEcho/MindEcho.xcodeproj \
  -scheme MindEcho
```
Expected: resolves without errors.

**Step 3: Verify build still succeeds**

Run:
```bash
xcodebuild build \
  -project /Users/sy-hash/Projects/mind-echo/MindEcho/MindEcho.xcodeproj \
  -scheme MindEcho \
  -destination 'platform=iOS Simulator,name=iPhone 17'
```
Expected: BUILD SUCCEEDED

**Step 4: Commit**

```bash
git add MindEcho/MindEcho.xcodeproj/project.pbxproj
git commit -m "Add DSWaveformImage v14 SPM dependency"
```

---

### Task 2: Add audioLevels to AudioRecording protocol and MockAudioRecorderService

**Files:**
- Modify: `Packages/MindEchoAudio/Sources/MindEchoAudio/AudioRecording.swift`
- Modify: `MindEcho/MindEcho/Mocks/MockAudioRecorderService.swift`

**Step 1: Add audioLevels property to AudioRecording protocol**

In `Packages/MindEchoAudio/Sources/MindEchoAudio/AudioRecording.swift`, add a new property:

```swift
public protocol AudioRecording {
    var isRecording: Bool { get }
    var isPaused: Bool { get }
    var audioLevels: [Float] { get }
    func startRecording(to url: URL) throws
    func pauseRecording()
    func resumeRecording()
    func stopRecording()
}
```

**Step 2: Update MockAudioRecorderService to conform**

In `MindEcho/MindEcho/Mocks/MockAudioRecorderService.swift`, add:

```swift
var audioLevels: [Float] = []
```

Add it after the existing `isPaused` property (line 8).

**Step 3: Verify build**

```bash
xcodebuild build \
  -project /Users/sy-hash/Projects/mind-echo/MindEcho/MindEcho.xcodeproj \
  -scheme MindEcho \
  -destination 'platform=iOS Simulator,name=iPhone 17'
```
Expected: BUILD SUCCEEDED (AudioRecorderService will fail until Task 3, but the protocol + mock should compile)

Note: This step may fail because `AudioRecorderService` doesn't conform yet. If so, proceed to Task 3 before building.

**Step 4: Commit (may combine with Task 3 if build fails)**

```bash
git add Packages/MindEchoAudio/Sources/MindEchoAudio/AudioRecording.swift \
       MindEcho/MindEcho/Mocks/MockAudioRecorderService.swift
git commit -m "Add audioLevels property to AudioRecording protocol"
```

---

### Task 3: Implement RMS calculation in AudioRecorderService

**Files:**
- Modify: `Packages/MindEchoAudio/Sources/MindEchoAudio/AudioRecorderService.swift`

**Step 1: Add audioLevels property**

Add after `isPaused` (line 27):

```swift
public var audioLevels: [Float] = []
```

**Step 2: Add RMS calculation in the installTap callback**

Replace the existing `installTap` block (lines 67-71) with:

```swift
let flag = pauseFlag
inputNode.installTap(onBus: 0, bufferSize: 4096, format: format) { [weak self] buffer, _ in
    if !flag.value {
        try? file.write(from: buffer)
    }

    // Calculate RMS level from audio buffer
    guard let channelData = buffer.floatChannelData?[0] else { return }
    let frameLength = Int(buffer.frameLength)
    var sum: Float = 0
    for i in 0..<frameLength {
        let sample = channelData[i]
        sum += sample * sample
    }
    let rms = sqrt(sum / Float(frameLength))

    // Convert to dB and normalize to 0.0-1.0
    let db = 20 * log10(max(rms, 1e-6))
    let minDb: Float = -60
    let maxDb: Float = 0
    let normalized = max(0, min(1, (db - minDb) / (maxDb - minDb)))

    DispatchQueue.main.async {
        self?.audioLevels.append(normalized)
    }
}
```

**Step 3: Clear audioLevels in stopRecording()**

In `stopRecording()`, add `audioLevels = []` after `pauseFlag.value = false` (line 97):

```swift
public func stopRecording() {
    audioEngine?.inputNode.removeTap(onBus: 0)
    audioEngine?.stop()
    audioEngine = nil
    audioFile = nil
    isRecording = false
    isPaused = false
    pauseFlag.value = false
    audioLevels = []

    try? AVAudioSession.sharedInstance().setActive(false)
}
```

**Step 4: Verify build**

```bash
xcodebuild build \
  -project /Users/sy-hash/Projects/mind-echo/MindEcho/MindEcho.xcodeproj \
  -scheme MindEcho \
  -destination 'platform=iOS Simulator,name=iPhone 17'
```
Expected: BUILD SUCCEEDED

**Step 5: Commit**

```bash
git add Packages/MindEchoAudio/Sources/MindEchoAudio/AudioRecorderService.swift
git commit -m "Add RMS-based audio level extraction to AudioRecorderService"
```

---

### Task 4: Forward audioLevels in HomeViewModel

**Files:**
- Modify: `MindEcho/MindEcho/ViewModels/HomeViewModel.swift`

**Step 1: Add computed property**

In `HomeViewModel`, add after `isRecordingPaused` (line 43):

```swift
var audioLevels: [Float] { audioRecorder.audioLevels }
```

**Step 2: Verify build**

```bash
xcodebuild build \
  -project /Users/sy-hash/Projects/mind-echo/MindEcho/MindEcho.xcodeproj \
  -scheme MindEcho \
  -destination 'platform=iOS Simulator,name=iPhone 17'
```
Expected: BUILD SUCCEEDED

**Step 3: Commit**

```bash
git add MindEcho/MindEcho/ViewModels/HomeViewModel.swift
git commit -m "Forward audioLevels from recorder to HomeViewModel"
```

---

### Task 5: Integrate WaveformLiveCanvas in HomeView

**Files:**
- Modify: `MindEcho/MindEcho/Views/HomeView.swift`

**Step 1: Add imports**

At the top of `HomeView.swift`, add:

```swift
import DSWaveformImage
import DSWaveformImageViews
```

**Step 2: Add WaveformLiveCanvas between duration and controls**

After the recording duration `Text` (line 32) and before the `HStack` for controls (line 36), insert:

```swift
// Recording duration (shown when recording)
if viewModel.isRecording {
    Text(formatDuration(viewModel.recordingDuration))
        .font(.system(.largeTitle, design: .monospaced))
        .accessibilityIdentifier("home.recordingDuration")

    WaveformLiveCanvas(
        samples: viewModel.audioLevels,
        configuration: Waveform.Configuration(
            style: .striped(.init(color: .red, width: 3, spacing: 2)),
            damping: .init()
        ),
        shouldDrawSilencePadding: true
    )
    .frame(height: 60)
    .opacity(viewModel.isRecordingPaused ? 0.5 : 1.0)
}
```

This replaces the existing `if viewModel.isRecording` block for duration (lines 29-33). The waveform is placed between the duration text and the control buttons.

**Step 3: Verify build**

```bash
xcodebuild build \
  -project /Users/sy-hash/Projects/mind-echo/MindEcho/MindEcho.xcodeproj \
  -scheme MindEcho \
  -destination 'platform=iOS Simulator,name=iPhone 17'
```
Expected: BUILD SUCCEEDED

**Step 4: Commit**

```bash
git add MindEcho/MindEcho/Views/HomeView.swift
git commit -m "Add live waveform visualization to recording UI"
```

---

### Task 6: Run existing tests to verify no regressions

**Step 1: Run all tests**

```bash
xcodebuild test \
  -project /Users/sy-hash/Projects/mind-echo/MindEcho/MindEcho.xcodeproj \
  -scheme MindEcho \
  -destination 'platform=iOS Simulator,name=iPhone 17'
```
Expected: All existing tests pass.

**Step 2: If tests fail, investigate and fix**

Common issues:
- `MockAudioRecorderService` missing `audioLevels` (should be fixed in Task 2)
- Import errors for DSWaveformImage in test targets (add framework search path if needed)
