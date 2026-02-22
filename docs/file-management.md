# ファイル管理仕様

MindEcho アプリにおけるディレクトリ構成、ファイル命名規則、同期タイミング、フォーマットの仕様。

## 保存先

アプリ内部で管理するファイルは `Application Support/` ディレクトリに保存し、ファイルアプリから不可視にする。
エクスポート（AI に共有）したファイルのみを `Documents/Exports/` に保存し、ファイルアプリから閲覧可能にする。
**1日につき録音ファイルは複数（セッションごと）生成する。**

```
Application Support/
├── Recordings/          # 音声ファイル（1日に複数ファイル可、ファイルアプリから不可視）
│   ├── 20250207_143000.m4a
│   ├── 20250207_211500.m4a
│   ├── 20250207_233045.m4a
│   └── 20250208_013000.m4a
└── Merged/              # 共有用の結合済み音声ファイル（一時生成、ファイルアプリから不可視）
    └── 20250207_merged.m4a

Documents/
└── Exports/             # エクスポート済みファイル（ファイルアプリに公開）
    ├── 20250207_merged.m4a
    ├── 20250207_transcription.txt
    └── ...
```

## ファイルアプリからのアクセス

iOS のファイルアプリ（「このiPhone内」→「（アプリ名）」）から
**エクスポート済みファイル（AI に共有したファイル）だけ** を閲覧・共有できるようにする。
アプリ内部で管理する録音ファイルは `Application Support/` に保存され、ファイルアプリからは不可視となる。

**Info.plist に以下を追加:**

```xml
<key>UIFileSharingEnabled</key>
<true/>
<key>LSSupportsOpeningDocumentsInPlace</key>
<true/>
```

| キー | Xcode 表示名 | 値 |
|------|-------------|-----|
| `UIFileSharingEnabled` | Application supports iTunes file sharing | YES |
| `LSSupportsOpeningDocumentsInPlace` | Supports opening documents in place | YES |

これにより、`Documents/` ディレクトリのみがファイルアプリに公開される。
`Application Support/` のファイルは公開されないため、ユーザーが誤って削除することを防げる。

※ SwiftData のストアファイルは `Application Support` に保存されるため、データベースファイルは露出しない。

## ファイル命名規則

**重要: ファイル名は半角英数字・ハイフン・アンダースコアのみを使用する。**
日本語を含めると NotebookLM へのインポート時に文字化けが発生するため禁止。
**すべてのファイルは日付をプリフィックスとする。エクスポートファイルはファイルアプリでの日付順ソートを保証し、内部の録音ファイルは実際の作成日時でデバッグ時の視認性を確保する。**

**音声ファイル（1日に複数ファイル）:**

```
Recordings/{datetime}.m4a
```

| 要素 | 内容 | 例 |
|------|------|-----|
| `{datetime}` | 録音開始の実日時（`YYYYMMDD_HHmmss`） | `20250207_143000` |

例: `20250207_143000.m4a`, `20250207_211500.m4a`（`Application Support/Recordings/` に保存）

- **ファイル名の日時は実際の録音開始時刻であり、論理日付（午前3時境界）ではない。** どの Entry に属するかは SwiftData が管理するため、ファイル名にビジネスロジック上の意味を持たせない
- 同一秒に複数の録音を開始することは物理的に不可能なため、秒精度で一意性が保証される（UUID・連番は不要）
- 録音を開始するたびに新しいファイルを生成
- 一時停止→再開は tap コールバック内の `isPaused` フラグで制御。`true` の間はバッファの書き込みをスキップし、`false` に戻すと同一 `AVAudioFile` への追記を再開する（`AVAudioEngine` は停止しない）
- 停止すると `AVAudioEngine` を停止し、`AVAudioFile` をクローズして録音が確定。次の録音は新しいファイルになる

## イベントごとのファイル操作

| イベント | 更新されるファイル |
|---------|-----------------|
| 録音開始 | `Application Support/Recordings/{datetime}.m4a` を新規生成 |
| 録音の一時停止・再開 | `isPaused` フラグで tap コールバック内の書き込みをスキップ/再開（同一 `.m4a` ファイル内、`AVAudioEngine` は停止しない） |
| 録音停止 | `.m4a` ファイルを確定。リアルタイム文字起こしの確定テキストを `Recording.transcription` に保存 |
| 音声共有時 | その日の全 Recording を連番順に結合 → `Application Support/Merged/` に一時生成 → `Documents/Exports/` にコピー |
| 文字起こし共有時 | 全 Recording の `transcription` を結合して `.txt` を生成 → `Documents/Exports/` にコピー |
| 録音削除（個別） | 対応する `Application Support/Recordings/` 内の `.m4a` を削除 + `Recording` エンティティを削除。**残りの Recording の `sequenceNumber` はリナンバーしない（欠番を許容）。** エクスポート時は実在する Recording を `sequenceNumber` 昇順で処理する。**次の録音の `sequenceNumber` は既存の最大値 + 1 で採番する**（例: #1, #3 が残っている場合、次は #4） |
| エントリ削除 | 対応する全 `.m4a` ファイルを削除（cascade で `Recording` も削除） |

## フォーマット

- 音声: AAC（`.m4a`）
- 録音の最大時間: 制限なし
- 容量表示機能は将来的に追加を検討
