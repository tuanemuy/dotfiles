# Phase 2: 実装ガイド

`tasks.md` までが整っている前提で、`/speckit.implement` をラップして実装し、quickstart.md で検証してから PR を作成する。

## Step 1: ブランチの確認

spec-kit の `create-new-feature.sh` は通常 `NNN-feature-name` 形式のブランチを作成済みである（`specs/NNN-feature-name/` ディレクトリと同じ名前）。

```bash
git branch --show-current
```

確認のポイント:

- 現在のブランチが `NNN-feature-name` 形式で `{FEATURE_DIR}` の名前と一致しているか
- 一致していない場合:
  - main / master 等にいる → `git checkout -b NNN-feature-name` でブランチを作成
  - 他のフィーチャーブランチにいる → ユーザーに確認（誤ったブランチ上で実装しないため）
- 既に同名のブランチがある場合はユーザーに確認する

ブランチ名は `{FEATURE_DIR}` のディレクトリ名（例: `001-user-authentication`）をそのまま使う。spec-kit の規約と PR・追跡の一貫性を保つため。

## Step 2: `/speckit.implement` の実行

spec-kit のスラッシュコマンドで実装を進める。

```
/speckit.implement
```

このコマンドは `tasks.md` のタスクを依存順（テスト → 実装の TDD 順序）に沿って実行する。`[P]` マーカーが付いたタスクは並列実行候補となる。

### 進行管理

`/speckit.implement` は長時間動作する可能性が高い。以下を守る:

1. 実行前に作業ディレクトリがクリーンか確認する（`git status` で未コミット変更がないこと）
2. 実行中は途中介入しない。spec-kit が依存順とテスト先行を管理しているため、勝手にタスクを並べ替えない
3. 完了後に以下を確認する:
   - `tasks.md` の各タスクのチェック状態（`[x]` 付与の有無）
   - 生成・変更されたファイルの一覧（`git status`）
   - テストの実行結果（spec-kit が実行している場合）

### 実装中の非自明な設計判断

`/speckit.implement` は内部で多くの判断を下す。重要なものはこちら側で抽出し、`{FEATURE_DIR}/adr.md` に追記する:

- ライブラリ・パッケージの選択（複数候補があったとき）
- データモデルの非自明な拡張（plan に書かれていない field 追加等）
- 既存コードとの統合方針（adapter パターン、ラッパー導入等）

判断材料は `/speckit.implement` の出力ログとコミット差分から拾う。すべて拾わなくてよい — 後から読み返して有用なもののみ記録する。

### 失敗時の対処

`/speckit.implement` が途中で失敗した場合:

1. 失敗箇所のタスク ID とエラー内容を確認する
2. **テストの失敗**ならば、spec / plan / tasks との齟齬の可能性が高い。`tasks.md` を確認し、必要に応じて `/speckit.analyze` で再検証する
3. **環境起因の失敗**（依存パッケージ未インストール、ポート競合等）ならば、根本原因を直してから `/speckit.implement` を再開する（spec-kit は途中のチェック状態を尊重する）
4. 3 回連続で同じ箇所で失敗するならば、ユーザーに判断を仰ぐ

### 全体の品質チェック

`/speckit.implement` 完了後、プロジェクトのルートにある `CLAUDE.md` / `README.md` / `package.json` から以下を読み取って実行する:

- 型チェック（`tsc --noEmit`、`mypy`、`cargo check` 等）
- Lint（`eslint`、`ruff`、`cargo clippy` 等）
- テスト（`pnpm test`、`pytest`、`cargo test` 等）

エラーがあれば spec-kit が見逃した可能性がある。エラー内容を確認し、サブエージェントに修正を委譲するか、自分で軽微な修正を行う（委譲方式は `../../_shared/references/subagent-policy.md` に従う）。

> **この品質チェック（および `tasks.md` の Polish フェーズで回す `code-reviewer` / `typescript-reviewer` / `log-compliance-checker` 等のレビュー）は、実装の技術的健全性を確認するものであって、Phase 3 のPRレビューの代替ではない。** ここで品質チェックが通っても、PR 作成後に Phase 3 のレイヤー観点による多角レビューループ（`review-guide.md`）を必ず別途実行すること。両者は目的・観点・完了条件が異なる。

## Step 3: quickstart.md による検証

`{FEATURE_DIR}/quickstart.md` は spec-kit が定義した受け入れ検証手順である。これを実行して、spec.md の意図通りに動くことを確認する。

### 実行方法

1. `quickstart.md` を読み、検証シナリオの全体像を把握する
2. 必要な事前準備（DB 起動、シードデータ、認証情報セットアップ等）を実行する
3. 各シナリオを順番に実行し、期待結果と実測結果を比較する
4. 失敗があれば原因を切り分ける

### 結果の記録

`{FEATURE_DIR}/quickstart-results.md` に結果を記録する:

