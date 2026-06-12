# Phase 3: PRレビュー・修正ガイド

Phase 2 で作成した PR に対して、セルフレビュー・修正を繰り返し品質を担保する。レビューループの共通構造（出力フォーマット・修正ループ）は `../../_shared/references/review-loop.md` を参照。ただし**完了条件は本ガイドの Step 7 で上書き**する（共通側の「2連続クリーン」ではなく「1ラウンドクリーンで完了」を採用）。

> **このレビューは Polish / 実装中の品質チェックとは別物。** `tasks.md` の Polish フェーズや Phase 2 の品質チェック（`code-reviewer` / `typescript-reviewer` / `log-compliance-checker` 等による lint・型・カバレッジ・ログ規約の確認）は実装の技術的健全性を見るもので、本 Phase 3 の代替にはならない。本 Phase 3 は PR 作成後に、spec.md の意図充足と plan/contracts/data-model/constitution 整合を**レイヤー観点**で検証し、Blocker 0 かつ Warning 0 を実測するまで修正ループを回す独立工程である。Polish が完了済みでも本工程は必ず実行する。

## 出力先

すべての成果物は `{FEATURE_DIR}` 配下に保存する。

- レビューファイル: `{FEATURE_DIR}/review/pr-review-{NNN}.md`（NNN は 001 から開始）
- ADR: `{FEATURE_DIR}/adr.md`（既存ファイルに追記）

## Step 1: PR の取得と分析

```bash
gh pr view <PR番号> --json title,body,baseRefName,headRefName,files
gh pr diff <PR番号>
```

差分の内容から、レビューすべきレイヤーを判定する。

## Step 2: レイヤーの判定

まず `{FEATURE_DIR}/plan.md` の **Technical Context** と **Project Structure** を読む。spec-kit の Project Structure は単一プロジェクト / Web（frontend + backend）/ モバイル+API の 3 パターンがあり、それぞれでレイヤー構成が異なる。

### 必須観点（バックエンド/ドメイン層に変更がある場合は常に含める）

差分にドメイン層・ユースケース層・アダプター層などサーバーサイドのロジックが含まれる場合、変更規模にかかわらず以下の 2 観点を**必ず**レビュー対象に入れる。変更規模の都合で他のレイヤーを削るときも、この 2 つは最後まで残す。

- **Domain Model 妥当性** — ドメインモデルが適切か。エンティティ・値オブジェクト・集約の境界が業務概念と一致しているか、`data-model.md` と整合しているか、ドメインの不変条件（invariant）がモデル内に閉じているか、貧血ドメインモデル（ロジックがユースケース側に漏れている）になっていないか
- **Layer Boundary 妥当性** — レイヤー境界が適切か。依存方向が内向き（ドメイン ← ユースケース ← アダプター）を保っているか、ドメイン層がフレームワーク・DB・外部 API に依存していないか、ユースケース層にインフラ詳細やプレゼンテーション関心が漏れていないか、ポート/インターフェースを跨ぐ責務配置が `plan.md` の Project Structure と一致しているか

純粋なフロントエンドのみ・設定/ドキュメントのみの変更で、サーバーサイドのドメインロジックに一切触れない場合はこの 2 観点を省略してよい。

### 変更規模の判定

- **小規模**（変更が 1〜2 ファイル、または完全に 1 タスク内に閉じている） → レイヤー分割せず **「General Review」1 本**で実施する。サブエージェントは 1 つだけ起動し、変更全体を一気に見させる。ただしその変更がドメイン層を含む場合は、General Review のサブエージェントに上記の必須 2 観点（Domain Model 妥当性・Layer Boundary 妥当性）を明示的にチェックさせる
- **中〜大規模** → 以下の通りレイヤーを判定する（必須 2 観点は独立したレビュー観点として常に起動する）

変更されたファイルのパスと内容、`tasks.md` のタスク分類から、レビューすべきレイヤーを自動判定する。以下はよくあるレイヤーの例だが、`plan.md` の Project Structure とプロジェクトの実態に合わせて柔軟に決める。

