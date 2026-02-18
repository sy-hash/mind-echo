# Fastlane TestFlight Upload Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** ローカル Mac からワンコマンド (`fastlane beta`) で MindEcho を TestFlight にアップロードできるようにする。

**Architecture:** Bundler で fastlane を管理し、API Key 認証 + Automatic Signing で TestFlight にアップロードする単一 `beta` lane を構成する。

**Tech Stack:** Fastlane, Bundler, App Store Connect API Key

---

### Task 1: Gemfile を作成

**Files:**
- Create: `Gemfile`

**Step 1: Gemfile を作成**

```ruby
source "https://rubygems.org"

gem "fastlane"
```

**Step 2: Commit**

```bash
git add Gemfile
git commit -m "Add Gemfile for Fastlane"
```

---

### Task 2: bundle install を実行

**Step 1: bundle install**

Run: `bundle install`
Expected: fastlane とその依存関係がインストールされ、`Gemfile.lock` が生成される。

**Step 2: Commit**

```bash
git add Gemfile.lock
git commit -m "Add Gemfile.lock"
```

---

### Task 3: .gitignore に fastlane 環境変数ファイルを追加

**Files:**
- Modify: `.gitignore`

**Step 1: `.gitignore` の fastlane セクション末尾に追加**

既存の `fastlane/test_output` の行の後に以下を追加:

```
fastlane/.env*
```

**Step 2: Commit**

```bash
git add .gitignore
git commit -m "Add fastlane .env files to .gitignore"
```

---

### Task 4: Appfile を作成

**Files:**
- Create: `fastlane/Appfile`

**Step 1: Appfile を作成**

```ruby
app_identifier("com.syhash.MindEcho")
team_id("LYMDWEXP2V")
```

**Step 2: Commit**

```bash
git add fastlane/Appfile
git commit -m "Add fastlane Appfile"
```

---

### Task 5: Fastfile を作成

**Files:**
- Create: `fastlane/Fastfile`

**Step 1: Fastfile を作成**

```ruby
default_platform(:ios)

platform :ios do
  desc "Build and upload to TestFlight"
  lane :beta do
    api_key = app_store_connect_api_key(
      key_id: ENV.fetch("ASC_KEY_ID"),
      issuer_id: ENV.fetch("ASC_ISSUER_ID"),
      key_filepath: ENV.fetch("ASC_KEY_PATH"),
    )

    increment_build_number(
      xcodeproj: "MindEcho/MindEcho.xcodeproj",
    )

    build_app(
      workspace: "MindEcho.xcworkspace",
      scheme: "MindEcho",
      export_method: "app-store",
    )

    upload_to_testflight(api_key: api_key)
  end
end
```

**Step 2: Commit**

```bash
git add fastlane/Fastfile
git commit -m "Add Fastfile with beta lane for TestFlight upload"
```

---

### Task 6: 動作確認（ドライラン）

**Step 1: 環境変数を設定して fastlane が読み込めるか確認**

Run: `bundle exec fastlane lanes`
Expected: `beta` lane が表示される。

**Step 2: ユーザーに次の手順を伝える**

実際にアップロードするには、事前に以下が必要:

1. App Store Connect で API Key を作成 (https://appstoreconnect.apple.com/access/integrations/api)
2. `.p8` ファイルをダウンロードして安全な場所に保存
3. 環境変数を設定して実行:

```bash
ASC_KEY_ID="XXXXXXXXXX" \
ASC_ISSUER_ID="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" \
ASC_KEY_PATH="$HOME/.appstoreconnect/AuthKey_XXXXXXXXXX.p8" \
bundle exec fastlane beta
```
