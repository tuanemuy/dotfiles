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
  ブランチ作成 → plan.md に沿って実装 → コミット → PR作成

Phase 3: レビュー・修正（pr-reviewに委譲）
  → 指摘修正 → 再レビュー（2回連続クリーンで完了、最大10ラウンド）

Phase 4: スコープ外Issueの起票
  → 全フェーズで見送ったスコープ外の改善・課題をIssueとして起票
```

---

## Phase 1: 計画

`../issue-planner/SKILL.md` を読み、その手順に従って計画を立てる。

計画が完了したら（plan.md, testing.md, 必要に応じて adr.md が作成されたら）Phase 2 に進む。

---

## Phase 2: 実装

`references/implementation-guide.md` を読み、その手順に従って実装する。

---

## Phase 3: レビュー・修正

Phase 2 で作成した PR に対して、`../pr-review/SKILL.md` を読み、その手順に従ってレビュー・修正を行う。

---

## Phase 4: スコープ外Issueの起票

全フェーズを通じて「スコープ外」と判断して見送った改善点・課題があれば、Issueとして起票する。

起票するもの:
- Phase 1 の計画時にスコープ外とした項目
- Phase 2 の実装中に気づいた課題
- Phase 3 のレビューで指摘されたがこのPRでは対応しないと判断したもの

起票前に `gh issue list --search "{キーワード}"` で既存Issueとの重複を確認する。重複がある場合は起票せず、既存Issueへのコメント追記で対応する。

起票がなければそのまま完了報告に進む。

---

## 完了報告

すべてのフェーズが完了したら、サマリーを出す。

```
Issue #{Issue番号} の実装が完了しました！

## 計画
- 計画ファイル: .issue/{Issue番号}/plan.md
- 設計判断: .issue/{Issue番号}/adr.md（{あり/なし}）
- 動作確認計画: .issue/{Issue番号}/testing.md

## 実装
- ブランチ: issue/{Issue番号}/{短い説明}
- PR: #{PR番号}
- コミット数: {数}

## レビュー
- レビューラウンド: {数}回
- 初回ブロッカー: {数}件
- 修正済み: {数}件
- 最終ステータス: APPROVED
- レビューファイル: .pr/{PR番号}/review/review-001.md 〜 review-{NNN}.md

## スコープ外Issue
- {起票したIssue一覧、またはなし}
```

---

## 原則

- Issueの要件を満たすことに集中する — スコープ外の改善を含めない
- plan.md の指示に忠実に実装する
- エージェントが失敗・タイムアウトした場合は、成功した結果だけで柔軟に進める
