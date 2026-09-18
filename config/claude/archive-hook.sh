#!/usr/bin/env bash
# SessionEnd から呼ばれる判定用スクリプト。
# 前回アーカイブから INTERVAL 経過していなければ即座に終了する。
set -euo pipefail

# hook は呼び出し元の PATH を引き継ぐ。nix の GNU coreutils が先に来ると
# stat/date の BSD 固有オプションが通らないため、システムツールに固定する。
export PATH=/usr/bin:/bin:/usr/sbin:/sbin

cat >/dev/null 2>&1 || true   # hook の stdin(JSON) を捨てる

OUT="${CLAUDE_ARCHIVE_DIR:-$HOME/claude-archive}"
WM="$OUT/.watermark"
LOCK="$OUT/.lock"
INTERVAL="${CLAUDE_ARCHIVE_INTERVAL:-$((7 * 86400))}"   # 日次にするなら 86400
RUN="${CLAUDE_ARCHIVE_RUN:-$HOME/.claude/archive-run.sh}"

mkdir -p "$OUT"

# 数値以外が返ったら 0 に倒す（0 はアーカイブ実行側に倒れるので安全）
epoch_of() {
  local v
  v=$(stat -f %m "$1" 2>/dev/null || true)
  case "$v" in
    '' | *[!0-9]*) echo 0 ;;
    *) echo "$v" ;;
  esac
}

now=$(date +%s)
wm=$(epoch_of "$WM")
[ $((now - wm)) -ge "$INTERVAL" ] || exit 0

# 1時間以上残っているロックは異常終了の残骸とみなす
if [ -d "$LOCK" ]; then
  lt=$(epoch_of "$LOCK")
  if [ $((now - lt)) -ge 3600 ]; then
    rmdir "$LOCK" 2>/dev/null || exit 0
  else
    exit 0
  fi
fi

mkdir "$LOCK" 2>/dev/null || exit 0

# セッション終了に巻き込まれないよう切り離して起動する
( nohup /bin/bash "$RUN" >>"$OUT/run.log" 2>&1 & )
exit 0
