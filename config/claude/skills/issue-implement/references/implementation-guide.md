# Phase 2: 実装ガイド

## Step 1: ブランチの作成

```bash
git checkout -b issue/{Issue番号}/{短い説明}
```

ブランチ名の `{短い説明}` はIssueのタイトルからケバブケースで生成する（英語・小文字・ハイフン区切り、30文字以内）。

既に同名のブランチがあればユーザーに確認する。

## Step 2: plan.md に沿った実装

サブエージェント（Agent tool, subagent_type="general-purpose"）を起動し、plan.md に沿って実装させる。

サブエージェントに渡す内容:

```
あなたは実装計画に基づいてコードを実装するエンジニアです。

## 対象Issue
- Issue番号: #{Issue番号}
- 計画ファイル: .issue/{Issue番号}/plan.md

## やること
1. .issue/{Issue番号}/plan.md を読む
2. 各実装ステップについて、対象ファイルを Read で読んで現状を把握する
3. 計画の指示に従って Edit/Write で変更を適用する
4. CLAUDE.md や README.md にテスト・lint・型チェックの実行方法が記載されていれば、それに従って確認する

## 重要な原則
- plan.md の指示に忠実に従う — 勝手にスコープを広げない
- 既存コードのスタイル・規約に合わせる
- 不明点や判断に迷う点があれば、実装せずにその旨を報告する

## 出力
- 変更したファイルの一覧と変更内容の要約
- テスト・lint実行結果（実行した場合）
- 判断に迷った点や懸念事項（あれば）
```

### 実装結果の確認

サブエージェントが完了したら:

1. 報告を確認する
2. 判断に迷った点やエラーがあれば対処する（必要ならユーザーに確認）
3. CLAUDE.md や README.md の手順に従い、全体のテスト・lint・型チェックで整合性を確認する

## Step 3: コミットとPR作成

1. 変更をステージング＆コミット

```bash
git add <変更ファイル>
git commit -m "$(cat <<'EOF'
{コミットメッセージ}

Issue #{Issue番号}
EOF
)"
```

2. リモートにプッシュ

```bash
git push -u origin issue/{Issue番号}/{短い説明}
```

3. PR作成

```bash
gh pr create --title "{PRタイトル}" --body "$(cat <<'EOF'
## Summary
- {変更内容の箇条書き}

## Issue
Closes #{Issue番号}

## Implementation Plan
Based on `.issue/{Issue番号}/plan.md`

## Test plan
- {testing.md からの主要確認項目}

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```
