# 録音中にリアルタイム音声波形フィードバックを追加する

## 概要

iOSのボイスメモアプリの録音画面のように、録音中にリアルタイムの音声波形（waveform）を表示するフィードバック機能を追加する。

## 背景・動機

現在の録音UIでは、録音中の経過時間（MM:SS）のみが表示されており、音声入力の視覚的なフィードバックがない。ボイスメモのような波形表示を追加することで、ユーザーが録音状態を直感的に把握できるようになる。

## 使用ライブラリ

**[DSWaveformImage](https://github.com/dmrschmidt/DSWaveformImage)** (v14.x)

- Swift Package Manager で導入
- `DSWaveformImage`（コア）+ `DSWaveformImageViews`（SwiftUI ビュー）の2モジュール構成
- `WaveformLiveCanvas` を使用してリアルタイム波形を描画

### 参考実装

DSWaveformImage のサンプルアプリにある **[RecordingIndicatorView](https://github.com/dmrschmidt/DSWaveformImage/blob/main/Example/DSWaveformImageExample-iOS/SwiftUIExample/RecordingIndicatorView.swift)** を参考にする。

```swift
// RecordingIndicatorView の主要部分
struct RecordingIndicatorView: View {
    let samples: [Float]
    let duration: TimeInterval

    @State var configuration: Waveform.Configuration = .init(
        style: .striped(.init(color: .systemGray, width: 3, spacing: 3)),
        damping: .init()
    )

    var body: some View {
        HStack {
            WaveformLiveCanvas(
                samples: samples,
                configuration: configuration,
                shouldDrawSilencePadding: shouldDrawSilence
            )
            Text(timeFormatter.string(from: duration) ?? "00:00")
            // ...
        }
    }
}
```

## 実装方針

### 1. DSWaveformImage の導入

- `MindEchoAudio` パッケージの `Package.swift` に DSWaveformImage を SPM 依存として追加
- または、メインアプリの `MindEcho.xcodeproj` に直接追加

### 2. 音声サンプルデータの取得

- `AudioRecorderService` は既に `AVAudioEngine` + `AVAudioTap` でリアルタイム音声キャプチャを行っている
- タップコールバックから正規化済み振幅サンプル（`[Float]`、0〜1の範囲）を抽出し、ViewModel へ公開する

### 3. UI の実装

- `HomeView` の録音中表示エリアに `WaveformLiveCanvas` を組み込む
- DSWaveformImage サンプルの `RecordingIndicatorView` のデザインを参考にする
  - 波形 + 経過時間 + 録音コントロールの横並びレイアウト
  - `Waveform.Configuration` の `style` でストライプや色を調整

### 4. 対応すべき状態

| 状態 | 波形表示 |
|------|---------|
| 録音中 | ライブ波形を表示 |
| 一時停止中 | 波形を停止（最後の状態を維持） |
| 録音停止後 | 波形をクリア / 非表示 |

## 影響範囲

- `Packages/MindEchoAudio/` - 音声サンプルデータの公開
- `MindEcho/MindEcho/ViewModels/HomeViewModel.swift` - サンプルデータのバインディング
- `MindEcho/MindEcho/Views/HomeView.swift` - 波形UIの追加
- `Package.swift` - DSWaveformImage 依存の追加

## 参考リンク

- [DSWaveformImage GitHub](https://github.com/dmrschmidt/DSWaveformImage)
- [DSWaveformImage - Swift Package Index](https://swiftpackageindex.com/dmrschmidt/DSWaveformImage)
- [RecordingIndicatorView サンプル](https://github.com/dmrschmidt/DSWaveformImage/blob/main/Example/DSWaveformImageExample-iOS/SwiftUIExample/RecordingIndicatorView.swift)
