---
name: issue-implement
description: >
  Issueの計画立案 → 実装 → PRレビュー・修正を一気通貫で行うスキル。
  issue-planner で計画を立て、計画に基づいて実装し、ブランチ作成・コミット・PR作成後に
  pr-review で品質を担保する。
  ユーザーが「Issue #123 を実装して」「#45 をやって」「このIssue対応して」
  「Issue実装」「implement #123」「これ対応して」「一気にやって」
  「計画から実装までやって」「プラン → 実装 → レビューまでお願い」
  などと言ったときにトリガーする。
  Issue番号やURLと共に実装の依頼があった場合にこのスキルを使うこと。
  計画だけでなく実装まで求められている場合は issue-planner ではなくこちらを使う。
---

# Issue Implement — 計画 → 実装 → レビューの一気通貫スキル

GitHub Issueに対して、計画立案 → 実装 → PR作成 → レビュー・修正を一連のフローで実行する。

## Workflow Overview

```
Phase 1: 計画（issue-plannerに委譲）
  → .issue/{Issue番号}/plan.md, testing.md, (adr.md) を作成

Phase 2: 実装
  ブランチ作成 → plan.md に沿って実装 → 検証環境確認 → manual-test スキルでブラウザ検証（シードデータ準備含む）→ コミット → PR作成

Phase 3: レビュー・修正
  → 指摘修正 → 再レビュー（1ラウンドでクリーンなら完了、最大10ラウンド）

Phase 4: スコープ外Issueの起票
  → 全フェーズで見送ったスコープ外の改善・課題をIssueとして起票
```

---

## Phase 1: 計画

`../issue-planner/SKILL.md` を読み、その手順に従って計画を立てる。

計画が完了したら（plan.md, testing.md, 必要に応じて adr.md が作成されたら）、Phase 2 に進む前に testing.md の「確認環境」セクションを検証する。具体的には:

1. testing.md の「実行手順」を読む
2. そこに書かれた各コマンドが CLAUDE.md・README.md・package.json の scripts（全項目）に実在するか、実際にファイルを読んで確認する
3. 変更箇所を実際に触れる状態にするまでに必要な手順が testing.md に揃っているかを確認する。曖昧な逃げ文句（例: 「手動で対応してください」「環境に応じて実行してください」）があれば、該当する正しいコマンドをプロジェクトのドキュメントから確認して置き換える
4. 実在しないコマンドがあれば削除または正しいコマンドに修正する
5. プロジェクト全体のセットアップ手順が含まれていたら削除し、Issue の変更を確認するのに必要なコマンドだけに絞る

---

## Phase 2: 実装

`references/implementation-guide.md` を読み、その手順に従って実装する。

実装中に下した非自明な設計判断は `.issue/{Issue番号}/adr.md` に追記する。
実装完了後、残存課題があれば `.issue/{Issue番号}/progress.md` に詳細を記録する。

---

## Phase 3: レビュー・修正

`references/review-guide.md` を読み、その手順に従ってレビュー・修正を行う。

レビューの成果物は `.issue/{Issue番号}/review/` に保存し、ADR は `.issue/{Issue番号}/adr.md` に追記する。

---

## Phase 4: スコープ外Issueの起票

「スコープ」とはIssueの**意図**であって plan.md の行ではない。同じファイル・同じ機能・同じ動線の中で気づいた問題は、原則としてその場で修正する（Phase 2/3 に戻る）。Issue起票するのは、別ドメインへの波及・追加で数時間以上かかる規模・元Issueの意図外の新機能要望、のように切り出すほうが明らかに自然なものだけ。

起票する場合は `gh issue list --search "{キーワード}"` で重複確認してから `gh issue create`。起票がなければそのまま完了報告へ。

---

## 完了報告

すべてのフェーズが完了したら、サマリーを出す。

```
Issue #{Issue番号} の実装が完了しました！

## 計画
- 計画ファイル: .issue/{Issue番号}/plan.md
- 設計判断: .issue/{Issue番号}/adr.md（{あり/なし}）
- 動作確認計画: .issue/{Issue番号}/testing.md
- 残存課題: .issue/{Issue番号}/progress.md（{あり/なし}）

## 実装
- ブランチ: issue/{Issue番号}/{短い説明}
- PR: #{PR番号}
- コミット数: {数}

## ブラウザ検証
- 成果物: .issue/{Issue番号}/manual-test/（またはスキップ）
- テストケース: {数}件（PASS: {数} / FAIL: {数}）
- 起票したIssue: {Issue一覧、またはなし}

## レビュー
- レビューラウンド: {数}回
- 初回ブロッカー: {数}件
- 修正済み: {数}件
- 最終ステータス: APPROVED
- レビューファイル: .issue/{Issue番号}/review/review-001.md 〜 review-{NNN}.md

## スコープ外Issue
- {起票したIssue一覧、またはなし}
```

---

## 原則

- Issueの**意図**を満たすことに集中する。plan.md は手段。意図に沿う小さな修正は plan.md 外でもスコープ内
- 同じファイル・機能・動線の問題はその場で直す。Issue起票は切り出すほうが自然なときだけ
- manual-test は原則実行。スキップは Phase 2 の条件を実際に確認したときのみ
- 実装中の非自明な設計判断は adr.md、未完了は progress.md に記録する
- 委譲方式・並列実行・失敗時の扱いは `../_shared/references/subagent-policy.md` に従う
