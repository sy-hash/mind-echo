# Fastlane TestFlight Upload Design

## Overview

Fastlane を導入し、ローカル Mac からワンコマンドで TestFlight へアップロードできるようにする。

## Decisions

| 項目 | 選択 | 理由 |
|------|------|------|
| 実行環境 | ローカルのみ | 個人プロジェクト。CI 統合は後から追加可能 |
| コード署名 | Automatic Signing | 既存設定を維持。ローカル実行なら最もシンプル |
| ビルド番号 | 自動インクリメント | アップロード重複を防止 |
| ASC 認証 | API Key (.p8) | 2FA の問題がなく、パスワード入力不要 |
| Lane 構成 | 単一 `beta` lane | YAGNI。必要になったら分離する |

## File Structure

```
mind-echo/
├── Gemfile
├── Gemfile.lock          (自動生成)
└── fastlane/
    ├── Appfile
    └── Fastfile
```

## Authentication

環境変数で API Key 情報を渡す。Fastfile にシークレットをハードコードしない。

| 環境変数 | 用途 |
|----------|------|
| `ASC_KEY_ID` | App Store Connect API Key ID |
| `ASC_ISSUER_ID` | App Store Connect Issuer ID |
| `ASC_KEY_PATH` | `.p8` ファイルへのパス |

## `beta` Lane Flow

```
1. app_store_connect_api_key  → API Key で認証
2. increment_build_number     → CURRENT_PROJECT_VERSION を +1
3. build_app                  → Automatic Signing で .ipa をビルド
4. upload_to_testflight       → TestFlight にアップロード
```

## Build Configuration

- **Workspace**: `MindEcho.xcworkspace` (SPM パッケージを含むため)
- **Scheme**: `MindEcho`
- **Export method**: `app-store`
- **Code Signing**: Automatic (Xcode 管理)

## .gitignore

既存エントリで fastlane の `report.xml`, `Preview.html`, `screenshots`, `test_output` は除外済み。追加で `.env` 系を除外する。
