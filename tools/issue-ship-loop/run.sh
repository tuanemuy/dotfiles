#!/usr/bin/env bash
# Run issue triage, investigation and shipping skills, headless, on Claude and/or Codex.
# Each issue gets its own worktree (git wt: copies .env, installs deps) and its own PR.
#
# Usage (inside the target repository):
#   run.sh triage [--from <label>] [--agent claude|codex]
#                                         Classify all open issues and queue a compatible Ready batch
#   run.sh investigate <number> [--agent claude|codex]
#                                         Investigate one issue and update its readiness (does not queue it)
#   run.sh [claude|codex|both] [-n <max>] [--skill <name>]
#                                         Ship queued issues until the queue is empty (default: both, issue-ship)
#   run.sh status                         Show the queue and what each agent has taken
#   run.sh stop                           Finish current issues, then stop taking new ones
#   run.sh resume                         Clear the stop request (does not start workers)
#
# Labels:
#   ready / triage:*          readiness managed by issue-triage
#   ship:auto                 the queue
#   ship:claude / ship:codex  taken by that agent
#   ship:needs-human          ended as a Draft PR or without a PR; read the PR or the log
#
# Locks and logs live in <git-common-dir>/ship-loop/, so the working tree stays clean.
# Worktrees are left in place; remove settled ones with wtclean --prune.
# Triage/investigation default to Claude. Re-run triage after investigations or PR merges.
# Workers consume ship:auto only; they do not automatically repeat triage or investigation.
# Use stop from another terminal to drain workers. Ctrl+C interrupts work mid-issue.

set -uo pipefail

QUEUE=ship:auto
HUMAN=ship:needs-human

cmd=both
max=0
skill=issue-ship
from=
stage_agent=claude
issue=
while [ $# -gt 0 ]; do
  case "$1" in
    triage|investigate|status|stop|resume|claude|codex|both) cmd=$1 ;;
    -n) max=${2:?-n needs a number}; shift ;;
    --skill) skill=${2:?--skill needs a name}; shift ;;
    --from) from=${2:?--from needs a label}; shift ;;
    --agent) stage_agent=${2:?--agent needs claude or codex}; shift ;;
    -h|--help) sed -n '2,/^$/s/^# \{0,1\}//p' "$0"; exit 0 ;;
    *)
      if [ "$cmd" = investigate ] && [ -z "$issue" ] && [[ "$1" =~ ^[1-9][0-9]*$ ]]; then
        issue=$1
      else
        echo "Unknown argument: $1" >&2; exit 1
      fi ;;
  esac
  shift
done
[[ "$max" =~ ^[0-9]+$ ]] || { echo "-n needs a non-negative integer" >&2; exit 1; }
case "$stage_agent" in claude|codex) ;; *) echo "--agent needs claude or codex" >&2; exit 1 ;; esac
[ "$cmd" != investigate ] || [ -n "$issue" ] || { echo "investigate needs an issue number" >&2; exit 1; }
[ -z "$from" ] || [ "$cmd" = triage ] || { echo "--from is only for triage" >&2; exit 1; }

git rev-parse --git-dir >/dev/null 2>&1 || { echo "Not a git repository" >&2; exit 1; }
root=$(git rev-parse --show-toplevel)
state="$(cd "$(git rev-parse --git-common-dir)" && pwd -P)/ship-loop"
mkdir -p "$state/locks" "$state/logs"
cd "$root" || exit 1

have() { command -v "$1" >/dev/null 2>&1; }
log() { printf '%s [%s] %s\n' "$(date +%H:%M:%S)" "$1" "$2"; }

# Run inside the directory's direnv environment when it has one, so devShell tools
# (pnpm etc.) resolve the same way as in an interactive shell.
in_env() {
  local dir=$1; shift
  if [ -f "$dir/.envrc" ] && have direnv; then (cd "$dir" && direnv exec . "$@"); else (cd "$dir" && "$@"); fi
}

ensure_labels() {
  gh label create "$QUEUE" --color 0e8a16 --description "issue-ship の自動対応キュー" >/dev/null 2>&1
  gh label create ship:claude --color d4c5f9 --description "Claude が自動対応" >/dev/null 2>&1
  gh label create ship:codex --color c5def5 --description "Codex が自動対応" >/dev/null 2>&1
  gh label create "$HUMAN" --color e99695 --description "自動対応で閉じきれなかった" >/dev/null 2>&1
  return 0
}

