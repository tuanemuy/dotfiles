#!/usr/bin/env bash
# terminal が null の間はセッション終了をブロックし、Manager を継続させる。
# 継続回数はセッションごとに数え、上限で必ず抜ける。
set -eu
input="$(cat)"
session="$(printf '%s' "$input" | jq -r '.session_id // "default"')"
status=".goal-implement/status.json"
counter=".goal-implement/.stop-continues.$session"
max="${GOAL_IMPLEMENT_MAX_CONTINUES:-50}"

[ -f "$status" ] || exit 0
terminal="$(jq -r '.terminal' "$status")"
[ "$terminal" = "null" ] || exit 0

count=$(( $(cat "$counter" 2>/dev/null || echo 0) + 1 ))
echo "$count" > "$counter"
if [ "$count" -gt "$max" ]; then
  echo "goal-implement: 継続回数が上限 $max に達した。status.json の terminal を設定して終了する。" >&2
  exit 0
fi

remaining="$(jq -r '.items | to_entries | map(select(.value != "done")) | map(.key) | join(", ")' "$status")"
jq -n --arg r "$remaining" \
  '{decision: "block", reason: ("goal-implement は未完了。plan.md と status.json を読み、次の一手を実行する。残項目: " + $r + "。終端に達したら status.json の terminal を設定する。")}'
