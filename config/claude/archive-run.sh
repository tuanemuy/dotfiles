#!/usr/bin/env bash
# 前回アーカイブ時刻から前日0時までのセッションログを tar.gz に固める。
# 原本は削除しない（cleanupPeriodDays に任せる）。
set -euo pipefail

# date -v / stat -f / tar --null は BSD 版の挙動に依存する。
export PATH=/usr/bin:/bin:/usr/sbin:/sbin

SRC="${CLAUDE_ARCHIVE_SRC:-$HOME/.claude/projects}"
OUT="${CLAUDE_ARCHIVE_DIR:-$HOME/claude-archive}"
WM="$OUT/.watermark"
LOCK="$OUT/.lock"
KEEP="${CLAUDE_ARCHIVE_KEEP:-52}"

trap 'rmdir "$LOCK" 2>/dev/null || true' EXIT

UNTIL=$(date -v-1d -v0H -v0M -v0S +%Y-%m-%dT%H:%M:%S)
SINCE=$(cat "$WM" 2>/dev/null || date -v-8d +%Y-%m-%dT%H:%M:%S)
TGZ="$OUT/claude-$(date +%Y-%m-%d).tar.gz"
LIST=$(mktemp)

cd "$SRC"
find . -type f -newermt "$SINCE" ! -newermt "$UNTIL" -print0 >"$LIST"
N=$(tr -cd '\0' <"$LIST" | wc -c | tr -d ' ')

if [ "$N" -eq 0 ]; then
  echo "$(date '+%F %T') 対象なし ($SINCE 〜 $UNTIL)"
  printf '%s' "$UNTIL" >"$WM"
  rm -f "$LIST"
  exit 0
fi

tar --null -czf "$TGZ.tmp" -T "$LIST"

# 件数が一致するまでウォーターマークを進めない
M=$(tar -tzf "$TGZ.tmp" | wc -l | tr -d ' ')
if [ "$M" -ne "$N" ]; then
  echo "$(date '+%F %T') 検証失敗 期待 $N 件 / 実際 $M 件"
  rm -f "$TGZ.tmp" "$LIST"
  exit 1
fi

mv "$TGZ.tmp" "$TGZ"
printf '%s' "$UNTIL" >"$WM"
rm -f "$LIST"

cnt=$(ls -1 "$OUT"/claude-*.tar.gz 2>/dev/null | wc -l | tr -d ' ')
if [ "$cnt" -gt "$KEEP" ]; then
  ls -1 "$OUT"/claude-*.tar.gz | sort | head -n $((cnt - KEEP)) | xargs rm -f
fi

echo "$(date '+%F %T') $SINCE 〜 $UNTIL  $N 件 → $(du -h "$TGZ" | cut -f1)"
