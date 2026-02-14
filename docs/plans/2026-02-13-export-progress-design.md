# Export Progress Indicator Design

## Overview

Audio export (share button -> audio file) currently provides no UI feedback during processing. This design adds a real-time progress overlay showing step-by-step completion during audio merge and export.

## UI Style

- Full-screen semi-transparent overlay with a centered card (`.regularMaterial` background)
- SwiftUI `ProgressView(value:total:)` (linear, determinate)
- Status text: "音声を結合中… X/N"
- No cancel button (processing takes seconds to tens of seconds)

## Progress Counting

All steps are counted flat. For an entry with N recordings:

`totalSteps = 1 (TTS) + N (recordings) + 1 (write merged file) + 1 (copy to export dir) = N + 3`

Example with 3 recordings:

| Step | completedSteps | Description |
|------|---------------|-------------|
| Start | 0 / 6 | Export begins |
| TTS processed | 1 / 6 | Date announcement buffer ready |
| Recording #1 read | 2 / 6 | First recording loaded & converted |
| Recording #2 read | 3 / 6 | Second recording loaded & converted |
| Recording #3 read | 4 / 6 | Third recording loaded & converted |
| Merged file written | 5 / 6 | Combined .m4a written to disk |
| Copied to export dir | 6 / 6 | File copied to Documents/Exports/ |

## Changes

### 1. Exporting Protocol (`Packages/MindEchoCore/Sources/MindEchoCore/Exporting.swift`)

Add progress-reporting overload:

```swift
public protocol Exporting {
    // Existing (unchanged)
    func exportTextJournal(entry: JournalEntry, to directory: URL) async throws -> URL
    func exportMergedAudio(entry: JournalEntry, to directory: URL) async throws -> URL

    // New
    func exportMergedAudio(
        entry: JournalEntry,
        to directory: URL,
        onProgress: @escaping @Sendable (Int, Int) -> Void  // (completed, total)
    ) async throws -> URL
}
```

### 2. AudioMerger (`Packages/MindEchoAudio/Sources/MindEchoAudio/AudioMerger.swift`)

Add optional `onProgress` callback parameter (default `nil` to preserve backward compatibility):

```swift
public static func merge(
    ttsBuffer: AVAudioPCMBuffer?,
    recordingURLs: [URL],
    silenceDuration: TimeInterval = 0.75,
    outputURL: URL,
    onProgress: (@Sendable (Int, Int) -> Void)? = nil
) async throws -> URL
```

Progress is reported at:
- After TTS buffer processing: `(1, totalSteps)`
- After each recording file read & conversion: `(1 + index + 1, totalSteps)`
- After merged file write: `(1 + N + 1, totalSteps)`

Where `totalSteps = 1 + recordingURLs.count + 1` (excludes copy step, handled by ExportService).

### 3. ExportServiceImpl (`MindEcho/MindEcho/Services/ExportService.swift`)

Implement the new protocol method. Relay AudioMerger callbacks and add the copy step:

```swift
func exportMergedAudio(
    entry: JournalEntry,
    to directory: URL,
    onProgress: @escaping @Sendable (Int, Int) -> Void
) async throws -> URL {
    let recordingCount = entry.sortedRecordings.count
    let totalSteps = recordingCount + 3  // TTS + N recordings + write + copy

    let ttsBuffer = try await TTSGenerator.generateDateAnnouncement(for: entry.date)

    let mergedURL = ...
    _ = try await AudioMerger.merge(
        ttsBuffer: ttsBuffer,
        recordingURLs: recordingURLs,
        outputURL: mergedURL,
        onProgress: { completed, _ in
            onProgress(completed, totalSteps)
        }
    )

    // Copy to export directory
    try FileManager.default.copyItem(at: mergedURL, to: exportURL)
    onProgress(totalSteps, totalSteps)

    return exportURL
}
```

### 4. EntryDetailViewModel (`MindEcho/MindEcho/ViewModels/EntryDetailViewModel.swift`)

Add export progress state as `@Observable` properties:

```swift
var exportProgress: Double = 0        // 0.0-1.0
var exportTotalSteps: Int = 0
var exportCompletedSteps: Int = 0
var isExporting = false
```

In `exportForSharing(type:)` for `.audio`:
- Set `isExporting = true` and reset progress before starting
- Pass `onProgress` closure that updates properties on `@MainActor`
- Set `isExporting = false` on completion (via `defer`)

Text export does not show progress (it completes near-instantly).

### 5. EntryDetailView (`MindEcho/MindEcho/Views/EntryDetailView.swift`)

Remove `@State private var isExporting` — use `viewModel.isExporting` instead.

Add overlay:

```swift
.overlay {
    if viewModel.isExporting {
        exportProgressOverlay
    }
}
```

Overlay implementation:

```swift
private var exportProgressOverlay: some View {
    ZStack {
        Color.black.opacity(0.4)
            .ignoresSafeArea()

        VStack(spacing: 16) {
            ProgressView(
                value: Double(viewModel.exportCompletedSteps),
                total: Double(max(viewModel.exportTotalSteps, 1))
            )
            .frame(width: 200)

            Text("音声を結合中… \(viewModel.exportCompletedSteps)/\(viewModel.exportTotalSteps)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(32)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
    .allowsHitTesting(true)
}
```

### 6. MockExportService (`MindEcho/MindEcho/Mocks/MockExportService.swift`)

Add conformance for the new protocol method.

## Files Changed

| File | Change |
|------|--------|
| `Exporting.swift` | Add `onProgress` overload to protocol |
| `AudioMerger.swift` | Add `onProgress` parameter, report at each step |
| `ExportService.swift` | Implement new method, relay + add copy step |
| `EntryDetailViewModel.swift` | Add export progress properties, wire callback |
| `EntryDetailView.swift` | Remove `@State isExporting`, add overlay UI |
| `MockExportService.swift` | Conform to updated protocol |

## Dependencies

None. Uses only standard SwiftUI (`ProgressView`) and existing AVFoundation APIs.

## Testing

- Existing UI tests for share flow are unaffected (they test the flow completion, not the overlay)
- MockExportService updated for protocol conformance
- Manual verification on real device recommended (progress timing depends on actual audio processing speed)
