#!/usr/bin/env bash
# SessionStart hook: セッションの作業ディレクトリで依存を揃える。
#
# git worktree はまっさらなチェックアウトなので、.worktreeinclude でコピーした
# 設定ファイルだけでは動かない。ここで direnv の許可と依存インストールまでやる。
#
# 動くのはリンクされた worktree のときだけ。メインチェックアウトで依存が無いのは
# 利用者が意図した状態なので、調べ物のセッションを install で待たせない。
#
# stdout は Claude のコンテキストに入るため、出力は1行に抑える。
# 何が起きても失敗させない（exit 0 固定）。セッション開始を止めない。

set -uo pipefail

[ "${CLAUDE_SKIP_WORKTREE_SETUP:-}" = "1" ] && exit 0

dir=$(cat | jq -r '.cwd // empty' 2>/dev/null)
[ -n "$dir" ] && [ -d "$dir" ] || exit 0
cd "$dir" 2>/dev/null || exit 0

# リンクされた worktree では git-dir が .git/worktrees/<名前> を指し、
# メインチェックアウトでは共通ディレクトリと一致する。
gitdir=$(git rev-parse --absolute-git-dir 2>/dev/null) || exit 0
common=$(cd "$(git rev-parse --git-common-dir 2>/dev/null)" 2>/dev/null && pwd -P) || exit 0
[ "$gitdir" = "$common" ] && exit 0

# セッションはサブディレクトリで始まることがある。
cd "$(git rev-parse --show-toplevel)" || exit 0

done_steps=()

note() { done_steps+=("$1"); }
have() { command -v "$1" >/dev/null 2>&1; }

# direnv の許可はパス単位で記録される。.envrc をコピーしただけの worktree は
# 未許可のまま黙って無効化されるので、ここで明示的に許可する。
# `Found RC allowed 0` が許可済みを表す。判定できなければ allow を実行するだけで害はない。
if [ -f .envrc ] && have direnv; then
  if ! direnv status 2>/dev/null | grep -q "Found RC allowed 0"; then
    direnv allow . >/dev/null 2>&1 && note "direnv allow"
  fi
fi

# 処理系が devShell 側にしか無いことがある（例: flake 経由の pnpm / cargo）。
run=()
run_set=""
if [ -f .envrc ] && have direnv; then
  run=(direnv exec .); run_set=1
elif [ -f flake.nix ] && have nix; then
  run=(nix develop -c); run_set=1
fi

# bash 3.2 は set -u 下で空配列を展開すると失敗するため、配列ではなくフラグで分岐する。
exec_in() {
  if [ -n "${run_set:-}" ]; then "${run[@]}" "$@"; else "$@"; fi
}

try() {
  local label="$1"; shift
  have "$1" || [ -n "${run_set:-}" ] || return 1
  if exec_in "$@" >/dev/null 2>&1; then note "$label"; else note "$label(失敗)"; fi
}

# node_modules は worktree ごとに必要。
if [ ! -d node_modules ] && [ -f package.json ]; then
  if   [ -f pnpm-lock.yaml ];  then try "pnpm install"  pnpm install --frozen-lockfile
  elif [ -f bun.lock ] || [ -f bun.lockb ]; then try "bun install" bun install --frozen-lockfile
  elif [ -f yarn.lock ];       then try "yarn install"  yarn install
  elif [ -f package-lock.json ]; then try "npm ci"      npm ci
  elif [ -f deno.lock ] || [ -f deno.json ] || [ -f deno.jsonc ]; then try "deno install" deno install
  else try "npm install" npm install
  fi
fi

# 仮想環境はディレクトリに紐づくので worktree ごとに作る。
if [ ! -d .venv ]; then
  if   [ -f uv.lock ];      then try "uv sync"       uv sync
  elif [ -f poetry.lock ];  then try "poetry install" poetry install
  elif [ -f Pipfile.lock ]; then try "pipenv sync"   pipenv sync
  fi
fi

if [ -f composer.json ] && [ ! -d vendor ]; then
  try "composer install" composer install
fi

if [ -f Gemfile ] && ! exec_in bundle check >/dev/null 2>&1; then
  try "bundle install" bundle install
fi

if [ -f mix.exs ] && [ ! -d deps ]; then
  try "mix deps.get" mix deps.get
fi

# Rust・Go・Deno のパッケージキャッシュ（~/.cargo, ~/go/pkg/mod, ~/.cache/deno）は
# グローバルで worktree 間で共有されるため、ここでは何もしない。

if [ -n "${done_steps[*]:-}" ]; then
  printf 'worktree setup: %s\n' "$(IFS=,; echo "${done_steps[*]}")"
fi

exit 0
