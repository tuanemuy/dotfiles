---
name: issue-implement
description: "Issueの計画立案 → 実装 → PRレビュー・修正 → ブラウザ検証 → コメント整理を一気通貫で行うスキル。ユーザーが「Issue #123 を実装して」「#45 をやって」「このIssue対応して」「implement #123」「計画から実装までやって」などと言ったとき、または Issue 番号・URL とともに実装まで求める依頼があったときにトリガーする。計画だけなら issue-planner、spec/ ベースの全体実装は implement を使う。"
---

# Issue Implement

## Workflow Overview

```text
Phase 1: 計画（issue-plannerに委譲）
  → .thread/{Issue番号}/plan.md, steps.md, testing.md, (adr.md) を作成

Phase 1.5: デザイン作成（条件付き — フロントエンドのUI画面を新設・変更する場合のみ）
  steps.md の UI セクションから gate 判定 → 既存コードからデザイン言語を抽出（ドラフト提案なし）
  → spec/design/pages/*.html を作成 → レビュー（UI画面の新設・変更がなければスキップ）

Phase 2: 実装
  ブランチ作成 → steps.md に沿って実装 → コミット → **Draft PR 作成**

Phase 3: レビュー・修正
  → 指摘修正 → 再レビュー（1ラウンドでクリーンなら完了、最大10ラウンド）→ APPROVED（PR は **Draft のまま**）

Phase 4: ブラウザ検証
  manual-test スキルで検証（シードデータ準備・サーバー起動含む）
  → 変更起因の FAIL があれば修正 → Phase 3 の再レビュー → APPROVED 後に再検証（検証サイクル最大3周）
  → 全PASS（または見送り記録済みの FAIL のみ）で **Ready for review に切替**

Phase 5: スコープ外Issueの起票
  → 全フェーズで見送ったスコープ外の改善・課題をIssueとして起票

Phase 6: コメント整理
  → ブランチの変更ファイル全体を comment-cleanup で整理 → コミット → push

Phase 7: ダッシュボード更新
  → ダッシュボード Issue があれば該当行だけ差分更新（この Issue の (In Progress) と新規起票の挿入のみ）

Phase 8: ADR の昇格とレビューファイルの削除
  → adr.md の各エントリを記録基準にかけ、満たすものを .adr/ に昇格
  → APPROVED で完了していれば .thread/{Issue番号}/review/ を削除（plan.md・adr.md 等は残す）
```

計画ファイルは役割で分かれている（詳細は `../issue-planner/references/plan-template.md`）。フェーズごとに必要なものだけを読む:

| ファイル | 役割 | 読むフェーズ |
| --- | --- | --- |
| `plan.md` | 契約 — 目的 / 受け入れ基準 / スコープ / リスク / テスト方針 | 全フェーズ |
| `steps.md` | 手順 — 設計 / 実装ステップ | Phase 1.5・2（Phase 3 は任意） |
| `adr.md` | 設計判断 | Phase 8 で昇格判定 |

## Phase 1: 計画

`../issue-planner/SKILL.md` を読み、その手順に従って計画を立てる。

計画が完了したら（plan.md, steps.md, testing.md, 必要に応じて adr.md が作成されたら）、次のフェーズに進む前に testing.md の「確認環境」セクションを検証する。具体的には:

1. testing.md の「実行手順」を読む
2. そこに書かれた各コマンドが CLAUDE.md・README.md・package.json の scripts（全項目）に実在するか、実際にファイルを読んで確認する
3. 変更箇所を実際に触れる状態にするまでに必要な手順が testing.md に揃っているかを確認する。曖昧な逃げ文句（例: 「手動で対応してください」「環境に応じて実行してください」）があれば、該当する正しいコマンドをプロジェクトのドキュメントから確認して置き換える
4. 実在しないコマンドがあれば削除または正しいコマンドに修正する
5. プロジェクト全体のセットアップ手順が含まれていたら削除し、Issue の変更を確認するのに必要なコマンドだけに絞る

検証が済んだら Phase 1.5 に進む。

## Phase 1.5: デザイン作成（条件付き）

