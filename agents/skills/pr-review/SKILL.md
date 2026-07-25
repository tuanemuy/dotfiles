---
name: pr-review
description: "Structured multi-layer PR review with iterative improvement loop. Use this skill whenever the user asks to review a pull request, do code review, check a PR, or wants feedback on changes in a GitHub PR. Also trigger when the user mentions \"PR review\", \"review this PR\", \"code review PR #123\", or gives a GitHub PR URL. Even casual phrasing like \"this PR大丈夫？\" or \"PRチェックして\" should trigger this skill."
---

# PR Review Skill

Structured, multi-layer code review for GitHub Pull Requests. Each review round uses parallel subagents when available to examine the PR through different architectural lenses, compiles findings into a numbered Markdown file, then iteratively fixes issues until the code is clean.

## Workflow Overview

```
PR取得 → レイヤー分析 → 並列レビュー → review-NNN.md作成
  → 指摘を台帳（triage.md）で仕分け → fix を修正 → 再レビュー（次の連番ファイル）
  → fix と仕分けた指摘が0件のラウンドで完了（最大10ラウンド）
  → 設計判断があれば ADR（.thread/{PR番号}/adr.md）に追記
  → 記録基準を満たす ADR を .adr/ に昇格 → レビューディレクトリ（.thread/{PR番号}/review/）を削除
```

レビューループの共通構造（出力フォーマット・指摘台帳・修正ループ・完了条件）は `_shared/references/review-loop.md` を参照。

## Step 1: PR の取得と分析

PR番号またはURLを受け取ったら、まず全体像を把握する。

```bash
gh pr view <PR> --json title,body,baseRefName,headRefName,files
gh pr diff <PR>
```

差分の内容から、このPRに関連するレイヤーを判定する。

## Step 2: レイヤーの判定

変更されたファイルのパスと内容から、レビューすべきレイヤーを自動判定する。以下はよくあるレイヤーの例だが、プロジェクトの構造に合わせて柔軟に決める。

**クリーンアーキテクチャ系:**
- **Domain** — エンティティ、値オブジェクト、ドメインルール
- **Use Case** — アプリケーションロジック、ユースケースの責務
- **Interface Adapter** — コントローラー、プレゼンター、ゲートウェイ
- **Infrastructure** — DB、外部API、フレームワーク固有コード

**横断的関心事:**
- **Test** — テストの網羅性、テスト設計、モック戦略
- **Frontend** — コンポーネント設計、状態管理、UX。加えてビューとロジックの切り分けと状態のモデル化: 外部データが境界でデコードされてドメイン型に変換されているか、状態が直和型・直積型で組まれ不正な組み合わせが型で排除されているか（内部の `if (!x) throw` や非nullアサーションはモデルが不正状態を許すシグナル。境界での検証は正当）、ビジネスロジックがフレームワーク非依存の純粋関数か、状態遷移がステートマシンとして明示されているか、副作用が最外殻に隔離され view が state => UI の純粋関数に保たれているか
- **Security** — 認証・認可、入力バリデーション、機密情報
- **Performance** — N+1、不要な計算、メモリ効率

変更がないレイヤーはスキップしてOK。少なくとも2つ、多くても5つ程度に絞る。

## Step 3: サブエージェントで並列レビュー

判定したレイヤーごとに、サブエージェントを並列に起動する（委譲方式は `_shared/references/subagent-policy.md` に従う）。

各サブエージェントには以下を渡す:

```
あなたは「{レイヤー名}」の観点でPRをレビューする専門家です。

## レビュー対象
- PR: {PR番号}
- リポジトリ: {リポジトリパス}

## やること
1. `gh pr diff {PR番号}` で差分を取得
2. 必要に応じて関連ファイルを読む
3. 「{レイヤー名}」の観点で厳しくレビュー

## 出力フォーマット
以下のフォーマットで結果を返して:

### {レイヤー名}

#### Blockers
- **[B-001]** 問題の説明
  - 場所: `ファイルパス:行番号`
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

すべてのサブエージェントが完了したら、結果を1つの連番Markdownファイルにまとめる。

ファイルの保存先: `.thread/{PR番号}/review/` ディレクトリに保存する。なければ作成する。

ファイル名: `review-NNN.md`（NNNは001から始まる3桁の連番）

```markdown
# PR Review #NNN — {PRタイトル}

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

基本方針: **Blocker・Warning問わず、できる限りすべてその場で修正する。** 後回しは最終手段。

review-NNN.md に指摘がある場合:

1. すべての Blocker・Warning を指摘台帳 `.thread/{PR番号}/review/triage.md` と突き合わせる（フォーマットは共通ガイドの「指摘台帳」参照）。Key が一致する既出指摘は判定を継承して再指摘カウントを +1 し、再審議しない
2. 新規の指摘を「このPRで直す（fix）」「対応しない（wont-fix）」「後回し（defer）」に仕分けて台帳に記録する
   - **wont-fix** — 誤った指摘、過度に防御的な提案、場当たり的に直すより設計を見直すべき指摘。一行理由を台帳に書く
   - **defer** — どうしてもこのPRのスコープでは対応できない場合のみ。`gh issue create` で別Issueを起票し、Issue番号を台帳に記録する
