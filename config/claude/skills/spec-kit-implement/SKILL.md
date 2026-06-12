---
name: spec-kit-implement
description: >
  GitHub spec-kit で初期化された spec.md がある状態から、計画 → レビュー → タスク分解 → レビュー →
  実装 → PRレビュー・修正までを一気通貫で回すスキル。
  /speckit.plan, /speckit.tasks, /speckit.analyze, /speckit.implement をラップしつつ、
  計画段階とPR段階に多角レビューループを挿入し、Spec-Driven Development の品質を担保する。
  ユーザーが「spec-kit で実装して」「specs/001 を実装して」「/speckit でやって」
  「spec-driven で実装」「この spec を実装して」「spec.md から実装まで一気にやって」
  「spec-kit のプランから実装まで」「spec-kit-implement」「implement this spec」
  などと言ったときにトリガーする。
  specs/NNN-feature-name/spec.md が存在する状態で、計画・実装・レビューまでを依頼された場合に
  このスキルを使うこと。spec.md がまだない（要件定義から始める）場合は spec-kit の
  /speckit.specify を先に促す。
---

# Spec-Kit Implement — spec.md → 実装 → レビューの一気通貫スキル

GitHub spec-kit のスペックを起点に、`/speckit.plan` → 計画レビュー → `/speckit.tasks` → タスクレビュー → `/speckit.implement` → 検証 → PR → PRレビュー・修正の一連のフローを実行する。

spec-kit が定める段階ゲートを尊重しつつ、計画段階と実装後にレビューループを挟むことで、Spec-Driven Development の予測可能性と品質を両立させる。

## 前提条件

このスキルを使う前に、以下が満たされていること:

1. プロジェクトが spec-kit で初期化済み（`.specify/` と `specs/` が存在）
2. 対象フィーチャーの `specs/NNN-feature-name/spec.md` が存在
3. spec.md に `[NEEDS CLARIFICATION]` マーカーが残っていない（残っていれば `/speckit.clarify` を先に促す）
4. プロジェクトの `.specify/memory/constitution.md` が定義済み（推奨）

これらが満たされない場合は、まずユーザーに spec-kit の前段コマンドを実行するよう促し、本スキルでは進めない。

## Workflow Overview

```
Phase 0: フィーチャーの特定と前提確認
  → specs/NNN-feature-name/ を特定、spec.md 読込、前提充足チェック

Phase 1: 計画
  → /speckit.plan で plan.md / research.md / data-model.md / contracts/ を生成
  → 計画レビューループ（要件カバレッジ / アーキ・リスクの2視点並列、最大3周）
  → 設計判断があれば adr.md に記録
  → /speckit.tasks で tasks.md を生成
  → /speckit.analyze で spec ↔ plan ↔ tasks の整合性を検証
  → tasks レビュー（依存・並列性・テスト先行性、1周）

Phase 2: 実装
  → ブランチ確認 → /speckit.implement → quickstart.md による検証 → コミット → PR作成

Phase 3: PRレビュー・修正
  → レイヤー別並列レビュー → 指摘修正 → 再レビュー（最大10ラウンド）

Phase 4: スコープ外の起票
  → 全フェーズで見送ったスコープ外の改善・課題を Issue として起票
```

---

## Phase 0: フィーチャーの特定と前提確認

ユーザーが指定したフィーチャー（番号・名前・ディレクトリ）から対象を特定する。

1. 入力からフィーチャーディレクトリを解決する
   - 「001」「specs/001-...」「feature-name」のいずれの指定でも、`specs/` 配下を探して一意に特定する
   - 候補が複数ある・存在しない場合はユーザーに確認する
2. `specs/NNN-feature-name/spec.md` を読み、内容を把握する
3. **前提充足チェック**を実行する
   - `[NEEDS CLARIFICATION]` の残存有無を grep で確認
   - `.specify/memory/constitution.md` の存在を確認
   - 既存の `plan.md` / `tasks.md` がある場合は上書き or 継続をユーザーに確認
4. 残課題があれば該当の spec-kit コマンド（`/speckit.clarify` / `/speckit.constitution`）の実行を促し、本スキルは保留する

特定したフィーチャーディレクトリを `{FEATURE_DIR}` として後続フェーズで使う。

---

## Phase 1: 計画

`references/planning-guide.md` を読み、その手順に従って計画とタスク分解を進める。

このフェーズの責務:

- `/speckit.plan` の実行と生成物の検収
- 計画レビューループ（要件カバレッジ / アーキ・リスクの2視点並列、最大3周）
- `/speckit.tasks` の実行と `tasks.md` の検収
- `/speckit.analyze` で spec ↔ plan ↔ tasks の整合性検証
- tasks レビュー（依存・並列性・テスト先行性、1周）

計画段階で生じた非自明な設計判断は `{FEATURE_DIR}/adr.md` に記録する。`{FEATURE_DIR}/review/` 配下に計画レビューの履歴を残す。

---

## Phase 2: 実装

