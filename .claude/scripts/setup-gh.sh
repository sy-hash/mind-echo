#!/bin/bash
# .claude/scripts/setup-gh.sh

# Web版(リモート)でなければスキップ
if [[ -z "$CLAUDE_CODE_REMOTE" ]]; then
  exit 0
fi

# すでにインストール済みならスキップ
if command -v gh &>/dev/null; then
  exit 0
fi

GH_VERSION="2.65.0"

wget -q "https://github.com/cli/cli/releases/download/v${GH_VERSION}/gh_${GH_VERSION}_linux_amd64.tar.gz" -O /tmp/gh.tar.gz
tar -xzf /tmp/gh.tar.gz -C /tmp
cp "/tmp/gh_${GH_VERSION}_linux_amd64/bin/gh" /usr/local/bin/gh
chmod +x /usr/local/bin/gh