3. **fix は Blocker から着手し、続けて Warning もすべて修正する** — Warning も放置せず潰す
4. 修正が終わったら、Step 3に戻って再レビュー（次の連番ファイルを作る）

## Step 6: ADR への追記

レビュー中に**プロダクトとしての重要な設計判断**を下した場合（例: 特定のパターンを採用した理由、ライブラリの選定理由など）、`.thread/{PR番号}/adr.md` に追記する。指摘への対応要否（wont-fix / defer）の記録には使わない — それは台帳の役割。仕分けが設計判断を伴う場合のみ ADR に起こし、台帳の理由欄からリンクする。adr.md は作業ログで、ルート `.adr/` への昇格判定は Step 8 でまとめて行う（基準は `_shared/references/adr-guide.md`）。

1. `.thread/{PR番号}/adr.md` が存在するか確認する
2. なければ新規作成し、以下のヘッダーを書く
3. あれば末尾に追記する

ファイルフォーマット:
```markdown
# ADR — PR #{PR番号}: {PRタイトル}

## ADR-001: {タイトル}

### Status
Proposed

### Context
{なぜこの判断が必要になったか}

### Decision
{何を決めたか}

### Consequences
{この判断の結果として何が起きるか}

---

## ADR-002: {タイトル}
...
```

1つのファイルにPRに関連するすべての設計判断を連番で追記していく。

## Step 7: 完了判定

完了条件は共通ガイドの通り「**そのラウンドで `fix` と仕分けた指摘がゼロ**」（台帳に `wont-fix` / `defer` を記録済みの指摘は件数から除外）。

**最大ラウンド数: 10回。** 10ラウンドに達しても収束しない場合は強制終了し、残っている指摘を最終レビューファイルにまとめてユーザーに判断を委ねる。

例:
- review-001.md → Blocker 3件, Warning 5件 → 全部 fix → 再レビュー
- review-002.md → Warning 2件 → 1件 fix、1件は wont-fix を台帳に記録 → 再レビュー
- review-003.md → Warning 1件 → 既出（Key 一致）で判定継承、fix 0件 → 完了！

## Step 8: ADR の昇格とレビューファイルの削除

### ADR の昇格

`.thread/{PR番号}/adr.md` が存在すれば、各エントリを `_shared/references/adr-guide.md` の記録基準（寿命テスト・波及テスト）にかけ、満たすものだけをプロジェクトルートの `.adr/NNN-title.md` に転記する（既存の連番の続き。ディレクトリがなければ新設する）。転記したエントリには adr.md 側に「→ `.adr/NNN` に昇格」と一行追記する。基準を満たさないエントリは作業履歴としてそのまま残す。

### レビューファイルの削除

APPROVED で完了したら、レビューの中間成果物を片付ける。指摘はすべてコードに反映済みか台帳の判定として決着しているため、レビューファイルを残す必要はない。

```bash
rm -rf .thread/{PR番号}/review/
```

- **削除するのは `review/` ディレクトリだけ。** `.thread/{PR番号}/adr.md` は残す（設計判断の記録なので消さない）。
- **10ラウンドに達して APPROVED に至らなかった場合は削除しない。** 残っている指摘をユーザーが確認する必要があるため、レビューファイルと台帳をそのまま残す。
- 削除前に、defer で起票した Issue 番号がすべて完了サマリーに載っていることを確認する（台帳が消えても追跡先が残るように）。
- 削除前に台帳の `wont-fix` 行を確認し、「指摘は正しいが意図的に逸脱している」ものは現場の why not コメントか ADR に転記する（`_shared/references/review-loop.md` の後片付けに従う）。

削除が済んだら完了サマリーを出す:

```
PR Review 完了！

全{N}ラウンドのレビューを実施しました。
- 初回ブロッカー: {数}件
- 修正済み: {数}件
- 見送り: wont-fix {数}件 / defer {数}件
- 最終ステータス: APPROVED
- ADR追加: {あれば .thread/{PR番号}/adr.md に記載}
- ADR昇格: {.adr/NNN-... x{数} / 昇格対象なし}
- 別Issue: {起票したIssue番号のリスト}
- レビューファイル: 削除済み（.thread/{PR番号}/review/）
```

## 重要な注意点

- 委譲方式・並列実行・失敗時の扱いは `_shared/references/subagent-policy.md` に従う
- レビューは**厳しく**行う。「まあいいか」は禁止。ただし誤検知は避ける
- 修正するのは自分が確信を持てるものだけ。判断に迷うものはユーザーに聞く
- **修正が基本**。defer は「このPRのスコープ外」と明確に判断できるときだけ。見送り（wont-fix / defer）は必ず台帳に記録し、defer は別Issueも起票する
- レビューファイルは追記ではなく、毎ラウンド新規作成（ループ中は履歴として参照する）。完了後は Step 8 でまとめて削除する
- ADRはプロダクトの設計判断のみ。指摘への対応要否や些細な実装詳細はADRにしない
