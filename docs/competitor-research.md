# 競合アプリ調査レポート

**調査日**: 2026-03-08

## 概要

MindEcho は「音声で日々の記録を残し、AI アプリ（Google NotebookLM 等）と連携する」ジャーナリングアプリです。本レポートでは、類似する音声ジャーナリング・AI ジャーナリングアプリを調査し、MindEcho との比較を行います。

---

## 市場トレンド（2025〜2026年）

- **デジタルジャーナルアプリ市場**: 2025年 約$5.7B → 2035年 約$15B（CAGR 9.5〜11.5%）
- **地域シェア**: 北米 約40%、アジア太平洋 約30%
- 音声認識市場は 2026年に **250億ドル規模** に成長予測
- AI によるインサイト（感情分析、パターン認識）が標準機能に
- プライバシー重視（オンデバイス処理、暗号化）の需要増
- 「ジャーナル＝テキストボックス」から、音声・写真・動画を含むマルチモーダルな記録へ進化
- セラピストやコーチがアプリベースのジャーナリングを治療に取り入れる動き
- ChatGPT をジャーナルとして使う層の出現（メモリ機能 + 音声入力）
- ウェアラブル連携（Apple Watch、フィットネストラッカーからのバイオメトリクス統合）の需要増

---

## 競合アプリ一覧

### 1. Day One

| 項目 | 詳細 |
|------|------|
| **開発元** | Day One / Automattic |
| **プラットフォーム** | iOS, Android, Mac, Web |
| **価格** | 無料（基本）/ Premium 約$35/年（iOS）、$25/年（Android） |
| **App Store 評価** | 4.7/5 |

**主な機能:**
- 音声録音（無制限 / Premium）、音声→テキスト書き起こし
- AI 機能（Labs）: エントリ要約、タイトル提案、Go Deeper（深掘りプロンプト）、AI 画像生成
- Apple Intelligence 連携（オンデバイス AI）
- 写真・動画・手書きも保存可能
- iCloud / Day One 独自クラウド同期
- 2026年版「Deep Voice」: 音声のトーンから感情（興奮・疲労・躊躇等）を検出

**MindEcho との比較:**
- **共通点**: 音声録音、書き起こし、AI 要約
- **Day One の強み**: 長い歴史、多機能（写真・動画・手書き）、Apple Intelligence 対応、大きなユーザーベース
- **MindEcho の差別化ポイント**: NotebookLM 等の外部 AI アプリへのエクスポートに特化、論理日付（午前3時境界）、シンプルな音声ファースト設計

---

### 2. AudioDiary（Audio Diary - AI Voice Journal）

| 項目 | 詳細 |
|------|------|
| **開発元** | AudioDiary |
| **プラットフォーム** | iOS, Android |
| **価格** | フリーミアム |
| **App Store 評価** | 4.9/5（500+レビュー） |

**主な機能:**
- 音声録音 → AI 書き起こし
- パーソナライズされたフィードバック（セラピスト/友人/ライフコーチのトーンを選択可能）
- 自動タグ付け・カスタムタグ
- ムードグラフ（感情トラッキング）
- GDPR 準拠、OpenAI にデータ提供なし

**MindEcho との比較:**
- **共通点**: 音声ファーストのジャーナリング、AI 書き起こし
- **AudioDiary の強み**: 感情分析・ムードトラッキング、パーソナライズされた AI フィードバック、高い App Store 評価
- **MindEcho の差別化ポイント**: 外部 AI アプリとのエクスポート連携、論理日付、複数の書き起こしエンジン選択

---

### 3. AudioPen

| 項目 | 詳細 |
|------|------|
| **開発元** | Louis Pereira |
| **プラットフォーム** | Web, iOS, Android, Chrome 拡張 |
| **価格** | 無料（3分/回、10ノート上限）/ Premium $60/年 or $120/買い切り |

**主な機能:**
- 音声 → 整形されたテキストへ変換（Whisper + GPT）
- 25以上のライティングスタイル
- 「Write Like Me」: ユーザーの文体を学習・模倣
- 多言語対応
- メモ帳的な使い方がメイン（ジャーナル特化ではない）

**MindEcho との比較:**
- **共通点**: 音声→テキスト変換、AI による整形
- **AudioPen の強み**: クロスプラットフォーム、文体カスタマイズ、汎用的なノートツール
- **MindEcho の差別化ポイント**: ジャーナリング特化（1日1エントリ・時系列管理）、ローカルストレージ優先、NotebookLM 連携