Issue が**ユーザーに見える UI 画面を新設・変更する**場合だけ、実装に入る前に新しい画面の HTML モックを作る。

`references/design-guide.md` を読み、その手順に従う。要点:

- まず `.thread/{Issue番号}/steps.md` の「UI / プレゼンテーション」から gate 判定する。新規UI画面の追加・既存画面のレイアウト変更がなければ（バックエンド/API/ロジックのみ、軽微な調整など）、判定理由を一言ログに残してそのまま Phase 2 へスキップする。
- 実行する場合、デザインの方向性は**既存実装から抽出する**（ドラフト提案・新規トークン定義はしない）。新規画面が出荷済みのアプリに自然に馴染むことがゴール。
- 成果物は `spec/design/` 配下に出力し、Phase 2 のコミットに含めて実装と一緒に PR へ載せる。

## Phase 2: 実装

`references/implementation-guide.md` を読み、その手順に従って実装する。

実装中に下した非自明な設計判断は `.thread/{Issue番号}/adr.md` に追記する。
実装完了後、残存課題があれば `.thread/{Issue番号}/progress.md` に詳細を記録する。

## Phase 3: レビュー・修正

`references/review-guide.md` を読み、その手順に従ってレビュー・修正を行う。

レビューの成果物は `.thread/{Issue番号}/review/` に保存し、ADR は `.thread/{Issue番号}/adr.md` に追記する。レビューファイルはこの時点では削除しない — Phase 4 のブラウザ検証からこのループに戻る可能性があるため、片付けは Phase 8 でまとめて行う。

APPROVED になっても PR は Draft のまま維持し、Phase 4 のブラウザ検証に進む。Ready for review への切り替えは Phase 4 の通過後に行う。10ラウンドに達して APPROVED に至らなかった場合は Draft のまま残してユーザーに判断を委ね、Phase 4 には進まず Phase 5 へ進む。

## Phase 4: ブラウザ検証

レビュー済みの最終形に近いコードに対して、`../manual-test/SKILL.md` の手順に従ってブラウザ検証を実行する。検証環境の起動・シードデータの準備も manual-test に委ねる。Phase 3 の修正がすべてコミット・push 済みであることを確認してから始める。

manual-test に渡す情報:

- テストソース: `.thread/{Issue番号}/testing.md`
- 成果物ディレクトリ: `.thread/{Issue番号}/manual-test/`
- Issue番号: #{Issue番号}

**スキップは原則しない。** 以下のいずれかを実際に確認した場合のみスキップ可:

- Web UIなし（`package.json` の dev/start 系欠如、UIファイル不在を確認）
- testing.md に画面操作項目が1件もない（実際に読んで確認）
- `agent-browser --version` がエラー

スキップする場合は PR の Test plan に「スキップ理由: {確認した内容}」を一行で記載する。「該当しそう」での自己判断は不可。

### 結果の処理

- **変更起因の FAIL** — サブエージェント（**判断区分**）に委譲して修正し（委譲方式とモデル選択は `../_shared/references/subagent-policy.md` に従う）、コミット・push してから Phase 3 のレビューループに戻る（レビューファイルの連番は続きから）。APPROVED 後にブラウザ検証を再実行する。再検証は FAIL したケースと修正の影響範囲に絞ったスコープ再実行でよい
- **変更と無関係の FAIL** — manual-test の手順に従って Issue を起票し、検証としてはそのまま続行する。このような FAIL だけが残った状態は通過扱い
- **検証サイクルの上限: 3周。**「修正 → 再レビュー → 再検証」を3周しても通過しない場合は強制終了し、残っている FAIL をまとめてユーザーに判断を委ねる（PR は Draft のまま）

### PR の更新と Ready for review への切り替え

検証を通過したら:

1. PR 本文に「## Browser Verification」セクションを追記する（実行結果サマリー — 全PASS / 見送り記録済みFAILの内訳 / スキップ理由、起票した Issue 番号）。`gh pr view <PR番号> --json body` で現在の本文を取得し、追記した本文を一時ファイルに書き出して `gh pr edit <PR番号> --body-file <一時ファイル>` で反映する
2. `gh pr ready <PR番号>` で Ready for review に切り替える

