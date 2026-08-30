#!/usr/bin/env bash
# Remote Control のサーバーを tmux の detached セッションで持ち、一覧・停止する。
#
# バックグラウンドに投げっぱなしにせず tmux に持たせるのは、attach すれば QR コードと
# 接続状況を見られるため。生の & では起動直後の URL 表示を取りこぼす。
#
# 使い方:
#   run.sh                          実行中のサーバーを一覧する
#   run.sh start [パス] [フラグ]     起動する（既定はカレント。追加フラグはそのまま渡る）
#   run.sh stop <名前|パス>          停止する
#   run.sh attach <名前|パス>        端末を開いて状態を見る

set -uo pipefail

PREFIX="rc-"

have() { command -v "$1" >/dev/null 2>&1; }
have tmux || { echo "tmux が必要です" >&2; exit 1; }

repo_root() { git -C "${1:-.}" rev-parse --show-toplevel 2>/dev/null; }
exists() { tmux has-session -t "=$1" 2>/dev/null; }

# 名前でもリポジトリのパスでも受ける。ディレクトリならリポジトリのルート名を使う。
session_of() {
  local arg="$1" root
  if [ -d "$arg" ] && root=$(repo_root "$arg"); then
    echo "${PREFIX}$(basename "$root")"
  else
    echo "${PREFIX}${arg#"$PREFIX"}"
  fi
}

cmd_list() {
  local found=0
  printf '%-36s %-44s %s\n' "SESSION" "REPOSITORY" "起動"
  printf '%s\n' "$(printf '%.0s-' {1..92})"
  while IFS='|' read -r name path created; do
    case "$name" in
      "${PREFIX}"*) ;;
      *) continue ;;
    esac
    found=1
    printf '%-36s %-44s %s\n' "$name" "${path/#"$HOME"/\~}" "$(date -r "$created" '+%m/%d %H:%M' 2>/dev/null)"
  done < <(tmux list-sessions -F '#{session_name}|#{session_path}|#{session_created}' 2>/dev/null)
  [ "$found" = 0 ] && echo "(起動中のサーバーはありません)"
}

cmd_start() {
  local target="$PWD" root name
  # 先頭がフラグでなく実在するディレクトリなら対象リポジトリ、以降は claude へのフラグ。
  if [ $# -ge 1 ] && [ "${1#-}" = "$1" ] && [ -d "$1" ]; then
    target="$1"; shift
  fi
  root=$(repo_root "$target") || { echo "git リポジトリではありません: $target" >&2; exit 1; }
  name="${PREFIX}$(basename "$root")"

  if exists "$name"; then
    echo "既に起動しています: $name"
    echo "状態を見るには: $(basename "$0") attach $(basename "$root")"
    exit 0
  fi

  # 対話シェルの claude エイリアスは tmux 経由では効かないので、ここで環境を落とす。
  # direnv が dotenv したプロジェクトの ANTHROPIC_API_KEY を拾うと Remote Control が拒否される。
  tmux new-session -d -s "$name" -c "$root" \
    env -u ANTHROPIC_API_KEY claude remote-control \
      --spawn worktree \
      --permission-mode auto \
      --remote-control-session-name-prefix "$(basename "$root")" "$@"

  # 起動に失敗すると tmux セッションごと即座に消えるため、少し待って生存を確認する。
  sleep 3
  if exists "$name"; then
    echo "起動しました: ${name}（$(basename "$root")）"
    echo "QR コードと URL: $(basename "$0") attach $(basename "$root")"
  else
    echo "起動に失敗しました。workspace trust を承認済みか確認してください:" >&2
    echo "  cd $root && claude" >&2
    exit 1
  fi
}

cmd_stop() {
  local name; name=$(session_of "$1")
  exists "$name" || { echo "起動していません: $name" >&2; exit 1; }
  tmux kill-session -t "=$name" && echo "停止しました: $name"
}

cmd_attach() {
  local name; name=$(session_of "$1")
  exists "$name" || { echo "起動していません: $name" >&2; exit 1; }
  # tmux の中からは attach できないので、クライアントを切り替える。
  if [ -n "${TMUX:-}" ]; then
    tmux switch-client -t "=$name"
  else
    tmux attach-session -t "=$name"
  fi
}

case "${1:-list}" in
  list|"")  cmd_list ;;
  start)    shift; cmd_start "$@" ;;
  stop)     shift; [ $# -ge 1 ] || { echo "名前かパスを指定してください" >&2; exit 1; }; cmd_stop "$1" ;;
  attach)   shift; [ $# -ge 1 ] || { echo "名前かパスを指定してください" >&2; exit 1; }; cmd_attach "$1" ;;
  *)        echo "不明なコマンド: $1" >&2; exit 1 ;;
esac
