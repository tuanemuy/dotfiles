# Phase 2: 実装ガイド

## Step 1: ブランチの作成

```bash
git checkout -b issue/{Issue番号}/{短い説明}
```

ブランチ名の `{短い説明}` はIssueのタイトルからケバブケースで生成する（英語・小文字・ハイフン区切り、30文字以内）。

既に同名のブランチがあればユーザーに確認する。

## Step 2: plan.md に沿った実装

サブエージェントを起動し、plan.md に沿って実装させる（委譲方式は `../../_shared/references/subagent-policy.md` に従う）。

サブエージェントに渡す内容:

```
あなたは実装計画に基づいてコードを実装するエンジニアです。

## 対象Issue
- Issue番号: #{Issue番号}
- 計画ファイル: .issue/{Issue番号}/plan.md

## やること
1. .issue/{Issue番号}/plan.md を読む
2. 各実装ステップについて、対象ファイルを読んで現状を把握する
3. 計画の指示に従って変更を適用する
4. CLAUDE.md や README.md にテスト・lint・型チェックの実行方法が記載されていれば、それに従って確認する
5. 実装中に非自明な設計判断を下した場合は、.issue/{Issue番号}/adr.md に追記する
   - 既に adr.md がある場合は末尾に追記、なければ新規作成
   - 形式: 各決定ごとに「## 決定タイトル」「コンテキスト」「決定内容」「理由」を記載

## 重要な原則
- plan.md の指示に忠実に従う — 勝手にスコープを広げない
- 既存コードのスタイル・規約に合わせる
- 不明点や判断に迷う点があれば、実装せずにその旨を報告する

## 出力
- 変更したファイルの一覧と変更内容の要約
- テスト・lint実行結果（実行した場合）
- 記録した設計判断（adr.md に追記した場合）
- 判断に迷った点や懸念事項（あれば）
- 完了できなかった項目や既知の制限（あれば）
```

### 実装結果の確認

サブエージェントが完了したら:

1. 報告を確認する
2. 判断に迷った点やエラーがあれば対処する（必要ならユーザーに確認）
3. CLAUDE.md や README.md の手順に従い、全体のテスト・lint・型チェックで整合性を確認する

### 残存課題の記録

実装結果を確認した後、以下のいずれかに該当する項目があれば `.issue/{Issue番号}/progress.md` に記録する:

- plan.md の項目のうち、完全には実装できなかったもの
- 既知の制限事項やエッジケース
- 適用した回避策とその理由
- フォローアップが必要な作業

各項目には具体的な内容・理由・影響範囲を明記する。「TODO」「後で対応」のような曖昧な記述は避ける。

該当なしの場合は progress.md を作成しない。

## Step 3: 検証環境確認とブラウザ検証

### 検証環境確認

ブラウザ検証の前に、testing.md の「検証環境の起動」に記載されたコマンドでサーバーが正常に起動できることを確認する。ステージング・本番環境へのデプロイは行わない。

```bash
# testing.md に記載された手順に従う（例）
pnpm dev     # 開発サーバーが起動するか確認
```

起動でエラーが発生した場合は、ブラウザ検証前に修正する。

### ブラウザ検証

`../manual-test/SKILL.md` を読み、その手順に従ってブラウザ検証を実行する。シードデータの準備も manual-test スキルに委ねる。

manual-test に渡す情報:
- テストソース: `.issue/{Issue番号}/testing.md`
- 成果物ディレクトリ: `.issue/{Issue番号}/manual-test/`
- Issue番号: #{Issue番号}

以下の場合はスキップして、その旨を PR の Test plan に記載する:
- Web UI を持たないプロジェクト（CLI ツール、ライブラリ等）
- testing.md にブラウザ操作を伴うテスト項目がない
- manual-test の前提条件（agent-browser 等）が満たせない

ブラウザ検証で失敗がある場合は、manual-test が原因分析を行い GitHub Issue を起票する。起票された Issue は PR の Test plan に記載する。

## Step 4: コミットとPR作成

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

### デプロイ・動作確認方法
{testing.md の「デプロイ・起動手順」から正確なコマンドを転記}

### 確認項目
- {testing.md からの主要確認項目}

## Browser Verification
- {ブラウザ検証の実行結果サマリー — 全PASS / 一部FAIL等 / スキップ}
- {FAILがあれば起票したIssue番号と理由}

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```
