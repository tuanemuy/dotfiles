#!/usr/bin/env bash
# Classify worktrees by state and show only the ones that are safe to remove.
#
# Names carry no meaning (on-demand worktrees are named automatically), so the decision
# is based on whether it is in use, has work left, and whether its PR is settled.
#
# Usage:
#   run.sh [repo path]              Show the list
#   run.sh [repo path] --prune      Remove the removable ones
#   run.sh [repo path] --classify   Print the verdicts in a machine-readable form (for other tools)

set -uo pipefail

repo=$(pwd)
prune=""
classify_mode=""
for arg in "$@"; do
  case "$arg" in
    --prune)    prune=1 ;;
    --classify) classify_mode=1 ;;
    *) repo="$arg" ;;
  esac
done
[ -n "$prune" ] && [ -n "$classify_mode" ] && { echo "--prune and --classify cannot be combined" >&2; exit 1; }

cd "$repo" 2>/dev/null || { echo "No such directory: $repo" >&2; exit 1; }
git rev-parse --git-dir >/dev/null 2>&1 || { echo "Not a git repository: $repo" >&2; exit 1; }

main_wt=$(git rev-parse --show-toplevel)
have_gh=$(command -v gh >/dev/null 2>&1 && echo 1 || echo "")

# Default branch to compare against. Tried in order for repositories without origin/HEAD.
base=$(git symbolic-ref -q --short refs/remotes/origin/HEAD 2>/dev/null)
for candidate in origin/main origin/master; do
  [ -n "$base" ] && break
  git rev-parse --verify -q "$candidate" >/dev/null 2>&1 && base="$candidate"
done

removable=()
prunables=()

classify() {
  local path="$1" branch="$2" locked="$3" prunable="$4"

  # The directory is gone and only the registration remains: prune, not remove.
  if [ -n "$prunable" ]; then
    echo "PRUNE|stale — directory missing (prunable)"; return
  fi

  if [ -n "$locked" ]; then
    echo "KEEP|in use — locked"; return
  fi

  if [ -n "$(git -C "$path" status --porcelain 2>/dev/null)" ]; then
    echo "KEEP|in progress — uncommitted or untracked changes"; return
  fi

  # Commits unreachable from any remote branch would be lost on removal.
  local orphan
  orphan=$(git -C "$path" rev-list --count HEAD --not --remotes 2>/dev/null || echo 0)
  if [ "${orphan:-0}" -gt 0 ] 2>/dev/null; then
    echo "KEEP|keep — ${orphan} unpushed commit(s)"; return
  fi

  # A worktree whose PR is still open should stay even if merged into main, so the PR
  # state takes precedence over the commit count. PRs are tied to branches, so the commit
  # count is used only for detached HEADs and when gh is unavailable.
  if [ -z "$branch" ] || [ -z "$have_gh" ]; then
    if [ -n "$base" ] && [ "$(git -C "$path" rev-list --count "$base..HEAD" 2>/dev/null || echo 0)" = "0" ]; then
      echo "REMOVE|removable — no commits"; return
    fi
    [ -z "$branch" ] && { echo "KEEP|check — detached HEAD, cannot look up PR"; return; }
    echo "KEEP|check — gh not available, cannot look up PR"; return
  fi

  local pr state num draft
  pr=$(gh pr list --head "$branch" --state all --limit 1 \
         --json number,state,isDraft --jq '.[0] | "\(.state)\t\(.number)\t\(.isDraft)"' 2>/dev/null)
  state=$(printf '%s' "$pr" | cut -f1)
  num=$(printf '%s' "$pr" | cut -f2)
  draft=$(printf '%s' "$pr" | cut -f3)
  case "$state" in
    MERGED) echo "REMOVE|removable — PR #${num} merged" ;;
    CLOSED) echo "REMOVE|removable — PR #${num} closed" ;;
    OPEN)   echo "KEEP|keep — PR #${num} open$([ "$draft" = "true" ] && echo " (draft)")" ;;
    *)      if [ -n "$base" ] && [ "$(git -C "$path" rev-list --count "$base..HEAD" 2>/dev/null || echo 0)" = "0" ]; then
              echo "REMOVE|removable — no PR, no commits"
            else
              echo "KEEP|check — pushed but no PR"
            fi ;;
  esac
}

if [ -z "$classify_mode" ]; then
  printf '%-24s %-40s %s\n' "WORKTREE" "BRANCH" "STATUS"
  printf '%s\n' "$(printf '%.0s-' {1..104})"
fi

path=""; branch=""; locked=""; prunable=""
flush() {
  [ -n "$path" ] || return
  if [ "$path" != "$main_wt" ]; then
    local result
    if [ -n "$classify_mode" ]; then
      # The lock only reflects that the spawn server is alive, not whether the session in
      # the worktree is. Callers want to know whether it is still needed, not whether it can
      # be removed, so the lock is left out of the verdict.
      result=$(classify "$path" "$branch" "" "$prunable")
      # Columns: status / path / branch / reason.
      # Tab is IFS whitespace, so an empty field would shift the columns for the reader. Always fill it.
      printf '%s\t%s\t%s\t%s\n' "${result%%|*}" "$path" "${branch:--}" "${result#*|}"
    else
      result=$(classify "$path" "$branch" "$locked" "$prunable")
      case "${result%%|*}" in
        REMOVE) removable+=("$path") ;;
        PRUNE)  prunables+=("$path") ;;
      esac
      printf '%-24s %-40s %s\n' "$(basename "$path")" "${branch:-(detached)}" "${result#*|}"
    fi
  fi
  path=""; branch=""; locked=""; prunable=""
}

# Porcelain output separates records with a blank line.
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

[ -n "$classify_mode" ] && exit 0

echo
[ ${#prunables[@]} -gt 0 ] && echo "Stale: ${#prunables[@]} (removed by git worktree prune)"
if [ ${#removable[@]} -eq 0 ] && [ ${#prunables[@]} -eq 0 ]; then
  echo "No removable worktrees."
  exit 0
fi

[ ${#removable[@]} -gt 0 ] && echo "Removable: ${#removable[@]}"
if [ -z "$prune" ]; then
  echo "Re-run with --prune to remove them."
  exit 0
fi

if [ ${#prunables[@]} -gt 0 ]; then
  git worktree prune -v 2>&1 | sed 's/^/  /'
fi

for p in "${removable[@]}"; do
  # No --force: if the verdict missed something, let git refuse.
  if git worktree remove "$p" 2>/dev/null; then
    echo "  Removed: $(basename "$p")"
  else
    echo "  Failed (rejected by git): $(basename "$p")"
  fi
done
