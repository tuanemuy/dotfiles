#!/usr/bin/env bash
# Run Remote Control servers in detached tmux sessions: list, stop, and revive them.
#
# tmux is used instead of a plain background job so that attaching shows the QR code
# and connection status. With a bare &, the URL printed right after startup is lost.
#
# When the server dies, the on-demand worktree sessions die with it. Remote Control's
# own reattach (--continue / --session-id) fails with "archived or expired" once the
# retention window has passed and cannot be combined with --spawn. Revival therefore
# resumes the conversation log left in each worktree (--resume) and publishes it again
# with --remote-control.
#
# Usage:
#   clrc                          List running servers and sessions
#   clrc history                  List repositories started before, with their status
#   clrc start [path|name] [flags] Start the server and revive remaining worktrees
#   clrc revive [path|name]        Revive worktrees only (when the server runs elsewhere)
#   clrc stop <name|path|all>      Stop. Given a repository, also stops its revived worktree sessions
#   clrc attach <name|path>        Open the terminal to see the status
#
# Repositories passed to start / revive are recorded, so a name (directory basename)
# can be used instead of a path afterwards.

set -uo pipefail

PREFIX="rc-"
SELF=$(cd "$(dirname "$0")" && pwd)/$(basename "$0")
WTSTATUS=$(cd "$(dirname "$0")/../worktree-status" && pwd)/run.sh
# Command name shown in hints. A shell function wrapping this script passes its own name.
ME="${CLRC_NAME:-$(basename "$0")}"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/remote-control"
HISTORY="$STATE_DIR/repos"

have() { command -v "$1" >/dev/null 2>&1; }
have tmux || { echo "tmux is required" >&2; exit 1; }

exists() { tmux has-session -t "=$1" 2>/dev/null; }

# Panes that exited with an error are kept, so an existing session is not necessarily alive.
dead() { [ "$(tmux list-panes -t "=$1" -F '#{pane_dead}' 2>/dev/null | head -1)" = 1 ]; }

# Show the last output of a dead session and remove it. Returns 0 only when it removed one.
reap() {
  local name="$1" code
  exists "$name" && dead "$name" || return 1
  code=$(tmux list-panes -t "=$name" -F '#{pane_dead_status}' 2>/dev/null | head -1)
  echo "${name} exited with an error (exit code ${code:-?}); last output:" >&2
  # Include scrollback: the visible screen alone may have pushed the error off the bottom.
  tmux capture-pane -p -S -30 -t "=$name:" 2>/dev/null | sed '/^[[:space:]]*$/d' | tail -n 5 | sed 's/^/  | /' >&2
  tmux kill-session -t "=$name"
}

# Run a command in a detached session. On abnormal exit the pane is kept so that
# attach and list can show the cause. Setting remain-on-exit from outside after
# creation is too late for failures right at startup, so __run sets it from inside.
spawn() {
  local name="$1" dir="$2"; shift 2
  tmux new-session -d -s "$name" -c "$dir" "$SELF" __run "$@"
}

cmd_run() {
  [ -n "${TMUX_PANE:-}" ] && tmux set-option -p -t "$TMUX_PANE" remain-on-exit failed
  "$@"
  local code=$?
  # Ctrl+C is an intentional stop; keeping the pane would show it as an error.
  [ "$code" = 130 ] && exit 0
  exit "$code"
}

kill_session() {
  tmux kill-session -t "=$1" && echo "Stopped: $1"
}

# Resolve the main repository even when run from a worktree; the server and the session
# names are always derived from the main working tree.
# git, lsof, and the conversation log directory all use physical paths, so use -P to
# match them even when invoked through a symlink.
main_root() {
  local dir="${1:-.}" common
  [ -d "$dir" ] || return 1
  common=$(cd "$dir" 2>/dev/null && cd "$(git rev-parse --git-common-dir 2>/dev/null)" 2>/dev/null && pwd -P) || return 1
  dirname "$common"
}