run_stage() (
  local stage_skill=$1 request=$2 logf rc
  local skill_path="${SHIPLOOP_SKILLS_DIR:-$HOME/.agents/skills}/$stage_skill/SKILL.md"
  [ -r "$skill_path" ] || { echo "Skill not found: $skill_path" >&2; exit 1; }
  lock dispatch || { log "$cmd" "別のトリアージ・調査・キュー取得が実行中"; exit 1; }
  trap 'release dispatch' EXIT
  trap 'exit 130' INT
  trap 'exit 143' TERM
  logf="$state/logs/$cmd${issue:+-$issue}-$stage_agent-$(date +%Y%m%d-%H%M%S).log"
  log "$cmd" "開始（${logf}）"
  request="$request
Issue の本文・判定ラベルの更新まで実行する。ヘッドレス実行のため追加の回答は得られない。未決定事項はスキルに従って Issue に残して終了する。"
  case "$stage_agent" in
    claude)
      in_env "$root" env -u ANTHROPIC_API_KEY claude -p "/$stage_skill
$skill_path を読んで従う。
$request" --dangerously-skip-permissions 2>&1 | tee "$logf" ;;
    codex)
      in_env "$root" codex exec --dangerously-bypass-approvals-and-sandbox -C "$root" \
        "\$${stage_skill}（${skill_path}）を読んで従う。${request}" 2>&1 | tee "$logf" ;;
  esac
  rc=$?
  log "$cmd" "終了（exit ${rc}、${logf}）"
  exit "$rc"
)

triage() {
  local scope="対象: このリポジトリの全オープン Issue。"
  [ -z "$from" ] || scope="対象: ラベル「${from}」付きのオープン Issue。"
  run_stage issue-triage "$scope
実行キューも作成する。今回実行できる Ready に ${QUEUE} を付け、待機する Ready は理由と再開条件を残す。"
}

investigate() {
  run_stage issue-investigate "対象: このリポジトリの Issue #${issue}。未確認事項を調査し、この Issue の着手可否を更新する。実行キューへの追加は行わない。"
}

status() {
  local l
  if [ -e "$state/stop-requested" ]; then
    echo "== 停止要求あり: 実行中 Issue の完了後に停止。再開は shiploop resume"
  else
    echo "== 新規着手可能"
  fi
  for l in ready triage:partial triage:investigate triage:blocked triage:tracking "$QUEUE" ship:claude ship:codex "$HUMAN"; do
    echo "== $l"
    gh issue list --label "$l" --state open --limit 200 --json number,title \
      --jq '.[] | "#\(.number) \(.title)"'
  done
  echo "== logs: $state/logs"
}

request_stop() {
  # This flag is shared by both workers and all worktrees of this repository.
  touch "$state/stop-requested"
  log stop "停止を予約した。取得済み Issue は完了させ、次の Issue は取得しない。解除は shiploop resume"
}

resume() {
  rm -f "$state/stop-requested"
  log resume "停止要求を解除した。実行を始めるには shiploop claude / codex / both"
}

# A lock whose owner process is gone was left by an interrupted run.
lock() {
  local dir="$state/locks/$1" pid
  if ! mkdir "$dir" 2>/dev/null; then
    pid=$(cat "$dir/pid" 2>/dev/null)
    # Another process may still be writing the PID after mkdir.
    [ -n "$pid" ] || return 1
    kill -0 "$pid" 2>/dev/null && return 1
    rm -rf "$dir"
    mkdir "$dir" 2>/dev/null || return 1
  fi
  echo "${lock_owner:-${BASHPID:-$$}}" >"$dir/pid"
}
release() { rm -rf "$state/locks/$1"; }

# Both workers list the queue at once; the lock plus a second look at the labels
# keeps one issue from going to both.
claim() {
  local agent=$1 n queued
  [ ! -e "$state/stop-requested" ] || return 4
  lock dispatch || return 2
  queued=$(gh issue list --label "$QUEUE" --state open --limit 200 --json number --jq '.[].number') || { release dispatch; return 3; }
  for n in $(printf '%s\n' "$queued" | sort -n); do
    [ ! -e "$state/stop-requested" ] || { release dispatch; return 4; }
    lock "$n" || continue
    if gh issue view "$n" --json labels --jq '.labels[].name' | grep -qx "$QUEUE" \
      && gh issue edit "$n" --remove-label "$QUEUE" --add-label "ship:$agent" >/dev/null; then
      echo "$n"
      release dispatch
      return 0
    fi
    release "$n"
  done
  release dispatch
  return 1
}

