#!/usr/bin/env bash
# worktree を状態で分類し、安全に消せるものだけを示す。
#
# 名前では判断できない（オンデマンド生成の worktree 名は自動命名で意味を持たない）ので、
# 実行中か・作業が残っているか・PR が決着したか、で決める。
#
# 使い方:
#   run.sh [リポジトリパス]            一覧を表示する
#   run.sh [リポジトリパス] --prune    削除可のものだけ削除する

set -uo pipefail

repo=$(pwd)
prune=""
for arg in "$@"; do
  case "$arg" in
    --prune) prune=1 ;;
    *) repo="$arg" ;;
  esac
done

cd "$repo" 2>/dev/null || { echo "ディレクトリがありません: $repo" >&2; exit 1; }
git rev-parse --git-dir >/dev/null 2>&1 || { echo "git リポジトリではありません: $repo" >&2; exit 1; }

main_wt=$(git rev-parse --show-toplevel)
have_gh=$(command -v gh >/dev/null 2>&1 && echo 1 || echo "")

# 比較対象の default branch。origin/HEAD が無いリポジトリのために順に試す。
base=$(git symbolic-ref -q --short refs/remotes/origin/HEAD 2>/dev/null)
for candidate in origin/main origin/master; do
  [ -n "$base" ] && break
  git rev-parse --verify -q "$candidate" >/dev/null 2>&1 && base="$candidate"
done

removable=()
prunables=()

classify() {
  local path="$1" branch="$2" locked="$3" prunable="$4"

  # 実体が消えて登録だけ残った worktree。remove ではなく prune で消す。
  if [ -n "$prunable" ]; then
    echo "PRUNE|残骸 — ディレクトリが無い（prune 対象）"; return
  fi

  if [ -n "$locked" ]; then
    echo "KEEP|実行中 — 触らない"; return
  fi

  if [ -n "$(git -C "$path" status --porcelain 2>/dev/null)" ]; then
    echo "KEEP|作業中 — 残す（未コミット/未追跡）"; return
  fi

  # どのリモートブランチからも到達できないコミットは、消すと失われる。
  local orphan
  orphan=$(git -C "$path" rev-list --count HEAD --not --remotes 2>/dev/null || echo 0)
  if [ "${orphan:-0}" -gt 0 ] 2>/dev/null; then
    echo "KEEP|残す — 未 push のコミット ${orphan} 件"; return
  fi

  # main に入っていても PR がレビュー中なら残したいので、コミット数より PR 状態を優先する。
  # PR は branch にしか紐づかないため、detached と gh 不在のときだけコミット数で判定する。
  if [ -z "$branch" ] || [ -z "$have_gh" ]; then
    if [ -n "$base" ] && [ "$(git -C "$path" rev-list --count "$base..HEAD" 2>/dev/null || echo 0)" = "0" ]; then
      echo "REMOVE|削除可 — コミットなし"; return
    fi
    [ -z "$branch" ] && { echo "KEEP|要確認 — detached で PR を辿れない"; return; }
    echo "KEEP|要確認 — gh が無く PR 状態を判定できない"; return
  fi

  local pr state num draft
  pr=$(gh pr list --head "$branch" --state all --limit 1 \
         --json number,state,isDraft --jq '.[0] | "\(.state)\t\(.number)\t\(.isDraft)"' 2>/dev/null)
  state=$(printf '%s' "$pr" | cut -f1)
  num=$(printf '%s' "$pr" | cut -f2)
  draft=$(printf '%s' "$pr" | cut -f3)
  case "$state" in
    MERGED) echo "REMOVE|削除可 — PR #${num} マージ済み" ;;
    CLOSED) echo "REMOVE|削除可 — PR #${num} クローズ済み" ;;
    OPEN)   echo "KEEP|残す — PR #${num} レビュー中$([ "$draft" = "true" ] && echo "（Draft）")" ;;
    *)      if [ -n "$base" ] && [ "$(git -C "$path" rev-list --count "$base..HEAD" 2>/dev/null || echo 0)" = "0" ]; then
              echo "REMOVE|削除可 — PR なし・コミットなし"
            else
              echo "KEEP|要確認 — push 済みだが PR なし"
            fi ;;
  esac
}

printf '%-24s %-40s %s\n' "WORKTREE" "BRANCH" "判定"
printf '%s\n' "$(printf '%.0s-' {1..104})"

path=""; branch=""; locked=""; prunable=""
flush() {
  [ -n "$path" ] || return
  if [ "$path" != "$main_wt" ]; then
    local result; result=$(classify "$path" "$branch" "$locked" "$prunable")
    case "${result%%|*}" in
      REMOVE) removable+=("$path") ;;
      PRUNE)  prunables+=("$path") ;;
    esac
    printf '%-24s %-40s %s\n' "$(basename "$path")" "${branch:-(detached)}" "${result#*|}"
  fi
  path=""; branch=""; locked=""; prunable=""
}

# porcelain はレコードを空行で区切る。
while IFS= read -r line; do
  case "$line" in
    "worktree "*)          path="${line#worktree }" ;;
    "branch refs/heads/"*) branch="${line#branch refs/heads/}" ;;
    locked*)               locked=1 ;;
    prunable*)             prunable=1 ;;
    "")                    flush ;;
  esac
done < <(git worktree list --porcelain; echo)
flush

echo
[ ${#prunables[@]} -gt 0 ] && echo "残骸: ${#prunables[@]} 件（git worktree prune で削除）"
if [ ${#removable[@]} -eq 0 ] && [ ${#prunables[@]} -eq 0 ]; then
  echo "削除可の worktree はありません。"
  exit 0
fi

[ ${#removable[@]} -gt 0 ] && echo "削除可: ${#removable[@]} 件"
if [ -z "$prune" ]; then
  echo "削除するには --prune を付けて再実行してください。"
  exit 0
fi

if [ ${#prunables[@]} -gt 0 ]; then
  git worktree prune -v 2>&1 | sed 's/^/  /'
fi

for p in "${removable[@]}"; do
  # --force は付けない。判定を取りこぼしていた場合に git に止めてもらう。
  if git worktree remove "$p" 2>/dev/null; then
    echo "  削除: $(basename "$p")"
  else
    echo "  失敗（git が拒否）: $(basename "$p")"
  fi
done