# Record a started repository. Most recent first.
remember() {
  mkdir -p "$STATE_DIR"
  # grep returns non-zero when the file is missing or has no other entries,
  # so its exit code must not gate the mv.
  { echo "$1"; [ -f "$HISTORY" ] && grep -Fxv "$1" "$HISTORY"; true; } > "$HISTORY.tmp"
  mv "$HISTORY.tmp" "$HISTORY"
}

# Look up a repository by name in the history. Accepts the rc- prefix.
# When several share a name, the most recently used one wins.
recall() {
  local name="${1#"$PREFIX"}" path
  [ -f "$HISTORY" ] || return 1
  while IFS= read -r path; do
    [ "$(basename "$path")" = "$name" ] && [ -d "$path" ] && { printf '%s' "$path"; return 0; }
  done < "$HISTORY"
  return 1
}

resolve_root() {
  if [ -d "$1" ]; then main_root "$1"; else recall "$1"; fi
}

# Reduce to characters allowed in a tmux session name: alphanumerics, - and _.
slug() {
  printf '%s' "$1" | tr -c 'A-Za-z0-9_-' '-' | sed 's/--*/-/g; s/^-//; s/-$//' | cut -c1-40
}

# Conversation logs live in a directory named after the cwd with every
# non-alphanumeric character replaced by -.
project_dir() {
  printf '%s/.claude/projects/%s' "$HOME" "$(printf '%s' "$1" | sed 's/[^a-zA-Z0-9]/-/g')"
}

# The main conversation log of a directory. A worktree may also hold short logs from
# briefly opening claude there; picking by mtime would revive one of those instead.
# The largest log is taken as the real one.
main_session() {
  local file
  file=$(ls -S "$(project_dir "$1")"/*.jsonl 2>/dev/null | head -1)
  [ -s "$file" ] && basename "$file" .jsonl
}

# Worktrees created by spawn mode always live under <repo>/.claude/worktrees/.
# Only those are revived, so manually created worktrees are left alone.
#
# Whether a worktree is still needed is decided by worktree-status. Merged or closed
# PRs, no commits, and stale entries are not worth reviving.
# It calls gh once per worktree, so this takes a few seconds.
#
# Columns: status / path / branch / reason. A detached branch arrives as "-".
# It is passed through as is: an empty field would collapse the tabs and shift columns.
judge_worktrees() {
  local root="$1" status path branch reason
  while IFS=$'\t' read -r status path branch reason; do
    case "$path" in
      "$root"/.claude/worktrees/*) ;;
      *) continue ;;
    esac
    printf '%s\t%s\t%s\t%s\n' "$status" "$path" "$branch" "$reason"
  done < <("$WTSTATUS" "$root" --classify 2>/dev/null)
}

# Working directories and pids of running claude processes. A safety net against double
# starts for sessions that cannot be found by session name.
busy_dirs() {
  local pid cwd
  for pid in $(pgrep -x claude 2>/dev/null); do
    cwd=$(lsof -a -p "$pid" -d cwd -Fn 2>/dev/null | sed -n 's/^n//p')
    [ -n "$cwd" ] && printf '%s|%s\n' "$cwd" "$pid"
  done
}

# Pid of an already running spawn server, read from the pointer Remote Control writes
# itself, so servers started outside this helper are found too and not duplicated.
server_pid() {
  local file pid
  file="$(project_dir "$1")/bridge-pointer.json"
  [ -f "$file" ] || return 1
  pid=$(sed -n 's/.*"pid":\([0-9][0-9]*\).*/\1/p' "$file" | head -1)
  [ -n "$pid" ] || return 1
  ps -o command= -p "$pid" 2>/dev/null | grep -q "remote-control" || return 1
  printf '%s' "$pid"
}

# Name shown in the app. Carries over the title Remote Control assigned, if any.
session_title() {
  local file title
  file="$(project_dir "$1")/$2/custom-title.json"
  [ -f "$file" ] || return 0
  # Skip escaped quotes inside the value up to the closing quote, then unescape.
  title=$(sed -E -n 's/.*"customTitle":"(([^"\\]|\\.)*)".*/\1/p' "$file" | head -1 | sed 's/\\"/"/g; s/\\\\/\\/g')
  # The name after --remote-control is optional, so a leading - would be parsed as a flag.
  case "$title" in -*) return 0 ;; esac
  printf '%s' "$title"
}