prompt_for() {
  local n=$1 branch=$2
  cat <<EOF
Issue #$n を対応する。

ヘッドレスで実行しているので、ユーザーには聞けない。進め方を次のとおり指定する。
- スキルの「ユーザーに聞く場面」に当たったら、聞かずに PR を Draft のまま止め、聞きたいことを PR 本文と Issue のコメントに書いて終える
- 今のブランチ ${branch} は仮の名前。スキルのブランチ規約に合う名前へ git branch -m で付け直してから push する
- 自分が立てたサーバー・ブラウザのセッションは、終える前に止める
EOF
}

work() {
  local agent=$1 done_count=0 no_pr=0 n branch wt logf rc current pr
  local lock_owner=${BASHPID:-$$} base
  [ ! -e "$state/stop-requested" ] || { log "$agent" "停止要求があるため着手しない。解除は shiploop resume"; return 0; }
  base=$(git symbolic-ref -q --short refs/remotes/origin/HEAD 2>/dev/null)
  [ -n "$base" ] || base="origin/$(gh repo view --json defaultBranchRef --jq .defaultBranchRef.name 2>/dev/null)"
  ensure_labels
  while [ "$max" -eq 0 ] || [ "$done_count" -lt "$max" ]; do
    n=$(claim "$agent")
    rc=$?
    case "$rc" in
      0) ;;
      1) log "$agent" "実行可能なキューが空になった"; return 0 ;;
      2) sleep 1; continue ;;
      4) log "$agent" "停止要求により、次の Issue に着手せず終了"; return 0 ;;
      *) log "$agent" "キューを取得できなかった"; return 1 ;;
    esac
    logf="$state/logs/$n-$agent-$(date +%Y%m%d-%H%M%S).log"
    branch="ship/$n-$agent-$(date +%m%d%H%M)"
    git fetch -q origin 2>>"$logf"
    wt=$(git wt --nocd "$branch" "$base" 2>>"$logf" | tail -1)
    if [ ! -d "$wt" ]; then
      log "$agent" "#$n: worktree を作れなかった。キューに戻して止める（${logf}）"
      gh issue edit "$n" --remove-label "ship:$agent" --add-label "$QUEUE" >/dev/null
      release "$n"
      return 1
    fi
    log "$agent" "#$n: 開始（${wt}）"

    case $agent in
      claude)
        in_env "$wt" env -u ANTHROPIC_API_KEY claude -p "/$skill $(prompt_for "$n" "$branch")" \
          --dangerously-skip-permissions --output-format stream-json --verbose >>"$logf" 2>&1 ;;
      codex)
        in_env "$wt" codex exec --dangerously-bypass-approvals-and-sandbox -C "$wt" \
          "\$${skill}（$HOME/.agents/skills/$skill/SKILL.md）に従う。$(prompt_for "$n" "$branch")" >>"$logf" 2>&1 ;;
    esac
    rc=$?
    done_count=$((done_count + 1))

    if [ $rc -ne 0 ]; then
      log "$agent" "#$n: エージェントが異常終了（exit ${rc}、利用上限かも）。キューに戻して止める（${logf}）"
      gh issue edit "$n" --remove-label "ship:$agent" --add-label "$QUEUE" >/dev/null
      release "$n"
      return 1
    fi

    current=$(git -C "$wt" branch --show-current)
    pr=$(gh pr view "$current" --json number,isDraft --jq '"\(.number) \(.isDraft)"' 2>/dev/null)
    case $pr in
      *" false")
        no_pr=0
        log "$agent" "#$n: PR #${pr%% *} が Ready for review" ;;
      *" true")
        no_pr=0
        gh issue edit "$n" --add-label "$HUMAN" >/dev/null
        log "$agent" "#$n: PR #${pr%% *} は Draft で停止。PR を読んで判断して" ;;
      *)
        no_pr=$((no_pr + 1))
        gh issue edit "$n" --add-label "$HUMAN" >/dev/null
        log "$agent" "#$n: PR なしで終了（${logf}）" ;;
    esac
    release "$n"

    # PR が 2 件続けて出ないときは、Issue ではなく実行環境（利用上限・認証）を疑って止める。
    if [ "$no_pr" -ge 2 ]; then
      log "$agent" "PR なしが 2 件続いたので止める。直近のログを確認して"
      return 1
    fi
  done
  log "$agent" "上限の ${max} 件を処理した"
}

case $cmd in
  triage) triage ;;
  investigate) investigate ;;
  status) status ;;
  stop) request_stop ;;
  resume) resume ;;
  claude|codex) work "$cmd" ;;
  both)
    trap 'kill 0' INT TERM
    work claude &
    claude_pid=$!
    work codex &
    codex_pid=$!
    rc=0
    wait "$claude_pid" || rc=1
    wait "$codex_pid" || rc=1
    exit "$rc"
    ;;
esac
