---
name: design-flow
description: >
  設計ドキュメント（spec/）をベースに、UIデザインを段階的に作成するスキル。
  代表画面の複数ドラフト提案からユーザーの方向性選択を経て、
  デザイントークンを定義し、全画面のHTMLデザインを作成・レビューする。
  spec スキルの成果物（spec/pages/index.md, spec/scenario/ 等）がある状態からの
  デザイン作業であれば積極的にこのスキルを使うこと。
  ユーザーが「デザインして」「UIデザイン作って」「画面デザインして」「デザイン提案して」
  「ドラフト見せて」「トークン定義して」「デザインシステム作って」
  「HTMLモックアップ作って」「ビジュアルデザインして」「見た目を作って」
  「モック作って」「プロトタイプ作って」「UI見せて」「デザインの続きやって」
  「design the UI」「create mockups」「design tokens」
  などと言ったときにトリガーする。
  spec/ ドキュメントを指して「これのデザインやって」のような間接的な依頼でもトリガーする。
  途中のフェーズから再開することも可能（既存の成果物を確認して続きから進める）。
  単発のUI作成は /frontend-design を直接使い、
  段階的なデザインワークフロー全体が必要な場合にこのスキルを使う。
---

# Design Flow

spec スキルの成果物（シナリオ、ページ設計など）をもとに、UIデザインを段階的に作成する。
ユーザーとの対話を通じて方向性を固め、デザイントークンで一貫性を担保しながら全画面のデザインを仕上げる。

## 前提条件

`agent-browser` CLIが必要。HTMLデザインのスクリーンショット取得・視覚的レビューに使用する。

```bash
agent-browser --version  # 確認
agent-browser install     # Chrome for Testingのセットアップ（初回のみ）
```

### 開始前のプロセスクリーンアップ

Skill ツールで `/agent-browser-cleanup` を呼び出す。別セッションで使用中でなければ残存プロセスをクリーンアップしてからデザイン作業を開始できる。

## なぜこの順序か

代表画面のドラフトを先に複数提案することで、抽象的な言葉だけでは伝わらないビジュアルの方向性を具体的にすり合わせられる。方向性が決まってからトークンを定義し、全画面に展開することで、手戻りと画面間の不整合を最小化できる。

## spec スキルとの関係

このスキルは spec スキルの **後工程** にあたる。spec スキルが出力する以下の成果物を入力として使う:

- `spec/index.md` — 設計全体のインデックス（進捗確認に使う）
- `spec/idea.md` — プロダクトの目的・ターゲット
- `spec/scenario/` — ユーザーシナリオ（体験の流れを理解するため）
- `spec/pages/index.md` — 画面一覧と各画面の目的・機能（デザイン対象の特定に使う）

design-flow の成果物は `spec/design/` 配下に出力し、完了時に `spec/index.md` を更新する。

## アーキテクチャ

```
メインエージェント（オーケストレーション）
  ├── /frontend-design（HTMLデザイン作成）
  ├── agent-browser（スクリーンショット取得・視覚的レビュー）
  └── /critique, /polish, /audit（レビュー）
```

メインエージェントは agent-browser を直接操作してもよいし、サブエージェントに委譲してもよい。
HTMLデザインファイルのスクリーンショット取得やビジュアル確認が主な用途。

## セッション管理

agent-browser の操作時は `--session` でセッションを分離する:

```bash
agent-browser --session design-draft open file:///path/to/draft.html
agent-browser --session design-review screenshot /tmp/design-screenshots/page.png
```

命名規則:
- `design-draft` — ドラフトのプレビュー・スクリーンショット
- `design-page-{画面名}` — 各画面デザインのプレビュー
- `design-review` — レビュー時の視覚的確認

## Workflow Overview

```
Phase 0: 準備
  spec/ の成果物確認・再開判定
  → 情報不足があればヒアリング（なければそのまま Phase 1 へ自走）

Phase 1: ドラフト提案
  代表画面を自動選定 → 5案のHTMLドラフトを /frontend-design で作成
  → agent-browser でスクリーンショットを取得
  → ユーザーに提示し、方向性を選択してもらう

Phase 2: デザイントークン・方針決定
  選択された方向性 → spec/design/tokens.md（トークン定義）
  → spec/design/index.md（デザイン方針）
  → そのまま Phase 3 へ自走

Phase 3: デザイン作成
  トークン・方針に基づき全画面のHTMLデザインを /frontend-design で作成
  → agent-browser でスクリーンショットを取得し視覚的に確認
  → spec/design/pages/*.html を生成

Phase 4: レビュー
  agent-browser で視覚的確認 → /critique → 修正 → /polish → /audit（アクセシビリティ）
  → クリーンになるまで繰り返す
```

途中のフェーズから再開する場合は、既存の成果物を確認して該当フェーズから開始する。

---

## Phase 0: 準備

`references/phase0-preparation.md` を読み、その手順に従う。

spec スキルの成果物（`spec/index.md`, `spec/pages/index.md`, `spec/scenario/` など）を読み込み、デザインに必要な情報を把握する。
既存のデザイン成果物がある場合は再開判定を行い、該当フェーズから開始する。
情報が十分であればユーザーに質問せず Phase 1 へ自走する。

成果物:
- デザイン対象の画面一覧と、ドラフト提案に使う代表画面の選定

---

## Phase 1: ドラフト提案

`references/phase1-drafts.md` を読み、その手順に従う。
このフェーズでは Skill ツールを使って `/frontend-design` でHTMLドラフトを作成する。

成果物:
- `spec/design/drafts/` — 代表画面の複数ドラフト（HTML）
- ユーザーによる方向性の選択

**このフェーズ完了後、ユーザーの選択を待つ。**

---

## Phase 2: デザイントークン・方針決定

`references/phase2-tokens.md` を読み、その手順に従う。

成果物:
- `spec/design/tokens.md` — デザイントークン定義
- `spec/design/index.md` — デザイン方針

---

## Phase 3: デザイン作成

`references/phase3-production.md` を読み、その手順に従う。
このフェーズでは Skill ツールを使って `/frontend-design` でHTMLデザインを作成する。

成果物:
- `spec/design/pages/*.html` — 全画面のHTMLデザイン（ブラウザで確認可能）

---

## Phase 4: レビュー

`references/phase4-review.md` を読み、その手順に従う。
複数のデザインスキルを使って段階的にレビュー・改善する。

成果物:
- `spec/design/review/${連番}.md` — レビュー記録
- 修正済みの `spec/design/pages/*.html`

---

## レビューの原則

- `spec/design/review/` 配下に連番ファイル（`001.md`, `002.md`, ...）で記録する
- 対応が必要な問題点のみ記載する
- 問題がなくなるまでレビュー → 修正を繰り返す

---

## 完了報告

すべてのフェーズが完了したら:

1. `spec/index.md` にデザインフェーズの成果物と完了ステータスを追記する
2. 成果物のサマリーを出す

```
デザインが完了しました！

## 成果物

### デザイン方針・トークン
- spec/design/index.md
- spec/design/tokens.md

### ドラフト
- spec/design/drafts/ ({実際のファイル数} 案)

### デザイン
- spec/design/pages/ ({実際のファイル数} 画面)

### レビュー記録
- spec/design/review/ ({実際のファイル数} ラウンド)
```