wt_branch() {
  local branch
  branch=$(git -C "$1" rev-parse --abbrev-ref HEAD 2>/dev/null)
  # Detached HEADs would all collide on the same name; use the worktree name instead.
  [ -z "$branch" ] || [ "$branch" = "HEAD" ] && branch=$(basename "$1")
  printf '%s' "$branch"
}

# Accepts a name or a path. A worktree path resolves to that worktree's session name.
session_of() {
  local arg="$1" root wt
  if [ -d "$arg" ] && root=$(main_root "$arg"); then
    wt=$(cd "$arg" && git rev-parse --show-toplevel 2>/dev/null)
    if [ -n "$wt" ] && [ "$wt" != "$root" ]; then
      echo "${PREFIX}$(basename "$root")-$(slug "$(wt_branch "$wt")")"
    else
      echo "${PREFIX}$(basename "$root")"
    fi
  else
    echo "${PREFIX}${arg#"$PREFIX"}"
  fi
}

cmd_history() {
  local path repo name pid state
  [ -s "$HISTORY" ] || { echo "No history yet. Repositories are recorded when started with: ${ME} start <path>"; return 0; }
  printf '%-24s %-56s %s\n' "NAME" "DIRECTORY" "STATUS"
  printf '%s\n' "$(printf '%.0s-' {1..100})"
  while IFS= read -r path; do
    [ -n "$path" ] || continue
    repo=$(basename "$path"); name="${PREFIX}${repo}"
    if [ ! -d "$path" ]; then
      state="directory missing"
    elif exists "$name"; then
      state="running"; dead "$name" && state="exited with error (see: ${ME} attach ${repo})"
    elif pid=$(server_pid "$path"); then
      state="running (pid ${pid}, outside this helper)"
    else
      state="stopped (restart: ${ME} start ${repo})"
    fi
    printf '%-24s %-56s %s\n' "$repo" "${path/#"$HOME"/\~}" "$state"
  done < "$HISTORY"
  return 0
}

cmd_list() {
  local found=0 state
  printf '%-56s %-46s %-12s %s\n' "SESSION" "DIRECTORY" "STARTED" "STATUS"
  printf '%s\n' "$(printf '%.0s-' {1..124})"
  while IFS='|' read -r name path created; do
    case "$name" in
      "${PREFIX}"*) ;;
      *) continue ;;
    esac
    found=1
    state="running"
    dead "$name" && state="exited with error (see: ${ME} attach)"
    printf '%-56s %-46s %-12s %s\n' "$name" "${path/#"$HOME"/\~}" "$(date -r "$created" '+%m/%d %H:%M' 2>/dev/null)" "$state"
  done < <(tmux list-sessions -F '#{session_name}|#{session_path}|#{session_created}' 2>/dev/null)
  [ "$found" = 0 ] && echo "(no running sessions)"
  return 0
}