---

### 4. Whisper Memos

| 項目 | 詳細 |
|------|------|
| **開発元** | Median Tech, s.r.o. |
| **プラットフォーム** | iOS（Apple Watch 対応） |
| **価格** | フリーミアム |

**主な機能:**
- 音声メモ → Whisper で書き起こし → GPT-4 で新聞記事風に整形
- メールで書き起こし結果を受信
- 外部音声ファイルのインポート・書き起こし対応（M4A, MP3, WAV, FLAC）
- Apple Watch 対応
- ランダムメモリー機能（過去のメモをランダム表示）

**MindEcho との比較:**
- **共通点**: Whisper ベースの書き起こし、AI による要約・整形
- **Whisper Memos の強み**: Apple Watch 対応、メール配信、多様な音声フォーマット対応
- **MindEcho の差別化ポイント**: ジャーナリングとしての構造化（日付ベース管理）、エクスポート機能、複数エンジン選択

---

### 5. Rosebud

| 項目 | 詳細 |
|------|------|
| **開発元** | Rosebud（Y Combinator 出身） |
| **プラットフォーム** | iOS, Android, Web |
| **価格** | 無料（基本）/ Premium $12.99/月 / Bloom $155.99/年 |
| **資金調達** | $6M（Bessemer Venture Partners 他） |

**主な機能:**
- 対話型ジャーナリング（AI がチャット形式でガイド）
- 感情分析・週間レポート
- セラピスト・CBT ベースのガイドコンテンツ
- 音声入力対応
- ユーザーの好みを学習（Learned Preferences）
- 目標設定・インテンション機能

**MindEcho との比較:**
- **共通点**: AI 活用のジャーナリング
- **Rosebud の強み**: 対話型 AI ガイド、セラピー的アプローチ、大きな投資と成長
- **MindEcho の差別化ポイント**: 音声録音ファースト（Rosebud はテキスト中心）、外部 AI 連携、シンプルな UX

---

### 6. Letterly

| 項目 | 詳細 |
|------|------|
| **開発元** | Letterly |
| **プラットフォーム** | iOS, Android, Web, macOS |
| **価格** | 約$70/年（AppSumo で$59 買い切りあり） |
| **評価** | 4.7/5（299 レビュー） |

**主な機能:**
- 音声 → 構造化テキスト（段落、箇条書き、見出し）
- 25以上のリライトスタイル
- 90言語以上対応、自動言語検出
- オフライン録音対応
- 最大90分の録音
- Webhook 連携（Google Docs, Notion 等）
- 画面オフ録音

**MindEcho との比較:**
- **共通点**: 音声 → テキスト変換、外部アプリ連携
- **Letterly の強み**: 多言語対応、オフライン録音、長時間録音、Webhook 連携
- **MindEcho の差別化ポイント**: ジャーナリング特化の UX、1日1エントリ構造、NotebookLM 最適化

---

### 7. Just Press Record

| 項目 | 詳細 |
|------|------|
| **開発元** | Open Planet Software（スコットランド） |
| **プラットフォーム** | iOS, watchOS, macOS（ユニバーサル購入） |
| **価格** | $4.99（買い切り） |

**主な機能:**
- ワンタップ録音（ロック画面、コントロールセンター、Apple Watch、Siri）
- 30言語以上の書き起こし
- 音声同期テキストハイライト
- 波形表示での編集
- iCloud Drive 同期
- 完全プライバシー（データ収集なし）

**MindEcho との比較:**
- **共通点**: シンプルな音声録音、書き起こし
- **Just Press Record の強み**: 買い切り価格、完全なプライバシー、Apple Watch 対応、多デバイス同期
- **MindEcho の差別化ポイント**: AI 要約機能、ジャーナリング構造、外部 AI 連携

---

### 8. Untold - Voice Journal

| 項目 | 詳細 |
|------|------|
| **開発元** | Untold |
| **プラットフォーム** | iOS |
| **価格** | 完全無料（広告なし、機能制限なし） |
| **App Store 評価** | 5.0/5 |

**主な機能:**
- Speech-to-Text による自動書き起こし・段落分割
- 感情分析（Hume Expression Measurement API）
- パーソナライズされたフォローアップ質問
- パーソナライズされたニュースフィード（自分に関するストーリー生成）
- ワードクラウド、月次レビュー
- 完全暗号化

