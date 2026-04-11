---
name: agent-browser-cleanup
model: haiku
description: >
  agent-browser を使うスキルが開始前に呼び出すクリーンアップユーティリティ。
  別のセッション（tmuxペイン・Claudeセッション等）で agent-browser が使用中でなければ、
  残存プロセスをすべて終了してクリーンな状態で開始できるようにする。
  他のスキルから「agent-browserを使う前に呼ぶ」用途専用。
---

# agent-browser-cleanup

agent-browser を使い始める前に呼び出す、プロセスクリーンアップユーティリティ。

## やること

現在のシェルセッション（Unix session ID）と異なるセッションで agent-browser プロセスが動いていないかを確認する。別セッションで使用中であればそのままにし、使用中でなければ残存プロセスを終了する。

## 手順

```bash
# 現在のシェルのセッションID
CURRENT_SID=$(ps -p $$ -o sid= | tr -d ' ')

# 別セッションで agent-browser プロセスが動いているか確認
OTHER=$(ps -eo sid,comm | awk -v sid="$CURRENT_SID" '$2 ~ /agent-browser/ && $1+0 != sid+0')

if [ -n "$OTHER" ]; then
  echo "別セッションで agent-browser が使用中のため、プロセスはそのままにします"
else
  agent-browser close --all 2>/dev/null || true
  pkill -f "agent-browser" 2>/dev/null || true
  echo "agent-browser の残存プロセスをクリーンアップしました"
fi
```

結果（「使用中のためスキップ」または「クリーンアップ完了」）を呼び出し元に返して終了する。