# The loop that keeps running inside tmux. Restarts the server quietly when it dies.
cmd_supervise() {
  local root="$1"; shift
  while true; do
    local started code ran
    started=$(date +%s)
    env -u ANTHROPIC_API_KEY claude remote-control \
      --spawn worktree \
      --permission-mode auto \
      --remote-control-session-name-prefix "$(basename "$root")" "$@"
    code=$?
    ran=$(( $(date +%s) - started ))

    # Ctrl+C and a clean exit are intentional stops; restarting would make stop impossible.
    case "$code" in 0|130) exit 0 ;; esac

    # Dying right after startup is a configuration problem that retrying will not fix.
    if [ "$ran" -lt 20 ]; then
      echo "Error: failed to start (exit code ${code})" >&2
      exit 1
    fi

    echo "Server exited unexpectedly (exit code ${code}); restarting" >&2
    # Bring back the worktree sessions that died with the server before looping.
    # Wait briefly: a process still shutting down keeps its cwd and would be taken as running.
    sleep 3
    "$SELF" revive "$root"
  done
}

# Resume the conversation logs left in worktrees and publish them through Remote Control again.
cmd_revive() {
  local target="${1:-$PWD}" root repo found=0 revived=0 skipped=0

  if [ ! -x "$WTSTATUS" ]; then
    echo "worktree-status not found: $WTSTATUS" >&2; exit 1
  fi
  root=$(resolve_root "$target") || { echo "Not a git repository or a known name: $target" >&2; exit 1; }
  repo=$(basename "$root")
  remember "$root"

  local busy; busy=$(busy_dirs)

  while IFS=$'\t' read -r status wt branch reason; do
    [ -n "$wt" ] || continue
    found=$((found + 1))
    local label name uuid title cwd
    [ "$branch" = "-" ] && branch=""
    label="${branch:-$(basename "$wt")}"

    # Check liveness first: a running session is left alone regardless of PR state.
    # A dead one is cleaned up and revived again.
    name="${PREFIX}${repo}-$(slug "$label")"
    if exists "$name" && ! reap "$name"; then
      echo "Already running: ${name}"
      continue
    fi
    # The session name comes from the worktree's branch, so it cannot be found once the
    # branch changes. Also check the cwd of running processes, whatever started them.
    local held=""
    while IFS='|' read -r cwd cpid; do
      # Prefix match, since the process may have cd'd inside. Worktrees are separate
      # directories, so this cannot match a sibling.
      case "$cwd" in "$wt"|"$wt"/*) held="$cpid"; break ;; esac
    done <<< "$busy"
    if [ -n "$held" ]; then
      echo "Already running: ${label} (pid ${held})"
      continue
    fi

    if [ "$status" != "KEEP" ]; then
      echo "Skipping: ${label} (${reason})"
      skipped=$((skipped + 1))
      continue
    fi
    uuid=$(main_session "$wt")
    if [ -z "$uuid" ]; then
      echo "Skipping: ${label} (no conversation log)"
      skipped=$((skipped + 1))
      continue
    fi
    title=$(session_title "$wt" "$uuid")

    # Revival must complete unattended. Resuming a large session after a long idle
    # period asks "resume from summary?", and the app is unusable until answered.
    # Raise the threshold for this process only (the global setting is untouched).
    # This always resumes in full, so the first exchange costs more tokens than a summary.
    spawn "$name" "$wt" \
      env -u ANTHROPIC_API_KEY \
          CLAUDE_CODE_RESUME_THRESHOLD_MINUTES=99999999 \
        claude \
        --resume "$uuid" \
        --permission-mode auto \
        --remote-control "${title:-${repo}/${label}}"
    revived=$((revived + 1))
    echo "Revived: ${name} (${title:-$label})"
  done < <(judge_worktrees "$root")

  if [ "$found" = 0 ]; then
    echo "No worktrees to revive"
  elif [ "$revived" -gt 0 ]; then
    echo "Revived ${revived} session(s). For the QR code and URL: ${ME} attach <name>"
  elif [ "$skipped" -gt 0 ]; then
    echo "Nothing to revive (${skipped} skipped: finished or no log)"
  fi
  return 0
}

cmd_start() {
  local target="$PWD" root name
  # A first argument that is not a flag is the target repository (path or recorded name);
  # everything after it is passed to claude.
  if [ $# -ge 1 ] && [ "${1#-}" = "$1" ]; then
    target="$1"; shift
  fi
  root=$(resolve_root "$target") || { echo "Not a git repository or a known name: $target" >&2; exit 1; }
  remember "$root"
  local repo_label; repo_label=$(basename "$root")
  name="${PREFIX}${repo_label}"

  local running
  if exists "$name" && ! reap "$name"; then
    echo "Already running: $name"
  elif running=$(server_pid "$root"); then
    echo "Already running: ${repo_label} (pid ${running}, started outside this helper)"
  else
    # The interactive shell's claude alias does not apply under tmux, so the supervisor
    # strips the environment itself. Remote Control refuses to run when it picks up an
    # ANTHROPIC_API_KEY that direnv loaded from the project's dotenv.
    spawn "$name" "$root" "$SELF" __supervise "$root" "$@"

    # A failed start exits almost immediately; wait briefly and check it is still alive.
    sleep 3
    if ! exists "$name" || reap "$name"; then
      echo "Failed to start. If this is the first run, accept the workspace trust prompt:" >&2
      echo "  cd $root && claude" >&2
      exit 1
    fi
    echo "Started: ${name} (${repo_label})"
    echo "For the QR code and URL: ${ME} attach ${repo_label}"
  fi

  cmd_revive "$root"
}

cmd_stop() {
  local stopped=0 name sname path root=""
  if [ "$1" = "all" ]; then
    while IFS= read -r name; do
      case "$name" in "${PREFIX}"*) kill_session "$name" && stopped=$((stopped + 1)) ;; esac
    done < <(tmux list-sessions -F '#{session_name}' 2>/dev/null)
    [ "$stopped" = 0 ] && echo "No running sessions"
    return 0
  fi

  name=$(session_of "$1")
  # Given the main repository, its revived worktree sessions are stopped as well.
  # With only a name, the path comes from the server's tmux session or from the history.
  if [ -d "$1" ]; then
    root=$(main_root "$1")
  elif exists "$name"; then
    root=$(tmux display-message -p -t "=$name:" '#{session_path}' 2>/dev/null)
  else
    root=$(recall "$1") || root=""
  fi
  if [ -n "$root" ] && [ "$name" = "${PREFIX}$(basename "$root")" ]; then
    while IFS='|' read -r sname path; do
      case "$sname" in "${PREFIX}"*) ;; *) continue ;; esac
      case "$path" in "$root"|"$root"/*) kill_session "$sname" && stopped=$((stopped + 1)) ;; esac
    done < <(tmux list-sessions -F '#{session_name}|#{session_path}' 2>/dev/null)
  elif exists "$name"; then
    kill_session "$name" && stopped=$((stopped + 1))
  fi
  [ "$stopped" = 0 ] && { echo "Not running: $name" >&2; exit 1; }
  return 0
}

cmd_attach() {
  local name; name=$(session_of "$1")
  exists "$name" || { echo "Not running: $name" >&2; exit 1; }
  # Attaching from inside tmux is not possible; switch the client instead.
  if [ -n "${TMUX:-}" ]; then
    tmux switch-client -t "=$name"
  else
    tmux attach-session -t "=$name"
  fi
}

case "${1:-list}" in
  list|"")      cmd_list ;;
  history)      cmd_history ;;
  start)        shift; cmd_start "$@" ;;
  revive)       shift; cmd_revive "$@" ;;
  stop)         shift; [ $# -ge 1 ] || { echo "Usage: ${ME} stop <name|path|all>" >&2; exit 1; }; cmd_stop "$1" ;;
  attach)       shift; [ $# -ge 1 ] || { echo "Usage: ${ME} attach <name|path>" >&2; exit 1; }; cmd_attach "$1" ;;
  __supervise)  shift; cmd_supervise "$@" ;;
  __run)        shift; cmd_run "$@" ;;
  *)            echo "Unknown command: $1" >&2; exit 1 ;;
esac