`references/implementation-guide.md` を読み、その手順に従って実装する。

このフェーズの責務:

- ブランチ確認（spec-kit が作成済みの `NNN-feature-name` ブランチを使う、未作成なら作成）
- `/speckit.implement` の実行と進行管理
- `quickstart.md` の検証シナリオの実行と結果記録
- 残存課題の `progress.md` への記録
- コミットと PR 作成

実装中に下した非自明な設計判断は `{FEATURE_DIR}/adr.md` に追記する。

---

## Phase 3: PRレビュー・修正

`references/review-guide.md` を読み、その手順に従って PR レビュー・修正を行う。

**Phase 3 は PR 作成後に必ず独立して実行する工程である。** `tasks.md` の Polish フェーズ（実装中の品質セルフチェック: lint / 型 / カバレッジ / ログ規約）や Phase 2 の品質チェックとは、目的・タイミング・観点・完了条件のすべてが異なる。Polish や Phase 2 のレビュー（`code-reviewer` / `typescript-reviewer` / `log-compliance-checker` 等）を実施したことをもって Phase 3 を代替・省略してはならない。Polish が通っていても、Phase 3 のレイヤー観点による多角レビューループは別途必ず回す。

このフェーズの責務:

- 変更レイヤーの判定と並列レビューの実行
- レビューファイルの作成（`{FEATURE_DIR}/review/pr-review-NNN.md`）
- Blocker / Warning の修正
- ADR への追記（PR レビュー中に重要な設計判断が見つかった場合）
- 完了判定（1ラウンドでクリーンなら完了、最大10ラウンド）

---

## Phase 4: スコープ外の起票

「スコープ」とは spec.md の**意図**であって plan.md / tasks.md の行ではない。同じファイル・同じユーザーストーリー・同じ動線の中で気づいた問題は、原則としてその場で修正する（Phase 1〜3 に戻る）。Issue 起票するのは、別フィーチャーへの波及・追加で数時間以上かかる規模・元 spec の意図外の新機能要望、のように切り出すほうが明らかに自然なものだけ。

起票する場合は `gh issue list --search "{キーワード}"` で重複確認してから `gh issue create` を実行し、`spec-kit feature: NNN-feature-name` のように起点を本文に明記する。起票がなければそのまま完了報告へ。

---

## 完了報告

すべてのフェーズが完了したら、サマリーを出す。

```
spec-kit フィーチャー「{NNN-feature-name}」の実装が完了しました！

## 計画
- 計画ファイル: {FEATURE_DIR}/plan.md
- タスクファイル: {FEATURE_DIR}/tasks.md
- 研究: {FEATURE_DIR}/research.md（{あり/なし}）
- データモデル: {FEATURE_DIR}/data-model.md（{あり/なし}）
- 契約: {FEATURE_DIR}/contracts/（{ファイル数}）
- 設計判断: {FEATURE_DIR}/adr.md（{あり/なし}）
- 計画レビュー: {FEATURE_DIR}/review/plan-review-001.md 〜（{N}周）
- タスクレビュー: {FEATURE_DIR}/review/tasks-review-001.md
- analyze 結果: {Pass / 修正済み}

## 実装
- ブランチ: {ブランチ名}
- PR: #{PR番号}
- コミット数: {数}
- 完了タスク: {完了数} / {全タスク数}
- 残存課題: {FEATURE_DIR}/progress.md（{あり/なし}）

## quickstart 検証
- 検証シナリオ: {数}件（PASS: {数} / FAIL: {数} / SKIP: {数}）
- 検証ログ: {FEATURE_DIR}/quickstart-results.md（あれば）

## PR レビュー
- レビューラウンド: {数}回
- 初回ブロッカー: {数}件
- 修正済み: {数}件
- 最終ステータス: APPROVED
- レビューファイル: {FEATURE_DIR}/review/pr-review-001.md 〜 pr-review-{NNN}.md

## スコープ外Issue
- {起票したIssue一覧、またはなし}
```

---

## 原則

- **spec.md の意図を満たすことに集中する。** plan/tasks は手段であって目的ではない。意図に沿う小さな修正は plan/tasks の行外でもスコープ内
- **spec-kit の段階ゲートを尊重する。** Constitution Check や `/speckit.analyze` の指摘は無視せず、Phase 1 のレビューループで取り込む
- **同じファイル・同じユーザーストーリーの問題はその場で直す。** Issue 起票は切り出すほうが自然なときだけ
- **quickstart.md は原則実行する。** spec-kit が定義した受け入れ検証手順なのでスキップしない
- 計画・実装中の非自明な設計判断は `adr.md` に、未完了は `progress.md` に記録する
- 委譲方式・並列実行・失敗時の扱いは `../_shared/references/subagent-policy.md` に従う
- エージェントが失敗・タイムアウトした場合は、成功した結果だけで柔軟に進める
- spec-kit のスラッシュコマンドが利用できない環境では、本スキルは保留してユーザーに環境セットアップを促す（自前で代替実装はしない）
