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
  → docs/plans/{Issue番号}/plan.md, testing.md, (adr.md) を作成

Phase 2: 実装
  ブランチ作成 → plan.md に沿って実装 → 必要なテストを追加 → コミット → PR作成

Phase 3: レビュー・修正
  → 指摘修正 → 再レビュー（2回連続クリーンで完了、最大10ラウンド）

Phase 4: スコープ外タスクの報告
  → 全フェーズで見送ったスコープ外の改善・課題を完了報告にまとめる
```

---

## Phase 1: 計画

`../issue-planner/SKILL.md` を読み、その手順に従って計画を立てる。

計画が完了したら（plan.md, testing.md, 必要に応じて adr.md が作成されたら）Phase 2 に進む。

---

## Phase 2: 実装

`references/implementation-guide.md` を読み、その手順に従って実装する。

実装中に下した非自明な設計判断は `docs/plans/{Issue番号}/adr.md` に追記する。
実装完了後、残存課題があれば `docs/plans/{Issue番号}/progress.md` に詳細を記録する。

---

## Phase 3: レビュー・修正

`references/review-guide.md` を読み、その手順に従ってレビュー・修正を行う。

レビューの成果物は `docs/plans/{Issue番号}/review/` に保存し、ADR は `docs/plans/{Issue番号}/adr.md` に追記する。

---

## Phase 4: スコープ外タスクの報告

全フェーズを通じて「スコープ外」と判断して見送った改善点・課題があれば、完了報告にまとめる（Issueの起票はしない）。

報告対象:
- Phase 1 の計画時にスコープ外とした項目
- Phase 2 の実装中に気づいた課題
- Phase 3 のレビューで指摘されたがこのPRでは対応しないと判断したもの

該当なしであればそのまま完了報告に進む。

---

## 完了報告

すべてのフェーズが完了したら、サマリーを出す。

```
Issue #{Issue番号} の実装が完了しました！

## 計画
- 計画ファイル: docs/plans/{Issue番号}/plan.md
- 設計判断: docs/plans/{Issue番号}/adr.md（{あり/なし}）
- 動作確認計画: docs/plans/{Issue番号}/testing.md
- 残存課題: docs/plans/{Issue番号}/progress.md（{あり/なし}）

## 実装
- ブランチ: feature/issue-{Issue番号}
- PR: #{PR番号}
- コミット数: {数}

## テスト
- テストファイル: {作成したテストファイルのパス、またはなし}
- 結果: 全PASS / {詳細}

## レビュー
- レビューラウンド: {数}回
- 初回ブロッカー: {数}件
- 修正済み: {数}件
- 最終ステータス: APPROVED
- レビューファイル: docs/plans/{Issue番号}/review/review-001.md 〜 review-{NNN}.md

## スコープ外タスク
- {見送った改善点・課題の一覧、またはなし}
```

---

## 原則

- Issueの要件を満たすことに集中する — スコープ外の改善を含めない
- plan.md の指示に忠実に実装する
- 実装中の非自明な設計判断は adr.md に記録する
- 完了できなかった項目や既知の制限は progress.md に明記する — 暗黙的に省略しない
- コンポーネントのテストは不要。既存のテスト体系に明確な必然性がない限り追加しない
- 委譲方式・並列実行・失敗時の扱いは `../_shared/references/subagent-policy.md` に従う
- エージェントが失敗・タイムアウトした場合は、成功した結果だけで柔軟に進める
