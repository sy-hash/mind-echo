# Recording Waveform Design

## Overview

Recording during the home screen currently only shows elapsed time. Users cannot visually confirm that audio is actually being captured. This design adds a real-time waveform visualization during recording using [DSWaveformImage](https://github.com/dmrschmidt/DSWaveformImage).

## Library

**DSWaveformImage** (v14.x) — two modules:
- `DSWaveformImage`: core waveform generation
- `DSWaveformImageViews`: SwiftUI views (`WaveformLiveCanvas`)

Added to **App Target only** (`MindEcho.xcodeproj`). MindEchoAudio remains dependency-free.

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
AVAudioEngine (installTap) → AudioRecorderService → HomeViewModel → WaveformLiveCanvas
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

### 4. HomeView (`MindEcho/MindEcho/Views/HomeView.swift`)

Insert `WaveformLiveCanvas` below the duration display:
```swift
import DSWaveformImageViews

// Inside recording block:
WaveformLiveCanvas(
    samples: viewModel.audioLevels,
    configuration: Waveform.Configuration(
        style: .striped(.init(color: .red, width: 3, spacing: 2)),
        damping: .init()
    ),
    shouldDrawSilencePadding: true
)
.frame(height: 60)
```

### 5. MockAudioRecorderService (`MindEcho/MindEcho/Mocks/MockAudioRecorderService.swift`)

Add `var audioLevels: [Float] = []` to conform to updated protocol.

### 6. MindEcho.xcodeproj

Add DSWaveformImage as SPM dependency (v14.x):
- Repository: `https://github.com/dmrschmidt/DSWaveformImage`
- Products: `DSWaveformImage`, `DSWaveformImageViews`

## Pause Behavior

| State | Waveform |
|-------|----------|
| Recording | Live waveform displayed |
| Paused | Waveform remains as-is, opacity reduced to 0.5 |
| Stopped | `audioLevels` cleared, waveform disappears |

## Dependencies

- **DSWaveformImage** v14.x (SPM, App Target only)
- MindEchoAudio: no new dependencies

## Testing

- No new unit tests needed (RMS depends on `AVAudioPCMBuffer`, hard to mock; waveform is pure visual)
- Mock updated for protocol conformance
- Existing UI tests unaffected (no dependency on waveform)
- Manual verification on real device required

## Files Changed

| File | Change |
|------|--------|
| `AudioRecording.swift` | Add `audioLevels` property |
| `AudioRecorderService.swift` | Add RMS calculation in tap callback |
| `HomeViewModel.swift` | Forward `audioLevels` |
| `HomeView.swift` | Integrate `WaveformLiveCanvas` |
| `MockAudioRecorderService.swift` | Add `audioLevels` property |
| `MindEcho.xcodeproj` | Add DSWaveformImage SPM dependency |