**MindEcho との比較:**
- **共通点**: 音声ファースト設計、書き起こし
- **Untold の強み**: 完全無料、感情分析（Hume AI）、5.0 の高評価
- **MindEcho の差別化ポイント**: 外部 AI エクスポート、複数書き起こしエンジン、論理日付。Untold は収益モデルが不明確

---

### 9. Narrate: AI Voice Journal

| 項目 | 詳細 |
|------|------|
| **開発元** | Narrate |
| **プラットフォーム** | iOS |
| **価格** | サブスクリプション（Basic $3.99/月、Deluxe $6.99/月） |

**主な機能:**
- リアルタイム書き起こし
- AI による内容整理・要約・アクションアイテム抽出
- ムード・生産性トラッキング
- マインドマップ表示
- PDF エクスポート
- イヤホンによるハンズフリー操作
- メモに基づく AI への質問機能

**MindEcho との比較:**
- **共通点**: 音声録音、リアルタイム書き起こし、AI 要約、エクスポート
- **Narrate の強み**: マインドマップ表示、ハンズフリー操作、生産性ツール的側面
- **MindEcho の差別化ポイント**: ジャーナリング特化（1日1エントリ）、音声結合機能、NotebookLM 連携

---

### 10. Apple Journal（純正アプリ）

| 項目 | 詳細 |
|------|------|
| **開発元** | Apple |
| **プラットフォーム** | iOS |
| **価格** | 完全無料（プリインストール） |

**主な機能:**
- 音声録音・書き起こし
- オンデバイス AI による提案
- 写真・動画・位置情報・心の状態の記録
- プライバシー重視（完全オンデバイス処理）

**MindEcho との比較:**
- **共通点**: SwiftUI ベース、オンデバイス AI、音声対応
- **Apple Journal の強み**: プリインストール、完全無料、Apple エコシステム統合
- **MindEcho の差別化ポイント**: 音声ファースト設計、NotebookLM 連携エクスポート、複数書き起こしエンジン、論理日付

---

### 11. その他注目アプリ

| アプリ名 | 特徴 | ポジション |
|---------|------|-----------|
| **Otter.ai** | 会議書き起こし特化、英語のみ、無料300分/月 | ミーティング向け（ジャーナル用途ではない） |
| **Reflection** | AI プロンプト、クロスプラットフォーム、充実した無料プラン | テキスト中心のジャーナリング |
| **Inner Dispatch** | 音声ジャーナリング特化、習慣トラッキング、プライバシー重視 | MindEcho に最も近い直接競合 |
| **Stoic** | ストア哲学 + CBT、ソクラティック AI | 哲学的ジャーナリング |
| **VoiceScriber** | 完全オフライン書き起こし（Whisper をオンデバイスで実行） | プライバシー最重視層向け |
| **Whisper Notes** | オフライン Whisper 書き起こし、$4.99 買い切り、データ送信なし | シンプルなオフライン書き起こし |
| **Lid** | 音声ストリーム → AI で整形エントリ化、日次 SoundBite 機能 | 音声ジャーナル新興（無料） |
| **CocoonWeaver** | カラーベースの感情分類、音声メモ整理 | ビジュアル重視のジャーナル |
| **Cleft Notes** | ワンタップ録音→オンデバイス書き起こし→構造化ノート、Obsidian/Notion 連携、$6.99/月 | ノートテイキング特化（Fast Company 選出） |
| **Apple Voice Memos** | iOS 18〜 自動書き起こし、Apple Intelligence 要約、無料プリインストール | 汎用録音（ジャーナル管理なし） |

---

## 競合マトリクス

| 機能 | MindEcho | Day One | AudioDiary | Untold | Narrate | AudioPen | Whisper Memos | Rosebud | Letterly | Just Press Record | Apple Journal |
|------|----------|---------|------------|--------|---------|----------|---------------|---------|----------|------------------|---------------|
| 音声録音 | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ⚠️ | ✅ | ✅ | ✅ |
| AI 書き起こし | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | ✅ | ✅ | ✅ |
| 複数エンジン選択 | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| AI 要約 | ✅ | ✅ | ✅ | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ |
| 感情分析 | ❌ | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | ❌ | ❌ |
| 外部 AI エクスポート | ✅ | ❌ | ❌ | ❌ | ⚠️ | ❌ | ❌ | ❌ | ⚠️ | ❌ | ❌ |
| 論理日付(3AM) | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Apple Watch | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ | ✅ | ❌ |
| オフライン対応 | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ | ✅ |
| 多言語対応 | ❌ | ✅ | ❌ | ❌ | ❌ | ✅ | ✅ | ❌ | ✅ | ✅ | ❌ |
| 完全無料 | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ |

