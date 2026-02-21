# SpeechAnalyzer を使った音声書き起こし機能の実装

## 概要

今日の音声記録に対して、Apple Speech フレームワーク（`SpeechAnalyzer`）を使った書き起こし機能を追加する。

## 背景

現在、HomeView では今日の音声記録のリストが表示されるが、録音内容をテキストとして確認する手段がない。
`SpeechAnalyzer`（iOS 26+）を利用して、オンデバイスでの音声書き起こしを提供する。

## 要件

### UI

- 今日の各録音セル（`home.recordingRow`）に **書き起こしボタン** を追加する
- ボタン押下で **書き起こし結果モーダル**（`.sheet`）を表示する
- モーダル内で書き起こし処理の進行状態と完了後の結果テキストを表示する

### 書き起こし処理

- `Speech` フレームワークの `SpeechAnalyzer` を使用する
- 対象の `Recording` の音声ファイル（`FilePathManager.recordingsDirectory` 配下）を入力として使う
- 書き起こし結果は **モーダル内での表示のみ**（データモデルへの永続化は行わない）

### 状態遷移

```
ボタン押下 → モーダル表示 → 書き起こし処理開始（ローディング表示）
  → 完了: 書き起こしテキストを表示
  → 失敗: エラーメッセージを表示
```

### 権限

- `SFSpeechRecognizer.requestAuthorization` による音声認識の権限リクエストが必要
- `Info.plist` に `NSSpeechRecognitionUsageDescription` を追加する

## 技術的な検討事項

### モジュール配置

| コンポーネント | 配置先 | 理由 |
|---|---|---|
| 書き起こし Service（protocol） | `MindEchoCore` or `MindEchoApp` | TBD: `MindEchoAudio` は Speech に依存させない方針とするか要検討 |
| 書き起こし Service（実装） | `MindEchoApp` | ExportServiceImpl と同様のブリッジ層パターン |
| 書き起こし結果モーダル View | `MindEchoApp` | |
| ViewModel の拡張 | `MindEchoApp` | HomeViewModel または専用 ViewModel |

### 影響範囲

- `HomeView.swift` — 録音セルに書き起こしボタンを追加
- `HomeViewModel.swift` — 書き起こし関連のステート管理を追加（または専用 ViewModel を新設）
- 新規: 書き起こしモーダル View
- 新規: 書き起こし Service（SpeechAnalyzer ラッパー）
- `Info.plist` — 音声認識権限の記述追加

## 対象 OS

- iOS 26.0+（`SpeechAnalyzer` は iOS 26 で導入）