## Phase 5: スコープ外Issueの起票

実装中・レビューで気づいた、本筋（元Issue）の外にある改善・課題を扱う。本筋の勢いを止めないための整理であって、Issueを量産・細分化する場ではない。

- **簡単なものは起票しない。** 数分で直せるもの、同じファイル・機能・動線の些細な問題は、その場で直す（Phase 2〜4 に戻る）。「念のためIssue」はトラッカーを散らかすだけ。
- **割らずにまとめる。** 同じテーマ・原因の気づきは1本に束ねる。スコープの境界を厳密に引くより、まとめて次へ進む。
- **既存へのマージを優先。** `gh issue list --search "{キーワード}"` で関連を探し、近ければコメントで追記。独立した新規だけ `gh issue create` する。

起票・追記がなければそのまま Phase 6 へ。

## Phase 6: コメント整理

`../comment-cleanup/SKILL.md` を読み、その手順に従ってこのブランチで触れたコードのコメントを整理する。

この時点では Phase 2〜4 の変更がすべてコミット済みなので、comment-cleanup がデフォルトで見る `git diff`（未コミット分）は空になる。対象は「このブランチがベースブランチに対して加えた変更」全体なので、変更ファイルを明示的に渡す：

1. PR のベースブランチ（通常 `main`）を特定する。
2. `git diff {ベースブランチ}...HEAD --name-only` で変更されたファイル一覧を取得する。
3. その一覧を comment-cleanup の `target` として渡し、各ファイルのコメントを整理する。
4. コメントが変更されたら `chore: コメントを整理` のような単一コミットにまとめて push し、PR を更新する。変更がなければコミットせずスキップする。

レビュー承認後の追加変更になるので、差分はコメントの増減のみに限定する。

## Phase 7: ダッシュボード更新

このリポジトリで Issue ダッシュボードを運用していれば、その全体像を最新化する。ダッシュボードは `Issue Dashboard` というタイトルの GitHub Issue として管理されている。

- **ダッシュボード Issue が存在するときだけ実行する。** 次のコマンドで探し、見つからなければダッシュボード運用をしていないということなので、勝手に新規作成せずスキップする。

  ```bash
  gh issue list --state open --search "Issue Dashboard in:title" --json number,title,body
  ```

  同名タイトルの誤検出を避けるため、本文先頭に `<!-- issue-dashboard -->` マーカーがあるかで最終確認する。
- **issue-dashboard スキルのフル更新は行わない。** 全 Issue・全 PR の再取得や再分析はせず、検出時に取得済みの本文に対して**この実行に関係する行だけ**を直接編集する:
  1. **この Issue の行**に `(In Progress)` を付ける（既に付いていればそのまま。本文に行が無ければ、内容に合う既存セクションに `- #番号 タイトル (In Progress)` の1行を挿入する）。
  2. **この実行で新たに起票した Issue**（Phase 3 の後回し・Phase 4 のブラウザ検証・Phase 5 のスコープ外起票）があれば、それぞれ内容に合う既存セクション（無ければ「その他」）に1行ずつ挿入する。依存先が自明な場合（この Issue から派生した等）のみサブリストを付ける。
  3. それ以外の行・セクション構成・並び順には**一切手を入れない**（フル整理は issue-dashboard スキルを明示的に呼んだときだけ）。
- 編集後の本文を一時ファイルに書き出し、`gh issue edit <ダッシュボード番号> --body-file <一時ファイル>` で反映する。
- 更新対象はダッシュボード Issue 本文だけで、実装ブランチや PR には一切影響しない。

## Phase 8: ADR の昇格とレビューファイルの削除

### ADR の昇格

`.thread/{Issue番号}/adr.md` が存在すれば、各エントリを `../_shared/references/adr-guide.md` の記録基準（寿命テスト・波及テスト）にかけ、満たすものだけをプロジェクトルートの `.adr/NNN-title.md` に転記する（既存の連番の続き。ディレクトリがなければ新設する）。転記したエントリには adr.md 側に「→ `.adr/NNN` に昇格」と一行追記する。基準を満たさないエントリは作業履歴としてそのまま残す — adr.md 自体は削除しない。