**バックエンド系:**
- **Domain Model 妥当性**（必須）— 上記参照
- **Layer Boundary 妥当性**（必須）— 上記参照
- **Contracts/API** — `contracts/` 配下のスキーマと実装の整合性、API レスポンス・エラーケース
- **Use Case / Application** — ユースケースロジック、ストーリー単位の責務分離
- **Infrastructure / Adapter** — DB、外部API、フレームワーク固有コード
- **Security** — 認証・認可、入力バリデーション、機密情報の取り扱い

**フロントエンド系:**
- **Component / UI** — コンポーネント設計、状態管理、UX
- **API Integration** — フロントエンドからのバックエンド呼び出し、エラーハンドリング

**横断的:**
- **Test** — テストの網羅性、テスト設計、契約テストと統合テストの整合性
- **Performance** — N+1、不要な計算、メモリ効率

変更がないレイヤーはスキップしてOK。**変更規模に応じて 1〜5 レイヤー**に絞る（小さい変更は 1 レイヤーで十分、複数レイヤーをまたぐ変更は最大 5 つまで）。

## Step 3: サブエージェントでレビュー

判定したレイヤーごとに、サブエージェントを起動する（委譲方式は `../../_shared/references/subagent-policy.md` に従う）。

- レイヤーが **1 つの場合**（小規模変更等） → サブエージェント 1 つを単発実行する
- レイヤーが **2 つ以上の場合** → サブエージェントを並列に起動する

各サブエージェントには以下を渡す:

```
あなたは「{レイヤー名}」の観点でPRをレビューする専門家です。

## レビュー対象
- PR: {PR番号}
- リポジトリ: {リポジトリパス}
- フィーチャー: {FEATURE_DIR}
- spec.md: {FEATURE_DIR}/spec.md
- plan.md: {FEATURE_DIR}/plan.md
- tasks.md: {FEATURE_DIR}/tasks.md
- contracts: {FEATURE_DIR}/contracts/（存在すれば）
- data-model.md: {FEATURE_DIR}/data-model.md（存在すれば）
- constitution: .specify/memory/constitution.md（存在すれば）

## やること
1. プロジェクトルートの CLAUDE.md を読む
2. `gh pr diff {PR番号}` で差分を取得
3. {FEATURE_DIR}/spec.md（ユーザーストーリー / FR / SC / エッジケース）を読む
4. {FEATURE_DIR}/plan.md と関連設計ファイルを読み、設計との整合性も確認する
5. 必要に応じて関連ファイルを読む（差分が触れる周辺のコードも見る）
6. 「{レイヤー名}」の観点で厳しくレビュー

## レビュー観点（必ず含める）
- spec.md の関連 FR・SC を満たしているか（カバレッジ）
- plan.md / data-model.md / contracts/ との整合性
- Constitution（.specify/memory/constitution.md）違反がないか
- TDD 順序が崩れていないか（実装がテストより先に書かれていないか）
- 「{レイヤー名}」固有の品質観点（Domain Model 妥当性 / Layer Boundary 妥当性 を担当する場合は Step 2 の必須観点の定義に挙げた具体項目をすべて確認する）

## 出力フォーマット
以下のフォーマットで結果を返して:

### {レイヤー名}

#### Blockers
- **[B-001]** 問題の説明
  - 場所: `ファイルパス:行番号`
  - 関連: {spec.md の FR-xxx / plan.md のセクション / constitution の原則}
  - 理由: なぜこれが問題か
  - 提案: どう直すべきか

#### Warnings
- **[W-001]** 問題の説明
  - 場所: `ファイルパス:行番号`
  - 理由: なぜ気になるか
  - 提案: 改善案

#### Notes
- **[N-001]** 良い点や参考情報

BlockerがなければBlockersセクションに「なし」と書く。
厳しく見ること。妥協しない。でも的外れな指摘はしない。
```

## Step 4: レビューファイルの作成

すべてのサブエージェントが完了したら、結果を 1 つの連番 Markdown ファイルにまとめる。

