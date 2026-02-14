# Recording Waveform Design

## Overview

Recording during the home screen currently only shows elapsed time. Users cannot visually confirm that audio is actually being captured. This design adds a real-time waveform bar visualization during recording.

## Style

Real-time vertical bars flowing from left to right (similar to Apple Voice Memos or LINE recording UI).

## Placement

Between the recording duration display and the control buttons (pause/stop).

```
+---------------------------+
|          今日              |
|                           |
|         0:23              |  ← Recording duration
|   ▏▎▍▌▋█▊▋▌▍▎▏▎▍▌▋█▊▋   |  ← Waveform (NEW)
|      ⏸        ⏹          |  ← Control buttons
|                           |
|     テキスト入力            |
|                           |
|   #1  0:45  ▶             |
|   #2  1:12  ▶             |
+---------------------------+
```

## Data Flow

```
AVAudioEngine (installTap) → AudioRecorderService → HomeViewModel → WaveformView
```

The existing `installTap` callback in `AudioRecorderService` receives `AVAudioPCMBuffer`. RMS (root mean square) is calculated from the buffer's `floatChannelData`, converted to a normalized 0.0-1.0 level, and appended to `audioLevels`.

## Changes

### 1. AudioRecording Protocol (`Packages/MindEchoAudio/Sources/MindEchoAudio/AudioRecording.swift`)

Add:
```swift
var audioLevels: [Float] { get }
```

### 2. AudioRecorderService (`Packages/MindEchoAudio/Sources/MindEchoAudio/AudioRecorderService.swift`)

- Add `public var audioLevels: [Float] = []` property
- In the `installTap` callback, calculate RMS from `buffer.floatChannelData`
- Convert to dB, then normalize to 0.0-1.0 range
- Dispatch to main thread to update `audioLevels`
- Clear `audioLevels` in `stopRecording()`
- Current `bufferSize: 4096` at 44100Hz sample rate yields ~0.09s update interval (good granularity)

### 3. HomeViewModel (`MindEcho/MindEcho/ViewModels/HomeViewModel.swift`)

Add computed property forwarding from recorder:
```swift
var audioLevels: [Float] { audioRecorder.audioLevels }
```

### 4. WaveformView (NEW: `MindEcho/MindEcho/Views/WaveformView.swift`)

```swift
struct WaveformView: View {
    let levels: [Float]       // 0.0-1.0 normalized audio levels
    let isPaused: Bool        // Whether recording is paused
    let barWidth: CGFloat     // Width of each bar (default: 3pt)
    let barSpacing: CGFloat   // Space between bars (default: 2pt)
    let maxBars: Int          // Max visible bars
}
```

Display logic:
- Take the last `maxBars` entries from `levels` array
- Bar height = level * view height (minimum 2pt guaranteed)
- Rightmost bar is newest, older data flows left
- `maxBars` auto-calculated from view width via `GeometryReader`

Visual properties:
- Bar color: `Color.red` (consistent with recording button)
- Corner radius: 1.5 (half of bar width)
- View height: fixed 60pt
- When paused: waveform remains, opacity reduced to 0.5

### 5. HomeView (`MindEcho/MindEcho/Views/HomeView.swift`)

Insert `WaveformView` below the duration display:
```swift
if viewModel.isRecording {
    Text(formatDuration(viewModel.recordingDuration))
    WaveformView(
        levels: viewModel.audioLevels,
        isPaused: viewModel.isRecordingPaused
    )
    .frame(height: 60)
    .accessibilityIdentifier("home.waveform")
}
```

### 6. MockAudioRecorderService (`MindEcho/MindEcho/Mocks/MockAudioRecorderService.swift`)

Add `var audioLevels: [Float] = []` to conform to updated protocol.

## Pause Behavior

- When paused: waveform bars remain displayed as-is, no new bars added, opacity reduced to 0.5
- When resumed: new bars continue from where it left off
- When stopped: `audioLevels` cleared, waveform disappears

## Dependencies

None. Uses only standard Apple frameworks (AVFoundation + SwiftUI).

## Testing

- No new unit tests needed (RMS depends on `AVAudioPCMBuffer`, hard to mock; `WaveformView` is pure visual)
- Mock updated for protocol conformance
- Existing UI tests unaffected (no dependency on waveform)
- Manual verification on real device required

## Files Changed

| File | Change |
|------|--------|
| `AudioRecording.swift` | Add `audioLevels` property |
| `AudioRecorderService.swift` | Add RMS calculation in tap callback |
| `HomeViewModel.swift` | Forward `audioLevels` |
| `WaveformView.swift` | **New file** - waveform bar rendering |
| `HomeView.swift` | Integrate `WaveformView` |
| `MockAudioRecorderService.swift` | Add `audioLevels` property |