※ ✅=対応 / ⚠️=部分対応 / ❌=未対応（または不明）

---

## NotebookLM 連携について

調査の結果、**NotebookLM と直接連携するジャーナリングアプリは現時点で存在しない**。一般的なワークフローは:

1. ジャーナリングアプリからテキスト/PDF をエクスポート
2. Google Drive にアップロード
3. NotebookLM でソースとして読み込み

NotebookLM は PDF、プレーンテキスト（.txt）、Markdown をソースとして受け付ける。NotebookLM 連携を設計段階から意識しているジャーナリングアプリは、調査範囲では **MindEcho のみ** であり、これは明確な差別化要因となる。

---

## MindEcho の差別化ポイントまとめ

### 独自の強み

1. **外部 AI 連携特化**: NotebookLM 等の AI アプリにデータを渡すことを前提としたエクスポート機能は、競合にはほとんどない（調査範囲で唯一）
2. **複数書き起こしエンジン選択**: Speech/Dictation/Whisper API を切り替えられるのはユニーク
3. **論理日付（午前3時境界）**: 深夜の記録を「前日分」として扱う、実用的なドメインロジック
4. **音声ファースト × シンプル**: 多機能にせず、音声録音→書き起こし→要約→エクスポートの一本道
5. **オンデバイス AI 要約（Apple Foundation Models）**: プライバシー面で優位（AudioDiary 等は OpenAI クラウドに依存）
6. **音声結合（AudioMerger）・TTS 生成**: 1日の複数録音を統合できる技術的な強み

### 強化を検討すべき領域

1. **感情分析・ムードトラッキング**: AudioDiary、Day One、Rosebud が実装済み。ユーザーのエンゲージメント向上に寄与
2. **Apple Watch 対応**: Day One、Whisper Memos、Just Press Record が対応済み。手軽な録音体験に直結
3. **オフライン対応**: オンデバイス Whisper や Apple の Speech Framework を活用した書き起こし
4. **多言語対応**: グローバル展開を見据えるなら重要
5. **Webhook / API 連携**: Letterly の Webhook 連携のように、Notion や Google Docs 等への自動連携

---

## 参考リンク

- [Best Voice Journaling Apps in 2025 | Inner Dispatch](https://innerdispatch.com/best-voice-journaling-apps/)
- [12 Best Voice to Notes Apps (2026)](https://voicetonotes.ai/blog/best-voice-to-notes-app/)
- [Best Journaling Apps of 2026 | Journaling Guide](https://journaling.guide/blog/best-journaling-apps-2026/)
- [Day One - Features](https://dayoneapp.com/features/)
- [Day One - AI Features](https://dayoneapp.com/guides/labs/ai-features/)
- [AudioDiary - App Store](https://apps.apple.com/us/app/audio-diary-a-simple-journal/id6444500487)
- [AudioPen](https://audiopen.ai/)
- [Whisper Memos](https://whispermemos.com/)
- [Rosebud](https://www.rosebud.app/)
- [Letterly](https://letterly.app/)
- [Just Press Record](https://www.openplanetsoftware.com/just-press-record/)
- [Otter.ai](https://otter.ai/)
- [VoiceScriber](https://voicescriber.com/)
- [Whisper Notes](https://whispernotes.app/)
- [Untold - Voice Journal - App Store](https://apps.apple.com/us/app/untold-voice-journal/id6451427834)
- [Narrate - App Store](https://apps.apple.com/us/app/narrate-ai-voice-journal/id6755108818)
- [Apple Journal](https://apps.apple.com/us/app/journal/id6447391597)
- [Rosebud on TechCrunch](https://techcrunch.com/2025/06/04/rosebud-lands-6m-to-scale-its-interactive-ai-journaling-app/)
- [AudioDiary](https://audiodiary.ai/)
- [Cleft Notes](https://www.cleftnotes.com/)
- [Apple Voice Memos Transcription](https://support.apple.com/guide/iphone/view-a-transcription-iph00953a982/ios)
- [Market Research Future - Digital Journal Apps](https://www.marketresearchfuture.com/reports/digital-journal-apps-market-29194)