### レビューファイルの削除

Phase 3 のレビューが APPROVED で完了していれば、レビューの中間成果物を片付ける。指摘はすべてコードに反映済みか台帳の判定として決着しているため、レビューファイルを残す必要はない。

```bash
rm -rf .thread/{Issue番号}/review/
```

- **削除するのは `review/` ディレクトリだけ。** `plan.md` / `steps.md` / `testing.md` / `adr.md` / `progress.md` / `manual-test/` は残す。
- **APPROVED に至らずに終わった場合は削除しない。** レビュー10ラウンド到達、または検証サイクル3周到達で PR が Draft のまま残っている場合は、ユーザーが残った指摘を確認する必要があるため、レビューファイルと台帳をそのまま残す。
- 削除前に、defer で起票した Issue 番号がすべて完了報告に載っていることを確認する（台帳が消えても追跡先が残るように）。
- 削除前に台帳の `wont-fix` 行を確認し、「指摘は正しいが意図的に逸脱している」ものは現場の why not コメントか ADR に転記する（`../_shared/references/review-loop.md` の後片付けに従う）。
- レビューディレクトリが VCS 管理下にある場合（`.thread/` を commit している運用）は、削除もコミットして push する。管理外（`.gitignore` 済み）ならファイルを消すだけでよい。

## 完了報告

すべてのフェーズが完了したら、サマリーを出す。

```text
Issue #{Issue番号} の実装が完了しました！

## 計画
- 契約: .thread/{Issue番号}/plan.md
- 実装手順: .thread/{Issue番号}/steps.md
- 設計判断: .thread/{Issue番号}/adr.md（{あり/なし}）
- 動作確認計画: .thread/{Issue番号}/testing.md
- 残存課題: .thread/{Issue番号}/progress.md（{あり/なし}）

## デザイン
- 実施: {実施（spec/design/pages/ に {数} 画面） / UI画面の新設・変更なしのためスキップ}
- レビュー記録: spec/design/review/（{ラウンド数} / スキップ時はなし）

## 実装
- ブランチ: issue/{Issue番号}/{短い説明}
- PR: #{PR番号}
- コミット数: {数}

## レビュー
- レビューラウンド: {数}回
- 初回ブロッカー: {数}件
- 修正済み: {数}件
- 最終ステータス: APPROVED
- 見送り: wont-fix {数}件 / defer {数}件（起票したIssue: {番号一覧、またはなし}）
- レビューファイル: 削除済み（.thread/{Issue番号}/review/）

## ブラウザ検証
- 成果物: .thread/{Issue番号}/manual-test/（またはスキップ）
- テストケース: {数}件（PASS: {数} / FAIL: {数}）
- 検証サイクル: {数}周
- 起票したIssue: {Issue一覧、またはなし}
- PR状態: Ready for review（レビュー10ラウンド到達・検証3周到達時のみ Draft のまま）

## スコープ外Issue
- {起票したIssue一覧、またはなし}

## コメント整理
- 整理結果: {消した件数とカテゴリ、またはなし}
- コミット: {コミットハッシュ、またはスキップ}

## ダッシュボード
- 更新: {ダッシュボード Issue の URL / ダッシュボード未運用のためスキップ}
- この Issue の表示: {(In Progress) として反映 / 未運用のためなし}

## 片付け
- レビューファイル: {削除済み / APPROVED 未達のため保持（.thread/{Issue番号}/review/）}
- ADR 昇格: {.adr/NNN-... x{数} / 昇格対象なし}
- 残した成果物: plan.md / steps.md / testing.md / adr.md / progress.md / manual-test/
```

## 原則

- Issueの**意図**を満たすことに集中する。steps.md は手段。意図に沿う小さな修正は steps.md 外でもスコープ内（ただし plan.md のスコープは越えない）
- メインはオーケストレーションに徹し、実作業（実装・修正）はサブエージェントに委譲する。実装・レビュー・修正は判断区分、関連コードの所在調査やコマンドの裏取りといった下調べは探索区分。委譲方式・並列実行・モデル選択・失敗時の扱いは `../_shared/references/subagent-policy.md` に従う