保存先: `{FEATURE_DIR}/review/pr-review-{NNN}.md`（NNN は 001 から始まる 3 桁の連番）

```markdown
# PR Review #NNN — {PRタイトル}

**Feature:** {NNN-feature-name}
**PR:** #{PR番号}
**Date:** {日付}
**Round:** {N}回目

---

## Summary

- Blockers: {数}
- Warnings: {数}
- Notes: {数}
- Verdict: **BLOCKED** / **APPROVED**

---

{各レイヤーのレビュー結果をここに配置}

---

## Design Decisions

このラウンドで見つかった設計判断があればここに記載。
なければ「特になし」。
```

## Step 5: 指摘の修正

基本方針: **Blocker・Warning 問わず、できる限りすべてその場で修正する。** 後回しは最終手段。

`pr-review-{NNN}.md` に指摘がある場合:

1. レビューファイルを読み、すべての Blocker・Warning を確認する
2. **Blocker から着手し、続けて Warning もすべて修正する** — Warning も放置せず潰す
3. 後回し判断の前に `../SKILL.md` Phase 4 のスコープ基準を確認する。同じファイル・同じユーザーストーリーの中で完結する指摘や軽微な指摘は、ほぼ確実にその場で直す（軽微なほど即時修正コストが低い）
4. それでもこの PR で対応できないと判断した場合のみ後回しにする:
   - `{FEATURE_DIR}/adr.md` に判断理由を記録する
   - `gh issue create` で別 Issue を起票し、ADR と本フィーチャー（`{NNN-feature-name}`）へのリンクを含める
   - レビューファイルの該当指摘に `→ 別Issue #{新Issue番号} で対応` と追記する
5. 修正は spec-kit のフローと整合する形で行う:
   - **コードのみの修正** → 直接ファイルを編集してコミットする
   - **タスク追加が必要** → `tasks.md` に追加してから着手する（後続の追跡性のため）
   - **設計変更が必要** → `plan.md` を直し、必要なら `/speckit.analyze` を再実行する
6. 修正が終わったら、Step 3 に戻って再レビュー（次の連番ファイルを作る）

## Step 6: ADR への追記

レビュー中に重要な設計判断が見つかった場合、`{FEATURE_DIR}/adr.md` に追記する。

Phase 1（計画時）で既に adr.md が存在する場合は、既存の連番の続きから追記する。なければ新規作成する。

各決定ごとに以下の形式で記載:

```markdown
## ADR-{NNN}: {タイトル}

### Status
Proposed

### Context
{なぜこの判断が必要になったか}

### Decision
{何を決めたか}

### Consequences
{この判断の結果として何が起きるか}
```

ADR は本当に重要な設計判断のみ。些細な実装詳細は ADR にしない。

## Step 7: 完了判定

**Blocker 0件 かつ Warning 0件**になったらレビュー完了。1 ラウンドでクリーンならその時点で終了する（2 連続クリーンを待たない）。

**最大ラウンド数: 10 回。** 10 ラウンドに達しても収束しない場合は強制終了し、残っている指摘を最終レビューファイルにまとめてユーザーに判断を委ねる。

## 重要な注意点

- 委譲方式・並列実行・失敗時の扱いは `../../_shared/references/subagent-policy.md` に従う
- レビューは**厳しく**行う。「まあいいか」は禁止。ただし誤検知は避ける
- 修正するのは自分が確信を持てるものだけ。判断に迷うものはユーザーに聞く
- **修正が基本**。後回しにするのは「この PR のスコープ外」と明確に判断できるときだけ。後回し時は必ず ADR 記録＋別 Issue 起票する
- レビューファイルは追記ではなく、毎ラウンド新規作成（履歴が残る）
- **spec.md / plan.md / contracts / data-model / constitution との整合性をレビュー観点に必ず含める** — spec-kit の段階ゲートの強みを活かすため
- 修正で tasks.md / plan.md を直す場合は、整合性が崩れないか `/speckit.analyze` で確認する
