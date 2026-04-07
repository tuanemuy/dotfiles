---
name: pr-review
description: >
  Structured multi-layer PR review with iterative improvement loop.
  Use this skill whenever the user asks to review a pull request, do code review,
  check a PR, or wants feedback on changes in a GitHub PR. Also trigger when the
  user mentions "PR review", "review this PR", "code review PR #123",
  or gives a GitHub PR URL. Even casual phrasing like "this PR大丈夫？"
  or "PRチェックして" should trigger this skill.
---

# PR Review Skill

Structured, multi-layer code review for GitHub Pull Requests. Each review round spawns parallel subagents that examine the PR through different architectural lenses, compiles findings into a numbered Markdown file, then iteratively fixes issues until the code is clean.

## Workflow Overview

```
PR取得 → レイヤー分析 → 並列レビュー → review-NNN.md作成
  → ブロッカーあり？ → コード修正 → 再レビュー（次の連番ファイル）
  → 2回連続ブロッカー・ワーニングなし → 完了（最大10ラウンド）
  → 設計判断があれば ADR に追記
```

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
- **Frontend** — コンポーネント設計、状態管理、UX
- **Security** — 認証・認可、入力バリデーション、機密情報
- **Performance** — N+1、不要な計算、メモリ効率

変更がないレイヤーはスキップしてOK。少なくとも2つ、多くても5つ程度に絞る。

## Step 3: サブエージェントで並列レビュー

判定したレイヤーごとに、サブエージェント（Agent tool, subagent_type="general-purpose"）を **並列に** 起動する。

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

ファイルの保存先: `.pr/{PR番号}/review/` ディレクトリに保存する。なければ作成する。

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

1. レビューファイルを読み、すべてのBlocker・Warningを確認する
2. **Blockerから着手し、続けてWarningもすべて修正する** — Warningも放置せず潰す
3. どうしてもこのPRのスコープでは対応できない場合のみ後回しにする:
   - `.pr/{PR番号}/adr.md` に判断理由を記録する（なぜ今やらないのか、どう対応すべきか）
   - `gh issue create` で別Issueを起票し、ADRへのリンクを含める
   - レビューファイルの該当指摘に `→ 別Issue #{新Issue番号} で対応` と追記する
4. 修正が終わったら、Step 3に戻って再レビュー（次の連番ファイルを作る）

## Step 6: ADR への追記

レビュー中に重要な設計判断が見つかった場合（例: 特定のパターンを採用した理由、ライブラリの選定理由など）、`.pr/{PR番号}/adr.md` に追記する。

1. `.pr/{PR番号}/adr.md` が存在するか確認する
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

**2回連続でBlocker 0件 かつ Warning 0件**になったらレビュー完了。

**最大ラウンド数: 10回。** 10ラウンドに達しても収束しない場合は強制終了し、残っている指摘を最終レビューファイルにまとめてユーザーに判断を委ねる。

例:
- review-001.md → Blocker 3件, Warning 5件 → 全部修正 → 再レビュー
- review-002.md → Blocker 0件, Warning 2件 → Warning修正 → 再レビュー
- review-003.md → Blocker 0件, Warning 0件 → もう1回レビュー
- review-004.md → Blocker 0件, Warning 0件 → 2回連続クリーン！完了！

完了時にサマリーを出す:
```
PR Review 完了！

全{N}ラウンドのレビューを実施しました。
- 初回ブロッカー: {数}件
- 修正済み: {数}件
- 後回し（別Issue起票）: {数}件
- 最終ステータス: APPROVED
- ADR追加: {あれば .pr/{PR番号}/adr.md に記載}
- 別Issue: {起票したIssue番号のリスト}
- レビューファイル: .pr/{PR番号}/review/review-001.md 〜 review-{NNN}.md
```

## 重要な注意点

- サブエージェントは**必ず並列で**起動する。直列だと遅すぎる
- レビューは**厳しく**行う。「まあいいか」は禁止。ただし誤検知は避ける
- 修正するのは自分が確信を持てるものだけ。判断に迷うものはユーザーに聞く
- **修正が基本**。後回しにするのは「このPRのスコープ外」と明確に判断できるときだけ。後回し時は必ずADR記録＋別Issue起票する
- レビューファイルは追記ではなく、毎ラウンド新規作成（履歴が残る）
- ADRは本当に重要な設計判断のみ。些細な実装詳細はADRにしない