```markdown
# Quickstart Results — {NNN-feature-name}

**Date:** {日付}
**Branch:** {ブランチ名}
**Commit:** {コミット SHA}

---

## シナリオ 1: {タイトル}

- **目的:** {quickstart.md からの引用}
- **手順:** {実行した手順}
- **期待結果:** {quickstart.md の期待結果}
- **実測結果:** {実際に観測されたもの}
- **判定:** PASS / FAIL / SKIP
- **備考:** {スクリーンショットパス・関連エラー等}

## シナリオ 2: ...

---

## サマリ

- 全シナリオ数: {数}
- PASS: {数}
- FAIL: {数}（詳細: {シナリオ番号と原因})
- SKIP: {数}（詳細: {スキップ理由})
```

### 失敗時の対処

- 変更箇所起因かつ即時修正可能な失敗 → Step 2 に戻って `/speckit.implement` を該当タスクから再開、または手動修正してから再検証する
- 環境起因の失敗 → 環境を直してから再実行する
- spec の意図と実装の齟齬が原因 → 修正方針を `adr.md` に記録した上で実装を直す。spec 自体に問題があれば Phase 4 で Issue 起票する

### スキップ条件

quickstart.md は原則実行する。スキップは以下のいずれかを**実際に確認した**場合のみ:

- `quickstart.md` が存在しない（spec-kit のテンプレートで意図的に省略されたケース）
- `quickstart.md` の内容が「該当なし」「N/A」のみ
- ローカル環境で実行不可能な前提（外部 SaaS への書き込み等）が含まれており、本番環境でしか検証できない

スキップする場合は PR の Test plan に「スキップ理由: {確認した内容}」を一行で記載する。

## Step 4: 残存課題の記録

実装結果を確認した後、以下のいずれかに該当する項目があれば `{FEATURE_DIR}/progress.md` に記録する:

- `tasks.md` の項目のうち、完全には実装できなかったもの
- 既知の制限事項やエッジケース
- 適用した回避策とその理由
- フォローアップが必要な作業

各項目には具体的な内容・理由・影響範囲を明記する。「TODO」「後で対応」のような曖昧な記述は避ける。

該当なしの場合は progress.md を作成しない。

## Step 5: コミットと PR 作成

### コミット

`/speckit.implement` がタスク単位でコミットを作成している場合はそのまま使う。一括で変更が残っている場合は意味のある単位でコミットする。

```bash
git add -A
git commit -m "$(cat <<'EOF'
{コミットメッセージ}

Feature: {NNN-feature-name}
Spec: {FEATURE_DIR}/spec.md
EOF
)"
```

コミットメッセージは Conventional Commits 形式（feat/fix/refactor/test/docs/chore）を使う。

### プッシュ

```bash
git push -u origin {NNN-feature-name}
```

### PR 作成

```bash
gh pr create --title "{PRタイトル}" --body "$(cat <<'EOF'
## Summary
- {spec.md のユーザーストーリーから要約}

## Spec
- Feature: `{FEATURE_DIR}/`
- spec.md: `{FEATURE_DIR}/spec.md`
- plan.md: `{FEATURE_DIR}/plan.md`
- tasks.md: `{FEATURE_DIR}/tasks.md`

## Implementation
- 完了タスク: {完了数} / {全タスク数}
- 残存課題: `{FEATURE_DIR}/progress.md`（あれば）

## Test plan

### 検証手順
`{FEATURE_DIR}/quickstart.md` を参照

### Quickstart 実行結果
- {quickstart-results.md のサマリ — 全PASS / 一部FAIL / スキップ}
- 詳細: `{FEATURE_DIR}/quickstart-results.md`

## Notes
- Constitution Check: {plan.md の Phase 0/1 の結果}
- 設計判断: `{FEATURE_DIR}/adr.md`（あれば）

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

PR タイトルは `feat({feature-name}): {要約}` のような spec-kit のフィーチャー名を含めた形式が望ましい。

## Step 6: Phase 2 完了報告

Phase 2 が完了したら、Phase 3 に進む前に以下を確認する:

```
Phase 2（実装）が完了しました。

- ブランチ: {ブランチ名}
- PR: #{PR番号}
- 完了タスク: {完了数} / {全タスク数}
- quickstart: PASS {数} / FAIL {数} / SKIP {数}
- 残存課題: progress.md（{あり/なし}）
```

quickstart に FAIL があり、それが spec の意図に関わる場合はユーザー判断を仰ぐ。それ以外は Phase 3 に進む。

## 重要な注意点

- spec-kit のスラッシュコマンドが利用できない環境では本スキルは保留する。自前で実装ロジックを書き起こさない
- `tasks.md` の依存順序を勝手に並べ替えない — spec-kit のテスト先行ポリシーが崩れる
- 委譲方式・並列実行・失敗時の扱いは `../../_shared/references/subagent-policy.md` に従う
- 実装中の非自明な設計判断は `adr.md` に記録する。すべての判断を拾う必要はないが、ライブラリ選択・データモデル拡張・統合方針は記録する
